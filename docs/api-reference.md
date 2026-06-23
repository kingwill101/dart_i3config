# V2 API Reference

Complete API reference for i3conf V2.

## Core Classes

### Config
Root configuration container.

```dart
class Config extends ConfigElement {
  final List<ConfigElement> statements;
  
  Config(this.statements, [super.span]);
  
  // Parse configuration from string
  static Config parse(String content);
  
  // Convert to JSON
  Map<String, dynamic> toJson();
  
  // Create from JSON
  factory Config.fromJson(Map<String, dynamic> json);
}
```

### ConfigElement (Sealed)
Base class for all configuration elements.

```dart
sealed class ConfigElement {
  SourceSpan? span;
  
  ConfigElement([this.span]);
  
  // Set source span
  void setSpan(SourceSpan span);
  
  // Convert to JSON
  Map<String, dynamic> toJson();
  
  // Create from JSON
  static ConfigElement fromJson(Map<String, dynamic> json);
}
```

### Statement (Sealed)
Base class for all statements (extends ConfigElement).

```dart
sealed class Statement extends ConfigElement {
  Statement([super.span]);
}
```

## Statement Types

### Assignment
Represents variable assignments with operators.

```dart
class Assignment extends Statement {
  final String variable;
  final AssignmentOperator operator;
  final List<Value> values;
  String? trailingComment;          // Inline comment text (without `#` prefix)
  
  Assignment(this.variable, this.operator, this.values, [super.span]);
  
  // Assignment operators
  enum AssignmentOperator {
    assign,  // =
    append,  // +=
  }
  
  // Create from symbol
  static AssignmentOperator fromSymbol(String symbol);
}
```

### Block
Represents block structures with optional identifier and nested body.

```dart
class Block extends Statement {
  final String? blockType;          // e.g. bar, mode, input
  final Value? identifier;          // Quoted, BareArg, etc.
  final List<ConfigElement> body;   // Nested statements
  Block? parentBlock;

  Block(this.blockType, this.identifier, this.body, [super.span]);

  List<Block> get childBlocks;      // Convenience view over nested blocks
}

// Utility to wire up parent references after parsing
void buildBlockHierarchy(Config config);
```

### Command
Represents commands with optional block.

```dart
class Command extends Statement {
  final String head;
  final List<Value> args;
  final List<Criterion>? criteria;
  final Block? block;               // Non-null for commands that open blocks
  String? trailingComment;          // Inline comment text (without `#` prefix)

  Command(this.head, this.args, [this.criteria, this.block, SourceSpan? span])
      : super(span);
  
  // Helper utilities live in mixins/extensions (see handlers.dart)
}
```

Command heads support dotted names like `client.focused`, `client.background`, etc.
Hex color values (e.g. `#4c7899`, `#ffffff`) are parsed as `BareArg` value types.

### Comment
Represents comments. Supports both full-line comments and inline trailing comments after commands/assignments.

```dart
class Comment extends ConfigElement {
  final String content;
  
  Comment(this.content, [super.span]);
}
```

## Value Types

### Value (Sealed)
Base class for all values with source span tracking.

```dart
sealed class Value {
  SourceSpan? span;

  Value([this.span]);

  String toConfigString();
  Map<String, dynamic> toJson();
  static Value fromJson(Map<String, dynamic> json);
}
```

### BareArg
Bare (unquoted) argument values. Hex color values (`#4c7899`, `#ffffff`) are also parsed as `BareArg`.

```dart
class BareArg extends Value {
  final String value;
  BareArg(this.value, [super.span]);
}
```

### Quoted
Quoted string values.

```dart
class Quoted extends Value {
  final String value;
  final String quoteChar;
  Quoted(this.value, this.quoteChar, [super.span]);
}
```

### VariableRef
Variable references (`$name`).

```dart
class VariableRef extends Value {
  final String name;
  VariableRef(this.name, [super.span]);
}
```

### ArrayValue
Array values (`[item, ...]`).

```dart
class ArrayValue extends Value {
  final List<Value> items;
  ArrayValue(this.items, [super.span]);
}
```

### InterpolatedString
Double-quoted strings with variable interpolation (`"hello $world"`).

```dart
class InterpolatedString extends Value {
  final List<ValueSegment> segments;
  final String quoteChar;
  InterpolatedString(this.segments, this.quoteChar, [super.span]);
}
```

### BlockReference
Dotted-path reference to a block property (`bar.main.position`).

```dart
class BlockReference extends Value {
  final List<String> path;
  BlockReference(this.path, [super.span]);
}
```

### ValueSegment (Sealed)
Base class for segments inside an `InterpolatedString`.

```dart
sealed class ValueSegment {
  const ValueSegment();
  String toConfigString();
  Map<String, dynamic> toJson();
  factory ValueSegment.fromJson(Map<String, dynamic> json);
}
```

