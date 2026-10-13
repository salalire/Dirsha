# Dirsha

**IPO management and real-time share trading for Ethiopia.**

*Dirsha* (ድርሻ) means "share" in Amharic. Dirsha lets companies offer shares to the public through a digital IPO, lets people subscribe from their phones, and, once the IPO closes, lets shareholders buy and sell those shares with each other in real time.

> Status: early design phase. Nothing here is production-ready, and Dirsha is not a licensed exchange or broker. See [Compliance](#compliance-and-disclaimer).

---

## Why Dirsha

Selling shares to the public in Ethiopia is slow and paper-heavy for companies, and confusing for everyday people who have money but have never bought a share. The same problem exists for banks, real estate companies and any business that wants to raise money from many small investors.

Dirsha digitizes the whole path:

1. A company lists an IPO.
2. Investors subscribe, with or without the help of a broker.
3. Shares are allocated and the company receives the capital.
4. The shares then trade on a live market between users.

## Users

| Role | What they do |
|---|---|
| **Investor** | Registers and verifies identity, funds a wallet, subscribes to IPOs, trades listed shares, tracks a portfolio |
| **Company** | Registers, submits an IPO with documents, tracks subscriptions and capital raised, sees its shareholders after listing |
| **Broker** | Guides investors who need help: explains IPOs, gives advice, and (only when allowed) places orders for them |
| **Admin** | Approves companies, brokers, investors and IPOs, controls market open/close, monitors activity, handles suspensions |

### Investor modes

Each investor chooses how a broker may help them, and can change or revoke it at any time:

- **Self-directed:** no broker; the investor does everything.
- **Advisory:** the broker advises, the investor places the orders.
- **Managed:** the broker places orders within limits the investor sets.

## IPO lifecycle

```
Company submits IPO  ->  DRAFT / PENDING
        |
Admin reviews documents
        |
   Approved  ->  OPEN (subscription period)
        |
Investors subscribe (money is reserved in their wallet)
        |
Subscription period ends
        |
Allocation (full, or pro-rata if oversubscribed)
        |
Unused money refunded, shares credited, company receives capital
        |
   CLOSED -> shares are LISTED and open for trading
```

## Trading (after listing)

Dirsha uses a real **order book** per listed stock, not simulated prices.

- Users place **limit orders** (their own price) or **market orders** (best available price).
- A matching engine pairs buyers and sellers by price, then by time.
- The **last matched trade** sets the market price, pushed to all users live over WebSocket.
- Cash and shares are **reserved** when an order is placed, so nobody can spend money twice or sell shares they don't own.
- The admin can open or close the market, or halt a single stock.

## AI assistant (planned, phase 2)

An assistant that **explains and informs**; it does not give personal buy/sell recommendations and never trades by itself.

- Explains an IPO in plain Amharic or English from the company's submitted documents
- Answers basic questions about shares, dividends, oversubscription and risk
- Helps brokers summarize IPOs and client portfolios
- Helps admins flag incomplete submissions and unusual activity

## Architecture

```
  Flutter app (Investor / Broker / Company)      Flutter web (Admin)
                     |                                   |
                     +----------- HTTPS / WebSocket -----+
                                      |
                              Node.js API server
        auth | ipo | wallet | orders & matching | brokers | admin | (ai)
                      |                       |
                 PostgreSQL                 Redis
        (users, ledger, orders, trades)   (live prices, sessions, queues)
```

## Tech stack

| Layer | Choice |
|---|---|
| Mobile and admin UI | Flutter |
| Backend | Node.js (TypeScript) |
| Database | PostgreSQL |
| Cache / pub-sub | Redis |
| Real-time | WebSocket (price and order updates) |
| Auth | JWT access + refresh tokens, role-based access control |

## Repository structure

```
Dirsha/
├── README.md
├── docs/        design, database schema, API outline, user flows
├── backend/     Node.js API
├── mobile/      Flutter app (investor, broker, company)
└── admin/       Flutter web admin dashboard
```

Full design details are in [`docs/DESIGN.md`](docs/DESIGN.md).

## Getting started

Setup instructions will be added as each part is built.

```bash
git clone <repo-url>
cd Dirsha
# backend/  -> see backend/README.md (coming soon)
# mobile/   -> see mobile/README.md (coming soon)
```

## Roadmap

- [ ] **Phase 0: Design.** User flows, schema, API outline, matching rules
- [ ] **Phase 1: Core.** Auth and roles, KYC flow, wallet and ledger, IPO lifecycle, admin approvals
- [ ] **Phase 2: Market.** Order book, matching engine, live prices, portfolios
- [ ] **Phase 3: Brokers.** Broker onboarding, investor-broker links and modes, audit trail
- [ ] **Phase 4: AI assistant.** IPO explainer, broker tools, admin flagging
- [ ] **Phase 5: Real-world readiness.** Payment integration, ID verification, security review, regulatory alignment

## Compliance and disclaimer

Securities trading is regulated. Before real money is involved, Dirsha must be reviewed against Ethiopian securities and financial regulations, including rules on exchanges, licensed intermediaries, investor identity checks and payments. Until then this is a development project. Nothing in it is investment advice.

## Team

A team of three. Roles and ownership will be listed here.

## Credits

Dirsha is a ground-up rebuild inspired by an earlier Java prototype, BrokerCraft.
