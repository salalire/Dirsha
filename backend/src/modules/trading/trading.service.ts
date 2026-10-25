import type { Db } from '../../db/pool.js';
import type { AuthUser } from '../../http/types.js';
import { Errors } from '../../lib/errors.js';
import { fromDb } from '../../lib/money.js';
import { recordAudit } from '../audit/audit.service.js';
import { applyLedgerEntry } from '../wallet/ledger.js';

export interface TradableSecurityDto {
  ipo_id: string;
  symbol: string;
  company_name: string;
  status: string;
  price_per_share_minor: number;
  last_traded_price_minor: number | null;
  total_trades: number;
  open_orders_count: number;
}

export interface ShareHoldingDto {
  ipo_id: string;
  symbol: string;
  company_name: string;
  quantity: number;
  reserved_quantity: number;
  available_quantity: number;
}

export interface OrderDto {
  id: string;
  user_id: string;
  assisted_by_broker_id: string | null;
  ipo_id: string;
  symbol: string;
  company_name: string;
  side: 'buy' | 'sell';
  order_type: 'limit' | 'market';
  price_per_share_minor: number;
  quantity: number;
  filled_quantity: number;
  status: 'open' | 'partially_filled' | 'filled' | 'cancelled' | 'rejected';
  reserved_amount_minor: number;
  is_simulated: boolean;
  created_at: string;
  updated_at: string;
}

export interface TradeDto {
  id: string;
  buy_order_id: string;
  sell_order_id: string;
  ipo_id: string;
  symbol: string;
  company_name: string;
  buyer_user_id: string;
  seller_user_id: string;
  price_per_share_minor: number;
  quantity: number;
  total_amount_minor: number;
  is_simulated: boolean;
  executed_at: string;
}

/**
 * Lists tradable securities with their last traded price and open order activity.
 */
export async function listTradableSecurities(db: Db): Promise<{ data: TradableSecurityDto[] }> {
  const { rows } = await db.query<{
    ipo_id: string;
    symbol: string;
    company_name: string;
    status: string;
    price_per_share_minor: string;
    last_traded_price_minor: string | null;
    total_trades: string;
    open_orders_count: string;
  }>(
    `SELECT i.id AS ipo_id, i.symbol, c.legal_name AS company_name, i.status,
            i.price_per_share_minor,
            (SELECT t.price_per_share_minor FROM trades t WHERE t.ipo_id = i.id ORDER BY t.executed_at DESC LIMIT 1) AS last_traded_price_minor,
            (SELECT count(*)::bigint FROM trades t WHERE t.ipo_id = i.id) AS total_trades,
            (SELECT count(*)::bigint FROM orders o WHERE o.ipo_id = i.id AND o.status IN ('open', 'partially_filled')) AS open_orders_count
     FROM ipos i
     JOIN companies c ON c.id = i.company_id
     WHERE i.status IN ('open', 'approved', 'closed', 'allocated')
     ORDER BY i.symbol ASC`,
  );

  return {
    data: rows.map((r) => ({
      ipo_id: r.ipo_id,
      symbol: r.symbol,
      company_name: r.company_name,
      status: r.status,
      price_per_share_minor: fromDb(r.price_per_share_minor),
      last_traded_price_minor: r.last_traded_price_minor ? fromDb(r.last_traded_price_minor) : null,
      total_trades: fromDb(r.total_trades),
      open_orders_count: fromDb(r.open_orders_count),
    })),
  };
}

/**
 * Retrieves share holdings for an investor (or for an authorized client if queried by broker).
 */
