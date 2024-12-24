# required packages
library(dplyr)
library(ggplot2)
library(here)
library(quanteda)
library(quanteda.textplots)
library(quanteda.textstats)
library(seededlda)
library(stringr)
library(tidyr)
library(writexl)

# define function
loadtxts <- function(x = "notebooks/MyTexts") {
  fls <- list.files(here::here(x), # path to the corpus data

    # full paths - not just the names of the files
    full.names = T
  )
  # remove test.txt from file list
  fls <- fls[!stringr::str_detect(fls, ".*test.txt")]

  # loop over the vector 'myfiles' that contains paths to the data
  txts <- sapply(fls, function(x) {
    # read the content of each file using 'scan'
    x <- scan(x,
      what = "char", # specify that the input is characters
      sep = "", # set separator to an empty string (read entire content)
      quote = "", # set quote to an empty string (no quoting)
      quiet = T, # suppress scan messages
      skipNul = T
    ) # skip NUL bytes if encountered

    # combine the character vector into a single string with spaces
    x <- paste0(x, sep = " ", collapse = " ")

    # remove extra whitespaces using 'str_squish' from the 'stringr' package
    x <- stringr::str_squish(x)
  })

  # clean names

  # Define the function to reduce the content to the first 10 words
  reduce_to_10_words <- function(corpus) {
    # Use sapply to apply the function to each file's content in the corpus
    reduced_corpus <- sapply(corpus, function(text) {
      # Split the text into words
      words <- str_split(text, "\\s+")[[1]]

      # Keep only the first 10 words
      words <- words[1:5]

      # Collapse the words back into a single string
      reduced_text <- paste(words, collapse = " ")

      return(reduced_text)
    })

    # Return the reduced corpus (still a named character vector)
    return(reduced_corpus)
  }

  # Test the function
  txts <- reduce_to_10_words(txts)

  # clean names
  names(txts) <- stringr::str_remove_all(names(txts), ".*/")
  names(txts) <- tools::file_path_sans_ext(names(txts)) # remove file extension (.txt)

  # inspect the structure of the text object
  return(txts)
}

