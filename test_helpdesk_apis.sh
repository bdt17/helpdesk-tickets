#!/bin/bash
echo "🧪 HELPDESK FULL API TEST SUITE"

BASE_URL="https://thomas-helpdesk-free.onrender.com"

echo "1. ROOT DASHBOARD"
curl -s -w "Status: %{http_code} Size: %{size_download}b\n" $BASE_URL/ | head -20

echo -e "\n2. HEALTH CHECK"
curl -s -w "Status: %{http_code}\n" $BASE_URL/rails/health || echo "No health endpoint"

echo -e "\n3. API ENDPOINTS SCAN"
for path in api/v1/tickets api/tickets users shipments drones; do
  echo "Testing $path:"
  curl -s -w "Status: %{http_code}\n" $BASE_URL/$path | head -3
done

echo -e "\n✅ TEST COMPLETE - $(date)"
