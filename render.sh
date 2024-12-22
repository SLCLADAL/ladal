#!/bin/bash

# Set the parent directory where your tutorial folders are located
PARENT_DIR="."

echo "$(realpath "$PARENT_DIR")"

runall=true
usecache=true
usethis="postag"

# the following tutorials need to first be built without cache (no idea why!)
# regression, postag

if $runall && $usecache; then
    echo "Running all tasks (CACHE)."
    quarto render --execute-dir $PARENT_DIR > logs/main.log 2>&1
    exit 0
elif $runall; then
    echo "Running all tasks (NO CACHE)."
    quarto render --no-cache --execute-dir $PARENT_DIR > logs/main.log 2>&1
    exit 0
fi


# Set the start index (change this to where you want to start)
START_INDEX=0

# Set the stop index (set to -1 for no stop condition, meaning process all folders)
STOP_INDEX=-1

# Loop through all subfolders in the tutorials folder
count=0  # Folder counter

for folder in "$PARENT_DIR/tutorials"/*/; do
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
    if [ "$folder_name" != "$usethis" ]; then
      # echo "Skipping folder: $folder_name"
      continue
    fi
    
    if $usecache; then
        # echo "Rendering $(realpath "$folder") with cache."
        echo "Rendering "$folder_name" (CACHE)."
        quarto render tutorials/${folder_name} --execute-dir $PARENT_DIR > logs/log_${folder_name}.log 2>&1
    else
        echo "Rendering "$folder_name" (NO CACHE)."
        quarto render tutorials/${folder_name} --no-cache --execute-dir $PARENT_DIR > logs/log_${folder_name}.log 2>&1
    fi

    # Increment the counter
    ((count++))
    fi
done