export async function listShareHoldings(
  db: Db,
  user: AuthUser,
  clientId?: string,
): Promise<{ data: ShareHoldingDto[] }> {
  let targetUserId = user.id;

  if (clientId) {
    targetUserId = await verifyBrokerClientAuthorization(db, user, clientId);
  } else if (user.role !== 'investor' && user.role !== 'admin') {
    throw Errors.forbidden('Only investors or authorized brokers can view share holdings');
  }

  const { rows } = await db.query<{
    ipo_id: string;
    symbol: string;
    company_name: string;
    quantity: string;
    reserved_quantity: string;
  }>(
    `SELECT sh.ipo_id, i.symbol, c.legal_name AS company_name, sh.quantity, sh.reserved_quantity
     FROM share_holdings sh
     JOIN ipos i ON i.id = sh.ipo_id
     JOIN companies c ON c.id = i.company_id
     WHERE sh.investor_id = $1
     ORDER BY i.symbol ASC`,
    [targetUserId],
  );

  return {
    data: rows.map((r) => {
      const q = fromDb(r.quantity);
      const res = fromDb(r.reserved_quantity);
      return {
        ipo_id: r.ipo_id,
        symbol: r.symbol,
        company_name: r.company_name,
        quantity: q,
        reserved_quantity: res,
        available_quantity: q - res,
      };
    }),
  };
}

/**
 * Places a simulated secondary-market order (buy or sell) with deterministic matching and settlement.
 */
