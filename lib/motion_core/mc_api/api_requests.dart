import "dart:convert";
import "package:http/http.dart" as http;

// https://zenquotes.io/api/today
// the functions gets data from the above url
// the daily quote displayed in the home page
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
    return "“Time is what we want most, but what we use worst.” - William Penn";
  }
}
