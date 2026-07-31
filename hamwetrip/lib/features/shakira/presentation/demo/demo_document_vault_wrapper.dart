import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/document.dart';
import '../document_vault_screen.dart';
import 'controllers/demo_document_controller.dart';
import '../../../../../core/widgets/hamwe_bottom_navigation.dart';

/// Wires up mock document data to your pure UI screen.
class DemoDocumentVaultWrapper extends StatefulWidget {
  const DemoDocumentVaultWrapper({super.key});

  @override
  State<DemoDocumentVaultWrapper> createState() =>
      _DemoDocumentVaultWrapperState();
}

class _DemoDocumentVaultWrapperState extends State<DemoDocumentVaultWrapper> {
  late final DemoDocumentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoDocumentController();
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
                    content: Text('Opening ${doc.title}... (Demo)'),
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
                    content: Text('Share link copied (Demo)'),
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
    // connect local document actions to the reusable vault screen.
    return DocumentVaultScreen(
      documents: _controller.documents,
      selectedCategory: _controller.currentCategory,
      categories: _controller.categories,
      isOffline: true, // Simulating offline mode for the demo
      // Wired to controller to actually filter the list
      onCategoryChanged: (category) => _controller.setCategory(category),
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.vault,
      ),

      // Fixes "Empty Handler" - View document
      onViewDocument: (doc) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing ${doc.title} (${doc.fileSize})'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },

      // Fixes "Empty Handler" - 3-dot options menu
      onDocumentOptions: (doc) => _showDocumentOptions(doc),

      // Fixes "Empty Handler" - Upload button
      onUploadDocument: () {
        _controller.simulateUpload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully! (Demo)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },

      // Fixes "Empty Handler" - Search icon
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