export async function placeOrder(
  db: Db,
  user: AuthUser,
  input: {
    ipo_id: string;
    side: 'buy' | 'sell';
    order_type?: 'limit' | 'market';
    price_per_share_minor: number;
    quantity: number;
    client_id?: string;
  },
  opts: { requestId: string },
): Promise<{ order: OrderDto; trades: TradeDto[] }> {
  let targetUserId = user.id;
  let assistedByBrokerId: string | null = null;

  if (input.client_id) {
    targetUserId = await verifyBrokerClientAuthorization(db, user, input.client_id);
    const brokerRes = await db.query<{ id: string }>(
      'SELECT id FROM brokers WHERE owner_user_id = $1',
      [user.id],
    );
    assistedByBrokerId = brokerRes.rows[0]?.id ?? null;
  } else if (user.role !== 'investor' && user.role !== 'admin') {
    throw Errors.forbidden('Only investors or authorized brokers can place trading orders');
  }

  const orderType = input.order_type ?? 'limit';
  const totalAmountMinor = input.price_per_share_minor * input.quantity;

  return db.tx(async (client) => {
    // Verify IPO exists and fetch metadata
    const ipoRes = await client.query<{ id: string; symbol: string; company_name: string }>(
      `SELECT i.id, i.symbol, c.legal_name AS company_name
       FROM ipos i
       JOIN companies c ON c.id = i.company_id
       WHERE i.id = $1`,
      [input.ipo_id],
    );
    const ipo = ipoRes.rows[0];
    if (!ipo) throw Errors.notFound('Security not found');

    // Get target user's wallet
    const walletRes = await client.query<{ id: string }>(
      'SELECT id FROM wallets WHERE user_id = $1',
      [targetUserId],
    );
    const userWallet = walletRes.rows[0];
    if (!userWallet) throw Errors.notFound('User wallet not found');

    let reservedCashMinor = 0;

    // 1. Financial Reservation
    if (input.side === 'buy') {
      reservedCashMinor = totalAmountMinor;
      // Reserve funds in buyer wallet using existing ledger engine
      await applyLedgerEntry(client, {
        walletId: userWallet.id,
        entryType: 'trade_reserve',
        availableDeltaMinor: -reservedCashMinor,
        reservedDeltaMinor: reservedCashMinor,
        referenceType: 'order',
        initiatedByUserId: user.id,
        initiatedByType: user.role === 'admin' ? 'admin' : 'user',
        description: `Reserved funds for ${input.quantity} shares of ${ipo.symbol} @ ETB ${(input.price_per_share_minor / 100).toFixed(2)}`,
      });
    } else {
      // Sell order: Reserve shares from share_holdings
      const holdingRes = await client.query<{
        id: string;
        quantity: string;
        reserved_quantity: string;
      }>(
        `SELECT id, quantity, reserved_quantity
         FROM share_holdings
         WHERE investor_id = $1 AND ipo_id = $2
         FOR UPDATE`,
        [targetUserId, input.ipo_id],
      );

      const holding = holdingRes.rows[0];
      const availableShares = holding
        ? fromDb(holding.quantity) - fromDb(holding.reserved_quantity)
        : 0;

      if (!holding || availableShares < input.quantity) {
        throw Errors.validation([
          {
            field: 'quantity',
            message: `Insufficient available shares to sell (available: ${availableShares}, requested: ${input.quantity})`,
          },
        ]);
      }

      await client.query(
        `UPDATE share_holdings
         SET reserved_quantity = reserved_quantity + $1
         WHERE id = $2`,
        [input.quantity, holding.id],
      );
    }

    // 2. Insert new Order
    const orderInsert = await client.query<{
      id: string;
      user_id: string;
      assisted_by_broker_id: string | null;
      ipo_id: string;
      side: 'buy' | 'sell';
      order_type: 'limit' | 'market';
      price_per_share_minor: string;
      quantity: string;
      filled_quantity: string;
      status: 'open' | 'partially_filled' | 'filled' | 'cancelled' | 'rejected';
      reserved_amount_minor: string;
      is_simulated: boolean;
      created_at: Date;
      updated_at: Date;
    }>(
      `INSERT INTO orders (
         user_id, assisted_by_broker_id, ipo_id, side, order_type,
         price_per_share_minor, quantity, filled_quantity, status,
         reserved_amount_minor, is_simulated
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, 0, 'open', $8, true)
       RETURNING *`,
      [
        targetUserId,
        assistedByBrokerId,
        input.ipo_id,
        input.side,
        orderType,
        input.price_per_share_minor,
        input.quantity,
        reservedCashMinor,
      ],
    );

    const newOrder = orderInsert.rows[0]!;
    let currentFilled = 0;
    let currentReserved = reservedCashMinor;
    const executedTrades: TradeDto[] = [];

    // 3. Deterministic Matching Engine
    if (input.side === 'buy') {
      // Find candidate sell orders: price <= buyer's limit price, ordered by price ASC, created_at ASC
      const oppOrders = await client.query<{
        id: string;
        user_id: string;
        price_per_share_minor: string;
        quantity: string;
        filled_quantity: string;
        reserved_amount_minor: string;
      }>(
        `SELECT id, user_id, price_per_share_minor, quantity, filled_quantity, reserved_amount_minor
         FROM orders
         WHERE ipo_id = $1 AND side = 'sell' AND status IN ('open', 'partially_filled')
           AND price_per_share_minor <= $2 AND user_id != $3
         ORDER BY price_per_share_minor ASC, created_at ASC
         FOR UPDATE`,
        [input.ipo_id, input.price_per_share_minor, targetUserId],
      );

      for (const sellOrder of oppOrders.rows) {
        const remainingToFill = input.quantity - currentFilled;
        if (remainingToFill <= 0) break;

        const sellRemaining = fromDb(sellOrder.quantity) - fromDb(sellOrder.filled_quantity);
        const matchQuantity = Math.min(remainingToFill, sellRemaining);
        const execPrice = fromDb(sellOrder.price_per_share_minor); // Maker price
        const tradeAmount = execPrice * matchQuantity;

        // Create trade
        const tradeRes = await client.query<{ id: string; executed_at: Date }>(
          `INSERT INTO trades (
             buy_order_id, sell_order_id, ipo_id, buyer_user_id, seller_user_id,
             price_per_share_minor, quantity, total_amount_minor, is_simulated
           )
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)
           RETURNING id, executed_at`,
          [
            newOrder.id,
            sellOrder.id,
            input.ipo_id,
            targetUserId,
            sellOrder.user_id,
            execPrice,
            matchQuantity,
            tradeAmount,
          ],
        );
        const tradeRow = tradeRes.rows[0]!;

        // Settle buyer's reserved cash for this trade portion
        await applyLedgerEntry(client, {
          walletId: userWallet.id,
          entryType: 'trade_settle',
          availableDeltaMinor: 0,
          reservedDeltaMinor: -tradeAmount,
          referenceType: 'trade',
          referenceId: tradeRow.id,
          initiatedByUserId: user.id,
          initiatedByType: 'system',
          description: `Settled payment for ${matchQuantity} shares of ${ipo.symbol}`,
        });

        // Price improvement refund (if buyer limit price > seller execution price)
        const priceDiffPerShare = input.price_per_share_minor - execPrice;
        if (priceDiffPerShare > 0) {
          const refundAmount = priceDiffPerShare * matchQuantity;
          await applyLedgerEntry(client, {
            walletId: userWallet.id,
            entryType: 'trade_release',
            availableDeltaMinor: refundAmount,
            reservedDeltaMinor: -refundAmount,
            referenceType: 'trade',
            referenceId: tradeRow.id,
            initiatedByUserId: user.id,
            initiatedByType: 'system',
            description: `Price improvement refund for ${matchQuantity} shares of ${ipo.symbol}`,
          });
          currentReserved -= refundAmount;
        }

        currentReserved -= tradeAmount;

        // Credit seller's wallet
        const sellerWalletRes = await client.query<{ id: string }>(
          'SELECT id FROM wallets WHERE user_id = $1',
          [sellOrder.user_id],
        );
        if (sellerWalletRes.rows[0]) {
          await applyLedgerEntry(client, {
            walletId: sellerWalletRes.rows[0].id,
            entryType: 'trade_credit',
            availableDeltaMinor: tradeAmount,
            reservedDeltaMinor: 0,
            referenceType: 'trade',
            referenceId: tradeRow.id,
            initiatedByUserId: user.id,
            initiatedByType: 'system',
            description: `Received proceeds for sale of ${matchQuantity} shares of ${ipo.symbol}`,
          });
        }

        // Transfer shares: decrement seller's total and reserved quantity
        await client.query(
          `UPDATE share_holdings
           SET quantity = quantity - $1,
               reserved_quantity = reserved_quantity - $1
           WHERE investor_id = $2 AND ipo_id = $3`,
          [matchQuantity, sellOrder.user_id, input.ipo_id],
        );

        // Increment buyer's share holdings
        await client.query(
          `INSERT INTO share_holdings (investor_id, ipo_id, quantity, reserved_quantity)
           VALUES ($1, $2, $3, 0)
           ON CONFLICT (investor_id, ipo_id)
           DO UPDATE SET quantity = share_holdings.quantity + $3`,
          [targetUserId, input.ipo_id, matchQuantity],
        );

        // Update seller order
        const newSellFilled = fromDb(sellOrder.filled_quantity) + matchQuantity;
        const newSellStatus =
          newSellFilled >= fromDb(sellOrder.quantity) ? 'filled' : 'partially_filled';
        await client.query(
          `UPDATE orders
           SET filled_quantity = $1, status = $2
           WHERE id = $3`,
          [newSellFilled, newSellStatus, sellOrder.id],
        );

        currentFilled += matchQuantity;

        executedTrades.push({
          id: tradeRow.id,
          buy_order_id: newOrder.id,
          sell_order_id: sellOrder.id,
          ipo_id: input.ipo_id,
          symbol: ipo.symbol,
          company_name: ipo.company_name,
          buyer_user_id: targetUserId,
          seller_user_id: sellOrder.user_id,
          price_per_share_minor: execPrice,
          quantity: matchQuantity,
          total_amount_minor: tradeAmount,
          is_simulated: true,
          executed_at: tradeRow.executed_at.toISOString(),
        });
      }
    } else {
      // Sell Order: match against candidate buy orders: price >= seller limit price, ordered by price DESC, created_at ASC
      const oppOrders = await client.query<{
        id: string;
        user_id: string;
        price_per_share_minor: string;
        quantity: string;
        filled_quantity: string;
        reserved_amount_minor: string;
      }>(
        `SELECT id, user_id, price_per_share_minor, quantity, filled_quantity, reserved_amount_minor
         FROM orders
         WHERE ipo_id = $1 AND side = 'buy' AND status IN ('open', 'partially_filled')
           AND price_per_share_minor >= $2 AND user_id != $3
         ORDER BY price_per_share_minor DESC, created_at ASC
         FOR UPDATE`,
        [input.ipo_id, input.price_per_share_minor, targetUserId],
      );

      for (const buyOrder of oppOrders.rows) {
        const remainingToFill = input.quantity - currentFilled;
        if (remainingToFill <= 0) break;

        const buyRemaining = fromDb(buyOrder.quantity) - fromDb(buyOrder.filled_quantity);
        const matchQuantity = Math.min(remainingToFill, buyRemaining);
        const execPrice = fromDb(buyOrder.price_per_share_minor); // Maker price
        const tradeAmount = execPrice * matchQuantity;

        // Create trade
        const tradeRes = await client.query<{ id: string; executed_at: Date }>(
          `INSERT INTO trades (
             buy_order_id, sell_order_id, ipo_id, buyer_user_id, seller_user_id,
             price_per_share_minor, quantity, total_amount_minor, is_simulated
           )
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)
           RETURNING id, executed_at`,
          [
            buyOrder.id,
            newOrder.id,
            input.ipo_id,
            buyOrder.user_id,
            targetUserId,
            execPrice,
            matchQuantity,
            tradeAmount,
          ],
        );
        const tradeRow = tradeRes.rows[0]!;

        // Settle buyer's reserved cash
        const buyerWalletRes = await client.query<{ id: string }>(
          'SELECT id FROM wallets WHERE user_id = $1',
          [buyOrder.user_id],
        );
        if (buyerWalletRes.rows[0]) {
          await applyLedgerEntry(client, {
            walletId: buyerWalletRes.rows[0].id,
            entryType: 'trade_settle',
            availableDeltaMinor: 0,
            reservedDeltaMinor: -tradeAmount,
            referenceType: 'trade',
            referenceId: tradeRow.id,
            initiatedByUserId: user.id,
            initiatedByType: 'system',
            description: `Settled payment for ${matchQuantity} shares of ${ipo.symbol}`,
          });
        }

        // Credit seller's cash
        await applyLedgerEntry(client, {
          walletId: userWallet.id,
          entryType: 'trade_credit',
          availableDeltaMinor: tradeAmount,
          reservedDeltaMinor: 0,
          referenceType: 'trade',
          referenceId: tradeRow.id,
          initiatedByUserId: user.id,
          initiatedByType: 'system',
          description: `Received proceeds for sale of ${matchQuantity} shares of ${ipo.symbol}`,
        });

        // Transfer shares: decrement seller's total and reserved quantity
        await client.query(
          `UPDATE share_holdings
           SET quantity = quantity - $1,
               reserved_quantity = reserved_quantity - $1
           WHERE investor_id = $2 AND ipo_id = $3`,
          [matchQuantity, targetUserId, input.ipo_id],
        );

        // Increment buyer's share holdings
        await client.query(
          `INSERT INTO share_holdings (investor_id, ipo_id, quantity, reserved_quantity)
           VALUES ($1, $2, $3, 0)
           ON CONFLICT (investor_id, ipo_id)
           DO UPDATE SET quantity = share_holdings.quantity + $3`,
          [buyOrder.user_id, input.ipo_id, matchQuantity],
        );

        // Update buyer order
        const newBuyFilled = fromDb(buyOrder.filled_quantity) + matchQuantity;
        const newBuyStatus =
          newBuyFilled >= fromDb(buyOrder.quantity) ? 'filled' : 'partially_filled';
        const newBuyReserved = fromDb(buyOrder.reserved_amount_minor) - tradeAmount;

        await client.query(
          `UPDATE orders
           SET filled_quantity = $1, status = $2, reserved_amount_minor = $3
           WHERE id = $4`,
          [newBuyFilled, newBuyStatus, newBuyReserved, buyOrder.id],
        );

        currentFilled += matchQuantity;

        executedTrades.push({
          id: tradeRow.id,
          buy_order_id: buyOrder.id,
          sell_order_id: newOrder.id,
          ipo_id: input.ipo_id,
          symbol: ipo.symbol,
          company_name: ipo.company_name,
          buyer_user_id: buyOrder.user_id,
          seller_user_id: targetUserId,
          price_per_share_minor: execPrice,
          quantity: matchQuantity,
          total_amount_minor: tradeAmount,
          is_simulated: true,
          executed_at: tradeRow.executed_at.toISOString(),
        });
      }
    }

    // Finalize incoming order state
    const finalStatus =
      currentFilled >= input.quantity
        ? 'filled'
        : currentFilled > 0
          ? 'partially_filled'
          : 'open';

    await client.query(
      `UPDATE orders
       SET filled_quantity = $1, status = $2, reserved_amount_minor = $3
       WHERE id = $4`,
      [currentFilled, finalStatus, currentReserved, newOrder.id],
    );

    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: 'trading.order_placed',
      targetType: 'order',
      targetId: newOrder.id,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: {
        ipo_id: input.ipo_id,
        side: input.side,
        quantity: input.quantity,
        filled: currentFilled,
        price_minor: input.price_per_share_minor,
        assisted_by_broker_id: assistedByBrokerId,
      },
    });

    return {
      order: {
        id: newOrder.id,
        user_id: targetUserId,
        assisted_by_broker_id: assistedByBrokerId,
        ipo_id: input.ipo_id,
        symbol: ipo.symbol,
        company_name: ipo.company_name,
        side: input.side,
        order_type: orderType,
        price_per_share_minor: input.price_per_share_minor,
        quantity: input.quantity,
        filled_quantity: currentFilled,
        status: finalStatus,
        reserved_amount_minor: currentReserved,
        is_simulated: true,
        created_at: newOrder.created_at.toISOString(),
        updated_at: new Date().toISOString(),
      },
      trades: executedTrades,
    };
  });
}

