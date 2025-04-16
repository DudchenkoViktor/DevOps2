#!/bin/bash
CONCURRENCY=100      # Увеличили количество параллельных процессов
REQUEST_DURATION=3   # Увеличили длительность запросов
INTERVAL=0.01        # Уменьшили интервал между запросами

echo "Starting load test with $CONCURRENCY concurrent processes..."
for i in $(seq 1 $CONCURRENCY); do
    (
        while true; do
            curl -s "http://localhost?sleep=$REQUEST_DURATION" >/dev/null &
            sleep $INTERVAL
        done
    ) &
done

# Автоматическое завершение через 15 минут
sleep 900
pkill -f "curl"
echo "Load test completed"
