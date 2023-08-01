#!/bin/bash 
  
# Pass ISBN and optionally the subdomain of a supported language edition of Wikipedia as command line arguments or get them from URI when invoked by a webserver

if [ -t 0 ]; then
  # Running in a terminal
  isbn="$1"
  lang="$2"
else
  # Running as a script invoked by a webserver
  declare -A params
  IFS='&' read -ra query_params <<< "$QUERY_STRING"
  for param in "${query_params[@]}"; do
    IFS='=' read -r key value <<< "$param"
    params["$key"]="$value"
  done

  isbn="${params["isbn"]}"
  lang="${params["lang"]}"
fi
  
# Remove any non-numerical characters from ISBN
isbn=$(echo "${isbn}" | tr -cd '[:digit:]')

# Use Google Books API to retrieve book information 
data=$(curl -s "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn") 

# Data extraction from API response 
title=$(echo $data | jq -r '.items[0].volumeInfo.title') 
author=$(echo $data | jq -r '.items[0].volumeInfo.authors | join(", ")') 
publisher=$(echo $data | jq -r '.items[0].volumeInfo.publisher') 
date=$(echo $data | jq -r '.items[0].volumeInfo.publishedDate') 
year=${date:0:4} 

# Format ISBN for output into number groups separated by hyphens
isbnf=${isbn:0:3}-${isbn:3:1}-${isbn:4:3}-${isbn:7:5}-${isbn:12:1}

# Template generation 

# for ru.wikipedia.org as an option 
if [[ $lang == "ru" ]]; then 
template="{{Книга 
|название=$title 
|автор=$author 
|год=$year 
|издательство=$publisher 
|isbn=$isbnf
|ref= 
}}" 
# for en.wikipedia.org as a default 
else 
template="{{Cite book 
|title=$title 
|author=$author 
|date=$date 
|publisher=$publisher 
|isbn=$isbnf
|ref= 
}}" 
fi 

echo "$template"
