#!/bin/bash
rails runner "
5.times do |i|
  Ticket.create!(
    title: "Network Issue ##{i+1}",
    description: "Customer reports WAN connectivity down on Cisco ISR4000. FortiGate logs show drops. Palo Alto PA220 interface eth1/1 down.",
    status: ['New', 'In Progress', 'Resolved'].sample
  )
end
puts '✅ 5 TEST TICKETS CREATED!'
Ticket.count
"
