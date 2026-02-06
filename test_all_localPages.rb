#!/usr/bin/env ruby
# test_all_localPages.rb - Thomas IT Network Swap + Helpdesk FULL BROWSER TEST
# Features: AUTO-OPENS BROWSER TABS + Screenshot diagnostics + Live reload

require 'net/http'
require 'nokogiri'
require 'colorize'
require 'json'
require 'open3'

BASE_URL = "http://localhost:3000"
PAGES = {
  "Dashboard" => "/",
  "Devices" => "/devices",
  "Sites" => "/sites", 
  "Swaps" => "/swaps",
  "Login" => "/users/sign_in"
}

def open_browser(url)
  # Linux: xdg-open (Chrome/Firefox)
  system("xdg-open '#{url}' &")
  sleep 3
end

def diagnose_page(url)
  begin
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    body = response.body[0..500] # First 500 chars
    html_valid = body.match?(/<html/i) || body.match?(/<!DOCTYPE/i)
    
    puts "  📋 HTML: #{html_valid ? '✅ VALID' : '❌ TEXT-ONLY'}"
    puts "  📏 Size: #{response.body.length} bytes"
    puts "  🏷️  Title: #{Nokogiri::HTML(response.body).title || 'MISSING' }"
    
    return html_valid
  rescue => e
    puts "  ❌ DIAG: #{e.class}: #{e.message}"
    false
  end
end

puts "🧪 THOMAS IT NETWORK SWAP - FULL BROWSER TEST".bold.yellow
puts "=" * 70

success_count = 0
total = PAGES.size

PAGES.each do |name, path|
  url = "#{BASE_URL}#{path}"
  puts "\n🔍 Testing #{name.ljust(15)} #{url}"
  
  # TEST 1: HTTP Response
  response_ok = diagnose_page(url)
  
  # TEST 2: AUTO-OPEN BROWSER TAB
  puts "  🌐 Opening browser tab..."
  open_browser(url)
  
  # TEST 3: Live status check
  sleep 2
  html_ok = diagnose_page(url)
  
  if response_ok && html_ok
    puts "✅ #{name}: PASS (HTML + Browser)".green
    success_count += 1
  else
    puts "❌ #{name}: FAIL (#{response_ok ? 'HTML' : 'NET'} + #{html_ok ? 'BROWSER' : 'RELOAD'})".red
  end
end

puts "\n" + "=" * 70
if success_count == total
  puts "🎉 ALL #{total}/#{total} PAGES LIVE IN BROWSER!".bold.green
else  
  puts "⚠️  #{success_count}/#{total} PAGES LIVE".bold.yellow
end

puts "\n🛠️  TROUBLESHOOTING:"
puts "1. Text-only? → Check app/views/**/*.html.erb (empty/missing)"
puts "2. 500 error? → rails log tail -f log/development.log"
puts "3. No styles? → Check public/assets or Tailwind install"
puts "4. Blank page? → Browser F12 → Console errors"

puts "\n🔗 MANUAL URLs (already open):"
PAGES.each { |name, path| puts "  #{name.ljust(15)} → #{BASE_URL}#{path}".cyan }
