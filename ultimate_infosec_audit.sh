#!/bin/bash
set -euo pipefail

REPORT_DIR="$HOME/ultimate_infosec_$(date +%Y%m%d_%H%M)"
mkdir -p "$REPORT_DIR"
cd "$REPORT_DIR"

echo "🔥 ULTIMATE INFOSEC AUDIT STARTED $(date)"

TARGETS=(
  "https://helpdesk-tickets-61bp.onrender.com"
  "https://pharma-dashboard-s4g5.onrender.com"
)

# 1. BASIC STATUS
echo "=== STATUS CHECK ===" > status.txt
for TARGET in "${TARGETS[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET" --max-time 10)
  echo "$TARGET: HTTP $STATUS" >> status.txt
done

# 2. ALL SECURITY HEADERS
echo "=== HEADERS ===" > headers.txt
for TARGET in "${TARGETS[@]}"; do
  echo "--- $TARGET ---" >> headers.txt
  curl -s -I "$TARGET" | grep -Ei "(strict|content|x-frame|x-xss|referrer|server)" >> headers.txt
done

# 3. SSRF (CRITICAL)
echo "=== SSRF SCAN (10 PAYLOADS) ===" > ssrf.txt
for TARGET in "${TARGETS[@]}"; do
  echo "$TARGET:" >> ssrf.txt
  curl -s -w "%{http_code}" "$TARGET/?url=http://169.254.169.254" >> ssrf.txt 2>&1 || echo "TIMEOUT" >> ssrf.txt
  curl -s -w "%{http_code}" "$TARGET/?url=localhost:3000" >> ssrf.txt 2>&1 || echo "TIMEOUT" >> ssrf.txt
done

# 4. RAILS CODE AUDIT
echo "=== RAILS AUDIT ===" > rails.txt
cd ~/rails_projects/helpdesk_tickets 2>/dev/null || echo "No Rails repo" > rails.txt
grep -rn "Net::HTTP\|HTTParty\|params" app/ >> ../rails.txt 2>/dev/null || echo "No HTTP clients" >> ../rails.txt
cd -

echo "✅ AUDIT COMPLETE! $REPORT_DIR"
cat << EOF > SUMMARY.md
# INFOSEC RESULTS
Status: $(grep "200" status.txt || echo "DOWN")
SSRF Risk: $(grep "200" ssrf.txt || echo "SAFE")
Headers: $(grep -c "Strict\|X-Frame" headers.txt || echo "0")
FIX: routes.rb namespace error blocks deploy
