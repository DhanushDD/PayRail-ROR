# PayRail — Payment Gateway Lifecycle, RESTful Auth, Sidekiq & RSpec

A clean, production-grade Ruby on Rails 8.1 application tailored for a **Custom Software Engineer (Payments Fundamentals & Ruby on Rails)** role.

---

## Core Payment Gateway & Backend Engineering Features

### 1. Payment Gateway Workflow (`Authorize → Capture / Void → Refund`)
- **Step 1 — Authorization (`Payment.authorize!`)**:
  - Validates card/payment method via `PaymentGatewayService`, issues an authorization code (`AUTH-XXXXXX`) and `gateway_transaction_id`, and places a hold on customer funds (`held_balance_cents`).
- **Step 2A — Capture & Fee Settlement (`Payment#capture!`)**:
  - Releases the authorization hold, calculates gateway processing fees (`2.9% + $0.30`), credits the net settlement amount (`net_amount_cents`) to the merchant wallet, and writes paired double-entry ledger entries.
- **Step 2B — Authorization Void (`Payment#void!`)**:
  - Cancels an `authorized` payment before capture and releases held funds back to the customer's available balance.
- **Step 3 — Payment Refund (`Payment#refund!`)**:
  - Reverses a `captured` or `completed` payment atomically, restoring funds and recording offsetting `debit`/`credit` ledger entries.
- **Step 4 — HMAC-SHA256 Gateway Webhooks (`POST /api/v1/webhooks/gateway`)**:
  - Verifies the `X-PayRail-Signature` header using `OpenSSL::HMAC` (`ActiveSupport::SecurityUtils.secure_compare`), stores idempotent [`WebhookEvent`](api/app/models/webhook_event.rb) records, and processes events asynchronously via [`GatewayWebhookJob`](api/app/jobs/gateway_webhook_job.rb).

### 2. Payments Fundamentals (`Wallet`, `Payment`, `LedgerEntry`)
- **Double-Entry Bookkeeping Ledger**: Every settled transaction writes paired `debit` and `credit` records with a verified `balance_after_cents` audit trail.
- **Idempotency Key Protection (`Idempotency-Key`)**: Prevents duplicate charges on network retries.
- **Deadlock-Free Pessimistic Locking (`lock!`)**: Locks wallet rows in deterministic primary-key order inside ACID database transactions.

### 3. Authentication (`sign_up` / `login` / `logout` / `me`)
- Stateless RESTful API authentication via **JWT Bearer tokens** (`JwtService`) and `X-API-Key` headers.
- Secure password hashing via `bcrypt` (`has_secure_password`).
- Web UI Portal (`Port 3001`) with Sign Up, Log In (1-tap Demo Login), and Payment Gateway Checkout Dashboard.

### 4. Background Job Processing (`Sidekiq`, `ActiveJob`, `sidekiq-cron`)
- [`WelcomeEmailJob`](api/app/jobs/welcome_email_job.rb) (`mailers` queue) — Sends welcome email on registration.
- [`LoginNotificationJob`](api/app/jobs/login_notification_job.rb) (`default` queue) — Tracks sign-in count/timestamp and sends security alert.
- [`PaymentNotificationJob`](api/app/jobs/payment_notification_job.rb) (`payments` queue) — Sends payment receipt email on capture/transfer/refund.
- [`GatewayWebhookJob`](api/app/jobs/gateway_webhook_job.rb) (`webhooks` queue) — Processes asynchronous gateway webhook events (`payment.captured`, `payment.voided`, `payment.refunded`, `payment.failed`).
- [`SessionCleanupJob`](api/app/jobs/session_cleanup_job.rb) (`maintenance` queue) — Recurring daily cron job scheduled in `config/schedule.yml` via `sidekiq-cron`.

---

## RESTful API Endpoints (`Port 3000`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/auth/sign_up` | Register user, provision `$1,000` wallet & enqueue `WelcomeEmailJob` |
| `POST` | `/api/v1/auth/login` | Authenticate via email or `$tag`, return JWT & enqueue `LoginNotificationJob` |
| `DELETE` | `/api/v1/auth/logout` | Log out authenticated user |
| `GET` | `/api/v1/auth/me` | Fetch current user & wallet profile |
| `GET` | `/api/v1/payments` | List wallet balance, held balance, payments, and double-entry ledger |
| `POST` | `/api/v1/payments` | Instant P2P payment transfer (supports `Idempotency-Key` header) |
| `POST` | `/api/v1/payments/authorize` | **Gateway Step 1**: Authorize payment & place hold on funds |
| `POST` | `/api/v1/payments/:id/capture` | **Gateway Step 2A**: Capture authorized hold & settle net amount (`2.9% + $0.30` fee) |
| `POST` | `/api/v1/payments/:id/void` | **Gateway Step 2B**: Void authorization & release held funds |
| `POST` | `/api/v1/payments/:id/refund` | **Gateway Step 3**: Refund captured/completed payment |
| `POST` | `/api/v1/payments/deposit` | Deposit funds into wallet |
| `POST` | `/api/v1/webhooks/gateway` | **Gateway Step 4**: Receive HMAC-SHA256 signed gateway webhooks |

---

## Quick Start

```bash
# 1. Setup database, seed demo data, and run all RSpec suites
./setup.sh

# 2. Start API (http://localhost:3000) & Web UI (http://localhost:3001)
./start.sh
```
