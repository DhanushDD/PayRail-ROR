# PayRail ⚡ — Enterprise Real-Time Payment Platform & Ledger

> **Built for the Accenture Custom Software Engineer Showcase**  
> A high-performance, real-time payment application engineered with Ruby on Rails 8, strict double-entry ledger bookkeeping, deadlock-free pessimistic locking, and decoupled API & Web UI micro-architecture.

---

## 🏛️ System Architecture

PayRail is physically split into two decoupled Ruby on Rails services:

```
                                  ┌──────────────────────────────────────────────┐
                                  │           PAYRAIL PLATFORM ROOT              │
                                  └──────────────────────┬───────────────────────┘
                                                         │
                        ┌────────────────────────────────┴───────────────────────────────┐
                        ▼                                                                ▼
   ┌─────────────────────────────────────────┐                      ┌─────────────────────────────────────────┐
   │             `api/` (Port 3000)          │                      │             `ui/` (Port 3001)           │
   │      Headless Core Payment Engine       │                      │        Modern Responsive Web Portal     │
   ├─────────────────────────────────────────┤                      ├─────────────────────────────────────────┤
   │ • Rails 8.1 API Service                 │  REST API / Webhook  │ • Rails 8.1 Full-Stack (Hotwire/Turbo)  │
   │ • JWT & API-Key Authentication          │ ◄──────────────────► │ • Tailwind CSS Dark/Light FinTech UI    │
   │ • Double-Entry Ledger Service           │                      │ • 1-Click Recruiter Demo Access         │
   │ • Pessimistic Row Locking (`with_lock`) │                      │ • Virtual Card Visualizer & Controls    │
   │ • Idempotency-Key Request Caching       │                      │ • Live In-Browser API Test Runner       │
   │ • Outgoing Webhook Event Dispatcher     │                      │ • Double-Entry Reconciliation Explorer  │
   └─────────────────────────────────────────┘                      └─────────────────────────────────────────┘
                        │                                                                │
                        └────────────────────────────────┬───────────────────────────────┘
                                                         ▼
                                    ┌──────────────────────────────────────────┐
                                    │    SQLite3 High-Performance Ledger DB    │
                                    │     (ACID Invariants: Debits == Credits) │
                                    └──────────────────────────────────────────┘
```

---

## 🎯 Accenture Custom Software Engineering Highlights

When presenting this project during your Accenture interview, highlight these key design patterns:

### 1. Double-Entry Bookkeeping Ledger
Money is never represented as a mutable balance column alone. Every transaction creates **paired, immutable ledger records**:
- **Debit Entry**: Deducted from the sender wallet.
- **Credit Entry**: Added to the recipient wallet.
- **Zero-Sum Invariant**: $\sum \text{Debits} == \sum \text{Credits} + \text{Fees}$. The transaction aborts and rolls back if this condition fails.

### 2. Deadlock-Free Concurrency & Pessimistic Locking
In concurrent payment environments, simultaneous transfers between two users can cause deadlocks if locks are acquired out of order.
- PayRail sorts wallet IDs before acquiring locks: `[sender_id, recipient_id].sort.each(&:lock!)`.
- Re-verifies balances exclusively under the row lock (`with_lock`) to eliminate race conditions and double-spending.

### 3. Idempotent Execution (`Idempotency-Key`)
Network drops and client retries must never cause duplicate payments.
- Supports the `Idempotency-Key` HTTP header.
- Cached outcomes are returned instantly with `X-Idempotency-Replay: true` upon receiving identical keys.

### 4. Decoupled Service Architecture
- `api/`: Stateless, high-throughput RESTful payment gateway with JWT auth, OpenAPI endpoints, and webhook events.
- `ui/`: Rich interactive consumer and merchant portal with virtual debit card controls, QR checkout, and an in-browser developer playground.

---

## 🚀 Quick Start (Running Both Services)

