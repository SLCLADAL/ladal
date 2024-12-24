import os
import shutil
import re

def copy_file(source_file, destination_folder):
        if os.path.isfile(source_file):
            try:
                # Move the file to the destination folder
                shutil.copy(source_file, destination_folder)
                # print(f"Copied '{source_file}' to '{destination_folder}'.")
            except Exception as e:
                print(f"Error moving file '{source_file}': {e}")
        else:
            print(f"Source file '{source_file}' does not exist. Skipping...")

def get_subfolders(parent_folder="tutorials"):
    """
    Get all sub-folder names under the given parent folder (one level deep).
    
    :param parent_folder: The parent folder to search for subfolders.
    :return: A list of subfolder names.
    """
    # List to store sub-folder names
    subfolders = []

    # Check if the parent folder exists
    if os.path.isdir(parent_folder):
        # Iterate through the contents of the parent folder
        for entry in os.listdir(parent_folder):
            full_path = os.path.join(parent_folder, entry)
            # Check if the entry is a directory (sub-folder)
            if os.path.isdir(full_path):
                subfolders.append(entry)
    else:
        print(f"The directory '{parent_folder}' does not exist.")

    return subfolders

def copy_rmd_files(folder_names, source_path, parent_folder="tools"):
    """
    Move .qmd files from the source path to the corresponding folders under a parent folder.
    
    :param folder_names: List of folder names to match and move .qmd files for.
    :param source_path: The path where the .qmd files are located.
    :param parent_folder: The parent folder under which the folders are organized.
    """
    for folder_name in folder_names:
        # Build the source file path and destination folder
        source_file = os.path.join(source_path, f"{folder_name}.Rmd")
        destination_folder = os.path.join(parent_folder, folder_name)
        
        if not os.path.exists(destination_folder):
            print(f"Destination folder '{destination_folder}' does not exist. Skipping...")
            continue

        # Get the filename without the .Rmd extension
        filename_without_extension = os.path.splitext(os.path.basename(source_file))[0]

        # Create the new filename with .qmd extension
        new_filename = filename_without_extension + ".qmd"

        # Construct the full destination path
        destination_path = os.path.join(destination_folder, new_filename)

        # Copy the file to the new destination with the new extension
        shutil.copy(source_file, destination_path)


def create_folder_structure(folder_names, parent_folder="./tools"):
    """
    Create a folder structure where each folder name in the list is created under
    a parent folder, and each has a "data" subfolder.
    
    :param folder_names: List of folder names to create.
    :param parent_folder: The parent folder under which folders are created.
    """
    # Ensure the parent folder exists
    if not os.path.exists(parent_folder):
        os.makedirs(parent_folder)
        # print(f"Parent folder '{parent_folder}' created.")
    
    # Iterate through each folder name
    for folder_name in folder_names:
        # Create the folder under the parent folder
        folder_path = os.path.join(parent_folder, folder_name)
        data_folder_path = os.path.join(folder_path, "data")
        rscripts_folder_path = os.path.join(folder_path, "rscripts")
        
        # Create the main folder and the 'data' subfolder
        os.makedirs(data_folder_path, exist_ok=True)
        os.makedirs(rscripts_folder_path, exist_ok=True)
        # print(f"Created folder: {folder_path}")
        # print(f"Created subfolder: {data_folder_path}")


def extract_urls_from_qmd(folder_name, parent_folder="tools"):
    """
    Extract all URLs from a .qmd file in the specified folder under the parent folder
    that are surrounded by specific characters.
    
    :param folder_name: Name of the folder where the .qmd file is located.
    :param parent_folder: The parent folder under which the folder is organized.
    :return: A list of extracted URLs, including their surrounding characters.
    """
    # Define the URL patterns with surrounding characters
    url_patterns = [
        r"['\"]https://slcladal\.github\.io[^\s]*['\"]",  # Single or double quotes
        r"[`\(\{]https://slcladal\.github\.io[^\s]*[`)\}]",  # Backticks, parentheses, or curly braces
        r"['\"]https://ladal\.edu\.au[^\s]*['\"]",  # Single or double quotes
        r"[`\(\{]https://ladal\.edu\.au[^\s]*[`)\}]",  # Backticks, parentheses, or curly braces
        r"url:\s*[^\s]*" # url: example
    ]
    
    found_urls = []
    # Construct the path to the .qmd file
    qmd_file_path = os.path.join(parent_folder, folder_name, f"{folder_name}.qmd")
    
    if os.path.isfile(qmd_file_path):
        try:
            with open(qmd_file_path, "r") as file:
                content = file.read()
            
            # Find all URLs matching the patterns
            for pattern in url_patterns:
                urls = re.findall(pattern, content)
                found_urls.extend(urls)
            
            # print(f"Extracted URLs from '{qmd_file_path}'.")
        except Exception as e:
            print(f"Error reading file '{qmd_file_path}': {e}")
    else:
        print(f"File '{qmd_file_path}' does not exist. Skipping...")

    return found_urls

