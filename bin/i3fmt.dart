import 'dart:io';

import 'package:artisanal/args.dart' as artisanal;
import 'package:i3config/i3config.dart';

class FormatCommand extends artisanal.Command<void> {
  FormatCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Write output to FILE instead of stdout.',
        valueHelp: 'FILE',
      )
      ..addOption(
        'indent',
        abbr: 'i',
        help: 'Number of spaces per indentation level.',
        valueHelp: 'N',
        defaultsTo: '2',
      )
      ..addFlag(
        'sort',
        help: 'Sort assignment statements alphabetically.',
        negatable: false,
      );
  }

  @override
  String get name => 'format';

  @override
  String get description => 'Format an i3 config file.';

  @override
  void run() {
    final args = argResults!;
    final indent = int.tryParse(args['indent'] as String) ?? 2;
    final sort = args['sort'] as bool;
    final outputPath = args['output'] as String?;
    final positionalArgs = args.rest;

    String input;
    String sourceName;

    if (positionalArgs.length > 1) {
      throw artisanal.UsageException(
        'Too many arguments. Expected at most 1 file.',
        usage,
      );
    } else if (positionalArgs.length == 1) {
      sourceName = positionalArgs.first;
      input = File(sourceName).readAsStringSync();
    } else {
      final lines = <String>[];
      while (true) {
        final line = stdin.readLineSync();
        if (line == null) break;
        lines.add(line);
      }
      input = lines.join('\n');
      sourceName = '<stdin>';
    }

    final config = Config.parse(input, url: Uri.file(sourceName));

    final formatter = ConfigFormatter(
      options: FormatterOptions(indent: indent, sortAssignments: sort),
    );

    final output = formatter.format(config);

    if (outputPath != null) {
      File(outputPath).writeAsStringSync(output);
    } else {
      stdout.write(output);
    }
  }
}

void main(List<String> args) {
  final runner = artisanal.CommandRunner(
    'i3fmt',
    'Format i3 configuration files.',
  )..addCommand(FormatCommand());
  runner.run(args);
}
