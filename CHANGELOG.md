## 2.5.0

### Features
- **Triple-quoted strings** — Multi-line literal strings delimited by `"""..."""` and `'''...'''`. Content is taken literally — no escape processing or variable interpolation. Preprocessing correctly preserves triple-quoted regions during line-continuation joining and blank-line removal (`lib/src/value.dart`, `lib/src/grammar.dart`)
- **`TripleQuoted` AST node** — New `Value` subtype with `value`, `delimiter` fields, `toConfigString()` with auto-switching delimiter (falls back to single-quoted when content contains both `"""` and `'''`), and JSON serialization (`lib/src/value.dart`)
- **Exhaustiveness** — `TripleQuoted` cases added to all `expandValue` switch statements in `BaseCommandHandler`, `BaseBlockHandler`, `CommandValueExtraction`, `ValueExpander`, and both processor states

### Documentation
- New `doc/language-guide.md` section: "Triple-Quoted Strings" covering syntax, literal semantics, and automatic delimiter switching
- Updated `README.md` with triple-quoted strings in Key Features, Language Features, and Examples list
- New `example/triple_quoted_example.dart` demonstrating multi-line exec commands, variable assignment, array use, and formatter idempotency

## 2.4.1

- Renamed `docs/` to `doc/` per Pub layout convention
- Updated README doc paths

## 2.4.0

### Features
- **String interpolation** — Double-quoted strings support `$variable` references, producing `InterpolatedString` AST nodes with `ValueSegmentLiteral` and `ValueSegmentVariableReference` segments. Single-quoted strings remain literal (`lib/src/grammar.dart`, `lib/src/value.dart`)
- **Block references** — Dotted-path references like `bar.main.position` resolve properties from processed blocks at runtime (`lib/src/context.dart`, `lib/src/grammar.dart`)
- **Block references in arrays** — Arrays can contain interpolated strings and block references alongside bare args and quoted strings
- **Dotted command heads** — `commandHead()` uses `dottedIdent()` so commands like `client.focused`, `client.unfocused` parse as a single head instead of splitting at the dot (`lib/src/grammar.dart`)
- **Hex color values** — New `hexColor()` parser recognizes `#` followed by hex digits as `BareArg`, preventing hex colors from being consumed as trailing comments (`lib/src/grammar.dart`)
- **Error reporting for unresolved references** — `Context.reportUnresolvedVariables` and `Context.reportUnresolvedBlockReferences` flags trigger `ErrorHandler.handleError` with `SourceSpan` positioning when variables or block properties cannot be resolved (`lib/src/context.dart`, `lib/src/handlers.dart`)
- **`Context.reportError()`** — New public API for reporting errors with optional source span from anywhere in the processing pipeline
- **Examples** — New `example/interpolation_and_block_ref_example.dart` and `example/dotted_heads_colors_example.dart` demonstrating all new features

### Breaking Changes
- **V1 removal** — The legacy V1 parser (`lib/src/v1/`, `i3config_v1.dart`) has been removed. Use the default `import 'package:i3config/i3config.dart'` instead.
- `ErrorHandler.handleError` signature: `dynamic error` → `String message` with named `SourceSpan? span` parameter
- `bareChar()` and `_arrayBareChar()` expanded to include `:` for font specs like `pango:Noto Sans`
- `include_handler.dart` error reporting passes string message instead of `ConfigCompositionException`

### Documentation
- Updated `docs/language-guide.md` with interpolation, block references, dotted command heads, hex colors, and inline comments
- Updated `docs/README.md` with new features and usage examples
- Updated `docs/api-reference.md` with `InterpolatedString`, `BlockReference`, `ValueSegment*` types, updated `ErrorHandler`, `Context`, `Command`, `Assignment` docs
- Updated root `README.md` feature list and error handling section

## 2.3.1

### Features
- **Contextual error messages** — Parse errors now produce specific messages instead of "end of input expected": `missing closing bracket/brace/quote`, `unexpected closing bracket/brace`, `expected a command after ';'`, and `unexpected character 'X'` (`lib/src/grammar.dart`)
- **`_orError()` helper** — PetitParser 7 compatible custom error messages via `failure()` + `toChoiceParser()`, applied to closing tokens in criteria, blocks, arrays, strings, and assignment operators

