import 'dart:convert';
import 'package:http/http.dart' as http;

// https://zenquotes.io/api/today
// the function gets data from the above URL
// the daily quote displayed on the home page
Future<String> fetchZenQuote() async {
  try {
    final request = await http.get(Uri.parse("https://zenquotes.io/api/today"));

    if (request.statusCode == 200) {
      // decode the JSON data
      var quoteData = jsonDecode(request.body);

      // get the quote
      String quote = quoteData[0]["q"];

      // get the author of the quote
      String author = quoteData[0]["a"];
      // return quote + author
      return '"$quote" - $author';
    } else {
      return "“Time is what we want most, but what we use worst.” - William Penn";
    }
  } catch (e) {
    // Handle the exception (no internet connection)
    return "“Time is what we want most, but what we use worst.” - William Penn";
  }
}
