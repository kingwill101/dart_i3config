import 'package:i3config/src/i3conf_base.dart' as parser;

class I3Config {
  List<ConfigElement> elements = [];

  I3Config();

  @override
  String toString() {
    return 'I3Config(elements: $elements)';
  }

   static parse(String configContent) {
    return parser.I3ConfigParser(configContent).parse();
  }
}


abstract class ConfigElement {}

class Section extends ConfigElement {
  String name;
  Map<String, String> properties = {};
  List<ConfigElement> children = [];

  Section(this.name);

  @override
  String toString() {
    return 'Section(name: $name, properties: $properties, children: $children)';
  }

  String get module {
    if (name.split(' ').length == 2) {
      return name.split(' ')[0];
    } else {
      return name;
    }
  }

  String get moduleName {
    if (name.split(' ').length == 2) {
      return name.split(' ')[1];
    } else {
      return '';
    }
  }
}

class ArrayElement extends ConfigElement {
  String name;
  List<String> values = [];

  ArrayElement(this.name);

  @override
  String toString() {
    return 'ArrayElement(name: $name, values: $values)';
  }
}

class Property extends ConfigElement {
  String key;
  String value;

  Property(this.key, this.value);

  @override
  String toString() {
    return 'Property(key: $key, value: $value)';
  }
}

class Command extends ConfigElement {
  String command;

  Command(this.command);

  @override
  String toString() {
    return 'Command(command: $command)';
  }
}
