#!/bin/bash
BASE="https://helpdesk-tickets-61bp.onrender.com"
LOG="$HOME/helpdesk_pro.log"

while true; do
  TS=$(date '+%H:%M:%S')
  HEALTH=$(curl -s -w "%{http_code}" "$BASE/api/health" --max-time 5)
  TICKETS=$(curl -s -w "%{http_code}" "$BASE/api/tickets" --max-time 5)
  
  STATUS="🟢" ; [[ "$HEALTH" != "200" || "$TICKETS" != "200" ]] && STATUS="🔴"
  echo "$TS $STATUS $HEALTH/$TICKETS" >> "$LOG"
  echo "$TS $STATUS Thomas Helpdesk: $HEALTH/$TICKETS"
  
  sleep 30
done