def replace_urls_in_qmd(folder_name, extracted_urls, parent_folder="tools", candidates=None):
    """
    Replace URLs in a .qmd file if they match specific patterns, and split and replace based on parts.
    
    :param folder_name: Name of the folder where the .qmd file is located.
    :param extracted_urls: List of URLs extracted from the file.
    :param parent_folder: The parent folder containing the .qmd files.
    :param candidates: List of keywords to match in Part b of the URL.
    """
    if candidates is None:
        candidates = ["amtool", "keytool"]  # Default list of candidates if not provided

    # Define patterns A and B
    pattern_a = r"https://ladal\.edu\.au/"
    pattern_b = r"https://slcladal\.github\.io/"
    folder_pattern = folder_name  # Pattern C

    # Construct the path to the .qmd file
    qmd_file_path = os.path.join(parent_folder, folder_name, f"{folder_name}.qmd")

    if not os.path.isfile(qmd_file_path):
        print(f"File '{qmd_file_path}' does not exist. Skipping...")
        return

    try:
        # Read the content of the file
        with open(qmd_file_path, "r") as file:
            content = file.read()

        # Replace URLs in the file content
        for url in extracted_urls:
            # Clean the URL by removing quotes, backticks, parentheses, and the "url: " prefix
            cleaned_url = re.sub(r"^url:\s*", "", url.strip(" '\"`(){}[]"))
            # print(cleaned_url)
            # Check if the cleaned URL starts with pattern A or B followed by C
            match = re.match(f"({pattern_a}|{pattern_b})(.*?)(\.(qmd|html|R|jpg|png|[a-zA-Z0-9]+))?$", cleaned_url)            
            if match:
                # Split the URL into three parts
                base_url = match.group(1)  # Pattern A or B
                part_b = match.group(2)    # Content after pattern A or B
                extension = match.group(3)  # File extension (.qmd or .html)
                # print(part_b)

                if part_b == "tools":
                    new_url = cleaned_url.replace(base_url, f"")
                elif part_b.startswith('rscripts'):
                    # print(parent_folder)
                    source_path = os.path.join("/Users/laurenceanthony/Documents/projects/LADAL", f"{part_b}{extension}")
                    destination_folder = os.path.join(parent_folder, folder_name, f"{part_b}{extension}")
                    # print(source_path)
                    # print(destination_folder)
                    copy_file(source_path, destination_folder)
                    new_url = os.path.join(parent_folder, folder_name, f"{part_b}{extension}")
                    # print(cleaned_url, new_url)
                elif part_b.startswith('images'):
                    new_url = cleaned_url.replace(base_url, f"/")
                elif any(candidate in part_b for candidate in candidates):
                    # Replace the base URL (A or B) with '/tools/C/'
                    new_url = cleaned_url.replace(base_url, f"tutorials/{part_b}/")

                # Replace the old URL in the content
                content = content.replace(cleaned_url, f"{new_url}")
                # print(f"Replaced '{cleaned_url}' with '{new_url}'")

        # Write the updated content back to the file
        with open(qmd_file_path, "w") as file:
            file.write(content)

    except Exception as e:
        print(f"Error processing file '{qmd_file_path}': {e}")

def replace_error_in_content(folder_name, parent_folder="tools"):
    # Construct the path to the .qmd file
    qmd_file_path = os.path.join(parent_folder, folder_name, f"{folder_name}.qmd")

    if not os.path.isfile(qmd_file_path):
        print(f"File '{qmd_file_path}' does not exist. Skipping...")
        return

    try:
        # Read the content of the file
        with open(qmd_file_path, "r") as file:
            content = file.read()

            if folder_name == "amtool":
                before = """Replace `YOUR TERM` with the term you are intersted in."""
                after = """Replace `linguistics` with the term you are intersted in."""
                content = content.replace(before, after)

                before = """dplyr::filter(w1 == "YOUR TERM") -> colldf"""
                after = """dplyr::filter(w1 == "linguistics") -> colldf"""
                content = content.replace(before, after)

            elif folder_name == "keytool":
                before = "text <- loadkeytxts()"
                after = """text <- loadkeytxts("notebooks/Target", "notebooks/Reference")"""
                content = content.replace(before, after)

        # Write the updated content back to the file
        with open(qmd_file_path, "w") as file:
            file.write(content)

    except Exception as e:
        print(f"Error processing file '{qmd_file_path}': {e}")

folder_names_list = ["amtool", "keytool", "kwictool", "nettool", "postool", "sentool", "stringtool", "topictool"]
source_path = os.path.join("/Users/laurenceanthony/Documents/projects/LADAL", "cbs")
tutorial_subfolders = get_subfolders()


create_folder_structure(folder_names_list)
copy_rmd_files(folder_names_list, source_path)
for folder_name in folder_names_list:
    print(folder_name)
    extracted_urls = extract_urls_from_qmd(folder_name)
    # for url in extracted_urls:
    #     print(url)

    replace_urls_in_qmd(folder_name, extracted_urls, "tools", tutorial_subfolders)
    replace_error_in_content(folder_name)

shutil.copy("helpers/corrected_rscripts/tabtop.R", "tools/topictool/rscripts/tabtop.R")
