import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/document.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
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
              Expanded(
                flex: 3,
                child: Container(
                  color: AppColors.warmSand,
                  child: Center(
                    child: Icon(_fileIcon, size: 42, color: _iconColor),
                  ),
                ),
              ),
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
    );
  }
}
