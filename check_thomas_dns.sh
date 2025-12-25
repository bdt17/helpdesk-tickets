#!/bin/bash
DOMAIN="thomasinformationtechnology.com"
echo "🔍 THOMAS IT DNS VERIFICATION - $DOMAIN"
echo "=============================================="

# 1. A Record (main site IP)
echo "1. A Record (IPv4):"
dig +short A $DOMAIN
dig +short A www.$DOMAIN
echo ""

# 2. AAAA Record (IPv6)
echo "2. AAAA Record (IPv6):"
dig +short AAAA $DOMAIN
dig +short AAAA www.$DOMAIN
echo ""

# 3. MX Records (email)
echo "3. MX Records (Email):"
dig +short MX $DOMAIN | sort -V
echo ""

# 4. NS Records (nameservers)
echo "4. NS Records:"
dig +short NS $DOMAIN | sort
echo ""

# 5. TXT Records (SPF/DMARC/DKIM)
echo "5. TXT Records:"
dig +short TXT $DOMAIN
dig +short TXT _dmarc.$DOMAIN
echo ""

# 6. CNAME Records (subdomains)
echo "6. CNAME Subdomains:"
for sub in helpdesk api mail www staging dev; do
  dig +short CNAME ${sub}.$DOMAIN 2>/dev/null && echo "  ${sub}.$DOMAIN → OK"
done
echo ""

# 7. Propagation check (Google + Cloudflare DNS)
echo "7. Propagation Check:"
echo "Google DNS:"
dig @$NS1{8.8,8.4}.8 A $DOMAIN +short
echo "Cloudflare DNS:"
dig @1.1.1.1 A $DOMAIN +short
echo ""

# 8. SSL Certificate check
echo "8. SSL Certificate:"
echo | openssl s_client -connect $DOMAIN:443 2>/n | openssl x509 -noout -subject -dates | grep -E "(subject|notAfter)"
echo ""

# 9. Summary
echo "✅ SUMMARY:"
echo "   A Record: $(dig +short A $DOMAIN | wc -l) records"
echo "   MX Records: $(dig +short MX $DOMAIN | wc -l) records" 
echo "   NS Records: $(dig +short NS $DOMAIN | wc -l) records"
echo "   Propagation: $( [ "$(dig +short @8.8.8.8 A $DOMAIN)" = "$(dig +short A $DOMAIN)" ] && echo "SYNCED" || echo "🚫 DELAYED" )"

echo "=============================================="
echo "🚀 THOMAS IT DNS = $( [ -n "$(dig +short A $DOMAIN)" ] && echo "✅ PRODUCTION READY" || echo "❌ NEEDS FIX" )"
