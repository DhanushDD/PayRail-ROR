#!/usr/bin/env bash
set -e

echo "=========================================================="
echo " ⚙️  Setting up PayRail Enterprise Payment Application    "
echo "=========================================================="

echo "1. Bundling and setting up API Engine..."
cd api
bundle install
bin/rails db:migrate
bin/rails db:seed
bin/rails test test/services/transfers_execute_service_test.rb
cd ..

echo "2. Bundling and setting up Web UI Portal..."
cd ui
bundle install
bin/rails db:test:prepare
bin/rails tailwindcss:build
bin/rails test test/controllers/transfers_controller_test.rb
cd ..

echo "3. Verifying Ruby & Rails Interview Handbook (Q1-Q169)..."
bin/verify_handbook

echo "=========================================================="
echo " ✅ Setup Complete! Run './start.sh' to launch PayRail!   "
echo "=========================================================="
