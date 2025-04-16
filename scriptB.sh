#!/bin/bash
for i in {1..500}; do  # 20 параллельных процессов вместо 5
    while true; do
        sleep $((1 + RANDOM % 2))  # Интервал 1-3 секунды
        curl -s "http://localhost?sleep=$((RANDOM % 2))" >/dev/null &
    done &
done
wait
