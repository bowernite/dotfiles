#!/bin/bash

# Build all TypeScript files in the projects directory
# This script recursively finds and compiles all .ts files

set -e  # Exit on any error

echo "Building all TypeScript files in projects directory..."

# Create build directory if it doesn't exist
mkdir -p .build bin

# Find and build all TypeScript files
find projects -name '*.ts' | while read -r file; do
    echo "Building: $file"
    
    # Get the relative path without extension for output naming
    relative_path="${file#projects/}"
    output_name="${relative_path%.ts}"
    
    # Build the file
    bun build --compile --outfile=".build/$output_name" "$file"
    
    # Move to bin directory
    mv ".build/$output_name" "bin/$output_name"
done

# Clean up temporary files
rm -f .*.bun-build

echo "Build complete! All files compiled to bin/ directory"
