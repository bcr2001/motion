import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../motion_reusable/general_reuseable.dart';

// Function to make an HTTP request to the ZenQuotes API.
// Returns the HTTP response containing the Zen quote data.
Future<http.Response> _getZenQuote() async {
  const String zenQuotesApiUrl = "https://zenquotes.io/api/today";
  return http
      .get(Uri.parse(zenQuotesApiUrl))
      .timeout(const Duration(seconds: 10));
}

// Function to fetch a Zen quote from the remote API.
// Returns the daily quote in the format: "Quote" - Author
Future<String?> fetchZenQuote() async {
  try {
    // Send an HTTP GET request to the ZenQuotes API.
    final request = await _getZenQuote();

    // Check if the HTTP response status code is 200 (OK).
    if (request.statusCode == 200) {
      // Decode the JSON data from the response.
      var quoteData = jsonDecode(request.body);

      // Extract the quote and author from the JSON data.
      String quote = quoteData[0]["q"];
      String author = quoteData[0]["a"];

      // Return the formatted quote string.
      return '"$quote" - $author';
    } else {
      return null;
    }
  } catch (e) {
    debugLog("Unable to fetch Zen quote: $e");
    return null;
  }
}