/**
 * Cancels an open or partially filled order, releasing any unspent cash or reserved shares.
 */
export async function cancelOrder(
  db: Db,
  user: AuthUser,
  orderId: string,
  opts: { requestId: string },
): Promise<OrderDto> {
  return db.tx(async (client) => {
    const { rows } = await client.query<{
      id: string;
      user_id: string;
      assisted_by_broker_id: string | null;
      ipo_id: string;
      symbol: string;
      company_name: string;
      side: 'buy' | 'sell';
      order_type: 'limit' | 'market';
      price_per_share_minor: string;
      quantity: string;
      filled_quantity: string;
      status: 'open' | 'partially_filled' | 'filled' | 'cancelled' | 'rejected';
      reserved_amount_minor: string;
      is_simulated: boolean;
      created_at: Date;
      updated_at: Date;
    }>(
      `SELECT o.*, i.symbol, c.legal_name AS company_name
       FROM orders o
       JOIN ipos i ON i.id = o.ipo_id
       JOIN companies c ON c.id = i.company_id
       WHERE o.id = $1
       FOR UPDATE`,
      [orderId],
    );

    const order = rows[0];
    if (!order) throw Errors.notFound('Order not found');

    // Verify ownership or authorized broker assistance
    if (order.user_id !== user.id) {
      if (user.role === 'broker') {
        await verifyBrokerClientAuthorization(db, user, order.user_id);
      } else if (user.role !== 'admin') {
        throw Errors.forbidden('You are not authorized to cancel this order');
      }
    }

    if (order.status !== 'open' && order.status !== 'partially_filled') {
      throw Errors.conflict(`Cannot cancel order in status '${order.status}'`);
    }

    const reservedAmount = fromDb(order.reserved_amount_minor);
    const totalQuantity = fromDb(order.quantity);
    const filledQuantity = fromDb(order.filled_quantity);
    const unfilledQuantity = totalQuantity - filledQuantity;

    if (order.side === 'buy' && reservedAmount > 0) {
      // Release remaining reserved cash back to available
      const walletRes = await client.query<{ id: string }>(
        'SELECT id FROM wallets WHERE user_id = $1',
        [order.user_id],
      );
      if (walletRes.rows[0]) {
        await applyLedgerEntry(client, {
          walletId: walletRes.rows[0].id,
          entryType: 'trade_release',
          availableDeltaMinor: reservedAmount,
          reservedDeltaMinor: -reservedAmount,
          referenceType: 'order',
          referenceId: order.id,
          initiatedByUserId: user.id,
          initiatedByType: user.role === 'admin' ? 'admin' : 'user',
          description: `Released unused funds from cancelled order for ${order.symbol}`,
        });
      }
    } else if (order.side === 'sell' && unfilledQuantity > 0) {
      // Release remaining unfilled shares
      await client.query(
        `UPDATE share_holdings
         SET reserved_quantity = reserved_quantity - $1
         WHERE investor_id = $2 AND ipo_id = $3`,
        [unfilledQuantity, order.user_id, order.ipo_id],
      );
    }

    await client.query(
      `UPDATE orders
       SET status = 'cancelled', reserved_amount_minor = 0
       WHERE id = $1`,
      [order.id],
    );

    await recordAudit(client, {
      actorUserId: user.id,
      actorRole: user.role,
      action: 'trading.order_cancelled',
      targetType: 'order',
      targetId: order.id,
      outcome: 'success',
      requestId: opts.requestId,
      metadata: {
        ipo_id: order.ipo_id,
        unfilled_quantity: unfilledQuantity,
        released_cash_minor: reservedAmount,
      },
    });

    return {
      id: order.id,
      user_id: order.user_id,
      assisted_by_broker_id: order.assisted_by_broker_id,
      ipo_id: order.ipo_id,
      symbol: order.symbol,
      company_name: order.company_name,
      side: order.side,
      order_type: order.order_type,
      price_per_share_minor: fromDb(order.price_per_share_minor),
      quantity: totalQuantity,
      filled_quantity: filledQuantity,
      status: 'cancelled',
      reserved_amount_minor: 0,
      is_simulated: order.is_simulated,
      created_at: order.created_at.toISOString(),
      updated_at: new Date().toISOString(),
    };
  });
}

