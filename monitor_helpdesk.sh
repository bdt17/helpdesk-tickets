#!/bin/bash
echo "👀 HELPDESK MONITOR [$(date)] - https://thomas-helpdesk-free.onrender.com/"
while true; do
  ts=$(date '+%H:%M:%S')
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://thomas-helpdesk-free.onrender.com/)
  size=$(curl -s --max-time 10 https://thomas-helpdesk-free.onrender.com/ | wc -c)
  if [ "$status" = "200" ]; then
    echo "[$ts] ✅ LIVE HTTP:200 ${size}b ✓"
  else
    echo "[$ts] ❌ DOWN HTTP:$status ✗"
  fi
  sleep 30
done
