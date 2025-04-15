AUTOMAKE_OPTIONS = subdir-objects
bin_PROGRAMS = program
program_SOURCES = main.cpp opp/trigonometry.cpp
program_CPPFLAGS = -I$(srcdir)/opp
check_PROGRAMS = test_program
test_program_SOURCES = test/test.cpp opp/trigonometry.cpp
test_program_CPPFLAGS = -I$(srcdir)/opp
TESTS = test_program