### ValueSegmentLiteral
Plain text segment inside an interpolated string.

```dart
class ValueSegmentLiteral extends ValueSegment {
  final String text;
  const ValueSegmentLiteral(this.text);
}
```

### ValueSegmentVariableReference
Variable reference segment inside an interpolated string.

```dart
class ValueSegmentVariableReference extends ValueSegment {
  final String name;
  const ValueSegmentVariableReference(this.name);
}
```

### Criterion
Represents entries inside criteria blocks (`[class="Firefox"]`).

```dart
class Criterion {
  final String key;
  final Value value;
  SourceSpan? span;

  Criterion(this.key, this.value, [this.span]);
}
```

## Parser API

```dart
class Parser {
  Config parse(String content, {Uri? url});
  ParseResult parseWithDetails(String content, {Uri? url});
}
```

- `parse` throws `ParseError` on failure and supports line continuation preprocessing.
- `parseWithDetails` returns `ParseSuccess` / `ParseFailure`, preserving suggestions for recovery.

### VariableRef
Variable references.

```dart
class VariableRef extends Value {
  final String name;
  
  VariableRef(this.name);
}
```

## Processing Classes

### ConfigProcessor
Main processor for configuration processing.

```dart
class ConfigProcessor implements BlockHandlerRegistry {
  final Context context;
  final FileSystem fileSystem;
  
  ConfigProcessor({FileSystem? fileSystem});
  
  // Process configuration
  Future<void> process(Config config);
  
  // Convenience: parse and process in one step
  Future<void> processString(String content);
  
  // Register handlers
  void registerCommandHandler(CommandHandler handler);
  void registerBlockHandler(BlockHandler handler);
  
  // Block-scoped handler registration
  void registerBlockScopedCommandHandler(String blockType, CommandHandler handler);
  void registerBlockScopedBlockHandler(String parentBlockType, BlockHandler handler);
  
  // State management
  void pushState(ProcessorState state);
  void popState();
  ProcessorState get currentState;
  
  // Context management
  Context get context;
  void pushContext();
  void popContext();
  
  // Error handling
  void setErrorHandler(ErrorHandler handler);
}
```

The `fileSystem` parameter controls how included files are read. Defaults to
`PhysicalFileSystem` (real I/O). Pass a `VirtualFileSystem` for testing.

### Context
Context for variable and option management.

```dart
class Context {
  final Map<String, dynamic> variables;
  final Map<String, String> options;
  final Context? parent;
  ErrorHandler? errorHandler;
  
  Context({this.parent});
  
  // Variable operations
  void setVariable(String name, dynamic value);
  dynamic getVariable(String name);
  bool hasVariable(String name);
  
  // Variable expansion
  String expandVariables(String text);
  
  // Block registry
  final Map<String, Map<String?, Map<String, dynamic>>> blockRegistry;
  void registerBlock(String blockType, String? identifier, Map<String, dynamic> properties);
  String resolveBlockReference(BlockReference ref);
  
  // Error reporting
  void reportError(String message, {SourceSpan? span});
  bool reportUnresolvedVariables;
  bool reportUnresolvedBlockReferences;
  
  // Context management
  Context createChild();
  void mergeChild(Context child);
}
```

## Handler Interfaces

### ErrorHandler
Interface for processing error handlers.

```dart
abstract class ErrorHandler {
  void handleError(String message, Context context, {SourceSpan? span});
}
```

The `span` parameter provides source location information when available.

### CommandHandler
Interface for command handlers.

```dart
abstract class CommandHandler {
  String get commandName;
  FutureOr<dynamic> handle(Command command, Context context);
}
```

### BlockHandler
Interface for block handlers.

```dart
abstract class BlockHandler {
  String get blockType;
  FutureOr<void> handle(Block block, Context context);
  
  // Scoped command registration
  void registerScopedCommands(BlockHandlerRegistry registry);
  
  // Child processing
  FutureOr<void>? processChildren(Block block, Context context);
  
  // Post-processing hook
  FutureOr<void> afterChildrenProcessed(Block block, Context context);
}
```

### BlockHandlerRegistry
Interface for registering scoped commands.

```dart
abstract class BlockHandlerRegistry {
  void registerCommand(String commandName, CommandHandler handler);
}
```

## Base Handler Classes

### `BaseCommandHandler<T>`
Base class for command handlers with built-in functionality.

```dart
abstract class BaseCommandHandler<T> implements CommandHandler {
  @override
  String get commandName;
  
  @override
  FutureOr<T?> handle(Command command, Context context);
  
  // Built-in value expansion
  String expandValue(Value value, Context context);
  
  // Type-safe argument extraction
  String getArgAsString(int index, Context context);
  int getArgAsInt(int index, Context context);
  double getArgAsDouble(int index, Context context);
  bool getArgAsBool(int index, Context context);
}
```

