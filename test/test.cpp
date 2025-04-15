#include "opp/trigonometry.h"
#include <cassert>
#include <iostream>

int main() {
    Trigonometry trig;
    double result = trig.FuncA(0.5, 3);
    double expected = 1 + 0.5 + 0.25;

    if (std::abs(result - expected) > 1e-9) {
        std::cerr << "Test failed: Expected " << expected << ", got " << result << std::endl;
        return 1;
    }
    std::cout << "Test passed!" << std::endl;
    return 0;
}
