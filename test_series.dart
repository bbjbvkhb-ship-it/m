import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final url = 'https://movie.vodu.me/index.php?do=view&type=post&id=111411';
  print('Fetching series details from: $url');
  final response = await http.get(Uri.parse(url));
  File('vodu_series.html').writeAsStringSync(response.body);
  print('Saved to vodu_series.html');
}
