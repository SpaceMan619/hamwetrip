import 'package:flutter/material.dart';
import '../models/document.dart';
import '../widgets/document_card.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Tickets',
    'IDs & Visas',
    'Bookings',
    'Insurance',
  ];

  // --- Mock Data ---
  // FIX: Removed 'const' from the list because DateTime.now() runs at runtime
  final List<TripDocument> _documents = [
    TripDocument(
      id: 'd1',
      title: 'RwandAir Boarding Pass - KGL to MXP',
      category: 'Tickets',
      type: DocType.pdf,
      uploadedBy: 'Jean Pierre',
      uploadedByInitials: 'JP',
      fileSize: '1.2 MB',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TripDocument(
      id: 'd2',
      title: 'Gorilla Trekking Permits',
      category: 'Bookings',
      type: DocType.pdf,
      uploadedBy: 'Alice Mugisha',
      uploadedByInitials: 'AM',
      fileSize: '850 KB',
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
    TripDocument(
      id: 'd3',
      title: 'Passport Scan - Claude N.',
      category: 'IDs & Visas',
      type: DocType.image,
      uploadedBy: 'Claude Niyonsaba',
      uploadedByInitials: 'CN',
      fileSize: '4.5 MB',
      date: DateTime.now().subtract(const Duration(days: 12)),
    ),
    TripDocument(
      id: 'd4',
      title: 'Travel Insurance Policy',
      category: 'Insurance',
      type: DocType.document,
      uploadedBy: 'Sarah Kim',
      uploadedByInitials: 'SK',
      fileSize: '2.1 MB',
      date: DateTime.now().subtract(const Duration(days: 15)),
    ),
    TripDocument(
      id: 'd5',
      title: 'Five Volcanoes Hotel Receipt',
      category: 'Bookings',
      type: DocType.pdf,
      uploadedBy: 'Sarah Kim',
      uploadedByInitials: 'SK',
      fileSize: '320 KB',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TripDocument(
      id: 'd6',
      title: 'East African Tourist Visa',
      category: 'IDs & Visas',
      type: DocType.image,
      uploadedBy: 'Jean Pierre',
      uploadedByInitials: 'JP',
      fileSize: '3.8 MB',
      date: DateTime.now().subtract(const Duration(days: 14)),
    ),
    TripDocument(
      id: 'd7',
      title: 'Group Photo at Lake Kivu',
      category: 'All', // Uncategorized
      type: DocType.image,
      uploadedBy: 'Patrick D.',
      uploadedByInitials: 'PD',
      fileSize: '5.2 MB',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<TripDocument> get _filteredDocuments {
    if (_selectedCategory == 'All') return _documents;
    return _documents
        .where((doc) => doc.category == _selectedCategory)
        .toList();
  }

  void _handleUploadDocument() {
    debugPrint('Upload document tapped');
  }

  void _handleViewDocument(TripDocument doc) {
    debugPrint('View document tapped: ${doc.title}');
  }

  void _handleDocumentOptions(TripDocument doc) {
    debugPrint('Options tapped for: ${doc.title}');
    // In a real app, show a BottomSheet with Download, Share, Delete
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;

    // Responsive grid columns
    final int crossAxisCount = MediaQuery.of(context).size.width > 900
        ? 4
        : isTablet
        ? 3
        : 2;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Text('Documents'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search Documents',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info & Upload Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            color: colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kigali City Tour',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_documents.length} files uploaded',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _handleUploadDocument,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Upload'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),

          // Category Filter Chips
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding - 4),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
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

          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),

          // Document Grid
          Expanded(
            child: _filteredDocuments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No documents in this category',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.75, // Height to width ratio
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = _filteredDocuments[index];
                      return DocumentCard(
                        document: doc,
                        onTap: () => _handleViewDocument(doc),
                        onMore: () => _handleDocumentOptions(doc),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
