import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, warning, info }

class ModernToast {
  static OverlayEntry? _currentToast;

  static void show(
    BuildContext context,
    String message, {
    ToastType? type,
    Duration duration = const Duration(seconds: 3),
    String? title,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    // Support both positional and named arguments
    _showToast(
      context,
      message: message,
      type: type ?? ToastType.info,
      duration: duration,
      title: title,
      icon: icon,
      onTap: onTap,
    );
  }

  static void _showToast(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final config = _getToastConfig(type);
    
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: onTap,
            child: ToastWidget(
              message: message,
              title: title,
              icon: icon ?? config.icon,
              backgroundColor: config.backgroundColor,
              borderColor: config.borderColor,
              textColor: config.textColor,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _currentToast = entry;

    Timer(duration, () {
      entry.remove();
      if (_currentToast == entry) {
        _currentToast = null;
      }
    });
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context,
      message,
      title: title,
      type: ToastType.success,
      duration: duration,
      onTap: onTap,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    show(
      context,
      message,
      title: title,
      type: ToastType.error,
      duration: duration,
      onTap: onTap,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context,
      message,
      title: title,
      type: ToastType.warning,
      duration: duration,
      onTap: onTap,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    show(
      context,
      message,
      title: title,
      type: ToastType.info,
      duration: duration,
      onTap: onTap,
    );
  }

  static void hide() {
    _currentToast?.remove();
    _currentToast = null;
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          backgroundColor: AppTheme.successColor.withOpacity(0.15),
          borderColor: AppTheme.successColor,
          textColor: AppTheme.successColor,
          icon: Icons.check_circle_outline,
        );
      case ToastType.error:
        return _ToastConfig(
          backgroundColor: AppTheme.errorColor.withOpacity(0.15),
          borderColor: AppTheme.errorColor,
          textColor: AppTheme.errorColor,
          icon: Icons.error_outline,
        );
      case ToastType.warning:
        return _ToastConfig(
          backgroundColor: AppTheme.warningColor.withOpacity(0.15),
          borderColor: AppTheme.warningColor,
          textColor: AppTheme.warningColor,
          icon: Icons.warning_outlined,
        );
      case ToastType.info:
        return _ToastConfig(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
          borderColor: AppTheme.primaryColor,
          textColor: AppTheme.primaryColor,
          icon: Icons.info_outline,
        );
    }
  }
}

class _ToastConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  _ToastConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });
}

class ToastWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const ToastWidget({
    super.key,
    required this.message,
    this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: borderColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: AppTheme.titleMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: -1.0, duration: 400.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 300.ms);
  }
}

class LoadingOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, {String? message}) {
    hide();
    
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: AppTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
