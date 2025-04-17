#!/bin/bash
CONTAINER_IMAGE="dudchenkoviktor/http-server:latest"
LOAD_THRESHOLD=4
DURATION_THRESHOLD=20

declare -A load_timers

get_load() {
    docker stats --no-stream --format "{{.CPUPerc}}" "srv$1" 2>/dev/null | tr -d '%' | awk '{print int($1)}'
}

# Ініціалізація srv1
if ! docker ps --format '{{.Names}}' | grep -q "srv1"; then
    docker run -d --name srv1 --cpuset-cpus=0 -p 8080:8080 "$CONTAINER_IMAGE"
    sleep 5
fi

while true; do
    echo -e "\n=== $(date) ==="
    
    for i in {1..2}; do
        if docker ps --format '{{.Names}}' | grep -q "srv$i"; then
            load=$(get_load $i)
            echo "srv$i CPU load: $load%"
            
            if (( load > LOAD_THRESHOLD )); then
                if [ -z "${load_timers[$i]}" ]; then
                    load_timers[$i]=$(date +%s)
                    echo "High load timer started"
                elif (( $(date +%s) - ${load_timers[$i]} >= DURATION_THRESHOLD )); then
                    next=$((i + 1))
                    if ! docker ps | grep -q "srv$next"; then
                        echo "SCALING: Launching srv$next"
                        docker run -d --name "srv$next" --cpuset-cpus="$next" -p "808$next:8080" "$CONTAINER_IMAGE"
                    fi
                fi
            else
                load_timers[$i]=""
            fi
        fi
    done
    
    sleep 5
done
