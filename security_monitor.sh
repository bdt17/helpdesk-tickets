#!/bin/bash

# Directory to monitor
MONITOR_DIR="/home/zero"    # Change this to the target directory

# Output file
OUTPUT="security_monitor_$(date +%F_%H%M%S).log"

echo "--- DIRECTORY LISTING ($MONITOR_DIR) ---" | tee -a "$OUTPUT"
ls -l "$MONITOR_DIR" | tee -a "$OUTPUT"

echo -e "\n--- REAL-TIME DIRECTORY EVENTS (10s sample, Ctrl+C to stop) ---" | tee -a "$OUTPUT"
timeout 10s inotifywait -m "$MONITOR_DIR" 2>/dev/null | tee -a "$OUTPUT"

echo -e "\n--- NETWORK CONNECTIONS (netstat) ---" | tee -a "$OUTPUT"
sudo netstat -tulpen | tee -a "$OUTPUT"

echo -e "\n--- NETWORK CONNECTIONS (ss) ---" | tee -a "$OUTPUT"
sudo ss -taunp | tee -a "$OUTPUT"

echo -e "\n--- OPEN NETWORK FILES (lsof) ---" | tee -a "$OUTPUT"
sudo lsof -nP -i | tee -a "$OUTPUT"

echo -e "\n--- TOP BANDWIDTH USAGE (iftop, 10s sample) ---" | tee -a "$OUTPUT"
sudo timeout 10s iftop -t -s 10 2>/dev/null | tee -a "$OUTPUT"

echo -e "\n--- SUSPICIOUS IP/PROCESS LOOKUP ---" | tee -a "$OUTPUT"
echo "Copy any unknown IP or process from above and search at:" | tee -a "$OUTPUT"
echo "https://www.abuseipdb.com/ or https://virustotal.com/" | tee -a "$OUTPUT"

echo -e "\n--- SCRIPT FINISHED. Output saved in $OUTPUT ---"

