import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  final url = 'https://movie.vodu.me/index.php?do=view&type=post&id=111411';
  final response = await http.get(Uri.parse(url));
  final document = parser.parse(response.body);
  
  final imgEl = document.querySelector('.col-md-4 img');
  if (imgEl != null) {
    print('Details Page Poster Src: "${imgEl.attributes['src']}"');
  } else {
    print('No poster image found in .col-md-4 img!');
  }

  // Also print other image URLs on the page
  final imgs = document.querySelectorAll('img');
  for (var img in imgs) {
    print('IMG: src="${img.attributes['src']}", class="${img.className}"');
  }
}
