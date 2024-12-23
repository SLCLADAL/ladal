import os
import shutil
import re

def rename_rmd_to_qmd(target_dir):
    # Check if the directory exists
    if not os.path.exists(target_dir):
        print(f"Error: Directory {target_dir} does not exist.")
        return

    # Walk through the directory
    for root, dirs, files in os.walk(target_dir):
        for file in files:
            # Check if the file has a .Rmd extension
            if file.endswith(".Rmd"):
                # Construct full file paths
                old_path = os.path.join(root, file)
                new_path = os.path.join(root, file.replace(".Rmd", ".qmd"))

                # Rename the file
                os.rename(old_path, new_path)
                print(f"Renamed: {old_path} -> {new_path}")

    print("All .Rmd files have been renamed to .qmd.")

def replace_images_path_in_file(file_path):
    """
    Replaces '](images' with '](/images' in a given file.
    """
    try:
        # Read the content of the file
        with open(file_path, 'r') as file:
            content = file.read()

        # Replace all occurrences of '](images' with '](/images'
        content = content.replace('](images', '](/images')

        source_dir = "/Users/laurenceanthony/Documents/projects/LADAL/"
        target_dir = ""
        pattern = r'source\("(rscripts[^"]+)"\)'
        matches = re.findall(pattern, content)  
        # Copy each matched R script from source_dir to target_dir
        for script_name in matches:
            source_path = os.path.join(source_dir, script_name)
            target_path = os.path.join(target_dir, script_name)
            if os.path.exists(source_path):
                shutil.copy2(source_path, target_path)
                print(f"Copied {script_name} from {source_dir} to {target_dir}")
            else:
                print(f"Warning: {script_name} not found in {source_dir}")

        # Write the updated content back to the file
        with open(file_path, 'w') as file:
            file.write(content)

        print(f"Updated {file_path}")

    except Exception as e:
        print(f"Error processing {file_path}: {e}")

def walk_and_replace(directory):
    """
    Walks through a directory and processes all `.qmd` files to replace '](images' with '](/images'.
    """
    # Walk through all files in the directory
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".qmd"):
                file_path = os.path.join(root, file)
                replace_images_path_in_file(file_path)


if __name__ == "__main__":

    # Define the target directory relative to the script
    target_directory = "notebooks"

    # Call the function
    rename_rmd_to_qmd(target_directory)
    walk_and_replace(target_directory)