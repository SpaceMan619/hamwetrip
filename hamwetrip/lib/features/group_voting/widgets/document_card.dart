import 'package:flutter/material.dart';
import '../models/document.dart';

class DocumentCard extends StatelessWidget {
  final TripDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onMore,
  });

  IconData get _fileIcon {
    switch (document.type) {
      case DocType.pdf:
        return Icons.picture_as_pdf;
      case DocType.image:
        return Icons.image;
      case DocType.document:
        return Icons.description;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (document.type) {
      case DocType.pdf:
        return Colors.redAccent;
      case DocType.image:
        return Colors.teal;
      case DocType.document:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = _getIconColor(colorScheme);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top: File Icon Area
              Expanded(
                flex: 3,
                child: Container(
                  color: colorScheme.surfaceContainerLow.withOpacity(0.5),
                  child: Center(
                    child: Icon(_fileIcon, size: 42, color: iconColor),
                  ),
                ),
              ),

              // Bottom: Details Area
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        document.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),

                      // Meta Info
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${document.type.name.toUpperCase()} • ${document.fileSize}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // 3-dot menu
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: onMore,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Uploader
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              document.uploadedByInitials,
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            document.uploadedBy,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
