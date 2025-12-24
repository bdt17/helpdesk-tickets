#!/bin/bash
echo "🌐 DNS SETUP FOR HELPDESK - thomas-helpdesk-free.onrender.com"

echo "1. CLOUDFLARE:"
echo "   Domain: yourdomain.com"
echo "   Type: CNAME"
echo "   Name: helpdesk"
echo "   Target: thomas-helpdesk-free.onrender.com"
echo "   Proxy: Proxied (orange cloud)"
echo "   TTL: Auto"

echo -e "\n2. NAMECHEAP:"
echo "   Type: CNAME Record"
echo "   Host: helpdesk"
echo "   Value: thomas-helpdesk-free.onrender.com"
echo "   TTL: Automatic"

echo -e "\n3. GODADDY:"
echo "   1. My Products → DNS → Manage DNS"
echo "   2. Add → CNAME"
echo "   3. Name: helpdesk"
echo "   4. Value: thomas-helpdesk-free.onrender.com"
echo "   5. TTL: 1 Hour (3600)"
echo "   6. SAVE"

echo -e "\n4. Test DNS (5min propagation):"
echo "   dig helpdesk.yourdomain.com"
echo "   nslookup helpdesk.yourdomain.com"
echo "   curl -I https://helpdesk.yourdomain.com"

echo -e "\n✅ DNS records created → 5-30min propagation"
echo "🌐 Final URL: https://helpdesk.yourdomain.com/"
