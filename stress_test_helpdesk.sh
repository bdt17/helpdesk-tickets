#!/bin/bash
echo "⚡ STRESS TEST - 100 concurrent users x 10s"

for i in {1..100}; do
  curl -s https://thomas-helpdesk-free.onrender.com/ > /dev/null &
done

wait
echo "✅ Stress test complete - $(curl -w "%{time_total}s" https://thomas-helpdesk-free.onrender.com/ -o /dev/null -s)"
