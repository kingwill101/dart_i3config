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

  Map<String, dynamic> toJson() {
    return {
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }

  factory I3Config.fromJson(Map<String, dynamic> json) {
    final config = I3Config();
    config.elements = (json['elements'] as List)
        .map((e) => ConfigElement.fromJson(e))
        .toList();
    return config;
  }
}

abstract class ConfigElement {
  Map<String, dynamic> toJson();
  static ConfigElement fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'Section':
        return Section.fromJson(json);
      case 'ArrayElement':
        return ArrayElement.fromJson(json);
      case 'Property':
        return Property.fromJson(json);
      case 'Command':
        return Command.fromJson(json);
      case 'Comment':
        return Comment.fromJson(json);
      case 'CommentBlock':
        return CommentBlock.fromJson(json);
      default:
        throw Exception('Unknown ConfigElement type');
    }
  }
}

class Section extends ConfigElement {
  String name;
  Map<String, dynamic> properties = {};
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Section',
      'name': name,
      'properties': properties,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    final section = Section(json['name']);
    section.properties = Map<String, dynamic>.from(json['properties']);
    section.children = (json['children'] as List)
        .map((e) => ConfigElement.fromJson(e))
        .toList();
    return section;
  }
}

class ArrayElement extends ConfigElement {
  String name;
  List<dynamic> values = [];

  ArrayElement(this.name);

  @override
  String toString() {
    return 'ArrayElement(name: $name, values: $values)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'ArrayElement',
      'name': name,
      'values': values,
    };
  }

  factory ArrayElement.fromJson(Map<String, dynamic> json) {
    final arrayElement = ArrayElement(json['name']);
    arrayElement.values = List<dynamic>.from(json['values']);
    return arrayElement;
  }
}

class Property extends ConfigElement {
  String key;
  dynamic value;

  Property(this.key, this.value);

  @override
  String toString() {
    return 'Property(key: $key, value: $value)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Property',
      'key': key,
      'value': value,
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(json['key'], json['value']);
  }
}

class Comment extends ConfigElement {
  String content;

  Comment(this.content);

  @override
  String toString() {
    return 'Comment(content: $content)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Comment',
      'content': content,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(json['content']);
  }
}

class CommentBlock extends ConfigElement {
  List<String> comments = [];

  CommentBlock([String? initialComment]) {
    if (initialComment != null) {
      comments.add(initialComment);
    }
  }

  void addComment(String comment) {
    comments.add(comment);
  }

  @override
  String toString() {
    return 'CommentBlock(comments: $comments)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'CommentBlock',
      'comments': comments,
    };
  }

  factory CommentBlock.fromJson(Map<String, dynamic> json) {
    final block = CommentBlock();
    block.comments = List<String>.from(json['comments']);
    return block;
  }
}

class Command extends ConfigElement {
  String command;

  Command(this.command);

  @override
  String toString() {
    return 'Command(command: $command)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Command',
      'command': command,
    };
  }

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(json['command']);
  }
}