/**
 * Lists orders for an investor (or for an authorized client if queried by broker).
 */
export async function listOrders(
  db: Db,
  user: AuthUser,
  filters: {
    client_id?: string;
    ipo_id?: string;
    side?: 'buy' | 'sell';
    status?: string;
  },
): Promise<{ data: OrderDto[] }> {
  let targetUserId = user.id;

  if (filters.client_id) {
    targetUserId = await verifyBrokerClientAuthorization(db, user, filters.client_id);
  } else if (user.role !== 'investor' && user.role !== 'admin') {
    throw Errors.forbidden('Only investors or authorized brokers can list trading orders');
  }

  const params: unknown[] = [targetUserId];
  let whereSql = 'WHERE o.user_id = $1';

  if (filters.ipo_id) {
    params.push(filters.ipo_id);
    whereSql += ` AND o.ipo_id = $${params.length}`;
  }
  if (filters.side) {
    params.push(filters.side);
    whereSql += ` AND o.side = $${params.length}`;
  }
  if (filters.status) {
    params.push(filters.status);
    whereSql += ` AND o.status = $${params.length}`;
  }

  const { rows } = await db.query<{
    id: string;
    user_id: string;
    assisted_by_broker_id: string | null;
    ipo_id: string;
    symbol: string;
    company_name: string;
    side: 'buy' | 'sell';
    order_type: 'limit' | 'market';
    price_per_share_minor: string;
    quantity: string;
    filled_quantity: string;
    status: 'open' | 'partially_filled' | 'filled' | 'cancelled' | 'rejected';
    reserved_amount_minor: string;
    is_simulated: boolean;
    created_at: Date;
    updated_at: Date;
  }>(
    `SELECT o.*, i.symbol, c.legal_name AS company_name
     FROM orders o
     JOIN ipos i ON i.id = o.ipo_id
     JOIN companies c ON c.id = i.company_id
     ${whereSql}
     ORDER BY o.created_at DESC`,
    params,
  );

  return {
    data: rows.map((r) => ({
      id: r.id,
      user_id: r.user_id,
      assisted_by_broker_id: r.assisted_by_broker_id,
      ipo_id: r.ipo_id,
      symbol: r.symbol,
      company_name: r.company_name,
      side: r.side,
      order_type: r.order_type,
      price_per_share_minor: fromDb(r.price_per_share_minor),
      quantity: fromDb(r.quantity),
      filled_quantity: fromDb(r.filled_quantity),
      status: r.status,
      reserved_amount_minor: fromDb(r.reserved_amount_minor),
      is_simulated: r.is_simulated,
      created_at: r.created_at.toISOString(),
      updated_at: r.updated_at.toISOString(),
    })),
  };
}

