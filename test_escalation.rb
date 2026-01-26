#!/usr/bin/env ruby
require './config/environment'

puts "=== Thomas IT Escalation Test ==="
puts "SopTickets: #{SopTicket.count}"

# Test escalation on ticket #1
job = EscalationAlertJob.new
job.perform(1)

ticket = SopTicket.find(1)
puts "Ticket #1: #{ticket.title} → #{ticket.status}"
puts "✅ Test COMPLETE"