### Fixes
- Removed unused `petitparser` import from `parser.dart`

## 2.3.0

### Features
- **Inline comments** — Comments on the same line as a command or assignment (`bindsym $mod+Return exec terminal # launch`) are now parsed and stored as `trailingComment` on `Command` and `Assignment` nodes
- **Inline comment formatting** — `ConfigFormatter` preserves and outputs trailing inline comments (two spaces before `#`)
- **SourceSpan error reporting** — Parse errors now map through blank-line removal and continuation preprocessing, reporting the correct `line`/`column` in the original content via `ParseError`
- **Grammar.parse() offset mapping** — New `_mapProcessedToOriginal()`, `_countRemovedBlankLines()`, and `_mapThroughContinuation()` helpers provide accurate error positions when the grammar preprocessor removes blank lines

### Fixes
- `#` characters in bare values no longer silently consume the rest of the line as arguments; inline comments are now properly parsed at the statement level
- Negative lookahead `(ws() & char('#')).not()` removed from `rhsList()` — inline comment detection is now handled uniformly in `_statementWithTrailing()`

## 2.2.0

### Features
- **ConfigFormatter** — New `formatter.dart` with `ConfigFormatter` class and `FormatterOptions` that serializes a `Config` AST back to formatted i3 config text. Supports custom indent, sorting assignments, and trailing newline control (`lib/src/formatter.dart`)
- **`toConfigString()` on Value types** — Every `Value` subtype (`BareArg`, `Quoted`, `VariableRef`, `ArrayValue`) now has a `toConfigString()` method for standalone serialization
- **`i3fmt` CLI tool** — New `bin/i3fmt.dart` using `package:artisanal/args.dart` for styled help output. Reads from file or stdin, writes to stdout or `-o`. Supports `--indent` and `--sort` flags

### Documentation
- Added comprehensive language guide (`docs/language-guide.md`) covering i3 config syntax and library usage end-to-end

### Dependencies
- Added `artisanal: ^0.3.0` dependency (used by the CLI tool)

## 2.1.1

### Fixes
- Fixed V2 parsing for nested blocks containing assignment inline comments with `:` characters, such as `require_root = true  # Default: ...`
- Added regression coverage for nested `resource`/`actions` style blocks so assignment comments do not break block parsing

## 2.1.0

### Features
- **Pluggable Filesystem** – New `FileSystem` abstract class lets the `IncludeHandler` read files from real I/O (`PhysicalFileSystem`) or an in-memory store (`VirtualFileSystem` for tests)
- **ConfigProcessor.fileSystem** – Constructor accepts an optional `FileSystem` parameter (defaults to `PhysicalFileSystem`)
- **VirtualFileSystem implements FileSystem** – The test VFS now implements the `FileSystem` interface, making it injectable into `ConfigProcessor`
- **File imports example** – New `example/file_imports_example.dart` demonstrating includes with the virtual filesystem

### Refactors
- `IncludeHandler` no longer imports `dart:io` or `test_vfs.dart` directly; it reads files through the injected `FileSystem`
- Removed unused `st` stack trace variable in `IncludeHandler`

### Documentation
- Added "Pluggable Filesystem" subsection to `docs/README.md` with injection examples
- Added `FileSystem`, `PhysicalFileSystem`, `VirtualFileSystem` and `IncludeHandler` to `docs/api-reference.md`
- Added VFS test patterns to `docs/command-handlers.md`
- Overhauled repo `README.md` with badges, cleaner structure, and filesystem coverage

## 2.0.0

### Major Features
- **Dedicated Assignment AST**: Assignment statements like `order += "value"` are now parsed as first-class `Assignment` objects instead of generic commands
- **Semantic Clarity**: Clean API with `assignment.variable`, `assignment.operator`, and `assignment.values` properties
- **Dotted Identifiers**: Full support for complex assignments like `bar.colors.focused = "#ffffff"`
- **Enhanced Grammar**: Implements proper assignment grammar: `LHS WS* AssignOp WS* RhsList`
- **Comprehensive Coverage**: Command parsing unified across blocks, chains, criteria, and escape sequences
- **Actionable Errors**: `parseWithDetails` now normalizes suggestions for common syntax issues

