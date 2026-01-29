#!/usr/bin/env ruby
# Thomas IT Helpdesk - ORIGINAL PRODUCTION DATA BACKUP

tickets = [
  { title: "Pharma Transport - missing implementations", status: "open" },
  { title: "Thomas IT drones IT functions", status: "open" },
  { title: "3-D printing optimization", status: "in_progress" },
  { title: "Pfizer shipment delay - site-42", status: "open" },
  { title: "FDA compliance alert", status: "in_progress" },
  { title: "Multi-region K8s deployment", status: "open" },
  { title: "Pharma Transport - missing implementations", status: "open" },
  { title: "Thomas IT drones IT functions", status: "open" },
  { title: "3-D printing optimization", status: "in_progress" },
  { title: "Pfizer shipment delay - site-42", status: "open" }
]

tickets.each do |t|
  Ticket.create!(t)
  puts "✅ #{t[:title]} created"
end

puts "\n🎉 THOMAS IT HELPDESK: 10 PRODUCTION TICKETS LIVE!"
