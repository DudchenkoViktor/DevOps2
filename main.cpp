#include "opp/trigonometry.h"
#include <iostream>

int main() {
    Trigonometry trig;
    double x = 0.5;  // Пример значения |x| < 1
    int n = 3;       // Количество элементов ряда
    std::cout << "Result: " << trig.FuncA(x, n) << std::endl;
    return 0;
}
