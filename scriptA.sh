#!/bin/bash
CONTAINER_IMAGE="dudchenkoviktor/http-server:latest"
NGINX_CONFIG="/etc/nginx/nginx.conf"

# Восстановление Nginx config если отсутствует
if [ ! -f "/etc/nginx/nginx.conf" ]; then
    echo "Restoring nginx.conf..."
    sudo tee /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    upstream backend {
        server 127.0.0.1:8080;
    }

    server {
        listen 80;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF
    sudo nginx -s reload
fi

# Проверка работы Nginx
if ! systemctl is-active --quiet nginx; then
    echo "Starting nginx service..."
    sudo systemctl start nginx
fi

# Функция добавления сервера в Nginx
add_to_nginx() {
    local port=$1
    tmpfile=$(mktemp)
    sudo cp "$NGINX_CONFIG" "$tmpfile"
    sudo sed -i "/upstream backend {/a \        server 127.0.0.1:$port;" "$tmpfile"
    sudo mv "$tmpfile" "$NGINX_CONFIG"
    sudo nginx -s reload || echo "WARNING: Nginx reload failed"
}

# Функция проверки доступности контейнера
wait_for_container() {
    local port=$1
    local container_name="srv$(($port-8080+1))"
    
    # Ожидание старта контейнера
    for i in {1..10}; do
        if [ "$(docker inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null)" = "true" ]; then
            break
        fi
        sleep 3
    done
    
    # Проверка доступности
    for i in {1..10}; do
        if curl -s --connect-timeout 3 http://localhost:$port >/dev/null; then
            echo "Container on port $port is ready"
            return 0
        fi
        sleep 3
    done
    echo "ERROR: Container on port $port not responding"
    return 1
}

# В функции scale_up добавьте лимиты памяти:
scale_up() {
    local core=$1
    local port=$((8080 + core))
    echo "$(date) - SCALING UP: Launching srv$core on core$core, port $port"
    docker run -d --name "srv$core" --cpuset-cpus="$core" -p "$port:8080" \
        --memory="256m" --memory-swap="512m" \
        "$CONTAINER_IMAGE"
    wait_for_container $port || return 1
    add_to_nginx "$port"
}

# Функция проверки нагрузки
check_load() {
    local container=$1
    local load=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container" | tr -d '%')
    echo "$load"
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
    wait_for_container 8080
    add_to_nginx 8080
fi

declare -A load_history

# Основной цикл мониторинга
while true; do
    echo -e "\n=== $(date) ==="
    
    # Проверка нагрузки и масштабирование
    for i in {1..2}; do
        if docker ps --format '{{.Names}}' | grep -q "srv$i"; then
            load=$(check_load "srv$i")
            echo "srv$i CPU load: $load%"
            
            if (( $(echo "$load > 5" | bc -l) )); then
                load_history["srv$i"]=$(date +%s)
                next=$((i + 1))
                if ! docker ps | grep -q "srv$next"; then
                    if [ $(($(date +%s) - ${load_history["srv$i"]:-0})) -ge 60 ]; then
                        scale_up "$next"
                    fi
                fi
            else
                load_history["srv$i"]=0
            fi
        fi
    done

    # Проверка простоя и остановка
    for i in {3..2}; do
        if docker ps --format '{{.Names}}' | grep -q "srv$i"; then
            load=$(check_load "srv$i")
            echo "srv$i CPU load: $load%"
            
            if (( $(echo "$load < 5" | bc -l) )); then
                idle_time=$(($(date +%s) - $(docker inspect --format '{{.State.StartedAt}}' "srv$i" | date +%s -f -)))
                if [ "$idle_time" -ge 120 ]; then
                    echo "$(date) - SCALING DOWN: Removing srv$i"
                    docker stop "srv$i" && docker rm "srv$i"
                    sudo sed -i "/server 127.0.0.1:$((8080 + i));/d" "$NGINX_CONFIG"
                    sudo nginx -s reload
                fi
            fi
        fi
    done

    # Проверка обновлений образа
    if [ "$(docker pull "$CONTAINER_IMAGE" | grep "Status: Downloaded newer image")" ]; then
        echo "$(date) - New image detected. Updating containers..."
        for i in {1..3}; do
            if docker ps | grep -q "srv$i"; then
                docker stop "srv$i" && docker rm "srv$i"
                scale_up "$i"
            fi
        done
    fi

    sleep 10
done

# Обработчик завершения работы
trap 'echo "Stopping containers..."; docker stop $(docker ps -q -f "name=srv[1-3]") 2>/dev/null' EXIT
