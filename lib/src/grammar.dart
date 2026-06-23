/// Minimal grammar for testing basic i3/Sway configuration parsing.
///
/// This is the simplest possible grammar to get basic parsing working.
library;

import 'package:i3config/src/value.dart';
import 'package:petitparser/petitparser.dart';
import 'package:source_span/source_span.dart';
import 'ast.dart';

/// Wrap a parser to produce a custom error message when it fails.
Parser<T> _orError<T>(Parser<T> parser, String message) =>
    [parser, failure<T>(message: message)].toChoiceParser();

// ===== Helper Functions =====

/// Global source file reference for position tracking
SourceFile? _globalSourceFile;

final SettableParser<Command> _commandParser = undefined<Command>();
bool _commandInitialized = false;

final SettableParser<dynamic> _valueParser = undefined<dynamic>();
bool _valueInitialized = false;

final SettableParser<dynamic> _arrayValueParser = undefined<dynamic>();
bool _arrayValueInitialized = false;

/// Utility to annotate a node with span information
T _annotate<T>(T node, int start, int end) {
  if (_globalSourceFile == null) return node;

  if (node is ConfigElement) {
    node.setSpan(_globalSourceFile!.span(start, end));
  } else if (node is Value) {
    node.setSpan(_globalSourceFile!.span(start, end));
  } else if (node is Criterion) {
    node.setSpan(_globalSourceFile!.span(start, end));
  }
  return node;
}

/// Process escape sequences in string content.
String _processEscapeSequences(String content) {
  final result = StringBuffer();
  for (int i = 0; i < content.length; i++) {
    if (content[i] == '\\' && i + 1 < content.length) {
      final nextChar = content[i + 1];
      switch (nextChar) {
        case 'n':
          result.write('\n');
          i++; // Skip the 'n'
          break;
        case 'r':
          result.write('\r');
          i++; // Skip the 'r'
          break;
        case 't':
          result.write('\t');
          i++; // Skip the 't'
          break;
        case '"':
          result.write('"');
          i++; // Skip the '"'
          break;
        case "'":
          result.write("'");
          i++; // Skip the "'"
          break;
        case '\\':
          result.write('\\');
          i++; // Skip the '\'
          break;
        case ' ':
          result.write(' '); // Escaped space
          i++; // Skip the space
          break;
        case '{':
          result.write('{');
          i++; // Skip the '{'
          break;
        case '}':
          result.write('}');
          i++; // Skip the '}'
          break;
        default:
          // Keep the backslash and next character as-is
          result.write(content[i]);
          break;
      }
    } else {
      result.write(content[i]);
    }
  }
  return result.toString();
}

/// Preprocess content to handle line continuations.
String preprocess(String content) {
  final lines = content.split('\n');
  final processedLines = <String>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Check for line continuation (backslash at end of line)
    if (line.endsWith('\\')) {
      // Find the next non-empty line
      int nextLine = i + 1;
      while (nextLine < lines.length && lines[nextLine].trim().isEmpty) {
        nextLine++;
      }

      if (nextLine < lines.length) {
        // Join the lines with a space
        final continuation =
            '${line.substring(0, line.length - 1)} ${lines[nextLine].trimLeft()}';
        processedLines.add(continuation);
        i = nextLine; // Skip the next line as it's been merged
      } else {
        // Remove trailing backslash if no continuation
        processedLines.add(line.substring(0, line.length - 1));
      }
    } else {
      processedLines.add(line);
    }
  }

  return processedLines.join('\n');
}

// ===== Layout / Trivia Parsers =====

Parser<String> ws() => pattern(' \t').plus().flatten();

Parser newline() =>
    (char('\r').optional() & char('\n')) | char('\n') | char('\r');

Parser wsOrNl() => pattern(' \t\r\n').star();

Parser<void> eof() => endOfInput();

Parser<Comment> comment() => position()
    .seq((char('#') & pattern('^\r\n').star() & newline().optional()).flatten())
    .seq(position())
    .map(
      (vals) => _annotate(
        Comment((vals[1] as String).trim()),
        vals[0] as int,
        vals[2] as int,
      ),
    );

Parser<dynamic> lineEnd() => newline() | eof();

