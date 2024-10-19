import 'package:i3config/src/models.dart';
export 'package:i3config/src/models.dart';

class I3ConfigParser {
  final String configContent;

  I3ConfigParser(this.configContent);

  /// Parses the configuration content and returns an [I3Config] object.
  ///
  /// This method processes the configuration content line by line, identifying
  /// different types of configuration elements (sections, properties, arrays,
  /// and commands) and building the corresponding [I3Config] structure.
  ///
  /// The parsing logic is as follows:
  /// - If the line is empty or starts with a '#', it is ignored.
  /// - If the line starts with a section name, a new [Section] is created and
  ///   added to the configuration.
  /// - If the line is '}', the current section is closed and removed from the
  ///   section stack.
  /// - If the line matches an array addition, a new [ArrayElement] is created
  ///   and the value is added to its list of values.
  /// - If the line matches a property, a new [Property] is created and added to
  ///   the current section.
  /// - If the line does not match any of the above patterns, it is treated as a
  ///   command and a new [Command] is created and added to the current section
  ///   or the configuration.
  ///
  /// The parsed [I3Config] object is returned at the end of the method.
  I3Config parse() {
    final config = I3Config();
    final lines = configContent.split('\n');
    final sectionStack = <Section>[];

    for (var line in lines) {
      line = line.trim();

      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      // Check for section start
      final sectionStartMatch =
          RegExp(r'(\w+)\s*(\S+)?\s*(?<!\\)\{(?![^"]*"\s*$)').firstMatch(line);
      if (sectionStartMatch != null) {
        final sectionName = sectionStartMatch.group(1)!;
        final sectionKey = sectionStartMatch.group(2);
        final fullSectionName =
            sectionKey != null ? '$sectionName $sectionKey' : sectionName;
        final newSection = Section(fullSectionName);

        if (sectionStack.isEmpty) {
          config.elements.add(newSection);
        } else {
          sectionStack.last.children.add(newSection);
        }

        sectionStack.add(newSection);
        continue;
      }

      // Check for section end
      if (line == '}') {
        sectionStack.removeLast();
        continue;
      }

      // Check for array addition
      final arrayMatch = RegExp(r'(\w+)\s*\+=\s*"?(.*?)"?$').firstMatch(line);
      if (arrayMatch != null) {
        final arrayName = arrayMatch.group(1)!;
        final arrayValue = arrayMatch.group(2)!;
        final arrayElement = config.elements.lastWhere(
          (element) => element is ArrayElement && element.name == arrayName,
          orElse: () {
            final newArrayElement = ArrayElement(arrayName);
            if (sectionStack.isEmpty) {
              config.elements.add(newArrayElement);
            } else {
              sectionStack.last.children.add(newArrayElement);
            }
            return newArrayElement;
          },
        ) as ArrayElement;
        arrayElement.values.add(arrayValue);
        continue;
      }

      // Check for property
      final propertyMatch = RegExp(r'(\w+)\s*=\s*"?(.*?)"?$').firstMatch(line);
      if (propertyMatch != null) {
        final key = propertyMatch.group(1)!;
        final value = propertyMatch.group(2)!.replaceAll(r'\', r'');

        final property = Property(key, value);

        if (sectionStack.isEmpty) {
          config.elements.add(property);
        } else {
          sectionStack.last.properties[key] = value;
          sectionStack.last.children.add(property);
        }
        continue;
      }

      // Treat any other line inside a section as a property
      if (sectionStack.isNotEmpty) {
        final propertyParts = line.split(RegExp(r'\s+'));

        if (propertyParts.length == 2) {
          final key = propertyParts[0];
          final value = propertyParts[1];
          final property = Property(key, value);
          sectionStack.last.properties[key] = value;
          sectionStack.last.children.add(property);
          continue;
        } else if (propertyParts.length > 2) {
          final key = propertyParts[0];
          final value = propertyParts.sublist(1).join(' ');
          final property = Property(key, value);
          sectionStack.last.properties[key] = value;
          sectionStack.last.children.add(property);
          continue;
        }
      }

      // Treat any other line as a command
      final command = Command(line);
      if (sectionStack.isEmpty) {
        config.elements.add(command);
      } else {
        sectionStack.last.children.add(command);
      }
    }

    return config;
  }
}
