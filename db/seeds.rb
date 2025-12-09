# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
KnowledgeBase.create!([
  {title: "No WiFi Connection", category: "networking", 
   steps: "1. Restart router\n2. Check SSID/password\n3. Forget network + reconnect", 
   commands: "ipconfig /release\nipconfig /renew\nnetsh winsock reset", 
   client_instructions: "Unplug router 30sec, restart PC, check password"},
  {title: "Slow Internet", category: "networking", 
   steps: "1. Run speedtest.net\n2. Check for bandwidth hogs\n3. Update WiFi drivers", 
   commands: "speedtest-cli", 
   client_instructions: "Close Chrome tabs, test speed at speedtest.net"},
  {title: "Can't Print", category: "printers", 
   steps: "1. Printer power cycle\n2. Check ink/toner\n3. Print test page", 
   commands: "", 
   client_instructions: "Turn printer off/on, check paper tray"}
])