// ===== Escape sequences =====

Parser<String> escapeSeq() =>
    (char('\\') &
            (char('\\') |
                char('"') |
                char("'") |
                char('n') |
                char('r') |
                char('t') |
                char('{') |
                char('}') |
                char(' ')))
        .flatten();

// ===== Interpolation helpers =====

List<ValueSegment> _splitInterpolation(String raw) {
  if (!raw.contains('\$')) return [ValueSegmentLiteral(raw)];

  final segments = <ValueSegment>[];
  int lastEnd = 0;
  final positions = <int>[];

  for (int i = 0; i < raw.length; i++) {
    if (raw[i] == '\$' && (i == 0 || raw[i - 1] != '\\')) {
      positions.add(i);
    }
  }

  for (final pos in positions) {
    if (lastEnd < pos) {
      segments.add(ValueSegmentLiteral(raw.substring(lastEnd, pos)));
    }
    final varMatch = _varNamePattern.matchAsPrefix(raw, pos + 1);
    if (varMatch != null) {
      segments.add(ValueSegmentVariableReference(raw.substring(pos + 1, varMatch.end)));
      segments.add(ValueSegmentLiteral(''));
      lastEnd = varMatch.end;
    } else {
      lastEnd = pos;
    }
  }

  if (lastEnd < raw.length) {
    segments.add(ValueSegmentLiteral(raw.substring(lastEnd)));
  }

  return segments.isEmpty ? [ValueSegmentLiteral('')] : segments;
}

RegExp _varNamePattern = RegExp(r'[a-zA-Z_][a-zA-Z0-9_-]*');

// ===== Strings =====

Parser<String> dqChar() => pattern('^"\\\\\r\n');

Parser<String> sqChar() => pattern("^'\\\\\r\n");

Parser<Value> dqString() => position()
    .seq(
      (char('"') &
          (dqChar() | escapeSeq()).star() &
          _orError(char('"'), "closing double quote")).flatten(),
    )
    .seq(position())
    .map(
      (vals) {
        final full = vals[1] as String;
        final raw = full.substring(1, full.length - 1);

        final segments = _splitInterpolation(raw);
        final hasVar =
            segments.any((s) => s is ValueSegmentVariableReference);
        final spanStart = vals[0] as int;
        final spanEnd = vals[2] as int;

        if (!hasVar) {
          final text =
              segments.whereType<ValueSegmentLiteral>().map((s) => s.text).join();
          return _annotate(Quoted(_processEscapeSequences(text), '"'), spanStart, spanEnd);
        }

        final processed = segments
            .map((s) => s is ValueSegmentLiteral
                ? ValueSegmentLiteral(_processEscapeSequences(s.text))
                : s);
        return _annotate(
            InterpolatedString(processed.toList(), '"'), spanStart, spanEnd);
      },
    );

Parser<Quoted> sqString() => position()
    .seq((char("'") & (sqChar() | escapeSeq()).star() & _orError(char("'"), "closing single quote")).flatten())
    .seq(position())
    .map(
      (vals) => _annotate(
        Quoted(
          _processEscapeSequences(
            (vals[1] as String).substring(1, (vals[1] as String).length - 1),
          ),
          "'",
        ),
        vals[0] as int,
        vals[2] as int,
      ),
    );

Parser quotedString() => dqString() | sqString();

// ===== Variables =====

Parser<String> varName() =>
    (pattern('a-zA-Z_') & pattern('a-zA-Z0-9_\\-').star()).flatten();

Parser<VariableRef> variableRef() => position()
    .seq(char('\$') & varName())
    .seq(position())
    .map(
      (vals) => _annotate(
        VariableRef((vals[1] as List)[1] as String),
        vals[0] as int,
        vals[2] as int,
      ),
    );

// ===== Identifiers =====

Parser<String> identChar() => pattern('a-zA-Z0-9_\\-\\./:');

Parser<String> identifier() => identChar().plus().flatten();

// ===== Bare arguments =====

Parser bareChar() =>
    (pattern('a-zA-Z0-9_') |
    char('-') |
    char('.') |
    char('/') |
    char('~') |
    char('*') |
    char('?') |
    char('=') |
    char('+') |
    char(',') |
    char('@') |
    char('%') |
    char(':'));

