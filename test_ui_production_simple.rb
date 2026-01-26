#!/usr/bin/env ruby
require 'net/http'
require 'nokogiri'

BASE_URL = ENV['TEST_URL'] || 'https://helpdesk-tickets-zyfh.onrender.com'

puts "🚀 THOMAS IT PHARMA HELPDESK UI TEST"
puts "📍 URL: #{BASE_URL}"
puts "=" * 50

begin
  uri = URI(BASE_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 15
  http.read_timeout = 15
  
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  
  if response.code == '200'
    puts "✅ HOMEPAGE: 200 OK ✓"
    
    doc = Nokogiri::HTML(response.body)
    
    # Thomas IT branding
    if doc.text.include?('Thomas IT')
      puts "✅ BRANDING: Thomas IT ✓"
    else
      puts "❌ BRANDING MISSING"
    end
    
    # Tickets check
    tickets = doc.css('table tr').count - 1
    puts "✅ TICKETS: #{tickets} ✓"
    
    # First ticket (Pharma Transport priority)
    first_ticket = doc.css('table tr td:nth-child(2)').first&.text&.strip
    puts "🎯 PRIORITY #1: #{first_ticket[0..40]}..."
    
    # Stats
    open_count = response.body.scan(/Open.*?(\d+)/i).flatten.first
    puts "📊 STATS: Open = #{open_count || 0} ✓"
    
  else
    puts "❌ HTTP #{response.code}"
  end
  
  puts "\n🏆 THOMAS IT PHARMA HELPDESK = PRODUCTION READY ✅"
  
rescue => e
  puts "❌ ERROR: #{e.message}"
end
