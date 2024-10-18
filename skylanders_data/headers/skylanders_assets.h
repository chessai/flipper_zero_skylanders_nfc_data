#pragma once

#include <stddef.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    size_t data_len;
    const char* name;   // basename without extension, "nfc_file" in the script
    const char* game;   // the game it's in, "game_dir" in the script
    const char* type;   // Figure, Magic Item, etc. "asset_dir" in the script
    unsigned char data[];  // Flexible array member for data
} Asset;

Asset* create_asset(const unsigned char* data, size_t data_len, const char* name, const char* game, const char* type);
void free_asset(Asset* asset);

extern Asset* assets[];  // Declare assets array externally

#define ASSET_COUNT 782
