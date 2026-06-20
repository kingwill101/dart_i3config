import 'dart:io' show Platform;

import 'package:i3config/src/v2/base_handlers.dart' show BaseCommandHandler;
import 'package:i3config/src/v2/context.dart' show Context;
import 'package:i3config/src/v2/ast.dart' show Command, Config;
import 'package:i3config/src/v2/processor.dart' show ConfigProcessor;
import 'package:i3config/src/v2/value.dart' show Value;
import 'filesystem.dart' show FileSystem, PhysicalFileSystem;

/// Exception thrown when a composed (included) configuration fails to process.
class ConfigCompositionException implements Exception {
  final String message;
  final String path;
  ConfigCompositionException(this.message, this.path);

  @override
  String toString() => 'ConfigCompositionException: $message (path: $path)';
}

/// Built-in handler for the `include` command.
///
/// The `include` command allows importing external configuration files
/// into the current i3/Sway configuration. This enables modular configuration
/// management by splitting configs into separate files.
///
/// ## Usage
///
/// ```i3
/// # Include a config file by absolute or relative path
/// include "~/.config/i3/modules/bar.conf"
/// include "modules/colors.conf"
///
/// # Include with variable expansion
/// set $config_dir ~/.config/i3
/// include "$config_dir/local.conf"
/// ```
///
/// ## Features
///
/// * **Pluggable filesystem** – Uses the [FileSystem] interface so files can
///   be read from the real filesystem or an in-memory store (e.g. for tests).
/// * **Variable expansion** – Paths may contain `$variable` or `${variable}`
///   references, which are expanded using the current context.
/// * **Path resolution** – `~` is expanded to the user's home directory.
/// * **Circular include detection** – Recursive includes are detected and
///   rejected with an error message.
/// * **Nested includes** – Included files may themselves contain `include`
///   directives.
///
/// ## Processing
///
/// When an `include` directive is encountered, the handler:
/// 1. Resolves the path (expanding variables and `~`).
/// 2. Reads the file content via the configured [FileSystem].
/// 3. Parses the content as an i3 configuration.
/// 4. Processes the parsed content using the current [ConfigProcessor],
///    merging variables, blocks, and commands into the current context.
class IncludeHandler extends BaseCommandHandler<void> {
  final FileSystem fileSystem;

  /// Creates an [IncludeHandler] backed by [fileSystem].
  /// Defaults to [PhysicalFileSystem] for real I/O.
  IncludeHandler({this.fileSystem = const PhysicalFileSystem()});

  @override
  String get commandName => 'include';

  /// Tracks paths currently being processed to detect circular includes.
  final Set<String> _processingPaths = {};

  @override
  Future<void> handle(Command command, Context context) async {
    if (command.args.length != 1) {
      print('Error: include command requires exactly one argument (the path)');
      return;
    }

    final path = _expandPath(command.args[0], context);

    final processor = context.options['_processor'] as ConfigProcessor?;
    if (processor == null) {
      print('Cannot include file without active processor');
      return;
    }

    if (_processingPaths.contains(path)) {
      print('Warning: circular include detected for "$path"');
      return;
    }

    try {
      // Read content from the configured filesystem
      final fileContent = await fileSystem.readFile(path);

      if (fileContent == null) {
        print('Warning: included file not found: "$path"');
        return;
      }

      // Parse and process the included config
      final includedConfig = Config.parse(fileContent);
      _processingPaths.add(path);
      try {
        await processor.process(includedConfig);
      } finally {
        _processingPaths.remove(path);
      }
    } catch (e) {
      context.errorHandler?.handleError(
        ConfigCompositionException('Failed to process included file: $e', path),
        context,
      );
    }
  }

  /// Expands [value] to a string path, resolving variables and `~`.
  String _expandPath(Value value, Context context) {
    // First expand the Value (handles Quoted/VariableRef/BareArg etc.)
    final raw = expandValue(value, context);
    String result = raw;

    // Expand $var and ${var} references using context variables
    final allVariables = <String, String>{};
    Context? current = context;
    while (current != null) {
      current.variables.forEach((name, val) {
        if (val is String) {
          allVariables[name] = val;
        } else if (val is List) {
          allVariables[name] = val.join(' ');
        } else {
          allVariables[name] = val.toString();
        }
      });
      current = current.parentContext;
    }

    allVariables.forEach((name, value) {
      result = result.replaceAll('\$$name', value);
      result = result.replaceAll('\${$name}', value);
    });

    // Expand ~ to home directory
    if (result.startsWith('~')) {
      final home = Platform.environment['HOME'] ?? '/home/user';
      result = result.replaceFirst('~', home);
    }

    return result;
  }
}
