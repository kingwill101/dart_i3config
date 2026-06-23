import 'dart:async';

import 'package:i3config/i3config.dart';
import 'package:source_span/source_span.dart';

Future<void> main() async {
  final configContent = r'''
# Theme and layout variables
set $theme dark
set $font_size 12
set $bar_height 28
set $gaps 8

# Top bar with interpolated values
bar "main" {
  status_command "i3status -c $theme"
  position top
  height $bar_height
  font pango:Noto Sans $font_size
}

# Workspace names using interpolation
set $ws1 "1: dev"
set $ws2 "2: design"
set $ws3 "3: docs"

# Array with mixed interpolation and block references
set $workspaces ["$ws1", "$ws2", "$ws3", bar.main.position]

# Nested block referencing parent block
bar "secondary" {
  status_command "i3status"
  position bottom
  height $bar_height

  colors {
    background #2d2d2d
    statusline "$theme"
  }
}

# Assign block property to variable using block reference
set $bar_pos bar.main.position
set $bar_cmd bar.main.status_command
set $bar_status bar.main.status_command

# Interpolation inside double-quoted strings with multiple vars
set $separator "$gaps px"
set $launcher "rofi -show drun -font 'Noto Sans $font_size'"

# Block reference without identifier (first match wins)
set $first_cmd bar.status_command

# Unresolved references resolve to empty string (no crash)
set $missing nonexistent.foo
set $unknown_var $does_not_exist

# Block reference to nested property
set $color_status bar.secondary.status_command
''';

  final parsed = Config.parse(configContent);
  final processor = ConfigProcessor();

  processor.registerCommandHandler(SetCommandHandler());
  processor.registerBlockHandler(BarBlockHandler());
  processor.registerBlockHandler(ColorsBlockHandler());

  processor.setErrorHandler(VerboseErrorHandler());
  processor.context.reportUnresolvedVariables = true;
  processor.context.reportUnresolvedBlockReferences = true;

  print('=== Parsed ${parsed.statements.length} statements ===\n');

  await processor.process(parsed);

  print('\n=== Variables after processing ===');
  final vars = processor.context.variables;
  final sortedKeys = vars.keys.toList()..sort();
  for (final key in sortedKeys) {
    final value = vars[key];
    final display = value is List
        ? '[${value.map((e) => '"$e"').join(', ')}]'
        : value;
    print('  \$$key = $display');
  }

  print('\n=== Block Registry ===');
  processor.context.blockRegistry.forEach((type, entries) {
    entries.forEach((id, props) {
      print('  $type${id ?? ""}: $props');
    });
  });

  print('\n=== Error Log ===');
  final errorHandler = processor.context.errorHandler as VerboseErrorHandler?;
  if (errorHandler != null && errorHandler.errors.isNotEmpty) {
    for (final err in errorHandler.errors) {
      print('  $err');
    }
  } else {
    print('  (no errors)');
  }
}

class BarBlockHandler implements BlockHandler {
  @override
  String get blockType => 'bar';

  @override
  void handle(Block block, Context context) {
    final props = <String, dynamic>{};
    for (final element in block.body) {
      if (element is Command) {
        final head = element.head;
        if (head == 'height' ||
            head == 'position' ||
            head == 'status_command' ||
            head == 'font') {
          final expanded = _expandFirstArg(element, context);
          props[head] = expanded;
        }
      }
    }
    final identifier = block.identifier?.toConfigString();
    context.registerBlock(blockType, identifier, props);
  }

  @override
  FutureOr<void>? processChildren(Block block, Context context) => null;

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}
}

class ColorsBlockHandler implements BlockHandler {
  @override
  String get blockType => 'colors';

  @override
  void handle(Block block, Context context) {
    final props = <String, dynamic>{};
    for (final element in block.body) {
      if (element is Command) {
        final head = element.head;
        if (element.args.isNotEmpty) {
          props[head] = _expandFirstArg(element, context);
        }
      }
    }
    context.registerBlock(blockType, null, props);
  }

  @override
  FutureOr<void>? processChildren(Block block, Context context) => null;

  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {}
}

String _expandFirstArg(Command command, Context context) {
  final value = command.args.first;
  return switch (value) {
    Quoted q => context.expandVariables(q.value),
    TripleQuoted t => t.value,
    VariableRef vr => context.getVariable(vr.name) ?? '\$${vr.name}',
    BareArg b => context.expandVariables(b.value),
    ArrayValue a =>
      a.items.map((v) => _expandFirstArg(Command('', [v]), context)).join(' '),
    InterpolatedString i => _expandInterpolatedString(i, context),
    BlockReference b => context.resolveBlockReference(b),
  };
}

String _expandInterpolatedString(InterpolatedString str, Context context) {
  final buffer = StringBuffer();
  for (final seg in str.segments) {
    if (seg is ValueSegmentLiteral) {
      buffer.write(seg.text);
    } else if (seg is ValueSegmentVariableReference) {
      final resolved = context.getVariable(seg.name);
      if (resolved is List) {
        buffer.writeAll(resolved, ' ');
      } else if (resolved != null) {
        buffer.write(resolved);
      } else {
        buffer.write('\$${seg.name}');
      }
    }
  }
  return buffer.toString();
}

class VerboseErrorHandler implements ErrorHandler {
  final List<String> errors = [];

  @override
  void handleError(String message, Context context, {SourceSpan? span}) {
    String display;
    if (span != null) {
      display = 'Line ${span.start.line}: col ${span.start.column} - $message';
    } else {
      display = message;
    }
    errors.add(display);
    print('ERROR: $display');
  }
}
