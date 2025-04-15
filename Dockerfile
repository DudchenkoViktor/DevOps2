FROM ubuntu:22.04
RUN apt-get update && apt-get install -y g++ cmake libssl-dev
WORKDIR /app
COPY . .
RUN g++ -std=c++11 HTTPServer.cpp opp/trigonometry.cpp -o server -lpthread
EXPOSE 8080  # Порт должен совпадать с кодом сервера
CMD ["./server"]
