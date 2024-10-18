#!/bin/bash

# Convert the .nfc file to a byte array and append it to the header file
convert_file_to_c_array() {
    local file_path="$1"
    local header_file="$2"

    # Append the output of xxd -i to the header file
    xxd -i "$file_path" >> "$header_file"
    echo "" >> "$header_file"  # Add a newline for readability
}

rm -rf "skylanders_data/headers"

# Iterate over each game directory
for game_dir in skylanders_data/*; do
    # Skip if not a directory, just in case
    [ -d "$game_dir" ] || continue

    # Iterate over each asset directory within the game directory
    for asset_dir in "$game_dir"/*; do
        # Create a C header file for each game,asset pair directory
        header_file="skylanders_data/headers/$(basename "$game_dir")_$(basename "$asset_dir").h"
        echo "Creating header file: $header_file"
        mkdir -p "skylanders_data/headers"

        # Write the #pragma once directive at the top
        echo "#pragma once" > "$header_file"
        echo "" >> "$header_file"

        # Iterate over each .nfc file in the child directory
        for nfc_file in "$asset_dir"/*.nfc; do
            if [ -f "$nfc_file" ]; then
                # Convert the .nfc file to a C array and append to the header file
                echo "Processing $nfc_file..."
                convert_file_to_c_array "$nfc_file" "$header_file"
            fi
        done
    done
done

echo "All header files created!"

