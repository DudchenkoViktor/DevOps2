#!/bin/bash
CONTAINER_IMAGE="dudchenkoviktor/http-server:latest"
NGINX_CONFIG="/etc/nginx/nginx.conf"
LOAD_THRESHOLD=5       # Порог нагрузки для масштабирования (5%)
SCALE_TIMEOUT=30       # 30 секунд высокой нагрузки перед масштабированием
declare -A load_timers # Ассоциативный массив для отслеживания времени

# Функция получения нагрузки
get_load() {
    local container=$1
    local load=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container" 2>/dev/null | tr -d '%' | awk '{print int($1)}')
    echo "${load:-0}"
}

# Инициализация srv1
if ! docker ps --format '{{.Names}}' | grep -q "srv1"; then
    echo "$(date) - Starting srv1 on core0"
    docker run -d --name srv1 --cpuset-cpus=0 -p 8080:8080 "$CONTAINER_IMAGE"
    sleep 5
fi

while true; do
    echo -e "\n=== $(date) ==="
    
    # Для каждого возможного сервера
    for i in {1..2}; do
        container="srv$i"
        if docker ps --format '{{.Names}}' | grep -q "$container"; then
            load=$(get_load "$container")
            echo "$container CPU load: $load%"
            
            # Проверка на необходимость масштабирования
            if (( load > LOAD_THRESHOLD )); then
                if [ -z "${load_timers[$container]}" ]; then
                    load_timers[$container]=$(date +%s)
                    echo "High load detected on $container, starting timer"
                else
                    duration=$(( $(date +%s) - ${load_timers[$container]} ))
                    echo "High load duration: $duration/$SCALE_TIMEOUT seconds"
                    
                    if (( duration >= SCALE_TIMEOUT )); then
                        next=$((i + 1))
                        if ! docker ps | grep -q "srv$next"; then
                            echo "$(date) - SCALING UP: Launching srv$next on core$next"
                            docker run -d \
                                --name "srv$next" \
                                --cpuset-cpus="$next" \
                                -p "808$next:8080" \
                                "$CONTAINER_IMAGE"
                            load_timers[$container]=0
                        fi
                    fi
                fi
            else
                load_timers[$container]=""
            fi
        fi
    done
    
    sleep 10
done
