import 'dart:io' show File;

/// Abstract filesystem for reading configuration files.
///
/// Used by [IncludeHandler] to resolve `include` directives.
/// Two implementations are provided:
///   - [PhysicalFileSystem] for real I/O (the default).
///   - [VirtualFileSystem] for testing in memory.
abstract class FileSystem {
  /// Read the content of [path].
  /// Returns `null` if the file does not exist.
  Future<String?> readFile(String path);
}

/// Default [FileSystem] implementation backed by `dart:io`.
class PhysicalFileSystem implements FileSystem {
  const PhysicalFileSystem();

  @override
  Future<String?> readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsString();
  }
}
