#!/bin/bash
echo "🔍 PRODUCTION VERIFICATION"
echo "1. Root:"
curl -s https://thomas-helpdesk-free.onrender.com/ | grep "THOMAS HELPDESK LIVE" && echo "✅ ROOT OK"
echo "2. Health:"
curl -s -I https://thomas-helpdesk-free.onrender.com/rails/health 2>/dev/null | head -1 | grep 200 && echo "✅ HEALTH OK" || echo "ℹ️ No health"
echo "3. Load time:"
curl -w "Total: %{time_total}s\n" -o /dev/null -s https://thomas-helpdesk-free.onrender.com/