Parser<BareArg> bareArg() => position()
    .seq(bareChar().plus().flatten())
    .seq(position())
    .map(
      (vals) =>
          _annotate(BareArg(vals[1] as String), vals[0] as int, vals[2] as int),
    );

// Bare char set without comma — used inside array literals so commas
// are treated as separators rather than value characters.
Parser _arrayBareChar() =>
    (pattern('a-zA-Z0-9_') |
    char('-') |
    char('.') |
    char('/') |
    char('~') |
    char('*') |
    char('?') |
    char('=') |
    char('+') |
    char('@') |
    char('%') |
    char(':'));

Parser<BareArg> _arrayBareArg() => position()
    .seq(_arrayBareChar().plus().flatten())
    .seq(position())
    .map(
      (vals) =>
          _annotate(BareArg(vals[1] as String), vals[0] as int, vals[2] as int),
    );

// ===== Block References =====

Parser<String> blockIdent() => pattern('a-zA-Z0-9_\\-').plus().flatten();

Parser<List<String>> _blockRefPathSegments() =>
    (blockIdent() &
            char('.') &
            blockIdent() &
            (char('.') & blockIdent()).star())
        .map((parts) {
          final first = parts[0] as String;
          final second = parts[2] as String;
          final rest = parts[3] as List;
          final result = <String>[first, second];
          for (final item in rest) {
            result.add(item[1] as String);
          }
          return result;
        });

Parser<BlockReference> blockReference() =>
    _blockRefPathSegments().map((path) => BlockReference(path));

// ===== Hex Colors =====

Parser<BareArg> hexColor() => position()
    .seq(
      (char('#') & pattern('0-9a-fA-F').plus()).flatten(),
    )
    .seq(position())
    .map(
      (vals) =>
          _annotate(BareArg(vals[1] as String), vals[0] as int, vals[2] as int),
    );

// ===== Values =====

  Parser<ArrayValue> arrayLiteral() => position()
    .seq(char('[') & wsOrNl().optional() &
        (_arrayValue() & (wsOrNl().optional() & char(',') & wsOrNl().optional() & _arrayValue()).star()).optional() &
        wsOrNl().optional() & _orError(char(']'), "closing bracket ']'"))
    .seq(position())
    .map((vals) {
      final parts = vals[1] as List;
      final optionalValues = parts[2]; // The optional value section
      if (optionalValues == null) {
        return _annotate(ArrayValue([]), vals[0] as int, vals[2] as int);
      }
      final values = <Value>[optionalValues[0] as Value];
      final rest = optionalValues[1] as List;
      for (final item in rest) {
        values.add(item[3] as Value); // item is [ws?, ',', ws?, value]
      }
      return _annotate(ArrayValue(values), vals[0] as int, vals[2] as int);
    });

  Parser _arrayValue() {
    if (!_arrayValueInitialized) {
      _arrayValueInitialized = true;
      _arrayValueParser.set(hexColor() | blockReference() | quotedString() | variableRef() | arrayLiteral() | _arrayBareArg());
    }
    return _arrayValueParser;
  }

  Parser value() {
    if (!_valueInitialized) {
      _valueInitialized = true;
      _valueParser.set(hexColor() | blockReference() | quotedString() | variableRef() | arrayLiteral() | bareArg());
    }
    return _valueParser;
  }

// ===== Dotted identifiers for assignments =====

Parser<String> dottedIdent() =>
    (identifier() & (char('.') & identifier()).star()).map((parts) {
      final first = parts[0] as String;
      final rest = parts[1] as List;
      final result = <String>[first];
      for (final item in rest) {
        result.add(item[1] as String); // item is ['.', identifier]
      }
      return result.join('.');
    });

Parser<String> lhs() => dottedIdent();

Parser<String> assignOp() =>
    _orError((string('+=') | char('=')).flatten(), "assignment operator '=' or '+='");

Parser<List<Value>> rhsList() =>
    (value() & (ws() & value()).star()).map((parts) {
      final result = <Value>[parts[0] as Value];
      final rest = parts[1] as List;
      for (final item in rest) {
        result.add(item[1] as Value);
      }
      return result;
    });

