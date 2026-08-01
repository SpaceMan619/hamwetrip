import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/core/error/app_error.dart';
import 'package:hamwetrip/data/local/document_file_store.dart';
import 'package:hamwetrip/data/mock/mock_document_repository.dart';
import 'package:hamwetrip/data/models/document.dart';
import 'package:hamwetrip/domain/repositories/document_repository.dart';
import 'package:hamwetrip/features/shakira/presentation/demo/controllers/demo_document_controller.dart';

/// A repository that refuses every write, to check the vault does not leave a
/// stored file behind when the record cannot be saved.
class _FailingDocumentRepository implements DocumentRepository {
  @override
  Stream<List<TripDocument>> watchDocuments(String tripId) =>
      Stream.value(const []);

  @override
  Future<TripDocument> uploadDocument({
    required String tripId,
    required String title,
    required String category,
    required DocType type,
    required String uploadedBy,
    required String uploadedByInitials,
    required String fileSize,
    String? localPath,
  }) async => throw const NetworkError();

  @override
  Future<void> deleteDocument({
    required String tripId,
    required String docId,
  }) async => throw const NetworkError();
}

void main() {
  late Directory root;
  late DocumentFileStore store;
  late MockDocumentRepository repository;
  late DemoDocumentController controller;

  /// A file standing in for something chosen in the system picker.
  Future<String> pickable(String name, {String contents = 'hello'}) async {
    final file = File('${root.path}/picked_$name');
    await file.writeAsString(contents);
    return file.path;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hamwe_vault_test');
    store = DocumentFileStore(rootDirectory: () async => root);
    repository = MockDocumentRepository();
    controller = DemoDocumentController(
      repository: repository,
      fileStore: store,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  tearDown(() async {
    controller.dispose();
    repository.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('formatFileSize', () {
    test('scales from bytes to megabytes', () {
      expect(formatFileSize(512), '512 B');
      expect(formatFileSize(2048), '2.0 KB');
      expect(formatFileSize(1024 * 900), '900 KB');
      expect(formatFileSize(1024 * 1024 * 3), '3.0 MB');
    });
  });

  group('docTypeForFileName', () {
    test('reads the extension, and falls back to a plain document', () {
      expect(docTypeForFileName('booking.PDF'), DocType.pdf);
      expect(docTypeForFileName('passport.jpeg'), DocType.image);
      expect(docTypeForFileName('insurance.docx'), DocType.document);
      expect(docTypeForFileName('no-extension'), DocType.document);
    });
  });

  group('DocumentFileStore', () {
    test('copies the file so the picker cache can be cleared', () async {
      final source = await pickable('passport.jpg', contents: 'bytes');

      final stored = await store.save(
        tripId: 'trip_1',
        sourcePath: source,
        fileName: 'passport.jpg',
      );

      expect(stored.path, isNot(source));
      expect(await File(stored.path).readAsString(), 'bytes');
      expect(stored.sizeLabel, '5 B');

      await File(source).delete();
      expect(DocumentFileStore.hasFile(stored.path), isTrue);
    });

    test('keeps both files when two share a name', () async {
      final first = await store.save(
        tripId: 'trip_1',
        sourcePath: await pickable('a.jpg', contents: 'one'),
        fileName: 'photo.jpg',
      );
      // The stored name carries a millisecond stamp, so two saves inside the
      // same millisecond would collide.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await store.save(
        tripId: 'trip_1',
        sourcePath: await pickable('b.jpg', contents: 'two'),
        fileName: 'photo.jpg',
      );

      expect(first.path, isNot(second.path));
      expect(await File(first.path).readAsString(), 'one');
      expect(await File(second.path).readAsString(), 'two');
    });

    test('a name that tries to climb out of the folder cannot', () async {
      final stored = await store.save(
        tripId: 'trip_1',
        sourcePath: await pickable('evil.txt'),
        fileName: '../../escaped.txt',
      );

      expect(stored.path, contains('hamwe_documents/trip_1'));
      expect(stored.path, isNot(contains('..')));
    });

    test('deleting a missing or null path is not an error', () async {
      await store.delete(null);
      await store.delete('${root.path}/never_existed.pdf');
    });

    test('hasFile is false for a path from another device', () {
      expect(
        DocumentFileStore.hasFile('/data/other-phone/passport.jpg'),
        false,
      );
      expect(DocumentFileStore.hasFile(null), false);
      expect(DocumentFileStore.hasFile(''), false);
    });
  });

  group('DemoDocumentController.uploadDocument', () {
    test('stores the file and records where it went', () async {
      final uploaded = await controller.uploadDocument(
        sourcePath: await pickable('permit.pdf', contents: 'permit'),
        fileName: 'permit.pdf',
        title: 'Park permit',
        category: 'Bookings',
        uploadedBy: 'Aime Shyaka',
        uploadedByInitials: 'AS',
      );

      expect(uploaded, isTrue);
      expect(controller.hasError, isFalse);

      final added = controller.documents.firstWhere(
        (doc) => doc.title == 'Park permit',
      );
      expect(added.type, DocType.pdf);
      expect(added.fileSize, '6 B');
      expect(added.category, 'Bookings');
      expect(controller.hasFile(added), isTrue);
      expect(await File(added.localPath!).readAsString(), 'permit');
    });

    test('counts only the documents whose file is on this device', () async {
      // The seeded vault has metadata but no files behind it.
      expect(controller.cachedCount, 0);

      await controller.uploadDocument(
        sourcePath: await pickable('ticket.png'),
        fileName: 'ticket.png',
        title: 'Bus ticket',
        category: 'Receipts',
        uploadedBy: 'Aime Shyaka',
        uploadedByInitials: 'AS',
      );

      expect(controller.cachedCount, 1);
    });

    test('the new document is reachable through its category chip', () async {
      await controller.uploadDocument(
        sourcePath: await pickable('receipt.jpg'),
        fileName: 'receipt.jpg',
        title: 'Fuel receipt',
        category: 'Receipts',
        uploadedBy: 'Aime Shyaka',
        uploadedByInitials: 'AS',
      );

      controller.setCategory('Receipts');

      expect(
        controller.documents.map((d) => d.title),
        contains('Fuel receipt'),
      );
    });

    test('leaves no orphan file when the record cannot be written', () async {
      final failing = DemoDocumentController(
        repository: _FailingDocumentRepository(),
        fileStore: store,
      );
      addTearDown(failing.dispose);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final uploaded = await failing.uploadDocument(
        sourcePath: await pickable('doomed.pdf'),
        fileName: 'doomed.pdf',
        title: 'Doomed',
        category: 'Other',
        uploadedBy: 'Aime Shyaka',
        uploadedByInitials: 'AS',
      );

      expect(uploaded, isFalse);
      expect(failing.error, isA<NetworkError>());

      final tripFolder = Directory('${root.path}/hamwe_documents/demo-trip');
      final leftBehind = await tripFolder.exists()
          ? tripFolder.listSync()
          : const <FileSystemEntity>[];
      expect(leftBehind, isEmpty);
    });
  });

  group('DemoDocumentController.deleteDocument', () {
    test('removes the record and the stored file together', () async {
      await controller.uploadDocument(
        sourcePath: await pickable('visa.pdf'),
        fileName: 'visa.pdf',
        title: 'Visa',
        category: 'IDs',
        uploadedBy: 'Aime Shyaka',
        uploadedByInitials: 'AS',
      );
      final added = controller.documents.firstWhere((d) => d.title == 'Visa');
      final path = added.localPath!;

      final deleted = await controller.deleteDocument(added);

      expect(deleted, isTrue);
      expect(controller.documents.map((d) => d.title), isNot(contains('Visa')));
      expect(File(path).existsSync(), isFalse);
    });
  });
}
