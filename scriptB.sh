#!/bin/bash
MAX_WORKERS=40          # Безпечна кількість процесів
REQUEST_DURATION=2      # Час виконання запиту
RAMP_UP_STEPS=6         # Кроки нарощування
STEP_DELAY=5            # Інтервал між кроками (5x6=30 сек до повної нагрузкі)

cleanup() {
    pkill -f "curl"
    echo "Load test stopped"
}
trap cleanup EXIT

echo "Starting smooth load test (ramp up in $((RAMP_UP_STEPS*STEP_DELAY)) seconds)"
for ((workers=1; workers<=MAX_WORKERS; workers+=(MAX_WORKERS/RAMP_UP_STEPS))); do
    echo "Current workers: $workers"
    for ((i=1; i<=workers; i++)); do
        while true; do
            curl -s "http://localhost?sleep=$REQUEST_DURATION" >/dev/null &
            sleep 0.3
        done &
    done
    sleep $STEP_DELAY
done

sleep 600 # Тривалість тесту
