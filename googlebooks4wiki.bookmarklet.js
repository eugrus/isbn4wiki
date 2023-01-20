javascript:(function() {
var isbn = prompt("Enter the ISBN of the book");
var lang = prompt("Optionally enter the Wikipedia subdomain (for supported non-English Wikipedias)");

if (!isbn) {
	alert("No ISBN provided.");
	return;
}

fetch("https://www.googleapis.com/books/v1/volumes?q=isbn:" + isbn)
.then(response => response.json())
.then(data => {
var title = data.items[0].volumeInfo.title;
var author = data.items[0].volumeInfo.authors.join(", ");
var publisher = data.items[0].volumeInfo.publisher;
var date = data.items[0].volumeInfo.publishedDate;
var year = date.substring(0, 4);

var template = "";

if (lang === "ru") {
	template = "{{" + "Книга" + "\n" +
		"  |название=" + title + "\n" +
		"  |автор=" + author + "\n" +
		"  |год=" + year + "\n" +
		"  |издательство=" + publisher + "\n" +
		"  |isbn=" + isbn + "\n" +
		"  |ref=" + "\n" +
		"}}";
}

else {
	template = "{{" + "Cite book" + "\n" +
		"  |title=" + title + "\n" +
		"  |author=" + author + "\n" +
		"  |date=" + date + "\n" +
		"  |publisher=" + publisher + "\n" +
		"  |isbn=" + isbn + "\n" +
		"  |ref=" + "\n" +
		"}}";
}
navigator.clipboard.writeText(template);
});
})();
