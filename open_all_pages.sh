#!/bin/bash
echo "🌐 Opening Thomas IT Network Swap App pages..."

# Wait for server to be ready
sleep 2

# Open all pages in new tabs
xdg-open "http://localhost:3000"
sleep 1
xdg-open "http://localhost:3000/devices" 
sleep 1
xdg-open "http://localhost:3000/sites"
sleep 1
xdg-open "http://localhost:3000/swaps"
sleep 1
xdg-open "http://localhost:3000/users/sign_in"

echo "✅ All 5 tabs opened! 🎉"
echo "🔹 localhost:3000 → Dashboard"
echo "🔹 /devices → Network Inventory"  
echo "🔹 /sites → Enterprise Locations"
echo "🔹 /swaps → EOL Planning"
echo "🔹 /users/sign_in → Agent Login"