// ===== Command head =====

Parser<String> commandHead() => dottedIdent();

// ===== Criteria parsing =====

Parser critValue() => quotedString() | bareArg();

Parser<Criterion> critItem() => position()
    .seq(
      identifier() &
          ws().optional() &
          char('=') &
          ws().optional() &
          critValue(),
    )
    .seq(position())
    .map(
      (vals) => _annotate(
        Criterion(
          (vals[1] as List)[0] as String,
          (vals[1] as List)[4] as Value,
        ),
        vals[0] as int,
        vals[2] as int,
      ),
    );

Parser<List<Criterion>> criteria() =>
    (char('[') &
            ws().optional() &
            critItem() &
            (ws().optional() & critItem()).star() &
            ws().optional() &
            _orError(char(']'), "closing bracket ']'"))
        .map((parts) {
          final items = <Criterion>[parts[2] as Criterion];
          final rest = parts[3] as List;
          for (final item in rest) {
            items.add(item[1] as Criterion); // item is [ws, critItem]
          }
          return items;
        });

// ===== Assignments =====

Parser<Assignment> assignStmt() => position()
    .seq(lhs() & ws() & assignOp() & ws() & rhsList())
    .seq(position())
    .map((vals) {
      final parts = vals[1] as List;
      final lhsValue = parts[0] as String;
      final opSymbol = parts[2] as String;
      final rhsValues = parts[4] as List<Value>;

      return _annotate(
        Assignment(
          lhsValue,
          AssignmentOperator.fromSymbol(opSymbol),
          rhsValues,
        ),
        vals[0] as int,
        vals[2] as int,
      );
    });

// ===== Argument patterns =====

Parser<List<Value>> argPattern() =>
    ((ws() & variableRef() & bareArg()) | (ws() & value())).map((parts) {
      if (parts.length == 3) {
        // Combine variable ref + suffix into a single value
        // e.g. $mod+Return → one token instead of [$mod, +Return]
        final varRef = parts[1] as VariableRef;
        final suffix = parts[2] as BareArg;
        return [BareArg('\$${varRef.name}${suffix.value}')];
      } else {
        // This is [ws, value]
        return [parts[1] as Value];
      }
    });

// ===== Commands =====

Parser<Command> command() {
  if (!_commandInitialized) {
    _commandInitialized = true;
    _commandParser.set(
      position()
          .seq(
            commandHead() &
                argPattern().star() &
                (ws().optional() & criteria()).optional() &
                (ws().optional() & value()).star() &
                (wsOrNl().optional() & block()).optional(),
          )
          .seq(position())
          .map((vals) {
            final parts = vals[1] as List;
            final head = parts[0] as String;
            final args = <Value>[];

            // Add arguments before criteria (flatten the lists)
            final argsBefore = parts[1] as List;
            for (final item in argsBefore) {
              final valueList = item as List<Value>;
              args.addAll(valueList);
            }

            // Add arguments after criteria
            final argsAfter = parts[3] as List;
            for (final item in argsAfter) {
              args.add(item[1] as Value); // item is [ws?, value]
            }

            // Extract criteria if present
            final crit = parts[2] != null
                ? (parts[2] as List)[1] as List<Criterion>
                : null;

            Block? blockPart;
            if (parts[4] != null) {
              final blockList = parts[4] as List;
              blockPart = blockList[1] as Block;
              final blockSpan = blockPart.span;
              blockPart = Block(
                head,
                blockPart.identifier,
                blockPart.body,
                blockSpan,
              );
            }

            return _annotate(
              Command(head, args, crit, blockPart),
              vals[0] as int,
              vals[2] as int,
            );
          }),
    );
  }
  return _commandParser;
}

// ===== Command chains =====

Parser<List<Command>> chainLine() =>
    (command() &
            (ws().optional() & char(';') & ws().optional() & command()).plus())
        .map((parts) {
          final commands = <Command>[parts[0] as Command];
          final rest = parts[1] as List;
          for (final item in rest) {
            commands.add(
              item[3] as Command,
            ); // item is [ws?, ';', ws?, command]
          }
          return commands;
        });

// ===== Simple command =====

