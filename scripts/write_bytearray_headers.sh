#!/bin/bash

# Convert the .nfc file to a C array (xxd -i format) and declare it before the asset array
convert_file_to_c_array() {
    local file_path="$1"
    local var_name="$2"
    local header_file="$3"

    # Use xxd to generate the byte array and its length variable with the correct name
    xxd -i "$file_path" | sed "s/unsigned int \w*/unsigned int ${var_name}_nfc_len/" >> "$header_file"
    echo "" >> "$header_file"  # Add a newline after the array declaration
}

# Create a struct definition for assets in the header
write_struct_definition() {
    local header_file="$1"
    echo "#pragma once" > "$header_file"
    echo "" >> "$header_file"
    echo "#include <stddef.h>" >> "$header_file"  # For size_t
    echo "" >> "$header_file"

        # Define the Asset struct
    cat <<EOL >> "$header_file"
typedef struct {
    unsigned char* data;
    size_t data_len;
    const char* name;   // basename without extension, "nfc_file" in the script
    const char* game;   // the game it's in, "game_dir" in the script
    const char* type;   // Figure, Magic Item, etc. "asset_dir" in the script
} Asset;

EOL
}

# Write the array of assets declaration (without entries) to the header file
write_asset_array_declaration() {
    local header_file="$1"
    echo "Asset assets[] = {" >> "$header_file"
}

# Close the array of assets in the header file
close_asset_array() {
    local header_file="$1"
    echo "};" >> "$header_file"
    echo "" >> "$header_file"
    echo "define ASSET_COUNT (sizeof(assets) / sizeof(assets[0]))" >> "$header_file"
}

# Strip the Skylanders_<number>_ prefix from the game name
strip_game_prefix() {
    local game_name="$1"
    echo "$game_name" | sed 's/^Skylanders_[0-9]\+_//'
}

# Directory for generated headers
rm -rf "skylanders_data/headers"
mkdir -p "skylanders_data/headers"
header_file="skylanders_data/headers/skylanders_assets.h"

# Write the struct definition at the top of the header file
write_struct_definition "$header_file"

# Buffer to hold the asset array definition to be written at the end
asset_array_buffer=""

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

                # Convert the file to a C array (write declarations first)
                convert_file_to_c_array "$nfc_file" "$var_name" "$header_file"

                # Strip Skylanders_<number>_ prefix from the game directory name
                game_name="$(strip_game_prefix "$(basename "$game_dir")")"

                # Prepare the asset struct entry (to be written later in the array)
                asset_array_buffer+=$(cat <<EOL

    {
        $var_name,
        ${var_name}_nfc_len,
        "$(basename "$nfc_file" .nfc)",
        "$game_name",
        "$(basename "$asset_dir")"
    },
EOL
)
            fi
        done
    done
done

# Write the array of assets declaration
write_asset_array_declaration "$header_file"

# Append all asset entries to the array
echo "$asset_array_buffer" >> "$header_file"

# Close the asset array declaration
close_asset_array "$header_file"

echo "Header file created at $header_file!"