### 1. Automated One-Command Setup
```bash
./setup.sh
```
This installs dependencies, migrates databases, seeds demo personas, and runs the test suite.

### 2. Launch API & UI Servers
```bash
./start.sh
```
- **Web UI Portal**: [http://localhost:3001](http://localhost:3001)
- **REST API Engine**: [http://localhost:3000](http://localhost:3000)

---

## 👤 Recruiter 1-Click Demo Accounts

When opening [http://localhost:3001/login](http://localhost:3001/login), 1-click login cards are available for instant evaluation:

| Persona | PayRail Tag | Role | Pre-Seeded Balance |
|---|---|---|---|
| **Alex Vance (Accenture Demo)** | `$accenture_demo` | Tech Consultant | **$9,711.75** |
| **Alice Johnson** | `$alice` | Senior Engineer | **$4,126.50** |
| **Bob Smith** | `$bob` | Lead Architect | **$5,300.00** |
| **Nova Coffee Roasters** | `$novacoffee` | Merchant | **$1,514.75** |

*(Default password for manual login: `password123`)*

---

## 💻 Key Web UI Features

1. **Dashboard (`/dashboard`)**:
   - Live wallet balance, inflow vs. outflow velocity metrics.
   - Interactive CSS virtual card with real-time **Freeze/Unfreeze** toggle.
   - Fast P2P send bar with instant tag search.
   - Recent transactions table with clickable **Double-Entry Ledger Audit Modals**.
2. **Send & Request Money (`/transfers/new`)**:
   - Live autocomplete recipient search (`/transfers/lookup`).
   - Quick increment chips (`+$10`, `+$50`, `+$100`, `+$500`).
   - Generates official printable payment receipts and ledger audit slips (`/transfers/:reference_id`).
3. **Double-Entry Ledger Explorer (`/ledger`)**:
   - Automated accounting reconciliation proof: $\text{Credits} - \text{Debits} == \text{Wallet Balance}$.
   - Filter by debits or credits with full timestamped audit logs.
4. **Virtual Debit Cards (`/cards`)**:
   - Issue multiple virtual cards (Black Metal, Platinum Horizon, Virtual).
   - Set custom monthly limits and toggle active status.
5. **Shareable Checkout Links (`/payment_links`)**:
   - Generate public payment links and checkout invoices (`/checkout/:token`).
6. **Developer & Recruiter Playground (`/developer`)**:
   - In-browser interactive API console to test `GET /wallets`, `GET /transfers`, and `GET /analytics`.
   - Production API Key (`pr_live_...`) and JWT bearer tokens with ready-to-copy `curl` commands.

---

## 🧪 Automated Test Suite

Both `api/` and `ui/` include automated test suites validating ledger invariants and user journeys:

```bash
# Test Core API Double-Entry Ledger Service & Overdraft Protection
cd api && bin/rails test test/services/transfers_execute_service_test.rb

# Test UI Authentication, Transfer Execution, & Recruiter Access
cd ui && bin/rails test test/controllers/transfers_controller_test.rb
```

---

## 📡 REST API Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/auth/login` | Authenticate & retrieve Bearer JWT |
| `GET` | `/api/v1/wallets` | List user wallets & live balances |
| `GET` | `/api/v1/wallets/:id/ledger` | Fetch wallet double-entry ledger entries |
| `POST` | `/api/v1/transfers` | Execute P2P transfer (`Idempotency-Key` supported) |
| `GET` | `/api/v1/transfers/lookup_recipient` | Search user by tag or email |
| `POST` | `/api/v1/deposits` | Add simulated funds from card or ACH rail |
| `GET` | `/api/v1/cards` | List virtual cards |
| `PATCH`| `/api/v1/cards/:id/toggle_freeze`| Freeze or unfreeze card |
| `GET` | `/api/v1/analytics/overview` | Payment volume, velocity, & monthly stats |
| `GET` | `/api/v1/webhooks` | Outgoing event delivery logs |
