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

  /// How many documents have their file on this device. Counted over the whole
  /// vault, not the filtered [documents], since it describes what is stored
  /// rather than what is currently on screen.
  final int cachedCount;

  /// True while a file is being copied in, so the upload button can show it is
  /// busy instead of accepting a second tap.
  final bool isUploading;

  /// Whether this document's file can be opened on this device. Drives the
  /// card's thumbnail and its sync badge.
  final bool Function(TripDocument) hasFile;

  /// Leaves the vault. Null hides the arrow entirely, for a caller that has
  /// nowhere sensible to send someone.
  final VoidCallback? onBack;

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
    required this.cachedCount,
    required this.hasFile,
    this.onBack,
    this.isUploading = false,
    this.isOffline = true,
    this.bottomNavigation,
  });

  String get _cacheSummary => cachedCount == 0
      ? 'Nothing stored on this device yet'
      : '$cachedCount document${cachedCount == 1 ? '' : 's'} cached locally '
            '• available offline';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppColors.ink,
                ),
                onPressed: onBack,
              ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Offline Vault',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: isUploading ? null : onUploadDocument,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file_outlined, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      color: AppColors.forest,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _cacheSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder_open_outlined,
                            size: 48,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No documents in this category',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: isUploading ? null : onUploadDocument,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Add a document'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 244,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      return DocumentCard(
                        document: doc,
                        isAvailableOffline: hasFile(doc),
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
