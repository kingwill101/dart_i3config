import './parser.dart';
import 'ast.dart' show Config, ConfigElement;

class I3Config {
  List<ConfigElement> elements = [];
  I3Config();

  @override
  String toString() {
    return 'I3Config(elements: $elements)';
  }

  static Config parse(String configContent) {
    return Parser().parse(configContent);
  }
}
