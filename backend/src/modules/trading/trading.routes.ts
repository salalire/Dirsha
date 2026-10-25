import { Router } from 'express';
import { z } from 'zod';
import { createAuthenticate } from '../../http/auth.js';
import type { AppDeps } from '../../http/types.js';
import { parseWith, uuidSchema } from '../../http/validate.js';
import { Errors } from '../../lib/errors.js';
import {
  cancelOrder,
  listOrders,
  listShareHoldings,
  listTradableSecurities,
  listTrades,
  placeOrder,
} from './trading.service.js';

const placeOrderSchema = z.strictObject({
  ipo_id: uuidSchema,
  side: z.enum(['buy', 'sell']),
  order_type: z.enum(['limit', 'market']).default('limit'),
  price_per_share_minor: z.number().int().positive(),
  quantity: z.number().int().positive(),
  client_id: uuidSchema.optional(),
});

const listHoldingsQuerySchema = z.strictObject({
  client_id: uuidSchema.optional(),
});

const listOrdersQuerySchema = z.strictObject({
  client_id: uuidSchema.optional(),
  ipo_id: uuidSchema.optional(),
  side: z.enum(['buy', 'sell']).optional(),
  status: z.enum(['open', 'partially_filled', 'filled', 'cancelled', 'rejected']).optional(),
});

const listTradesQuerySchema = z.strictObject({
  client_id: uuidSchema.optional(),
  ipo_id: uuidSchema.optional(),
});

export function tradingRouter(deps: AppDeps): Router {
  const router = Router();
  router.use(createAuthenticate(deps));

  // GET /trading/securities: List tradable securities and market activity
  router.get('/securities', async (_req, res) => {
    const securities = await listTradableSecurities(deps.db);
    res.json(securities);
  });

  // GET /trading/holdings: List share holdings (own or authorized client)
  router.get('/holdings', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const query = parseWith(listHoldingsQuerySchema, req.query);
    const holdings = await listShareHoldings(deps.db, req.user, query.client_id);
    res.json(holdings);
  });

  // POST /trading/orders: Place simulated buy/sell order with matching & instant settlement
  router.post('/orders', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const body = parseWith(placeOrderSchema, req.body);
    const result = await placeOrder(deps.db, req.user, body, {
      requestId: req.requestId,
    });
    res.status(201).json(result);
  });

  // POST /trading/orders/:id/cancel: Cancel open order and release remaining cash/shares
  router.post('/orders/:id/cancel', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const orderId = parseWith(uuidSchema, req.params.id);
    const result = await cancelOrder(deps.db, req.user, orderId, {
      requestId: req.requestId,
    });
    res.json(result);
  });

  // GET /trading/orders: List orders for investor or authorized client
  router.get('/orders', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const query = parseWith(listOrdersQuerySchema, req.query);
    const orders = await listOrders(deps.db, req.user, query);
    res.json(orders);
  });

  // GET /trading/trades: List trade history for investor or authorized client
  router.get('/trades', async (req, res) => {
    if (!req.user) throw Errors.unauthenticated();
    const query = parseWith(listTradesQuerySchema, req.query);
    const trades = await listTrades(deps.db, req.user, query);
    res.json(trades);
  });

  return router;
}
