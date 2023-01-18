[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8 # Unicode output doesn't seem to work though

# Pass ISBN and optinally the subdomain of a supported language edition of Wikipedia as command line arguments
$isbn = $args[0]
$lang = $args[1]

# Use Google Books API to retrieve book information
$data = Invoke-WebRequest -Uri "https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn" -Method Get

# Data extraction from API response
$json = $data.Content | ConvertFrom-Json
$title = $json.items[0].volumeInfo.title
$authors = $json.items[0].volumeInfo.authors -join ", "
$publisher = $json.items[0].volumeInfo.publisher
$date = $json.items[0].volumeInfo.publishedDate
$year = $date.Substring(0,4)

# Template generation

# for ru.wikipedia.org as an option
if ($lang -eq "ru") {
  $template = "{{Книга
  |название=$title
  |автор=$authors
  |год=$year
  |издательство=$publisher
  |isbn=$isbn
  |ref=
  }}"
} 
# for en.wikipedia.org as a default
else {
  $template = "{{Cite book
  |title=$title
  |author=$authors
  |date=$date
  |publisher=$publisher
  |isbn=$isbn
  |ref=
  }}"
}

Write-Output $template
