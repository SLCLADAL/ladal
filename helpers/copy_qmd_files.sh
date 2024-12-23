#!/bin/bash

# Define paths
PROJECT_ROOT=$(pwd)
OUTPUT_ROOT="$PROJECT_ROOT/_site"

echo "Running post render script"
# Find and copy .qmd files under tutorials subfolders
find "$PROJECT_ROOT/tutorials" -type f -name "*.qmd" | while read -r file; do
  # Get the relative path
  relative_path="${file#$PROJECT_ROOT/}"
  # Define the destination path
  dest_path="$OUTPUT_ROOT/$relative_path"
  # Ensure the destination directory exists
  mkdir -p "$(dirname "$dest_path")"
  # Copy the file
  cp "$file" "$dest_path"
  echo "Copied $file to $dest_path"
done