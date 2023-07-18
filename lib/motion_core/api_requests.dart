import "dart:convert";

import "package:http/http.dart" as http;

// https://zenquotes.io/api/today
// the functions gets data from the above url
Future<String> fetchZenQuote() async {
  final request = await http.get(Uri.parse("https://zenquotes.io/api/today"));

  if (request.statusCode == 200) {
    // decode the json data
    var quoteData = jsonDecode(request.body);

    // get the quote
    String quote = quoteData[0]["q"];

    // get auther of quote
    String author = quoteData[0]["a"];
    // return quote + author
    return '"$quote" - $author';
  } else {
    throw Exception("Failed to get today's quote :(");
  }
}
