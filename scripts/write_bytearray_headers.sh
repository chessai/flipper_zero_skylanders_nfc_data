#!/bin/bash

# Get the number of .nfc files and store it in a variable
nfc_count=$(find skylanders_data/ -name '*.nfc' | wc -l)

# Convert the .nfc file to a C array (xxd -i format) and store it in a separate buffer for runtime initialization
convert_file_to_c_array() {
    local file_path="$1"
    local var_name="$2"
    local c_file="$3"

    # Generate the byte array using xxd and append it to the .c file
    xxd -i "$file_path" >> "$c_file"
    echo "" >> "$c_file"  # Add a newline after the array declaration
}

# Create a struct definition for assets in the header
write_struct_definition() {
    local header_file="$1"
    echo "#pragma once" > "$header_file"
    echo "" >> "$header_file"
    echo "#include <stddef.h>" >> "$header_file"  # For size_t
    echo "#include <stdlib.h>" >> "$header_file"  # For malloc, free
    echo "#include <string.h>" >> "$header_file"  # For memcpy
    echo "" >> "$header_file"

    # Define the Asset struct with flexible array member for data
    cat <<EOL >> "$header_file"
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

EOL
}

# Write the function to dynamically allocate and initialize assets in a .c file
write_asset_functions() {
    local c_file="$1"

    cat <<EOL >> "$c_file"
#include <stdlib.h>
#include <string.h>
#include "skylanders_assets.h"

// Function to create an Asset dynamically
Asset* create_asset(const unsigned char* data, size_t data_len, const char* name, const char* game, const char* type) {
    // Allocate memory for the Asset struct plus the data array
    Asset* asset = (Asset*)malloc(sizeof(Asset) + data_len);
    if (!asset) return NULL;

    // Initialize the fields
    asset->data_len = data_len;
    asset->name = name;
    asset->game = game;
    asset->type = type;

    // Copy the data into the flexible array member
    memcpy(asset->data, data, data_len);

    return asset;
}

// Function to free the dynamically allocated Asset
void free_asset(Asset* asset) {
    free(asset);
}

EOL
}

# Strip the Skylanders_<number>_ prefix from the game name
strip_game_prefix() {
    local game_name="$1"
    echo "$game_name" | sed 's/^Skylanders_[0-9]\+_//'
}

# Directory for generated headers and source files
rm -rf "skylanders_data/headers"
mkdir -p "skylanders_data/headers"
header_file="skylanders_data/headers/skylanders_assets.h"
c_file="skylanders_data/headers/skylanders_assets.c"

# Write the struct definition at the top of the header file
write_struct_definition "$header_file"
write_asset_functions "$c_file"

# Declare the assets array with size based on the number of .nfc files
echo "Asset* assets[$nfc_count];" >> "$c_file"  # Dynamically set the array size

# Buffer to hold the runtime asset creation calls
runtime_creation_buffer="void initialize_assets() {\n    int asset_index = 0;\n"  # Declare asset_index locally

# Iterate over each game directory
for game_dir in skylanders_data/*; do
    [ -d "$game_dir" ] || continue  # Skip if not a directory

    # Iterate over each asset directory within the game directory
    for asset_dir in "$game_dir"/*; do
        # Iterate over each .nfc file in the child directory
        for nfc_file in "$asset_dir"/*.nfc; do
            if [ -f "$nfc_file" ]; then
                # Generate a variable name based on the file name and directory structure
                var_name="$(basename "$game_dir")_$(basename "$asset_dir")_$(basename "$nfc_file" .nfc)"
                var_name="${var_name//[^a-zA-Z0-9_]/_}"  # Sanitize the variable name

                echo "Processing $nfc_file..."

                # Convert the file to a C array and store it in the .c file
                convert_file_to_c_array "$nfc_file" "$var_name" "$c_file"

                # Strip Skylanders_<number>_ prefix from the game directory name
                game_name="$(strip_game_prefix "$(basename "$game_dir")")"

                # Add code to create the asset dynamically at runtime using asset_index
                runtime_creation_buffer+=$(cat <<EOL
    {
        extern unsigned char skylanders_data_${var_name}_nfc[];
        extern unsigned int skylanders_data_${var_name}_nfc_len;
        assets[asset_index] = create_asset(skylanders_data_${var_name}_nfc, skylanders_data_${var_name}_nfc_len,
            "$(basename "$nfc_file" .nfc)", "$game_name", "$(basename "$asset_dir")");
        asset_index++;
    }
EOL
)
            fi
        done
    done
done

# Close the runtime creation function
runtime_creation_buffer+="}\n"

# Append the runtime creation function to the .c file
echo -e "$runtime_creation_buffer" >> "$c_file"

echo "Header file created at $header_file!"
echo "Source file created at $c_file!"
