import 'package:flutter/material.dart';

class OfflineStatusBar extends StatelessWidget {
  const OfflineStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: const Color(0xFFE0A458).withOpacity(0.15),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 14,
            color: Color(0xFFB87A1B),
          ), // Darker muted amber for icon
          SizedBox(width: 6),
          Text(
            'Working Offline — Changes will sync later.',
            style: TextStyle(
              color: Color(0xFF8A6310), // Dark muted amber for text
              fontSize: 12, // label-md size
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
