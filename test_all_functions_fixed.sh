#!/bin/bash
BASE="https://helpdesk-tickets-61bp.onrender.com"
PASS=0

echo "🧪 THOMAS HELPDESK FULL FUNCTIONALITY TEST"
echo "⏰ $(date)"

test_api() {
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$1" --max-time 5)
  SIZE=$(curl -s -w "%{size_download}" -o /dev/null "$BASE$1" --max-time 5 2>/dev/null || echo "0")
  echo "  $1 → $STATUS (${SIZE}B)"
  [[ "$STATUS" == "200" ]] && ((PASS++))
}

echo "1. CORE APIs:"
test_api "/api/health"
test_api "/api/tickets" 
test_api "/api/ai/status"

echo "2. ENTERPRISE APIs:"
test_api "/api/users"
test_api "/api/shipments"
test_api "/api/drones"

echo "✅ $PASS/6 APIs LIVE"
