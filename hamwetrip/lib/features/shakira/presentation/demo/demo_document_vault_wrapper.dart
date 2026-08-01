import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/document.dart';
import '../document_vault_screen.dart';
import 'controllers/demo_document_controller.dart';
import '../../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../../core/widgets/trip_scoped.dart';

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening ${doc.title}...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.share_outlined,
                color: AppColors.forest,
              ),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share link copied'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.forest,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _controller.deleteDocument(doc.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${doc.title} deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
      isOffline: false,
      onCategoryChanged: (category) => _controller.setCategory(category),
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.vault,
      ),
      onViewDocument: (doc) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing ${doc.title} (${doc.fileSize})'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },
      onDocumentOptions: (doc) => _showDocumentOptions(doc),
      onUploadDocument: () {
        _controller.simulateUpload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },
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