### Breaking Changes
- **Assignment Parsing**: Assignment statements are no longer parsed as `Command` objects with `head='assign'`
- **Migration Required**: Update code using `whereType<Command>().where((cmd) => cmd.head == 'assign')` to use `whereType<Assignment>()`

### New API
- `Assignment` class: Dedicated AST node for assignment statements
- `Assignment.variable`: Left-hand side variable name (supports dotted identifiers)
- `Assignment.operator`: Assignment operator ('=' or '+=')
- `Assignment.values`: List of right-hand side values
- Full JSON serialization support for Assignment objects
- Visitor pattern support with `visitAssignment()` method

### Tooling & Documentation
- Added `test/advanced_parser_test.dart` to cover grammar breadth, error reporting, and line continuations
- Refreshed V2 API reference, migration guide, and README with 2.0 guidance

### Migration Guide

#### Before (1.x):
```dart
final assignments = config.statements
    .whereType<Command>()
    .where((cmd) => cmd.head == 'assign');

for (final cmd in assignments) {
  final variable = (cmd.args[0] as BareArg).value;
  final operator = (cmd.args[1] as BareArg).value;
  final value = cmd.args[2];
}
```

#### After (2.0.0+):
```dart
final assignments = config.statements
    .whereType<Assignment>();

for (final assignment in assignments) {
  final variable = assignment.variable;
  final operator = assignment.operator;
  final value = assignment.values[0];
}
```

## 2.0.0 (Initial 2.0 Release)

### Breaking Changes
- Values are now automatically parsed into appropriate types (int, bool, double, string)
- Comments are now preserved and structured into CommentBlocks
- Fixed array handling in sections to properly group values under the same ArrayElement
- Changed Property value type from String to dynamic to support typed values

### Features
- Added type inference for configuration values
- Added structured comment preservation
- Improved array handling in sections
- Added JSON serialization support

### Fixes
- Fixed parsing double quoted strings in sections when not using the assign operator
- Added topics metadata to package

## 1.2.0

### Major Features
- **V2 Now Default**: Enhanced PetitParser implementation is now the default export
- **Dual Parser Architecture**: Support for both V1 (legacy) and V2 (default) parsers
- **Source Position Tracking**: V2 parser provides precise source location information for all parsed elements
- **Enhanced Type Safety**: V2 uses sealed classes for better pattern matching and exhaustiveness checking
- **Legacy V1 Support**: V1 parser available via explicit import for backward compatibility

### New API Endpoints
- `package:i3config/i3config.dart` - Default export (V2 enhanced parser)
- `package:i3config/i3config_v1.dart` - Legacy V1 parser (stable, hand-written)
- `package:i3config/i3config_v2.dart` - Explicit V2 parser (same as default)

### V2 Parser Features
- **Source Spans**: Every parsed element includes optional `SourceSpan` with line/column information
- **Enhanced Error Reporting**: Detailed error messages with suggestions and precise location info
- **Visitor Pattern**: Built-in visitor support for AST traversal and processing
- **Processing Framework**: Extensible handlers for custom configuration processing
- **Modern Architecture**: Uses PetitParser framework for robust parsing

### V1 Parser Improvements
- Fixed quote handling inconsistency in fallback property parsing
- Properties using `key "value"` format now correctly strip quotes (consistent with `key = "value"`)

### Examples and Documentation
- Added comprehensive position tracking example demonstrating V2 features
- Updated README with migration guide and version selection guidance
- Added processor examples showing advanced V2 capabilities
- Enhanced API documentation for both parser versions

### Technical Improvements
- **Restructured Architecture**: Clean separation between V1 and V2 implementations
- **Enhanced Testing**: Comprehensive test coverage for both parser versions
- **Better Error Handling**: V2 provides detailed parse errors with context and suggestions
- **Memory Efficiency**: V2 uses modern parsing techniques for better performance

### Dependencies
- Added `source_span` ^1.10.1 for position tracking support
- Updated `petitparser` ^7.0.0 for V2 implementation

### Breaking Changes
- Package structure reorganized with v1/v2 subdirectories
- Default import now explicitly uses V1 for maximum backward compatibility
- V2 has different API surface with enhanced type safety (sealed classes)

## 1.1.1

- support properties with escaped curlies

## 1.0.1

- support section variables with longer names containing spaces
- add helpers for getting module name and types

## 1.0.0

- Initial version.
