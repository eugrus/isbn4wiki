#!/bin/bash

# Pass ISBN and optionally the subdomain of a supported language edition of Wikipedia as command line arguments
isbn=$1
lang=$2

# Use Google Books API to retrieve book information
data=$(curl -s "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn")

# Data extraction from API response
title=$(echo $data | jq -r '.items[0].volumeInfo.title')
author=$(echo $data | jq -r '.items[0].volumeInfo.authors[]' | tr '\n' ", ")
author=${author:0:-1} # removing the leftover comma
publisher=$(echo $data | jq -r '.items[0].volumeInfo.publisher')
date=$(echo $data | jq -r '.items[0].volumeInfo.publishedDate')
year=${date:0:4}

# Template generation

# for ru.wikipedia.org as an option
if [[ $lang == "ru" ]]; then
  template="{{Книга
  |название=$title
  |автор=$author
  |год=$year
  |издательство=$publisher
  |isbn=$isbn
  |ref=
  }}"
# for en.wikipedia.org as a default
else
  template="{{Cite book
  |title=$title
  |author=$author
  |date=$date
  |publisher=$publisher
  |isbn=$isbn
  |ref=
  }}"
fi

echo "$template"
