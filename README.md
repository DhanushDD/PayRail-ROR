# PayRail — Payment App with RESTful Auth, Sidekiq Jobs & RSpec

A clean, modular Ruby on Rails payment application demonstrating core backend engineering skills:
- **Fundamental Payment App Features**:
  - **Digital Wallet**: Automatic `$1,000.00` wallet provisioning on registration, instant wallet top-up (`deposit!`), and pessimistic locking (`lock!`).
  - **P2P Money Transfers (`Payment.transfer!`)**: Send money by `$tag` or email inside an ACID database transaction with balance validation and history tracking.
- **Authentication (`sign_up` / `login` / `logout` / `me`)**: JWT Bearer tokens (`jwt`) and `bcrypt` (`has_secure_password`).
- **Background Job Processing (`Sidekiq`, `ActiveJob`, & `sidekiq-cron`)**:
  - `WelcomeEmailJob`: Enqueued asynchronously on user registration (`mailers` queue).
  - `LoginNotificationJob`: Enqueued asynchronously on login to update sign-in metrics and dispatch security alerts (`default` queue).
  - `PaymentNotificationJob`: Enqueued asynchronously on P2P payment completion to email a receipt (`payments` queue).
  - `SessionCleanupJob`: Recurring cron job configured via `sidekiq-cron` (`config/schedule.yml`) on the `maintenance` queue.
- **Database Optimization**: Unique & composite indexes on `users`, `wallets`, and `payments` for fast lookups and history queries.
- **Automated Testing (`RSpec`)**: Full model, background job, and request test coverage in `spec/` (`24 examples, 0 failures`).

---

## RESTful API Endpoints (`Port 3000`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/auth/sign_up` | Register a new user, provision `$1,000` wallet & enqueue `WelcomeEmailJob` |
| `POST` | `/api/v1/auth/login` | Authenticate via email or `$tag`, return JWT & enqueue `LoginNotificationJob` |
| `DELETE` | `/api/v1/auth/logout` | Log out authenticated user |
| `GET` | `/api/v1/auth/me` | Fetch current authenticated user & wallet profile |
| `GET` | `/api/v1/payments` | List wallet balance & recent payment transactions |
| `POST` | `/api/v1/payments` | Send P2P payment to `$tag` or email & enqueue `PaymentNotificationJob` |
| `POST` | `/api/v1/payments/deposit` | Add money to wallet balance |

---

## Quick Start

```bash
# Run RSpec tests
cd api && bundle exec rspec
cd ../ui && bundle exec rspec

# Start API (3000) & Web UI (3001)
./start.sh
```
