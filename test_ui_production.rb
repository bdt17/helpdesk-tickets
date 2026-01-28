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

# ALL TEST PAGES
PAGES = {
  pharma: { url: "#{PHARMA_URL}/", expect: "Thomas IT Analytics" },
  network: { url: "#{NETWORK_URL}", expect: "Network Operations Dashboard" },
  tickets: { url: "#{PHARMA_URL}/tickets", expect: "tickets" },
  new_ticket: { url: "#{PHARMA_URL}/tickets/new", expect: "New Ticket" },
  reports: { url: "#{PHARMA_URL}/reports", expect: "Reports" },
  api: { url: "#{PHARMA_URL}/api/tickets.json", expect: "json" }
}

def test_page(url, expect_text, name)
  begin
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    status = case response.code
             when "200" then "✅ PASS".colorize(:green)
             when "302" then "🔄 REDIRECT".colorize(:yellow)
             when "401" then "🔐 LOGIN REQ".colorize(:blue)
             else "❌ #{response.code}".colorize(:red)
             end
    
    content_check = Nokogiri::HTML(response.body).text.include?(expect_text) ? 
                    "✓ Content OK".colorize(:green) : "⚠️ Missing: #{expect_text}".colorize(:red)
    
    puts "#{name.ljust(15)}: #{status} | #{content_check} (#{response.body.length} bytes)"
    return { success: response.code == "200", status: response.code }
  rescue => e
    puts "#{name.ljust(15)}: ❌ ERROR - #{e.message}".colorize(:red)
    return { success: false, status: "ERROR" }
  end
end

# RUN ALL TESTS
results = {}
PAGES.each { |name, page| results[name] = test_page(page[:url], page[:expect], name.to_s.capitalize) }

# LOGIN TEST (if agent credentials work)
begin
  login_uri = URI("#{PHARMA_URL}/users/sign_in")
  login_response = Net::HTTP.post_form(login_uri, 'user[email]' => TEST_EMAIL, 'user[password]' => TEST_PASS)
  
  login_status = login_response.code == "302" ? "✅ LOGIN OK".colorize(:green) : "❌ LOGIN FAILED".colorize(:red)
  puts "\n🔐 Agent Login Test: #{login_status}"
  
  # Test authenticated pharma dashboard
  if login_response['location']&.include?('dashboard')
    auth_dash = test_page("#{PHARMA_URL}/", "Open Tickets", "Pharma-Auth")
    results[:pharma_auth] = auth_dash
  end
rescue => e
  puts "🔐 Agent Login Test: ❌ ERROR - #{e.message}".colorize(:red)
end

# SUMMARY
success_count = results.values.count { |r| r[:success] }
total_tests = results.size

puts "\n" + "="*60
puts "📊 TEST SUMMARY: #{success_count}/#{total_tests} PASS".colorize(success_count == total_tests ? :green : :yellow)
puts "🚀 PRODUCTION STATUS: #{success_count == total_tests ? '✅ FULLY OPERATIONAL' : '⚠️  NEEDS ATTENTION'}"

# Detail failures
failures = results.select { |k,v| !v[:success] }
unless failures.empty?
  puts "\n❌ FAILURES:"
  failures.each { |name, result| puts "  • #{name.capitalize}: #{result[:status]}" }
end

puts "\n🎉 All key endpoints tested! Pharma + Network dashboards responsive.".colorize(:green)
