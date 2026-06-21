import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  final r = await http.get(Uri.parse('https://movie.vodu.me/index.php?do=view&type=post&id=8047'));
  final doc = parser.parse(r.body);
  final eps = doc.querySelectorAll('.episodeitem');
  for (var ep in eps.take(3)) {
    print(ep.outerHtml);
    print('---------');
  }
}
