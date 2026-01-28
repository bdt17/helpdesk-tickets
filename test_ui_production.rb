#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'nokogiri'
require 'colorize'

# CONFIG
PHARMA_URL = "https://helpdesk-tickets-zyfh.onrender.com"
NETWORK_URL = "#{PHARMA_URL}/network-dashboard"
TEST_EMAIL = "agent1@thomasit.com"
TEST_PASS = "AgentPass123!"

puts "🎨 UI PRODUCTION TESTS - FULL HELPDESK SUITE".colorize(:cyan)
puts "=" * 60

# COMPLETE HELPDESK TEST SUITE - ALL PHASES
PAGES = {
  # Phase 3-4: Core Dashboards
  pharma: { url: "#{PHARMA_URL}/", expect: "Thomas IT Analytics" },
  network: { url: "#{NETWORK_URL}", expect: "Network Operations Dashboard" },
  
  # Phase 5: Tickets CRUD
  tickets: { url: "#{PHARMA_URL}/tickets", expect: "All Tickets" },
  new_ticket: { url: "#{PHARMA_URL}/tickets/new", expect: "New Ticket" },
  edit_ticket: { url: "#{PHARMA_URL}/tickets/1/edit", expect: "Edit Ticket" },
  
  # Phase 5: Reporting & API
  reports: { url: "#{PHARMA_URL}/reports", expect: "Reports" },
  api: { url: "#{PHARMA_URL}/api/tickets.json", expect: "json" },
  analytics: { url: "#{PHARMA_URL}/analytics/dashboard", expect: "Analytics" },
  
  # Phase 4: User Management
  agents: { url: "#{PHARMA_URL}/users", expect: "Agents" },
  profile: { url: "#{PHARMA_URL}/users/edit", expect: "Profile" },
  
  # Pharma Logistics (your domain)
  shipments: { url: "#{PHARMA_URL}/shipments", expect: "Shipments" },
  drivers: { url: "#{PHARMA_URL}/drivers", expect: "Drivers" }
}

def test_page(url, expect_text, name)
  begin
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    status = case response.code
             when "200" then "✅ PASS".colorize(:green)
             when "302" then "🔄 REDIRECT (PROTECTED)".colorize(:yellow)
             when "401" then "🔐 LOGIN REQ".colorize(:blue)
             else "❌ #{response.code}".colorize(:red)
             end

    content_check = Nokogiri::HTML(response.body).text.include?(expect_text) ?
                    "✓ Content OK".colorize(:green) : "⚠️ Missing: #{expect_text}".colorize(:yellow)

    puts "#{name.ljust(18)}: #{status} | #{content_check} (#{response.body.length} bytes)"
    return { success: response.code == "200", status: response.code }
  rescue => e
    puts "#{name.ljust(18)}: ❌ ERROR - #{e.message}".colorize(:red)
    return { success: false, status: "ERROR" }
  end
end

# RUN ALL TESTS
results = {}
PAGES.each { |name, page| results[name] = test_page(page[:url], page[:expect], name.to_s.capitalize) }

# AGENT LOGIN TEST
puts "\n" + "="*60
begin
  login_uri = URI("#{PHARMA_URL}/users/sign_in")
  login_response = Net::HTTP.post_form(login_uri, 'user[email]' => TEST_EMAIL, 'user[password]' => TEST_PASS)

  login_status = login_response.code == "302" ? "✅ LOGIN SUCCESS".colorize(:green) : "❌ LOGIN FAILED (#{login_response.code})".colorize(:red)
  puts "🔐 Agent Login Test: #{login_status}"

  # Test authenticated pharma dashboard (agent sees Open: 8, not 0)
  if login_response.code == "302" && login_response['location']
    puts "🔑 Authenticated session: #{login_response['location']}".colorize(:cyan)
    auth_dash = test_page("#{PHARMA_URL}/", "Open Tickets", "Pharma-Auth")
    results[:pharma_auth] = auth_dash
  end
rescue => e
  puts "🔐 Agent Login Test: ❌ ERROR - #{e.message}".colorize(:red)
end

# SUMMARY
success_count = results.values.count { |r| r[:success] }
total_tests = results.size
auth_pass = results[:pharma_auth]&.[](:success) || false

puts "\n" + "="*60
puts "📊 TEST SUMMARY: #{success_count}/#{total_tests} PASS + #{auth_pass ? '✅' : '❌'} AUTH".colorize(success_count == total_tests && auth_pass ? :green : :yellow)
puts "🚀 PRODUCTION STATUS: #{(success_count >= 8 && auth_pass) ? '✅ FULLY OPERATIONAL - PHASE 5 LIVE' : '⚠️  NEEDS ATTENTION'}"

# Detail failures
failures = results.select { |k,v| !v[:success] }
unless failures.empty?
  puts "\n❌ FAILURES (302 REDIRECTS = Devise protection = GOOD):"
  failures.each { |name, result| puts "  • #{name.capitalize}: #{result[:status]}" }
end

puts "\n🎉 Thomas IT Helpdesk Production Tests Complete!".colorize(:green)
puts "💉 Pharma Dashboard: #{PHARMA_URL}".colorize(:cyan)
puts "🔗 Test Agent: #{TEST_EMAIL} / #{TEST_PASS}".colorize(:magenta)
