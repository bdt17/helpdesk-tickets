# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Pharma Transport Project
SopTicket.create!(
  title: "Pharma Transport Build Sprint 1",
  description: "Complete Kubernetes deployment pipeline for pharmaceutical logistics platform. FDA compliance validation required.",
  priority: "high",
  status: "open"
)

# Thomas IT Helpdesk Project
SopTicket.create!(
  title: "Thomas IT Helpdesk Rails 8.1 Optimization", 
  description: "Performance tuning + seed data for production deployment. Add analytics dashboard metrics.",
  priority: "medium",
  status: "open"
)
