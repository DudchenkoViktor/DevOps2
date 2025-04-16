#!/bin/bash
for i in {1..20}; do
    while true; do
        sleep_time=$((RANDOM % 3 + 1))  # 1-3 секунды
        sleep $sleep_time
        curl -s "http://localhost?sleep=$((RANDOM % 3))" >/dev/null &
    done &
done

# Остановка через 5 минут
sleep 300
pkill -f "curl"
