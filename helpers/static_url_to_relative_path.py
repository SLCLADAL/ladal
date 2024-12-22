import json
import os
import re
from pathlib import Path
import shutil

def move_file(src, dest):
    try:
        # Move the file from the source to the destination
        shutil.copy(src, dest)
        print(f"File moved successfully from {src} to {dest}")
    except Exception as e:
        print(f"Error: {e}")

#Notes
# No tagging tutorial
# No topicmodels tutorial
# No pvd tutorial
# URLS will be replaced with dummy tutorials/ paths


tutorials = [f for f in os.listdir('tutorials') 
        if os.path.isdir(os.path.join('tutorials', f))]

tutorials.append('tagging')
tutorials.append('topicmodels')

# Function to replace the URL part with the relative path
def replace_url_with_relative_path(qmd_file_path, urls):

    current_tutorial = Path(qmd_file_path).stem
    # print(current_tutorial)

    updated_urls = []

    for url in urls:

        new_url = url
        # print(new_url)

        for tutorial in tutorials:

            new_url = new_url.replace('[Here]', '[here]')
            new_url = new_url.replace('[**here**]', '[here]')
            new_url = new_url.replace('[This tutorials]', '[this tutorial]')
            new_url = new_url.replace('[This tutorial]', '[this tutorial]')
            new_url = new_url.replace('[this tutorials]', '[this tutorial]')
            new_url = new_url.replace("note = {https://slcladal.github.io/survey.html}", "note = {https://slcladal.github.io/surveys.html}")
            new_url = new_url.replace("note = {https://slcladal.github.io/basicstatzchi.html}", "note = {https://slcladal.github.io/basicstatz.html}")
            new_url = new_url.replace("[here](\"https://slcladal.github.io/content/atap_docclass.Rmd\")", "[here](https://slcladal.github.io/content/atap_docclass.Rmd)")
            new_url = new_url.replace("note = {https://ladal.edu.au/ATAP_DocClass_Markdown.html}", "note = {https://ladal.edu.au/atap_docclass.html}")
            new_url = new_url.replace("(https://slcladal.github.io/content/bibliography.bib)", "(/assets/bibliography.bib)")
            new_url = new_url.replace("(https://ladal.edu.au/clust.html#2_Correspondence_Analysis)", "(tutorials/clust/clust.html#2_Correspondence_Analysis)")
            new_url = new_url.replace("(https://slcladal.github.io/content//pdf2txt.Rmd)", "(tutorials/pdf2txt/pdf2txt.Rmd)")
            new_url = new_url.replace("(https://slcladal.github.io/content/surveys.Rmd)", "(tutorials/surveys/surveys.Rmd)")
            new_url = new_url.replace("(https://slcladal.github.io/regression.html#Multicollinearity)", "(tutorials/regression/regression.html#Multicollinearity)")
            # print(tutorial)
            # print('>', url)
            for value in ['here', 'this tutorial to R', '**bibliography file**', 'this tutorial']:
                for site in ['https://slcladal.github.io', 'https://ladal.edu.au']:

                    matching_url = f'[{value}]({site}/{tutorial}.html)'
                    replaced_url = f'[{value}](tutorials/{tutorial}/{tutorial}.html)'
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f'[{value}]({site}/{tutorial}.html#16_Robust_Regression)'
                    replaced_url = f'[{value}](tutorials/{tutorial}/{tutorial}.html#16_Robust_Regression)'
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f'[{value}]({site}/{tutorial}.html#Example_2:_Teaching_Styles)'
                    replaced_url = f'[{value}](tutorials/{tutorial}/{tutorial}.html#Example_2:_Teaching_Styles)'
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f'[{value}]({site}/{tutorial}.html#Working_with_text)'
                    replaced_url = f'[{value}](tutorials/{tutorial}/{tutorial}.html#Working_with_text)'
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f'[{value}]({site}/{tutorial}.html#11_Simple_Linear_Regression)'
                    replaced_url = f'[{value}](tutorials/{tutorial}/{tutorial}.html#11_Simple_Linear_Regression)'
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f'[{value}]({site}/content/{tutorial}.Rmd)'
                    
                    replaced_url = f'[{value}](tutorials/{tutorial}/{tutorial}.qmd)'
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f'[{value}]({site}/content/bibliography.bib)'
                    replaced_url = f'[{value}](/assets/bibliography.bib'
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f'[{value}]({site}/content/bibtex.bib)'
                    replaced_url = f'[{value}](/assets/bibliography.bib'
                    if new_url == matching_url:
                        new_url = replaced_url

                    if f"readRDS(url(\"{site}/data/" in new_url:
                        new_url = new_url.replace(f"readRDS(url(\"{site}/data/", f"readRDS(\"tutorials/{current_tutorial}/data/")
                        new_url = new_url.replace('))', ')')
                        
                    if f"read.delim(\"{site}/data/" in new_url:
                        new_url = new_url.replace(f"read.delim(\"{site}/data/", f"read.delim(\"tutorials/{current_tutorial}/data/")

                    matching_url = f"note = {{{site}/{tutorial}.html}}"
                    replaced_url = f"note = {{tutorials/{tutorial}/{tutorial}.html}}"
                    if new_url == matching_url:
                        new_url = replaced_url

                    matching_url = f"Queensland. url: {site}/{tutorial}.html"
                    replaced_url = f"Queensland. url: https://ladal.edu.au/tutorials/{tutorial}.html"
                    if new_url == matching_url:
                        new_url = replaced_url

                    if f"`{site}/data" in new_url:
                        new_url = new_url.replace(f"`{site}/data", f"`tutorials/{current_tutorial}/data")

                    if f"\"{site}/data" in new_url:
                        new_url = new_url.replace(f"\"{site}/data", f"\"tutorials/{current_tutorial}/data")

                    if f"\"{site}/images" in new_url:
                        new_url = new_url.replace(f"\"{site}/images", f"\"images")
                        source_path = os.path.join("/Users/laurenceanthony/Documents/projects/LADAL_refactored/old_content/old_non_content_files", new_url.replace('"', ''))
                        destination_path = "/Users/laurenceanthony/Documents/projects/@projects_misc/LADALQ_TEMP/images"
                        print(source_path)
                        print(destination_path)
                        move_file(source_path, destination_path)

                    if f"\"{site}/rscripts" in new_url:
                        new_url = new_url.replace(f"\"{site}/rscripts", f"\"rscripts")

                    if f"\"{site}/rscripts" in new_url:
                        new_url = new_url.replace(f"\"{site}/rscripts", f"\"rscripts")

                    if f"({site}/data" in new_url:
                        new_url = new_url.replace(f"({site}/data", f"(tutorials/{current_tutorial}/data")

                    if f"({site}/images" in new_url:
                        new_url = new_url.replace(f"({site}/images", f"(images")
                        source_path = os.path.join("/Users/laurenceanthony/Documents/projects/LADAL_refactored/old_content/old_non_content_files", new_url.replace('(', '').replace(')', ''))
                        destination_path = "/Users/laurenceanthony/Documents/projects/@projects_misc/LADALQ_TEMP/images"
                        print(source_path)
                        print(destination_path)
                        move_file(source_path, destination_path)
        

                    if new_url == f"({site}/{tutorial}.html)":
                        new_url = f"(tutorials/{tutorial}.html)"

                    if new_url == f"{site}/{tutorial}.html":
                        new_url = f"tutorials/{tutorial}.html"

                    if new_url == f"({site})":
                        new_url = f"(/)"        

        updated_urls.append(new_url)

        

    # # Get the parent folder path of the QMD file
    # parent_folder = os.path.dirname(qmd_file_path)
    
    # # Iterate over the URLs and replace the matching part with the relative path
    # for url in urls:
    #     relative_path = os.path.relpath(parent_folder, start=os.getcwd())

    #     # Check if the URL contains the target base URL
    #     # if url == "https://ladal.edu.au":
    #     #     new_url = url.replace("https://ladal.edu.au", "/")
    #     #     updated_urls.append(new_url)
    #     if "https://slcladal.github.io/content/" in url:
    #         new_url = url.replace("https://slcladal.github.io/content/", relative_path + "/")
    #         updated_urls.append(new_url)
    #     elif "https://slcladal.github.io/data" in url:
    #         new_url = url.replace("https://slcladal.github.io/data/", 'data/')
    #         updated_urls.append(new_url)
    #     elif "https://ladal.edu.au/data" in url:
    #         new_url = url.replace("https://ladal.edu.au/data/", relative_path + "/" + 'data/')
    #         updated_urls.append(new_url)
    #     else:
    #         updated_urls.append(url)
    
    return updated_urls

# Function to process the JSON file and update the URLs in the QMD files
def process_json_and_update_urls(json_file):
    # Open and load the JSON data
    with open(json_file, 'r', encoding='utf-8') as file:
        data = json.load(file)
    
    # Iterate through each QMD file path (key) in the JSON data
    for qmd_file_path, urls in data.items():
        if '.qmd' not in qmd_file_path:
            continue
        # if qmd_file_path != 'tutorials/tree/tree.qmd':
        #     continue
        print(f"Processing {qmd_file_path}...")


        # Read the .qmd file and update the URLs
        updated_urls = replace_url_with_relative_path(qmd_file_path, urls)

        # for url in urls:
        #     print('>', url)
        # for url in updated_urls:
        #     print('<', url)

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