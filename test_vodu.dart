import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://movie.vodu.me/');
  final response = await http.get(url);
  File('vodu_full.html').writeAsStringSync(response.body);
  print('Saved to vodu_full.html');
}
