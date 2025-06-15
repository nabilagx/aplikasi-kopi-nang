import 'package:flutter/material.dart';

void showKopiNangAlert(
    BuildContext context,
    String title,
    String message, {
      String type = 'success', // bisa: 'success', 'warning', 'error'
    }) {
  IconData icon;
  Color color;
  switch (type) {
    case 'warning':
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
      break;
    case 'error':
      icon = Icons.cancel;
      color = Colors.red;
      break;
    case 'success':
    default:
      icon = Icons.check_circle;
      color = const Color(0xFF0D47A1); // Warna biru khas KOPI NANG
      break;
  }

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 60),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Oke",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
