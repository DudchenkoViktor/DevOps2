FROM alpine:latest
RUN apk add --no-cache gcompat libstdc++ build-base
WORKDIR /app
COPY . .
RUN g++ -o server main.cpp -std=c++11 -lpthread
CMD ["/app/server"]
