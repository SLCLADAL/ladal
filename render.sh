#!/bin/bash

# Set the parent directory where your tutorial folders are located
PARENT_DIR="."

echo "$(realpath "$PARENT_DIR")"

runone=false
usecache=true
usethis="basicstatz"
parentfolder="tutorials"
exclude_list=("./tutorials/postag/postag.qmd ./tutorials/regression/regression.qmd")

if $runone; then
  > logs/all.log
fi
# the following tutorials need to first be built without cache (no idea why!)
# regression, postag

# if $runall && $usecache; then
#     echo "Running all tasks (CACHE)."
#     quarto render --execute-dir $PARENT_DIR --exclude ./tutorials/postag/postag.qmd > logs/main.log 2>&1
#     exit 0
# elif $runall; then
#     echo "Running all tasks (NO CACHE)."
#     quarto render --no-cache --execute-dir $PARENT_DIR > logs/main.log 2>&1
#     exit 0
# fi


# Set the start index (change this to where you want to start)
START_INDEX=0

# Set the stop index (set to -1 for no stop condition, meaning process all folders)
STOP_INDEX=-1

# Loop through all subfolders in the tutorials folder
count=0  # Folder counter

find "$PARENT_DIR" -type f -name "*.qmd" | sort | while read -r file; do
  # echo "$file"
  # Check if it's a directory (just a safety check)
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

    # echo $file

    # Optional: You can add additional skipping logic here, like checking folder names
    # Example: Skip folders named "skip_this_folder"
    if $runone && [ "$file" != "./$parentfolder/$usethis/$usethis.qmd" ]; then
      # echo "Skipping folder: $folder_name"
      continue
    fi
    
    if $usecache; then
      # Loop through the exclude list
      use_nocache=false
      for exclude in "${exclude_list[@]}"; do
          if [ "$file" == "$exclude" ]; then
              use_nocache=true
              break  # Exit the loop once a match is found
          fi
      done

      # If a match was found, use_nocache this file
      if [ "$use_nocache" == true ]; then
          echo "Nocache file: $file => Render with no cache"
          quarto render ${file} --no-cache --execute-dir $PARENT_DIR 2>&1 | tee logs/log_${usethis}.log | tee -a logs/all.log > /dev/null
          continue
      else
        # echo "Rendering $(realpath "$folder") with cache."
        echo "Rendering $count "$file" (CACHE)"
        quarto render ${file} --execute-dir $PARENT_DIR 2>&1 | tee logs/log_${usethis}.log | tee -a logs/all.log > /dev/null
      fi

    else
        echo "Rendering $count "$file" (NO CACHE)."
        quarto render ${file} --no-cache --execute-dir $PARENT_DIR 2>&1 | tee logs/log_${usethis}.log | tee -a logs/all.log > /dev/null
    fi

    # Increment the counter
    ((count++))
done

if [ "$runone" == "false" ]; then
  echo "Running the copy_qmd_files script because runone is false."
  ./helpers/copy_qmd_files.sh
else
  # echo "Not running the copy_qmd_files script because runone is true."
  echo ""
fi
