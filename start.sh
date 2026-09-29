#!/usr/bin/env bash
set -e

echo "=========================================================="
echo " 🚀 Starting PayRail Platform (API + Modern Web UI)      "
echo "=========================================================="

API_PORT=3000
UI_PORT=3001

echo "-> Starting PayRail Core API on http://127.0.0.1:${API_PORT}"
(cd api && bundle exec rails server -p ${API_PORT}) &
API_PID=$!

echo "-> Starting PayRail Web UI on http://127.0.0.1:${UI_PORT}"
(cd ui && bundle exec rails server -p ${UI_PORT}) &
UI_PID=$!

# Trap SIGINT / SIGTERM to cleanly kill both processes on Ctrl+C
cleanup() {
  echo ""
  echo "🛑 Stopping PayRail servers..."
  kill -9 $API_PID $UI_PID 2>/dev/null || true
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

echo ""
echo "=========================================================="
echo " ✅ Both PayRail services are running!                     "
echo " 🌐 Web UI Portal:   http://localhost:${UI_PORT}           "
echo " ⚡ REST API Engine: http://localhost:${API_PORT}          "
echo "=========================================================="
echo " 💡 Recruiter Quick Login is available on the login page! "
echo " Press Ctrl+C to stop both servers.                       "
echo "=========================================================="

wait
