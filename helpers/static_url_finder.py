import os
import json
import re

# Define the parent folder
parent_folder = 'tutorials'

# Define a regular expression pattern to match URLs in {r} blocks
# url_pattern = re.compile(r'url\("([^"]+)"\)')
# url_pattern = re.compile(r'https?://[^\s"]+')
# url_pattern = re.compile(r'https?://[^\s")]+')
url_pattern = re.compile(r'\[[hH]ere\]\(["\']?https?://[^\)"\']+["\']?\)')

# Dictionary to store the results
results = {}

# Function to process a qmd file and extract URLs
def extract_urls_from_qmd(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
        
    # Find all URLs in the file content
    urls = re.findall(url_pattern, content)
    
    # Return a list of URLs found
    return urls

# Walk through all subdirectories of the parent folder
for root, dirs, files in os.walk(parent_folder):
    for file in files:
        # if file != 'atap_docclass.qmd':
        #     continue


        if file.endswith('.qmd'):  # Process only .qmd files
            qmd_file_path = os.path.join(root, file)
            urls = extract_urls_from_qmd(qmd_file_path)

            print(qmd_file_path, len(urls))

            
            # If URLs are found, store them in the results dictionary
            if urls:
                results[qmd_file_path] = urls

# Output the results as a JSON key-value store
output_file = 'helpers/qmd_urls.json'
with open(output_file, 'w', encoding='utf-8') as json_file:
    json.dump(results, json_file, ensure_ascii=False, indent=4)

print(f"Extraction complete. Results saved in '{output_file}'.")