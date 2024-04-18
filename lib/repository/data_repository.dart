import 'package:http/http.dart' as http;

class DataRepository {
  final String baseUrl = 'https://io.adafruit.com/api/v2';

  // fetch the latest 5 data points from the server
  Future<String> fetchData(String username, String feedName) async {
    try {
      final response = await http.get(Uri.https(
        'io.adafruit.com',
        '/api/v2/$username/feeds/$feedName/data',
        {'limit': '5',
          'include': 'value,created_at',
        }, // query parameters
      )); // https://io.adafruit.com/api/v2/phucnguyenng/feeds/sensor1/data
      // add query parameters to the URL

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }
}
