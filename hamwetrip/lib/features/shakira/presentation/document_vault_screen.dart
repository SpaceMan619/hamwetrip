import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/document.dart';
import '../../../core/widgets/shakira_widgets/document_card.dart';
import '../../../core/widgets/shakira_widgets/offline_status_bar.dart';

class DocumentVaultScreen extends StatelessWidget {
  final List<TripDocument> documents;
  final String selectedCategory;
  final List<String> categories;
  final void Function(String) onCategoryChanged;
  final void Function(TripDocument) onViewDocument;
  final void Function(TripDocument) onDocumentOptions;
  final VoidCallback onUploadDocument;
  final VoidCallback onSearch;
  final bool isOffline;
  final Widget? bottomNavigation;

  const DocumentVaultScreen({
    super.key,
    required this.documents,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.onViewDocument,
    required this.onDocumentOptions,
    required this.onUploadDocument,
    required this.onSearch,
    this.isOffline = true,
    this.bottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Documents'),
        actions: [
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_outlined, color: AppColors.forest),
          ),
        ],
      ),
      body: Column(
        children: [
          // NEW: Offline Status Bar
          if (isOffline) const OfflineStatusBar(),

          // Header Info & Upload Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Offline Vault',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      // NEW: Storage Stats matching Figma
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            color: AppColors.forest,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '3 documents cached locally in Rwanda',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onUploadDocument,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Add Document'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),

          // Category Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) => onCategoryChanged(category),
                      selectedColor: AppColors.forest.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: selectedCategory == category
                            ? AppColors.forest
                            : AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.line),

          // Document Grid (Updated mock data to match Figma exactly)
          Expanded(
            child: documents.isEmpty
                ? const Center(
                    child: Text(
                      'No documents in this category',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      return DocumentCard(
                        document: doc,
                        onTap: () => onViewDocument(doc),
                        onMore: () => onDocumentOptions(doc),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigation,
    );
  }
}
