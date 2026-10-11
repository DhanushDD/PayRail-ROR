#!/usr/bin/env bash
set -e

echo "=========================================================="
echo " ⚙️  Setting up PayRail Payment & Authentication App       "
echo "=========================================================="

echo "1. Bundling and setting up API Engine..."
cd api
bundle install
bin/rails db:migrate
bin/rails db:seed
RAILS_ENV=test bin/rails db:migrate
bundle exec rspec
cd ..

echo "2. Bundling and setting up Web UI Portal..."
cd ui
bundle install
cp ../api/db/schema.rb db/schema.rb
RAILS_ENV=test bin/rails db:migrate
bundle exec rspec
cd ..

echo "=========================================================="
echo " ✅ Setup Complete! Run './start.sh' to launch PayRail!   "
echo "=========================================================="
