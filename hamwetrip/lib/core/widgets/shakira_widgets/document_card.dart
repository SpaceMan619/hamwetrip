import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/document.dart';

class DocumentCard extends StatelessWidget {
  final TripDocument document;

  /// Whether the file itself is on this device. Unlike the expense and
  /// itinerary cards, where the badge means "written to Firestore", a document
  /// is only useful offline if its bytes are here — so that is what the badge
  /// reports, and what decides whether a thumbnail can be drawn.
  final bool isAvailableOffline;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const DocumentCard({
    super.key,
    required this.document,
    this.isAvailableOffline = true,
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

  Color get _iconColor {
    switch (document.type) {
      case DocType.pdf:
        return Colors.redAccent;
      case DocType.image:
        return AppColors.forest;
      case DocType.document:
        return Colors.blueAccent;
    }
  }

  /// The top band of the card: the picture itself when the document is an
  /// image this device holds, and the type icon otherwise.
  Widget _preview() {
    final path = document.localPath;
    if (isAvailableOffline && document.type == DocType.image && path != null) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        // Falls back to the icon rather than Flutter's grey error box if the
        // file turns out not to be a decodable image.
        errorBuilder: (context, error, stack) => _iconPreview(),
      );
    }
    return _iconPreview();
  }

  Widget _iconPreview() => Container(
    color: AppColors.warmSand,
    child: Center(child: Icon(_fileIcon, size: 42, color: _iconColor)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Updated to 0.5rem radius
        border: Border.all(color: AppColors.line),
      ),
      // Moved clipBehavior here so the Stack's positioned icon isn't cut off
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Existing layout
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8), // Updated radius
            // Removed clipBehavior from here
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _preview()),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              height: 1.3,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${document.type.name.toUpperCase()} • ${document.fileSize}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.muted,
                                  ),
                                  onPressed: onMore,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.paleMint,
                                child: Text(
                                  document.uploadedByInitials,
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                document.uploadedBy,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
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

          // NEW: Clear "Sync Status" icon in the top right corner
          // It sits perfectly over the WarmSand image area
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAvailableOffline
                    ? Icons.offline_pin_outlined
                    : Icons.cloud_off_outlined,
                size: 14, // Slightly smaller to fit the document grid nicely
                color: isAvailableOffline ? AppColors.forest : AppColors.sunset,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
