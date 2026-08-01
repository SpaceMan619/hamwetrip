import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/state/view_state.dart';
import '../../../../data/local/document_file_store.dart';
import '../../../../data/models/document.dart';
import '../document_preview_screen.dart';
import '../document_vault_screen.dart';
import 'controllers/demo_document_controller.dart';
import '../../../../core/widgets/create_forms.dart';
import '../../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../../core/widgets/trip_scoped.dart';
import '../../../home/home_providers.dart';

/// What kind of file the traveller says they are adding, which decides where
/// the system picker opens.
enum _PickSource {
  /// The system document browser, filtered to the formats a trip actually
  /// produces. On Android this opens the file browser rather than Recents.
  document(FileType.custom),

  /// The gallery.
  image(FileType.image),

  /// Everything, for the file the other two do not cover.
  any(FileType.any);

  const _PickSource(this.fileType);

  final FileType fileType;
}

/// The formats the "PDF or document" picker offers.
///
/// Android maps these to MIME types; any it does not recognise makes the whole
/// filter fall back to "all files", so an unusual format is never locked out —
/// it just loses the filtering.
const _documentExtensions = <String>[
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'csv',
];

/// Wires up document data from Firestore to the pure UI screen.
class DemoDocumentVaultWrapper extends StatelessWidget {
  const DemoDocumentVaultWrapper({super.key});

  @override
  Widget build(BuildContext context) => TripScoped(
    destination: HamweDestination.vault,
    builder: (tripId) =>
        _DocumentVaultView(key: ValueKey(tripId), tripId: tripId),
  );
}

class _DocumentVaultView extends ConsumerStatefulWidget {
  const _DocumentVaultView({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<_DocumentVaultView> createState() =>
      _DemoDocumentVaultWrapperState();
}

class _DemoDocumentVaultWrapperState extends ConsumerState<_DocumentVaultView> {
  late final DemoDocumentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoDocumentController(
      repository: ref.read(documentRepositoryProvider),
      tripId: widget.tripId,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify(String message, {bool good = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: good ? AppColors.forest : null,
      ),
    );
  }

  /// Asks what kind of file is coming before opening the picker.
  ///
  /// Worth the extra tap. Asking Android for "any file" opens the document
  /// picker on its Recents view, which lists photos and hides everything else
  /// behind a menu — so a PDF sitting in Downloads looks unreachable. Naming
  /// the kind up front lets the picker open where that kind actually lives.
  Future<void> _chooseSourceAndUpload() async {
    final source = await showModalBottomSheet<_PickSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add to vault',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.forest,
              ),
              title: const Text('PDF or document'),
              subtitle: const Text('Bookings, permits, insurance'),
              onTap: () => Navigator.pop(ctx, _PickSource.document),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.forest,
              ),
              title: const Text('Photo'),
              subtitle: const Text('A picture of a passport or a receipt'),
              onTap: () => Navigator.pop(ctx, _PickSource.image),
            ),
            ListTile(
              leading: const Icon(
                Icons.folder_outlined,
                color: AppColors.forest,
              ),
              title: const Text('Browse all files'),
              onTap: () => Navigator.pop(ctx, _PickSource.any),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _pickAndUpload(source);
  }

  /// Picks a file from the device, asks what to call it, then stores it.
  ///
  /// Nothing is written until the form is completed, so backing out of either
  /// step leaves the vault untouched.
  Future<void> _pickAndUpload(_PickSource source) async {
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        dialogTitle: 'Add to vault',
        type: source.fileType,
        // Only FileType.custom may carry extensions; the others throw.
        allowedExtensions: source == _PickSource.document
            ? _documentExtensions
            : null,
      );
    } catch (_) {
      // Thrown when the picker cannot start at all — permission refused, or no
      // document provider on the device.
      _notify("We couldn't open the file picker on this device.");
      return;
    }
    if (picked == null || picked.files.isEmpty) return; // Cancelled.

    final file = picked.files.first;
    final sourcePath = file.path;
    if (sourcePath == null) {
      // A picked file with no path — a cloud provider entry the platform never
      // materialised. There is nothing on disk for us to copy.
      _notify("That file couldn't be read from where it is stored.");
      return;
    }
    if (!mounted) return;

    final input = await showUploadDocumentForm(
      context,
      fileName: file.name,
      fileSizeLabel: formatFileSize(file.size),
    );
    if (input == null || !mounted) return;

    final profile = switch (ref.read(currentUserProfileProvider).view) {
      ViewData(:final data) => data,
      _ => null,
    };

    final uploaded = await _controller.uploadDocument(
      sourcePath: sourcePath,
      fileName: file.name,
      title: input.title,
      category: input.category,
      uploadedBy: profile?.displayName ?? 'You',
      uploadedByInitials: profile?.initials ?? '?',
    );

    _notify(
      uploaded
          ? '${input.title} added to the vault'
          : _controller.error?.message ?? "Couldn't add that document",
      good: uploaded,
    );
  }

  Future<void> _openDocument(TripDocument doc) async {
    if (!_controller.hasFile(doc)) {
      _notify(
        '${doc.title} was added on another device, so the file '
        "isn't stored here.",
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentPreviewScreen(document: doc)),
    );
  }

  Future<void> _deleteDocument(TripDocument doc) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete document?',
      message:
          '"${doc.title}" will be removed from the vault and deleted from '
          "this device. This can't be undone.",
    );
    if (!confirmed) return;

    final deleted = await _controller.deleteDocument(doc);
    _notify(
      deleted
          ? '${doc.title} deleted'
          : _controller.error?.message ?? "Couldn't delete that document",
    );
  }

  void _showDocumentOptions(TripDocument doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                doc.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.visibility_outlined,
                color: AppColors.forest,
              ),
              title: const Text('View Document'),
              onTap: () {
                Navigator.pop(ctx);
                _openDocument(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteDocument(doc);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.vault,
        ),
      );
    }

    // Error state
    if (_controller.hasError) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _controller.error?.message ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.vault,
        ),
      );
    }

    return DocumentVaultScreen(
      documents: _controller.documents,
      selectedCategory: _controller.currentCategory,
      categories: _controller.categories,
      cachedCount: _controller.cachedCount,
      hasFile: _controller.hasFile,
      isUploading: _controller.isUploading,
      isOffline: false,
      onCategoryChanged: (category) => _controller.setCategory(category),
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.vault,
      ),
      onViewDocument: _openDocument,
      onDocumentOptions: _showDocumentOptions,
      onUploadDocument: _chooseSourceAndUpload,
      onSearch: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Search Documents'),
            content: TextField(
              onChanged: (val) => _controller.search(val),
              decoration: const InputDecoration(
                hintText: 'e.g. "Passport" or "Booking"',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _controller.clearSearch();
                  Navigator.pop(ctx);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        );
      },
    );
  }
}
