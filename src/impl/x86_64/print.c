#include "print.h"

const static size_t NUM_COLS = 80;
const static size_t NUM_ROWS = 25;

// Represents a character on the screen with character data and color information.
struct Char {
    uint8_t character;  // The ASCII character to display.
    uint8_t color;     // The color attributes for the character.
};

// The video buffer for text mode (0xb8000) is cast to an array of Char structures.
// This buffer is used for displaying text on the screen.
struct Char* buffer = (struct Char*) 0xb8000;

size_t col = 0;  // Current column position on the screen.
size_t row = 0;  // Current row position on the screen.
uint8_t color = PRINT_COLOR_WHITE | (PRINT_COLOR_BLACK << 4);  // Default text color.

// Clears a specific row on the screen by filling it with empty spaces.
void clear_row(size_t row) {
    struct Char empty = (struct Char) {
        character: ' ',
        color: color,
    };

    for (size_t col = 0; col < NUM_COLS; col++) {
        buffer[col + NUM_COLS * row] = empty;
    }
}

// Clears the entire screen by calling clear_row for each row.
void print_clear() {
    for (size_t i = 0; i < NUM_ROWS; i++) {
        clear_row(i);
    }
}

// Moves to a new line (carriage return and line feed).
// If the last row is reached, it scrolls the entire screen up.
void print_newline() {
    col = 0;

    if (row < NUM_ROWS - 1) {
        row++;
        return;
    }

    for (size_t row = 1; row < NUM_ROWS; row++) {
        for (size_t col = 0; col < NUM_COLS; col++) {
            struct Char character = buffer[col + NUM_COLS * row];
            buffer[col + NUM_COLS * (row - 1)] = character;
        }
    }

    clear_row(NUM_COLS - 1);
}

// Displays a character on the screen.
// Handles newlines, scrolling, and moving to the next row.
void print_char(char character) {
    if (character == '\n') {
        print_newline();
        return;
    }

    if (col >= NUM_COLS) {
        print_newline();
    }

    buffer[col + NUM_COLS * row] = (struct Char) {
        character: (uint8_t) character,
        color: color,
    };

    col++;
}

// Displays a null-terminated string on the screen by calling print_char for each character.
void print_str(char* str) {
    for (size_t i = 0; 1; i++) {
        char character = (uint8_t) str[i];

        if (character == '\0') {
            return;
        }

        print_char(character);
    }
}

// Sets the text color attributes (foreground and background).
void print_set_color(uint8_t foreground, uint8_t background) {
    color = foreground + (background << 4);
}
