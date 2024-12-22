import os
import json
import re

# Define the parent folder
parent_folder = 'tutorials'

# Dictionary to store the results
results = {}

# Function to process a qmd file and extract URLs
def extract_urls_from_qmd(file_path, url_pattern):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
        
    # Find all URLs in the file content
    urls = re.findall(url_pattern, content)
    
    # Return a list of URLs found
    return urls

# Walk through all subdirectories of the parent folder
for root, dirs, files in os.walk(parent_folder):
    for file in files:
        # if file != 'lex.qmd':
        #     continue

        if file.endswith('.qmd'):  # Process only .qmd files
            qmd_file_path = os.path.join(root, file)
            
            complete_urls = []
            # Define a regular expression pattern to match URLs in {r} blocks
            # url_pattern = re.compile(r'url\("([^"]+)"\)')
            # url_pattern = re.compile(r'https?://[^\s"]+')
            # url_pattern = re.compile(r'https?://[^\s")]+')

            url_patterns = [
                #stage 1 "[Here] examples"
                re.compile(r'\[[hH]ere\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'\[\*\*here\*\*\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'\[this tutorial to R\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'\[this tutorial\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'\[This tutorials\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'\[This tutorial\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'\[this tutorials\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'\[\*\*bibliography file\*\*\]\(["\']?https?://[^\)"\']+["\']?\)'),
                re.compile(r'readRDS\(url\(["\']https?://[^\)"\']+["\'],\s*["\'][^"\']*["\']\)\)'),
                re.compile(r'read\.delim\(["\']https?://[^\)"\']+["\']'),
                re.compile(r'note\s*=\s*\{https?://[^\}]+\}'),
                re.compile(r'Queensland\.\s*url:\s*https?://[^\s]+'),
                re.compile(r'["\']https?://[^\)"\']+["\']'),
                re.compile(r'\([^\s\)]*https?://[^\s\)]*\)'),
                re.compile(r'`[^\s\)]*https?://[^\s\)]*`'),
                re.compile(r'url:\s*(https?://(?:www\.)?(?:slcladal|ladal)\.[a-z\.]+[^\s]*)')

            ]



        # [this tutorial to R]

            for url_pattern in url_patterns:

                urls = extract_urls_from_qmd(qmd_file_path, url_pattern)
                for url in urls:
                    if 'slcladal' in url or 'ladal' in url:
                        complete_urls.append(url)

            print(qmd_file_path, len(complete_urls))

            
            # If URLs are found, store them in the results dictionary
            if complete_urls:
                results[qmd_file_path] = complete_urls

# Output the results as a JSON key-value store
output_file = 'helpers/qmd_urls.json'
with open(output_file, 'w', encoding='utf-8') as json_file:
    json.dump(results, json_file, ensure_ascii=False, indent=4)

print(f"Extraction complete. Results saved in '{output_file}'.")