import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/error/app_error.dart';
import '../models/document.dart';

/// A file that has been copied into the app's own storage.
class StoredDocumentFile {
  const StoredDocumentFile({required this.path, required this.sizeLabel});

  /// Absolute path inside the app's documents directory.
  final String path;

  /// Human-readable size, e.g. `1.2 MB`, ready to render on the card.
  final String sizeLabel;
}

/// Keeps the bytes of a trip's documents on this device.
///
/// The vault deliberately splits the two halves of a document: the metadata
/// record goes through `DocumentRepository` (Firestore, or the in-memory mock),
/// while the file itself is copied here, into the app's own documents
/// directory. That means uploading and opening a document needs no Storage
/// bucket and no connection — which is the whole point of an "offline vault" —
/// and it survives a restart, unlike anything held in memory.
///
/// The copy matters: a path handed over by the system file picker points at a
/// cache entry the OS is free to delete, so keeping only that path would give
/// a vault whose files quietly vanish.
class DocumentFileStore {
  const DocumentFileStore({Future<Directory> Function()? rootDirectory})
    : _rootDirectory = rootDirectory;

  /// Where the vault folder is created. Defaults to the app's documents
  /// directory; a test passes a temporary directory instead, which is the only
  /// reason this is injectable.
  final Future<Directory> Function()? _rootDirectory;

  static const _folder = 'hamwe_documents';

  Future<Directory> _tripDirectory(String tripId) async {
    final root =
        await (_rootDirectory?.call() ?? getApplicationDocumentsDirectory());
    final directory = Directory('${root.path}/$_folder/$tripId');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Copies [sourcePath] into this trip's folder and reports where it landed.
  ///
  /// The stored name is prefixed with a timestamp so uploading two files called
  /// `passport.jpg` keeps both rather than overwriting the first.
  Future<StoredDocumentFile> save({
    required String tripId,
    required String sourcePath,
    required String fileName,
  }) async {
    try {
      final directory = await _tripDirectory(tripId);
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final target = '${directory.path}/${stamp}_${_safeName(fileName)}';
      final copied = await File(sourcePath).copy(target);
      return StoredDocumentFile(
        path: copied.path,
        sizeLabel: formatFileSize(await copied.length()),
      );
    } on FileSystemException catch (error) {
      throw UnknownError(
        message: "We couldn't save that file to this device.",
        cause: error,
      );
    }
  }

  /// Removes a stored file. A path that is null or already gone is not an
  /// error: deleting the record is what the person asked for, and a missing
  /// file means that half of the job is done.
  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Nothing useful to tell the traveller: the metadata is what they see,
      // and a stray file costs them nothing.
    }
  }

  /// Whether the bytes for [path] are actually on this device.
  ///
  /// Synchronous so the grid and the preview screen can decide what to draw
  /// during a build. Records synced from another member carry that member's
  /// path, which does not exist here — hence the check before every open.
  static bool hasFile(String? path) =>
      path != null && path.isNotEmpty && File(path).existsSync();

  /// Strips anything that would let a file name escape the trip folder.
  static String _safeName(String fileName) {
    final base = fileName.split(RegExp(r'[/\\]')).last;
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'document' : cleaned;
  }
}

/// Renders a byte count the way a file manager would.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
}

/// Guesses which [DocType] icon a file should get from its extension.
///
/// Only the extension is consulted — the vault takes whatever the picker
/// returns, and the type here drives nothing but the icon and whether the
/// preview screen tries to render the file inline.
DocType docTypeForFileName(String fileName) {
  final extension = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  switch (extension) {
    case 'pdf':
      return DocType.pdf;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
    case 'bmp':
    case 'heic':
    case 'heif':
      return DocType.image;
    default:
      return DocType.document;
  }
}
