import json
import os
import re

# Function to replace the URL part with the relative path
def replace_url_with_relative_path(qmd_file_path, urls):
    # Get the parent folder path of the QMD file
    parent_folder = os.path.dirname(qmd_file_path)
    
    # Iterate over the URLs and replace the matching part with the relative path
    updated_urls = []
    for url in urls:
        relative_path = os.path.relpath(parent_folder, start=os.getcwd())

        # Check if the URL contains the target base URL
        # if url == "https://ladal.edu.au":
        #     new_url = url.replace("https://ladal.edu.au", "/")
        #     updated_urls.append(new_url)
        if "https://slcladal.github.io/content/" in url:
            new_url = url.replace("https://slcladal.github.io/content/", relative_path + "/")
            updated_urls.append(new_url)
        elif "https://slcladal.github.io/data" in url:
            new_url = url.replace("https://slcladal.github.io/data/", 'data/')
            updated_urls.append(new_url)
        elif "https://ladal.edu.au/data" in url:
            new_url = url.replace("https://ladal.edu.au/data/", relative_path + "/" + 'data/')
            updated_urls.append(new_url)
        else:
            updated_urls.append(url)
    
    return updated_urls

# Function to process the JSON file and update the URLs in the QMD files
def process_json_and_update_urls(json_file):
    # Open and load the JSON data
    with open(json_file, 'r', encoding='utf-8') as file:
        data = json.load(file)
    
    # Iterate through each QMD file path (key) in the JSON data
    for qmd_file_path, urls in data.items():
        if qmd_file_path != 'tutorials/basicquant/basicquant.qmd':
            continue
        print(f"Processing {qmd_file_path}...")


        # Read the .qmd file and update the URLs
        updated_urls = replace_url_with_relative_path(qmd_file_path, urls)

        for url in urls:
            print(url)
        for url in updated_urls:
            print(url)

        # quit()
        # print(updated_urls)

        # for updated_url in updated_urls:
        #     print(updated_url)
                
        # Now, open the actual QMD file and update the URLs
        with open(qmd_file_path, 'r', encoding='utf-8') as qmd_file:
            qmd_content = qmd_file.read()
        
        # Replace old URLs with the new ones in the content
        for old_url, new_url in zip(urls, updated_urls):
            qmd_content = qmd_content.replace(old_url, new_url)
        
        # Write the updated content back to the QMD file
        with open(qmd_file_path, 'w', encoding='utf-8') as qmd_file:
            qmd_file.write(qmd_content)
        
        print(f"Updated URLs in {qmd_file_path}")

# Define the path to the JSON file containing URLs
json_file = 'helpers/qmd_urls.json'

# Run the script
process_json_and_update_urls(json_file)

print("Processing complete.")