Parser<List<Command>> simpleCommand() => command().map((cmd) => [cmd]);

// ===== Inline comment consumer =====

/// Consumes whitespace + comment on the same line and attaches it as
/// [Command.trailingComment] or [Assignment.trailingComment] on the
/// last element of [statement]'s result list.
Parser<List> _statementWithTrailing() =>
    (statement() & (ws() & comment()).optional()).map((parts) {
      final stmts = parts[0] as List;
      final trailing = parts[1] as List?;
      if (trailing != null) {
        final content = (trailing[1] as Comment).content;
        for (final stmt in stmts) {
          if (stmt is Command) {
            stmt.trailingComment = content;
          } else if (stmt is Assignment) {
            stmt.trailingComment = content;
          }
        }
      }
      return stmts;
    });

// ===== Blocks =====

Parser<List<ConfigElement>> blockBody() =>
    (wsOrNl().optional() &
            ((wsOrNl() & (comment() | _statementWithTrailing())).star()) &
            wsOrNl().optional())
        .map((parts) {
          final elements = parts[1] as List;
          final flattened = <ConfigElement>[];
          for (final elementGroup in elements) {
            final element = elementGroup[1];
            if (element is List) {
              for (final item in element) {
                if (item is ConfigElement) {
                  flattened.add(item);
                }
              }
            } else if (element is ConfigElement) {
              flattened.add(element);
            }
          }
          return flattened;
        });

Parser<Block> block() => position()
    .seq(char('{') & blockBody() & _orError(char('}'), "closing brace '}'"))
    .seq(position())
    .map(
      (vals) => _annotate(
        Block('generic', null, ((vals[1] as List)[1] as List<ConfigElement>)),
        vals[0] as int,
        vals[2] as int,
      ),
    );

// ===== Statements =====

Parser statement() =>
    assignStmt().map((assignment) => [assignment]) |
    chainLine() |
    simpleCommand();

// ===== Root config =====

Parser<Config> configParser() => position()
    .seq(
      wsOrNl().optional() &
          ((comment() | _statementWithTrailing()) & wsOrNl().optional()).star() &
          wsOrNl().optional(),
    )
    .seq(position())
    .map((vals) {
      final parts = vals[1] as List;
      final elements = parts[1] as List;
      final flattenedElements = <ConfigElement>[];
      for (final elementGroup in elements) {
        final element =
            elementGroup[0]; // Get the first element (comment | statement)
        if (element is List) {
          // This is a command chain or simple command - flatten it
          for (final item in element) {
            if (item is ConfigElement) {
              flattenedElements.add(item);
            }
          }
        } else if (element is ConfigElement) {
          // This is a single ConfigElement
          flattenedElements.add(element);
        }
      }
      return _annotate(
        Config(flattenedElements),
        vals[0] as int,
        vals[2] as int,
      );
    });

/// Minimal grammar builder for i3/Sway configuration files.
class Grammar {
  final SourceFile _sourceFile;

  /// Create a new grammar instance with source file for position tracking
  Grammar(String source, {Uri? url})
    : _sourceFile = SourceFile.fromString(source, url: url);

  /// Get the main config parser
  Parser<Config> get config => configParser();

  /// Parse configuration content into an AST
  Config parse(String content) {
    // Set the global source file for position tracking
    _globalSourceFile = _sourceFile;

    // Preprocess the content to handle line continuations and empty lines
    final lineContinuationProcessed = preprocess(content);
    final processedContent = _preprocessContent(lineContinuationProcessed);
    final result = configParser().end().parse(processedContent);
    if (result is Success<Config>) {
      return result.value;
    } else {
      final failure = result as Failure;
      final position = failure.position;
      // Map the failure position from processed content back to original content.
      // We build a cumulative offset map by re-running both preprocessing steps
      // to determine how many characters were removed before `position`.
      final origPos =
          _mapProcessedToOriginal(content, position, lineContinuationProcessed);
      final lines = content.substring(0, origPos).split('\n');
      final line = lines.length;
      final column = lines.last.length + 1;
      final message = _contextualMessage(content, origPos, failure.message);
      throw ParseError(message, line, column, content.split('\n')[line - 1]);
    }
  }

