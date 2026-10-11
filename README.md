# PayRail — Payments Fundamentals, RESTful API, Sidekiq & RSpec

A clean, production-grade Ruby on Rails 8.1 application tailored for a **Custom Software Engineer (Payments Fundamentals & Ruby on Rails)** role.

---

## Core Capabilities & Architecture

### 1. Payments Fundamentals (`Wallet`, `Payment`, `LedgerEntry`)
- **Double-Entry Bookkeeping Ledger**: Every P2P transfer or refund atomically writes paired `debit` and `credit` records in `ledger_entries` with a verified `balance_after_cents` audit trail.
- **Idempotency Key Protection (`Idempotency-Key`)**: Prevents duplicate charges on network retries via unique database constraint and idempotent lookup.
- **Deadlock-Free Pessimistic Locking (`lock!`)**: Locks sender and recipient wallet rows in deterministic primary-key order inside an ACID transaction (`ActiveRecord::Base.transaction`).
- **Instant Payment Refunds (`Payment#refund!`)**: Reverses completed P2P transfers atomically, updating original payment status to `refunded` and recording offsetting ledger entries.

### 2. Authentication (`sign_up` / `login` / `logout` / `me`)
- Stateless RESTful API authentication via **JWT Bearer tokens** (`JwtService`) and `X-API-Key` headers.
- Secure password hashing via `bcrypt` (`has_secure_password`).
- Full Web UI session authentication (`Sign Up`, `Log In` with 1-tap Demo Access, `Log Out`).

### 3. Background Job Processing (`Sidekiq`, `ActiveJob`, `sidekiq-cron`)
- [`WelcomeEmailJob`](api/app/jobs/welcome_email_job.rb) (`mailers` queue): Dispatches welcome email on registration.
- [`LoginNotificationJob`](api/app/jobs/login_notification_job.rb) (`default` queue): Updates sign-in count/timestamp and sends security alert email.
- [`PaymentNotificationJob`](api/app/jobs/payment_notification_job.rb) (`payments` queue): Sends instant payment receipt email to recipients.
- [`SessionCleanupJob`](api/app/jobs/session_cleanup_job.rb) (`maintenance` queue): Daily cron job scheduled in `config/schedule.yml` via `sidekiq-cron`.

### 4. Database Performance & Automated Testing (`RSpec`)
- Unique & composite indexes across `users`, `wallets`, `payments`, and `ledger_entries`.
- Comprehensive RSpec suite (`25 examples, 0 failures`) covering models, Sidekiq jobs, and REST API / UI payment & auth workflows.

---

## RESTful API Endpoints (`Port 3000`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/auth/sign_up` | Register user, provision `$1,000` wallet & enqueue `WelcomeEmailJob` |
| `POST` | `/api/v1/auth/login` | Authenticate via email or `$tag`, return JWT & enqueue `LoginNotificationJob` |
| `DELETE` | `/api/v1/auth/logout` | Log out authenticated user |
| `GET` | `/api/v1/auth/me` | Fetch current user & wallet profile |
| `GET` | `/api/v1/payments` | List wallet balance, recent payments, and double-entry ledger entries |
| `POST` | `/api/v1/payments` | Execute atomic P2P payment (supports `Idempotency-Key` header) |
| `POST` | `/api/v1/payments/deposit` | Deposit funds into wallet |
| `POST` | `/api/v1/payments/:id/refund` | Refund a completed payment & reverse wallet balances |

---

## Quick Start

```bash
# 1. Setup database, seed demo data, and run all RSpec suites
./setup.sh

# 2. Start API (http://localhost:3000) & Web UI (http://localhost:3001)
./start.sh
```
