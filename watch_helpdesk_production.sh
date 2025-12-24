#!/bin/bash
URL="https://thomas-helpdesk-free.onrender.com/"
while true; do
  ts=$(date +%H:%M:%S)
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $URL)
  [ $code = 200 ] && echo "[$ts] ✅ LIVE $URL" || echo "[$ts] ❌ $code $URL"
  sleep 30
done
