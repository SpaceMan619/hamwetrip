import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../data/local/document_file_store.dart';
import '../../../data/models/document.dart';

/// Shows a document that this device holds the file for.
///
/// Images are drawn inline — the common case in the vault is a photo of a
/// passport or a booking confirmation, and Flutter can render those without
/// help. Everything else (PDFs, .docx) is handed to whatever app the phone
/// already has for that file type, since bundling a PDF engine to display the
/// occasional booking slip is not a trade worth making.
class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({super.key, required this.document});

  final TripDocument document;

  Future<void> _openExternally(BuildContext context) async {
    final path = document.localPath;
    if (path == null) return;

    final result = await OpenFilex.open(path);
    if (result.type == ResultType.done || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.type == ResultType.noAppToOpen
              ? 'No app on this phone can open a '
                    '${document.type.name.toUpperCase()} file.'
              : "We couldn't open that file.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = DocumentFileStore.hasFile(document.localPath);

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Spelled out rather than left to `automaticallyImplyLeading`. Every
        // other screen here turns that off and keeps the bottom bar, so the
        // default arrow is not what someone is looking for on this one.
        leading: IconButton(
          tooltip: 'Back to the vault',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(document.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (hasFile)
            IconButton(
              tooltip: 'Open in another app',
              onPressed: () => _openExternally(context),
              icon: const Icon(Icons.open_in_new, color: AppColors.forest),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(child: _body(context, hasFile: hasFile)),
          ),
          _Details(document: document),
        ],
      ),
      // Kept, unlike the other pushed detail screens. A document is opened
      // from a tab and read on the spot; losing the bar makes the screen feel
      // like somewhere you fell into rather than somewhere you navigated to.
      bottomNavigationBar: const HamweBottomNavigation(
        selected: HamweDestination.vault,
      ),
    );
  }

  Widget _body(BuildContext context, {required bool hasFile}) {
    if (!hasFile) {
      return const _Placeholder(
        icon: Icons.cloud_off_outlined,
        title: 'Not on this device',
        message:
            'This document was added on another phone, so only its details '
            'are here. Ask whoever uploaded it to share the file.',
      );
    }

    if (document.type == DocType.image) {
      return InteractiveViewer(
        maxScale: 5,
        child: Image.file(
          File(document.localPath!),
          fit: BoxFit.contain,
          // A file can be present but unreadable — a half-written copy, or an
          // extension that lied about what the bytes are.
          errorBuilder: (context, error, stack) => const _Placeholder(
            icon: Icons.broken_image_outlined,
            title: "Can't show this image",
            message: 'The file is on this device but could not be read.',
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            document.type == DocType.pdf
                ? Icons.picture_as_pdf
                : Icons.description,
            size: 64,
            color: document.type == DocType.pdf
                ? Colors.redAccent
                : Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          Text(
            document.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openExternally(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open document'),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.document});

  final TripDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.category,
              style: const TextStyle(
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${document.type.name.toUpperCase()} • ${document.fileSize}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Added by ${document.uploadedBy}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
