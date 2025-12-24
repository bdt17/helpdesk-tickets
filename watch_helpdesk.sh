#!/bin/bash
while true; do
  ts=$(date +%H:%M:%S)
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://thomas-helpdesk-free.onrender.com/)
  [ $code = 200 ] && echo "[$ts] ✅ LIVE" || echo "[$ts] ❌ $code"
  sleep 30
done
