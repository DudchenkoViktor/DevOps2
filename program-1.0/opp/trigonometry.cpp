#include "trigonometry.h"
#include <cmath>

double Trigonometry::FuncA(double x, int n) {
    if (fabs(x) >= 1) return NAN; // Проверка условия |x| < 1
    double sum = 0;
    for (int i = 0; i < n; ++i) {
        sum += pow(x, i);
    }
    return sum;
}

/**
 * Calculates the sum of the first n terms of the series 1/(1-x).
 * @param x Base value (|x| must be < 1).
 * @param n Number of terms to sum.
 * @return Sum of the series or NAN if |x| >= 1.
 */
