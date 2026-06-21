/// Minimal grammar for testing basic i3/Sway configuration parsing.
///
/// This is the simplest possible grammar to get basic parsing working.
library;

import 'package:i3config/src/v2/value.dart';
import 'package:petitparser/petitparser.dart';
import 'package:source_span/source_span.dart';
import 'ast.dart';

// ===== Helper Functions =====

/// Global source file reference for position tracking
SourceFile? _globalSourceFile;

final SettableParser<Command> _commandParser = undefined<Command>();
bool _commandInitialized = false;

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

// ===== Strings =====

Parser<String> dqChar() => pattern('^"\\\\\r\n');

Parser<String> sqChar() => pattern("^'\\\\\r\n");

Parser<Quoted> dqString() => position()
    .seq((char('"') & (dqChar() | escapeSeq()).star() & char('"')).flatten())
    .seq(position())
    .map(
      (vals) => _annotate(
        Quoted(
          _processEscapeSequences(
            (vals[1] as String).substring(1, (vals[1] as String).length - 1),
          ),
          '"',
        ),
        vals[0] as int,
        vals[2] as int,
      ),
    );

Parser<Quoted> sqString() => position()
    .seq((char("'") & (sqChar() | escapeSeq()).star() & char("'")).flatten())
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
    char('#'));

Parser<BareArg> bareArg() => position()
    .seq(bareChar().plus().flatten())
    .seq(position())
    .map(
      (vals) =>
          _annotate(BareArg(vals[1] as String), vals[0] as int, vals[2] as int),
    );

// ===== Values =====

Parser value() => quotedString() | variableRef() | bareArg();

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

Parser<String> assignOp() => (string('+=') | char('=')).flatten();

Parser<List<Value>> rhsList() =>
    (value() & ((ws() & char('#')).not() & ws() & value()).star()).map((parts) {
      final result = <Value>[parts[0] as Value];
      final rest = parts[1] as List;
      for (final item in rest) {
        result.add(item[2] as Value);
      }
      return result;
    });

// ===== Command head =====

Parser<String> commandHead() =>
    (pattern('a-zA-Z') & pattern('a-zA-Z0-9_\\-').star()).flatten();

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
            char(']'))
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

// ===== Blocks =====

Parser<List<ConfigElement>> blockBody() =>
    (wsOrNl().optional() &
            ((wsOrNl() & (comment() | assignStmt() | command())).star()) &
            wsOrNl().optional())
        .map((parts) {
          final elements = parts[1] as List;
          return elements.map((e) => e[1]).whereType<ConfigElement>().toList();
        });

Parser<Block> block() => position()
    .seq(char('{') & blockBody() & char('}'))
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
          ((comment() | statement()) & wsOrNl().optional()).star() &
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
      final lines = content.substring(0, position).split('\n');
      final line = lines.length;
      final column = lines.last.length + 1;
      throw ParseError(
        'Parse error: ${failure.message}',
        line,
        column,
        content.split('\n')[line - 1],
      );
    }
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
