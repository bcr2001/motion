import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../motion_themes/mth_app/app_strings.dart';

// Function to fetch a Zen quote from a remote API.
// Returns the daily quote in the format: "Quote" - Author
Future<String> fetchZenQuote() async {
  try {
    // Send an HTTP GET request to the ZenQuotes API.
    final request = await http.get(Uri.parse("https://zenquotes.io/api/today"));

    // Check if the HTTP response status code is 200 (OK).
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
      // If the response status code is not 200, return a default quote
      return AppString.defaultAppQuote;
    }
  } catch (e) {
    // Handle exceptions, such as no internet connection, and return a default quote.
    return AppString.defaultAppQuote;
  }
}
