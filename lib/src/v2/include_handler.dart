import 'dart:io';
import 'package:i3config/src/v2/context.dart';

class IncludeHandler extends BaseCommandHandler<void> {
  final ConfigProcessor processor;
  
  IncludeHandler(this.processor);

  @override
  String get commandName => 'include';

  @override
  void handle(Command command, Context context) async {
    final path = command.args[0];
    
    // Recursion detection
    final contextChain = _getContextChain(context);
    final contextId = '${contextChain.hashCode()}_$path';
    
    if (processor._processingIncludes?.contains(contextId) ?? false) {
      print('Warning: Recursive include detected: $path');
      return;
    }
    
    processor._processingIncludes?.add(contextId);
    
    try {
      // Resolve path relative to context if needed
      final resolvedPath = _resolvePath(path, context);
      final fileContent = await File(resolvedPath).readAsString();
      
      // Parse the included configuration
      final includedConfig = Config.parse(fileContent);
      
      // Process the included configuration using current processor
      processor.process(includedConfig);
      
    } catch (e) {
      print('Error including $path: ${e.toString()}');
    } finally {
      processor._processingIncludes?.remove(contextId);
    }
  }

  /// Helper to get the full context chain for recursion detection
  List<Object> _getContextChain(Context context) {
    final chain = <Object>[];
    Context? current = context;
    while (current != null) {
      chain.add(current.variables);
      current = current.parentContext;
    }
    return chain;
  }

  /// Resolve relative paths based on context
  String _resolvePath(String path, Context context) {
    // If path is relative, resolve it relative to current working directory or context-based path
    if (path.startsWith('~/') || !path.startsWith('/')) {
      // Could implement more sophisticated path resolution here
      return path;
    }
    return path;
  }
}

// Extension to add recursion tracking to ConfigProcessor
extension IncludeTracking on ConfigProcessor {
  late Set<String> _processingIncludes;

  void _initIncludeTracking() {
    _processingIncludes = <String>{};
  }