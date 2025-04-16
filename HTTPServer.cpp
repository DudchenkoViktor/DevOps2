#include <iostream>
#include <vector>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <sstream>
#include <iomanip>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

// Ваша функция расчета (пример для 1/(1-x))
double calculateFunction(double x, int n) {
    double sum = 0;
    for(int i = 0; i < n; ++i) {
        sum += pow(x, i);
    }
    return sum;
}

std::string generateResponse() {
    const int array_size = 10000;
    const int cycles = 100;
    std::vector<double> results(array_size);
    
    auto start = std::chrono::high_resolution_clock::now();
    
    // Расчет и сортировка
    for(int i = 0; i < cycles; ++i) {
        for(int j = 0; j < array_size; ++j) {
            results[j] = calculateFunction(0.5, 10); // x=0.5, n=10
        }
        std::sort(results.begin(), results.end());
    }
    
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;
    
    // Формируем HTTP-ответ
    std::ostringstream oss;
    oss << "HTTP/1.1 200 OK\r\n"
        << "Content-Type: text/html\r\n"
        << "Connection: close\r\n\r\n"
        << "<html><body>"
        << "<h1>Calculation Results</h1>"
        << "<p>Elapsed time: " << std::fixed << std::setprecision(2) << elapsed.count() << "s</p>"
        << "<p>First 5 values: ";
    
    for(int i = 0; i < 5; ++i) {
        oss << results[i] << " ";
    }
    
    oss << "</p></body></html>";
    return oss.str();
}

int main() {
    // Создаем сокет
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        std::cerr << "Socket creation failed" << std::endl;
        return 1;
    }

    // Настройка адреса
    sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(8080);

    // Биндим и слушаем
    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        std::cerr << "Bind failed" << std::endl;
        return 1;
    }
    if (listen(server_fd, 10) < 0) {
        std::cerr << "Listen failed" << std::endl;
        return 1;
    }

    std::cout << "HTTP Server started on port 8080" << std::endl;

    // Основной цикл сервера
    while(true) {
        int client_fd = accept(server_fd, nullptr, nullptr);
        if (client_fd < 0) {
            std::cerr << "Accept failed" << std::endl;
            continue;
        }

        std::string response = generateResponse();
        send(client_fd, response.c_str(), response.size(), 0);
        close(client_fd);
    }

    close(server_fd);
    return 0;
}
