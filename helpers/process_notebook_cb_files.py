import os

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

if __name__ == "__main__":
    # Define the target directory relative to the script
    target_directory = "notebooks"

    # Call the function
    rename_rmd_to_qmd(target_directory)