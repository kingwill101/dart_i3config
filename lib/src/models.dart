class I3Config {
  List<ConfigElement> elements = [];

  I3Config();
  factory I3Config.parse(String configContent) {
    return I3Config.parse(configContent);
  }

  @override
  String toString() {
    return 'I3Config(elements: $elements)';
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