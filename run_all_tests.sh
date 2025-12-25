#!/bin/bash
echo "🚀 THOMAS HELPDESK - FULL TEST SUITE"
echo "=================================="

echo "1. FUNCTIONALITY..."
~/test_all_functions.sh

echo "2. INFOSEC AUDIT..."
~/infosec_master.sh

echo "3. BRAKEMAN SCAN..."
~/brakeman_scan.sh

echo "4. MONITORING STATUS..."
tail -5 ~/helpdesk_pro.log

echo "✅ ALL TESTS COMPLETE!"
