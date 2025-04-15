#include "opp/trigonometry.h"
#include "httplib.h"
#include <vector>
#include <algorithm>
#include <chrono>

int main() {
    std::cout << "Server started on port 8080" << std::endl;
    httplib::Server svr;
    svr.Get("/calculate", [](const httplib::Request &req, httplib::Response &res) {
        auto start = std::chrono::high_resolution_clock::now();

        Trigonometry trig;
        std::vector<double> results;
        int cycles = 40000000; // Настройте под ваше железо
        for (int i = 0; i < cycles; ++i) {
            results.push_back(trig.FuncA(0.5, i % 10 + 1)); // Используем FuncA из trigonometry.cpp
        }
        std::sort(results.begin(), results.end());

        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::high_resolution_clock::now() - start
        ).count();

        res.set_content("Elapsed time: " + std::to_string(duration) + " ms\n", "text/plain");
    });

    svr.listen("0.0.0.0", 8080);
    return 0;
}
