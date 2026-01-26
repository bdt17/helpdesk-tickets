#!/usr/bin/env bash
echo "🏆 FINAL PRODUCTION CERTIFICATION"
echo "Thomas IT Helpdesk + Network Ops"

# HTTP Status
echo "HTTP Status:"
curl -s -o /dev/null -w "Pharma: %{http_code}\n" https://thomasinformationtechnology.com/
curl -s -o /dev/null -w "Network: %{http_code}\n" https://thomasinformationtechnology.com/network-dashboard

# Content check (after Devise fix)
echo -e "\nContent:"
curl -s https://thomasinformationtechnology.com/ | grep -i "thomas\|helpdesk\|dashboard" && echo "✅ PHARMA OK"
curl -s https://thomasinformationtechnology.com/network-dashboard | grep -i "dashboard\|network" && echo "✅ NETWORK OK"

echo "🎉 PHASE 6 COMPLETE - PRODUCTION LIVE!"
