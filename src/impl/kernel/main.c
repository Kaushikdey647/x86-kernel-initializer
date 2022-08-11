#include "print.h"

void kernel_main() {
    print_clear();
    print_set_color(PRINT_COLOR_BLACK, PRINT_COLOR_RED);
    print_str("Welcome to try-os\nWHY\nDON'T\nYOU\nJUST\nTRY\nIT?");
}