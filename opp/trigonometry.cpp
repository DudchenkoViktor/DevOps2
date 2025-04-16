#include "opp/trigonometry.h"
#include <cmath>
#include <iostream> // Добавляем этот include

double calculateFunction(double x, int n) {
    if(n <= 0 || x >= 1.0 || x <= -1.0) return 0;
    double sum = 0;
    double term = 1.0;
    
    for(int i = 0; i < n; ++i) {
        sum += term;
        term *= x;
        
        // Отладочный вывод
        std::cout << "Step " << i << ": term=" << term << " sum=" << sum << std::endl;
    }
    return sum;
}
