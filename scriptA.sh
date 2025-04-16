#!/bin/bash
CONTAINER_IMAGE="dudchenkoviktor/http-server:latest"

scale_up() {
    local core=$1
    local port=$((8080+core))
    echo "$(date) - SCALING UP: Launching srv$core on core$core"
    docker run -d --name srv$core --cpuset-cpus=$core -p $port:8080 $CONTAINER_IMAGE
}

check_load() {
    local container=$1
    local load=$(docker stats --no-stream --format "{{.CPUPerc}}" $container | tr -d '%')
    echo $load
}

while true; do
    echo -e "\n=== $(date) ==="
    
    # 1. Проверка нагрузки
    for i in {1..2}; do
        if docker ps --format '{{.Names}}' | grep -q "srv$i"; then
            load=$(check_load "srv$i")
            echo "srv$i CPU load: $load%"
            
            if (( $(echo "$load > 10" | bc -l) )); then
                next=$((i+1))
                if ! docker ps | grep -q "srv$next"; then
                    scale_up $next
                fi
            fi
        fi
    done

    # 2. Проверка простоя
    for i in {3..2}; do
        if docker ps --format '{{.Names}}' | grep -q "srv$i"; then
            load=$(check_load "srv$i")
            echo "srv$i CPU load: $load%"
            
            if (( $(echo "$load < 10" | bc -l) )); then
                echo "$(date) - SCALING DOWN: Removing srv$i"
                docker stop srv$i && docker rm srv$i
            fi
        fi
    done

    sleep 10
done
