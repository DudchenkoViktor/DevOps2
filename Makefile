CXX = g++
CXXFLAGS = -std=c++11 -I./opp
TARGET = program

all: $(TARGET)

$(TARGET): main.cpp opp/trigonometry.cpp
    $(CXX) $(CXXFLAGS) $^ -o $@

clean:
    rm -f $(TARGET)
