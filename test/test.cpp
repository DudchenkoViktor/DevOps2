#include "opp/trigonometry.h"
#include <catch2/catch.hpp>

TEST_CASE("FuncA computes series sum correctly", "[trigonometry]") {
    Trigonometry trig;
    REQUIRE(trig.FuncA(0.5, 3) == Approx(1 + 0.5 + 0.25));
}
