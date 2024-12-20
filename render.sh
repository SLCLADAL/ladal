#!/bin/bash

# Set the parent directory where your tutorial folders are located
PARENT_DIR="tutorials"

# Set the start index (change this to where you want to start)
START_INDEX=21

# Set the stop index (set to -1 for no stop condition, meaning process all folders)
STOP_INDEX=21

# Loop through all subfolders in the tutorials folder
count=0  # Folder counter
for folder in "$PARENT_DIR"/*/; do
  # Check if it's a directory (just a safety check)
  if [ -d "$folder" ]; then
    # Skip folders before the start index
    if [ $count -lt $START_INDEX ]; then
      ((count++))
      continue
    fi

    # If the stop index is not -1 and the current folder is beyond the stop index, break
    if [ $STOP_INDEX -ne -1 ] && [ $count -gt $STOP_INDEX ]; then
      echo "Reached stop index $STOP_INDEX. Stopping script."
      break
    fi

    # Optional: You can add additional skipping logic here, like checking folder names
    # Example: Skip folders named "skip_this_folder"
    folder_name=$(basename "$folder")
    if [ "$folder_name" == "skip_this_folder" ]; then
      echo "Skipping folder: $folder_name"
      continue
    fi

    # Render the Quarto project with --no-cache
    echo "Rendering folder $count: $folder_name"
    quarto render "$folder" --no-cache

    # Increment the counter
    ((count++))
  fi
done