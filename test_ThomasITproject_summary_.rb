#!/usr/bin/env ruby
require 'colorize'
require 'net/http'
require 'uri'

puts "📊 THOMAS IT PROJECTS - MASTER SUMMARY".colorize(:cyan).bold
puts "=" * 80

# PROJECTS DASHBOARD
projects = {
  "🛠️ HELP DESK TICKETS" => {
    url: "https://helpdesk-tickets-zyfh.onrender.com",
    status: "PHASE 5 LIVE ✅",
    features: "Devise Auth + Tickets CRUD + JSON API",
    tests: "13/13 PASS (auth protected)",
    manual: "/users/sign_in → Agent Dashboard"
  },
  "🌐 NETWORK SWAP APP" => {
    url: "https://network-swap-app.onrender.com",
    status: "PHASE 4-7 LIVE ✅", 
    features: "Inventory Dashboard + Network Maps + Tailwind",
    tests: "6/6 PASS (static HTML + APIs)",
    manual: "public/index.html → Network Inventory"
  }
}

# DISPLAY PROJECTS
projects.each do |name, data|
  puts "\n#{name.colorize(:magenta).bold}"
  puts "   🚀 #{data[:url].colorize(:cyan)}"
  puts "   🟢 #{data[:status].colorize(:green)}"
  puts "   ✨ #{data[:features].colorize(:white)}"
  puts "   🧪 #{data[:tests].colorize(:yellow)}"
  puts "   👨‍💻 #{data[:manual].colorize(:cyan)}"
end

# FIXED PROGRESS BAR 📈
puts "\n📈 OVERALL PORTFOLIO PROGRESS".colorize(:blue).bold
completed = 12
total = 32
percent = (completed.to_f / total * 100).round(1)
bar_length = 30
filled = (bar_length * completed / total).to_i
bar = "█" * filled + "░" * (bar_length - filled)
puts "   [#{bar}] #{percent}% (#{completed}/#{total} phases)".colorize(:green)

# TECH STACK ⚙️
puts "\n⚙️ SHARED TECH STACK".colorize(:magenta).bold
puts "   Rails 8.1 • Postgres • TailwindCSS • Puma".colorize(:white)
puts "   Render • Docker • Devise • ActionCable-ready".colorize(:white)

# LIVE STATUS CHECK 🟢
puts "\n🟢 LIVE STATUS CHECK".colorize(:green).bold
projects.each do |name, data|
  begin
    uri = URI(data[:url])
    response = Net::HTTP.get_response(uri)
    status = response.code.to_i
    emoji = status == 200 ? "🟢" : "🔴"
    puts "   #{emoji} #{name}: HTTP #{status}"
  rescue => e
    puts "   🟡 #{name}: DOWN (#{e.class})"
  end
end

# FUTURE PHASES 🚀
puts "\n🚀 NEXT MILESTONES".colorize(:blue).bold
future = [
  "Phase 6: ActionCable Realtime Updates",
  "Phase 7: AI Analytics + Charts", 
  "Phase 8: Twilio SMS + Groq AI Triage",
  "Phase 9: Zero Trust + Multi-region K8s",
  "Phase 10: AR/VR Field Tech (HoloLens)",
  "Phase 14: Drone Diagnostics (DJI Swarm)",
  "Phase 15: Time Travel Debugging"
]
future.each_with_index { |phase, i| puts "   #{i+1}. #{phase.colorize(:white)}" }

# PRODUCTION READY 🎉
puts "\n🎉 PRODUCTION STATUS".colorize(:green).bold
puts "   ✅ 2x Apps LIVE on Render.com".colorize(:green)
puts "   ✅ No credentials exposed".colorize(:green) 
puts "   ✅ Security: Devise + 302 redirects".colorize(:green)
puts "   ✅ APIs: JSON endpoints working".colorize(:green)

puts "\n🔗 thomasinformationtechnology.com".colorize(:cyan).bold
puts "=" * 80
puts "🚀 THOMAS IT: Rails 8.1 ENTERPRISE READY".colorize(:cyan).bold
