#!/bin/bash
CONTAINER_IMAGE="dudchenkoviktor/http-server:latest"
NGINX_CONFIG="/etc/nginx/nginx.conf"

# Объявление функций ДО их использования
add_to_nginx() {
    local port=$1
    tmpfile=$(mktemp)
    sudo cp "$NGINX_CONFIG" "$tmpfile"
    sudo sed -i "/upstream backend {/a \        server 127.0.0.1:$port;" "$tmpfile"
    sudo mv "$tmpfile" "$NGINX_CONFIG"
    sudo nginx -s reload || echo "WARNING: Nginx reload failed"
}

scale_up() {
    local core=$1
    local port=$((8080 + core))
    echo "$(date) - SCALING UP: Launching srv$core on core$core, port $port"
    docker run -d --name "srv$core" --cpuset-cpus="$core" -p "$port:8080" "$CONTAINER_IMAGE"
    wait_for_container $port || return 1
    add_to_nginx "$port"
}

check_load() {
    local container=$1
    local load=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container" | tr -d '%')
    echo "$load"
}

# Восстановление Nginx config если отсутствует
if [ ! -f "/etc/nginx/nginx.conf" ]; then
    echo "Restoring nginx.conf..."
    sudo tee /etc/nginx/nginx.conf <<'EOF'
[вставьте содержимое конфига из пункта 1]
EOF
    sudo nginx -s reload
fi

# Проверка работы контейнера
wait_for_container() {
    local port=$1
    for i in {1..10}; do
        if curl -s http://localhost:$port >/dev/null; then
            echo "Container on port $port is ready"
            return 0
        fi
        sleep 3
    done
    echo "ERROR: Container on port $port not responding"
    return 1
}

# Проверка наличия образа
if ! docker image inspect "$CONTAINER_IMAGE" &>/dev/null; then
    echo "Image $CONTAINER_IMAGE not found. Pulling..."
    docker pull "$CONTAINER_IMAGE" || exit 1
fi

# Автоматический запуск srv1 если его нет
if ! docker ps --format '{{.Names}}' | grep -q "srv1"; then
    echo "$(date) - Initializing: Starting srv1 on core0"
    docker run -d --name srv1 --cpuset-cpus=0 -p 8080:8080 "$CONTAINER_IMAGE"
    add_to_nginx 8080
fi

declare -A load_history

while true; do
    echo -e "\n=== $(date) ==="
    
    # Основная логика мониторинга...
    for i in {1..2}; do
        if docker ps --format '{{.Names}}' | grep -q "srv$i"; then
            load=$(check_load "srv$i")
            echo "srv$i CPU load: $load%"
            
            if (( $(echo "$load > 70" | bc -l) )); then
                load_history["srv$i"]=$(date +%s)
                next=$((i + 1))
                if ! docker ps | grep -q "srv$next"; then
                    if [ $(($(date +%s) - ${load_history["srv$i"]:-0})) -ge 120 ]; then
                        scale_up "$next"
                    fi
                fi
            else
                load_history["srv$i"]=0
            fi
        fi
    done

    sleep 10
done

trap 'echo "Stopping containers..."; docker stop $(docker ps -q -f "name=srv[1-3]") 2>/dev/null' EXIT