/**
 * Lists executed trades where caller or authorized client was buyer or seller.
 */
export async function listTrades(
  db: Db,
  user: AuthUser,
  filters: {
    client_id?: string;
    ipo_id?: string;
  },
): Promise<{ data: TradeDto[] }> {
  let targetUserId = user.id;

  if (filters.client_id) {
    targetUserId = await verifyBrokerClientAuthorization(db, user, filters.client_id);
  } else if (user.role !== 'investor' && user.role !== 'admin') {
    throw Errors.forbidden('Only investors or authorized brokers can list trade history');
  }

  const params: unknown[] = [targetUserId];
  let whereSql = 'WHERE (t.buyer_user_id = $1 OR t.seller_user_id = $1)';

  if (filters.ipo_id) {
    params.push(filters.ipo_id);
    whereSql += ` AND t.ipo_id = $${params.length}`;
  }

  const { rows } = await db.query<{
    id: string;
    buy_order_id: string;
    sell_order_id: string;
    ipo_id: string;
    symbol: string;
    company_name: string;
    buyer_user_id: string;
    seller_user_id: string;
    price_per_share_minor: string;
    quantity: string;
    total_amount_minor: string;
    is_simulated: boolean;
    executed_at: Date;
  }>(
    `SELECT t.*, i.symbol, c.legal_name AS company_name
     FROM trades t
     JOIN ipos i ON i.id = t.ipo_id
     JOIN companies c ON c.id = i.company_id
     ${whereSql}
     ORDER BY t.executed_at DESC`,
    params,
  );

  return {
    data: rows.map((r) => ({
      id: r.id,
      buy_order_id: r.buy_order_id,
      sell_order_id: r.sell_order_id,
      ipo_id: r.ipo_id,
      symbol: r.symbol,
      company_name: r.company_name,
      buyer_user_id: r.buyer_user_id,
      seller_user_id: r.seller_user_id,
      price_per_share_minor: fromDb(r.price_per_share_minor),
      quantity: fromDb(r.quantity),
      total_amount_minor: fromDb(r.total_amount_minor),
      is_simulated: r.is_simulated,
      executed_at: r.executed_at.toISOString(),
    })),
  };
}

/**
 * Helper to ensure a broker has an active authorized relationship with a client.
 */
async function verifyBrokerClientAuthorization(
  db: Db,
  user: AuthUser,
  clientId: string,
): Promise<string> {
  if (user.role === 'admin') return clientId;

  if (user.role !== 'broker') {
    throw Errors.forbidden('Only authorized brokers can act on behalf of a client');
  }

  const brokerRes = await db.query<{ id: string }>(
    'SELECT id FROM brokers WHERE owner_user_id = $1',
    [user.id],
  );
  const broker = brokerRes.rows[0];
  if (!broker) throw Errors.forbidden('Broker profile not found');

  const relRes = await db.query<{ status: string }>(
    `SELECT status FROM broker_client_relationships
     WHERE broker_id = $1 AND investor_id = $2`,
    [broker.id, clientId],
  );

  const rel = relRes.rows[0];
  if (!rel || rel.status !== 'active') {
    throw Errors.forbidden(
      `Access denied. Active client authorization is required (current: ${rel?.status ?? 'none'})`,
    );
  }

  return clientId;
}
