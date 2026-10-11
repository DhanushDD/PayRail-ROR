# PayRail — Ruby on Rails Authentication, Sidekiq Jobs & RSpec

A clean, modular Ruby on Rails application built to demonstrate core backend engineering skills:
- **RESTful Authentication (`sign_up` / `login` / `logout` / `me`)** using JWT Bearer tokens (`jwt`) and `bcrypt` (`has_secure_password`).
- **Background Job Processing (`Sidekiq`, `ActiveJob`, & `sidekiq-cron`)**:
  - `WelcomeEmailJob`: Enqueued asynchronously on user registration (`mailers` queue).
  - `LoginNotificationJob`: Enqueued asynchronously on login to update sign-in metrics and dispatch security alerts (`default` queue).
  - `SessionCleanupJob`: Recurring cron job configured via `sidekiq-cron` (`config/schedule.yml`) on the `maintenance` queue.
- **Database Optimization**: Unique & composite indexes on `users` (`email`, `payrail_tag`, `api_key`, `[:role, :created_at]`) and optimized query scopes (`User.find_by_identifier`).
- **Automated Testing (`RSpec`)**: Full model, background job, and request test coverage in `spec/`.

---

## Project Structure

- `api/` — Rails 8.1 API-only backend (Port `3000`)
- `ui/` — Rails 8.1 Web Portal for Sign Up, Login, Logout & Profile Dashboard (Port `3001`)

---

## Quick Start

### 1. Setup & Seed Database
```bash
./setup.sh
```

### 2. Run RSpec Test Suites
```bash
cd api && bundle exec rspec
cd ../ui && bundle exec rspec
```

### 3. Start Servers
```bash
./start.sh
```
- **Web UI**: `http://localhost:3001`
- **REST API**: `http://localhost:3000`

---

## RESTful API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/auth/sign_up` | Register a new user & enqueue `WelcomeEmailJob` |
| `POST` | `/api/v1/auth/login` | Authenticate via email or `$tag`, return JWT & enqueue `LoginNotificationJob` |
| `DELETE` | `/api/v1/auth/logout` | Log out authenticated user |
| `GET` | `/api/v1/auth/me` | Fetch current authenticated user profile |
