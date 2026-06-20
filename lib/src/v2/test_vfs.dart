import 'filesystem.dart';

/// Virtual filesystem for testing imports.
///
/// Implements [FileSystem] so it can be injected into
/// [ConfigProcessor] via the `fileSystem` parameter.
class VirtualFileSystem implements FileSystem {
  static final VirtualFileSystem _instance = VirtualFileSystem._internal();
  factory VirtualFileSystem() => _instance;

  VirtualFileSystem._internal();

  final Map<String, String> _files = {};

  /// Create a virtual file with given path and content.
  void createFile(String path, String content) {
    _files[path] = content;
  }

  @override
  Future<String?> readFile(String path) async => _files[path];

  /// Read a virtual file synchronously (returns null if not found).
  String? read(String path) {
    return _files[path];
  }

  /// Check if file exists in VFS.
  bool exists(String path) {
    return _files.containsKey(path);
  }

  /// Clear all virtual files.
  void clear() {
    _files.clear();
  }
}

/// Global test virtual filesystem instance.
final vfs = VirtualFileSystem();
