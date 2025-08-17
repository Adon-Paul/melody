import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassToast {
  static OverlayEntry? _currentToast;

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  Color backgroundColor = const Color(0xCC1B5E20), // dark green with opacity
    Color textColor = Colors.white,
  double blurSigma = 16.0,
    double borderRadius = 24.0,
    double fontSize = 16.0,
    IconData? icon,
  }) {

    _currentToast?.remove();
    _currentToast = null;

    // If the background color is a shade of red, make it more glassy
    Color effectiveBackground = backgroundColor;
    double effectiveBlur = blurSigma;
    // Check if the background color is red-ish (error toast)
    if ((backgroundColor.red > 180 && backgroundColor.green < 100 && backgroundColor.blue < 100)) {
      // More translucent and more blur for error toasts
      effectiveBackground = backgroundColor.withOpacity(0.55);
      effectiveBlur = blurSigma + 8.0;
    }

    // IMPORTANT: The context passed to GlassToast.show must be from a widget below MaterialApp or Navigator.
    // Otherwise, Overlay.of(context) may throw an assertion error.
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 56,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: effectiveBackground,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: fontSize + 4),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.2)),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _currentToast = entry;
    Timer(duration, () {
      entry.remove();
      if (_currentToast == entry) _currentToast = null;
    });
  }
}