  /// Map a position in processed content back to the original content position.
  int _mapProcessedToOriginal(
    String original,
    int processedPos,
    String afterContinuation,
  ) {
    // First, map processedPos through blank-line removal (step 2)
    final blankLinesBefore = _countRemovedBlankLines(afterContinuation, processedPos);
    final afterBlankRemoval = processedPos + blankLinesBefore;

    // Then, map through line-continuation joining (step 1)
    return _mapThroughContinuation(original, afterBlankRemoval);
  }

  /// Count how many blank/whitespace-only lines were removed by
  /// [_preprocessContent] up to the given offset in the continuation-processed
  /// content.
  int _countRemovedBlankLines(String content, int offset) {
    final processedUpTo = content.substring(0, offset);
    final processedLines = processedUpTo.split('\n');
    final allLines = content.split('\n');
    int removed = 0;
    for (int i = 0; i < processedLines.length && i < allLines.length; i++) {
      if (allLines[i].trim().isEmpty) {
        removed++;
      }
    }
    return removed;
  }

  /// Map an offset through line-continuation preprocessing.
  int _mapThroughContinuation(String original, int offset) {
    final lines = original.split('\n');
    int originalOffset = 0;
    int processedOffset = 0;
    for (int i = 0; i < lines.length && processedOffset <= offset; i++) {
      final line = lines[i];
      if (line.endsWith('\\')) {
        // Line continuation: backslash + newline removed from original
        // The continuation joins: backslash (1), newline (1) = 2 removed chars
        final continuationLen = line.length - 1; // Without backslash
        if (processedOffset + continuationLen >= offset) {
          // Offset falls within this line
          return originalOffset + (offset - processedOffset);
        }
        processedOffset += continuationLen; // No newline in processed
        originalOffset += line.length + 1; // +1 for newline in original
        // Skip the next line (already joined)
        if (i + 1 < lines.length) {
          i++; // Will be incremented again by loop
          originalOffset += lines[i].length + 1; // Consume skipped line + newline
        }
      } else {
        // Normal line
        if (processedOffset + line.length + 1 > offset) {
          return originalOffset + (offset - processedOffset);
        }
        processedOffset += line.length + 1;
        originalOffset += line.length + 1;
      }
    }
    return originalOffset;
  }

  /// Generate a contextual error message when PetitParser's default message is generic.
  String _contextualMessage(String content, int position, String originalMessage) {
    if (position < content.length) {
      final char = content[position];
      switch (char) {
        case '[':
          return "missing closing bracket ']'";
        case '{':
          return "missing closing brace '}'";
        case '"':
          return "missing closing double quote";
        case "'":
          return "missing closing single quote";
        case ']':
          return "unexpected closing bracket ']'";
        case '}':
          return "unexpected closing brace '}'";
        case ';':
          return "expected a command after ';'";
      }
      return "unexpected character '$char'";
    }
    return 'Parse error: $originalMessage';
  }

  /// Preprocess content to handle line continuations.
  String preprocess(String content) {
    final lines = content.split('\n');
    final processedLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check for line continuation (backslash at end of line)
      if (line.endsWith('\\')) {
        // Find the next non-empty line
        int nextLine = i + 1;
        while (nextLine < lines.length && lines[nextLine].trim().isEmpty) {
          nextLine++;
        }

        if (nextLine < lines.length) {
          // Join the lines with a space
          final continuation =
              '${line.substring(0, line.length - 1)} ${lines[nextLine].trimLeft()}';
          processedLines.add(continuation);
          i = nextLine; // Skip the next line as it's been merged
        } else {
          // Remove trailing backslash if no continuation
          processedLines.add(line.substring(0, line.length - 1));
        }
      } else {
        processedLines.add(line);
      }
    }

    return processedLines.join('\n');
  }

  /// Preprocess content to handle empty lines and whitespace
  String _preprocessContent(String content) {
    // Remove empty lines but keep comment-only lines
    final lines = content.split('\n');
    final nonEmptyLines = lines.where((line) {
      final trimmed = line.trim();
      return trimmed.isNotEmpty; // Keep comments and other content
    }).toList();
    return nonEmptyLines.join('\n');
  }
}
