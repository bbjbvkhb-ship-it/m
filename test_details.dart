import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final url = 'https://movie.vodu.me/index.php?do=view&type=post&id=117689';
  print('Fetching Details URL: $url');
  final response = await http.get(Uri.parse(url));
  print('Status: ${response.statusCode}');
  
  File('vodu_details.html').writeAsStringSync(response.body);
  print('Saved to vodu_details.html');
}