### BaseBlockHandler
Base class for block handlers with built-in functionality.

```dart
abstract class BaseBlockHandler implements BlockHandler {
  @override
  String get blockType;
  
  @override
  FutureOr<void> handle(Block block, Context context);
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry);
  
  @override
  FutureOr<void>? processChildren(Block block, Context context);
  
  @override
  FutureOr<void> afterChildrenProcessed(Block block, Context context);
  
  // Built-in value expansion
  String expandValue(Value value, Context context);
  
  // Helper methods
  String? getBlockIdentifier(Block block, Context context);
  List<Command> findCommands(Block block, String commandName);
  Command? findFirstCommand(Block block, String commandName);
}
```

## FileSystem Abstraction

Pluggable filesystem for reading included config files. Enables testing without
real I/O by swapping implementations.

### FileSystem

```dart
abstract class FileSystem {
  /// Read the content of [path].
  /// Returns `null` if the file does not exist.
  Future<String?> readFile(String path);
}
```

### PhysicalFileSystem

Default implementation backed by `dart:io`. Reads files from the real filesystem.

```dart
class PhysicalFileSystem implements FileSystem {
  const PhysicalFileSystem();
  
  @override
  Future<String?> readFile(String path);
}
```

### VirtualFileSystem

In-memory implementation for testing. Exported from `package:i3config/i3config.dart`.

```dart
class VirtualFileSystem implements FileSystem {
  VirtualFileSystem();
  
  void createFile(String path, String content);
  String? read(String path);
  bool exists(String path);
  void clear();
  
  @override
  Future<String?> readFile(String path);
}
```

Usage in tests:
```dart
import 'package:i3config/i3config.dart';

final vfs = VirtualFileSystem();
vfs.createFile('modules/bar.conf', 'position top');

final processor = ConfigProcessor(fileSystem: vfs);
await processor.processString('include "modules/bar.conf"');
```

## Built-in Handlers

### SetCommandHandler
Built-in handler for `set` commands.

```dart
class SetCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'set';
  
  @override
  String? handle(Command command, Context context);
}
```

### IncludeHandler
Built-in handler for the `include` command. Registered automatically by
`ConfigProcessor`.

```dart
class IncludeHandler extends BaseCommandHandler<void> {
  final FileSystem fileSystem;
  
  IncludeHandler({this.fileSystem = const PhysicalFileSystem()});
  
  @override
  String get commandName => 'include';
  
  @override
  Future<void> handle(Command command, Context context);
}
```

## State Machine

### ProcessorState
Base class for processing states.

```dart
abstract class ProcessorState {
  String get stateName;
  Future<void> process(ConfigElement element, ConfigProcessor processor);
}
```

### InitialState
Initial processing state that routes elements.

```dart
class InitialState extends ProcessorState {
  @override
  String get stateName => 'Initial';
  
  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor);
}
```

### CommandProcessingState
Processes command elements.

```dart
class CommandProcessingState extends ProcessorState {
  @override
  String get stateName => 'CommandProcessing';
  
  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor);
}
```

### BlockProcessingState
Processes block elements.

```dart
class BlockProcessingState extends ProcessorState {
  @override
  String get stateName => 'BlockProcessing';
  
  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor);
}
```

### AssignmentProcessingState
Processes assignment elements.

```dart
class AssignmentProcessingState extends ProcessorState {
  @override
  String get stateName => 'AssignmentProcessing';
  
  @override
  Future<void> process(ConfigElement element, ConfigProcessor processor);
}
```

## Usage Examples

### Basic Processing
```dart
final config = Config.parse(configContent);
final processor = ConfigProcessor();
await processor.process(config);
```

### Custom Command Handler
```dart
class MyCommandHandler extends BaseCommandHandler<String> {
  @override
  String get commandName => 'my_command';
  
  @override
  String? handle(Command command, Context context) {
    final value = command.getArgAsString(0, context);
    return value;
  }
}
```

### Custom Block Handler
```dart
class MyBlockHandler extends BaseBlockHandler {
  @override
  String get blockType => 'my_block';
  
  @override
  void handle(Block block, Context context) {
    // Block processing logic
  }
  
  @override
  void registerScopedCommands(BlockHandlerRegistry registry) {
    registry.registerCommand('scoped_cmd', MyScopedHandler());
  }
}
```

### Simple AST Iteration
```dart
final config = Config.parse(configContent);
for (final element in config.statements) {
  if (element is Command) {
    print('Command: ${element.head}');
  } else if (element is Assignment) {
    print('Assignment: ${element.variable}');
  }
}
```
