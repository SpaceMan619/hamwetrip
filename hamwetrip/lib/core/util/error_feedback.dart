import 'package:flutter/material.dart';

import '../error/app_error.dart';

/// Shows [error] as a snackbar. The single place every screen routes a
/// caught [AppError] through, so failures always surface the same way
/// instead of each screen inventing its own presentation.
void showAppErrorSnackBar(BuildContext context, AppError error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: const Color(0xFF9A2424),
      ),
    );
}

/// Shows a plain success/info message, for actions with no [AppError] to
/// report (e.g. "invite code copied").
void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
