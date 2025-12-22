#!/bin/bash 
	
# Pass ISBN and optionally the subdomain of a supported language edition of Wikipedia as command line arguments or get them from URI when invoked by a webserver

shopt -s globasciiranges

if [ -t 0 ]; then
	# Running in a terminal
	isbn="$1"
	lang="$2"
else
	# Running as a script invoked by a webserver
 	echo "Content-Type: text/plain; charset=utf-8" && echo
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
isbn=${isbn//%??}
isbn=${isbn//[^0-9]}

# Sanitize other input
lang=${lang//[^a-z]}

# Use Google Books API to retrieve book information 
data=$(curl -s --max-time 10 --fail  "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn")

# Data extraction from Google Books API response 
title=$(echo $data | jq -r '.items[0].volumeInfo.title') 
author=$(echo $data | jq -r '.items[0].volumeInfo.authors | join(", ")') 
publisher=$(echo $data | jq -r '.items[0].volumeInfo.publisher') 
date=$(echo $data | jq -r '.items[0].volumeInfo.publishedDate')  

# If any data missing in Google Books get it from OpenLibrary
# info: https://www.youtube.com/watch?v=reN_okp2Gq4&t=504s Mek@archive.org
#       https://openlibrary.org/dev/docs/api/books
if [[ $title == "null" || $author == "null" || $publisher == "null" || $date == "null" ]]; then

	data=$(curl -sL --max-time 10 --fail "https://openlibrary.org/isbn/$isbn.json") # example: https://openlibrary.org/isbn/9780140328721.json

	if jq -e . >/dev/null 2>&1 <<<"$data"; then # only proceed with new data if the answer is JSON (OpenLibrary returns HTML for 404 when no book entry)
	
		if [[ $title == "null" ]]; then
			title=`echo $data | jq -r '.title'`
		fi

		if [[ $author == "null" ]]; then
			author=`curl -s --max-time 10 --fail  "https://openlibrary.org$(echo $data | jq -r '.authors[]'.key).json" | jq -r '.name'`
		fi

		if [[ $publisher == "null" ]]; then
			publisher=`echo $data | jq -r '.publishers[]'`
		fi

		if [[ $date == "null" ]]; then
			date=$(date -d "`echo $data | jq -r '.publish_date'`" +%Y-%m-%d) # convert into the ISO format from the US format found in the OpenLibrary data
		fi
	fi
fi

year=${date:0:4}

# Format ISBN for output into number groups separated by hyphens
if [ ${#isbn} -eq 13 ]; then # ISBN-13
	isbnf=${isbn:0:3}-${isbn:3:1}-${isbn:4:3}-${isbn:7:5}-${isbn:12:1}
elif [ ${#isbn} -eq 10 ]; then # ISBN-10
	isbnf=${isbn:0:1}-${isbn:1:4}-${isbn:5:4}-${isbn:9:1}
else
	isbnf=$isbn
fi

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
