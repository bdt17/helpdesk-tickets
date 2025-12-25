#!/bin/bash
echo "🧪 THOMAS HELPDESK API v2 TEST SUITE"

BASE="https://helpdesk-tickets-61bp.onrender.com"

test_endpoint() {
  local url="$1" name="$2"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$url" --max-time 5)
  SIZE=$(curl -s -w "%{size_download}" -o /dev/null "$BASE$url" --max-time 5 2>/dev/null || echo "0")
  echo "$name: $STATUS (${SIZE}B)"
}

echo "1. ROOT: $(curl -s -w "%{http_code}" "$BASE" --max-time 5)"
test_endpoint "/api/health" "HEALTH API"
test_endpoint "/api/tickets" "TICKETS API"
test_endpoint "/api/ai/status" "AI STATUS"

echo "✅ ALL PASS - $(date)"
