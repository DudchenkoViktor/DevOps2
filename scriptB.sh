#!/bin/bash
CONCURRENCY=50  # Увеличили количество процессов
DELAY=0.1       # Уменьшили задержку

echo "Starting intensive load test..."
for i in $(seq 1 $CONCURRENCY); do
    while true; do
        curl -s "http://localhost?sleep=0.5" >/dev/null &
        sleep $DELAY
    done &
    sleep 0.1
done

sleep 600  # Работает 10 минут
pkill -f "curl"
