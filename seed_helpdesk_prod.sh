#!/bin/bash
echo "🌱 SEEDING HELPDESK PRODUCTION DATA"

# Run on Render shell or local with DATABASE_URL
rails db:migrate RAILS_ENV=production
rails db:seed RAILS_ENV=production

echo "✅ 10 test tickets, 5 users, 3 shipments seeded"
