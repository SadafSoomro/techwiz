import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// MEMBER 1 - Shared themed alert.
///
/// Every "bottom notification" in the app (login successful, saved, deleted,
/// booking confirmed, ...) is shown through this single helper so the message
/// always matches the dark Fandom Verse theme instead of a plain snack bar.
enum AppAlertType { success, error, warning, info }

class _AlertStyle {
  const _AlertStyle(this.color, this.icon);

  final Color color;
  final IconData icon;
}

_AlertStyle _styleFor(AppAlertType type, Color? accent) {
  switch (type) {
    case AppAlertType.success:
      return _AlertStyle(accent ?? AppTheme.successColor, Icons.check_rounded);
    case AppAlertType.error:
      return _AlertStyle(accent ?? AppTheme.errorColor, Icons.close_rounded);
    case AppAlertType.warning:
      return const _AlertStyle(Color(0xFFF59E0B), Icons.priority_high_rounded);
    case AppAlertType.info:
      return _AlertStyle(accent ?? AppTheme.primaryColor, Icons.info_outline_rounded);
  }
}

/// Shows a theme-matching alert dialog and completes when it is dismissed.
///
/// Usage:
/// ```dart
/// await showAppAlert(context,
///     title: 'Login Successful',
///     message: response.message,
///     type: AppAlertType.success);
/// ```
Future<void> showAppAlert(
  BuildContext context, {
  required String message,
  String? title,
  AppAlertType type = AppAlertType.info,
  Color? accent,
  String confirmLabel = 'OK',
}) async {
  final style = _styleFor(type, accent);

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title ?? 'Alert',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => _AppAlertDialog(
      title: title,
      message: message,
      style: style,
      confirmLabel: confirmLabel,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Green "it worked" alert.
Future<void> showSuccessAlert(
  BuildContext context,
  String message, {
  String? title,
  Color? accent,
}) =>
    showAppAlert(
      context,
      message: message,
      title: title ?? 'Success',
      type: AppAlertType.success,
      accent: accent,
    );

/// Red "something went wrong" alert.
Future<void> showErrorAlert(
  BuildContext context,
  String message, {
  String? title,
  Color? accent,
}) =>
    showAppAlert(
      context,
      message: message,
      title: title ?? 'Something went wrong',
      type: AppAlertType.error,
      accent: accent,
    );

/// Neutral / informational alert.
Future<void> showInfoAlert(
  BuildContext context,
  String message, {
  String? title,
  Color? accent,
}) =>
    showAppAlert(
      context,
      message: message,
      title: title ?? 'Heads up',
      type: AppAlertType.info,
      accent: accent,
    );

/// Amber alert used for "needs attention" messages.
Future<void> showWarningAlert(
  BuildContext context,
  String message, {
  String? title,
}) =>
    showAppAlert(
      context,
      message: message,
      title: title ?? 'Please note',
      type: AppAlertType.warning,
    );

class _AppAlertDialog extends StatelessWidget {
  const _AppAlertDialog({
    required this.message,
    required this.style,
    required this.confirmLabel,
    this.title,
  });

  final String? title;
  final String message;
  final _AlertStyle style;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: style.color.withValues(alpha: 0.38),
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.color.withValues(alpha: 0.28),
                    blurRadius: 34,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --------------------------------------------- icon badge
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.color.withValues(alpha: 0.16),
                      border: Border.all(
                        color: style.color.withValues(alpha: 0.55),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: style.color.withValues(alpha: 0.45),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(style.icon, color: style.color, size: 30),
                  ),
                  const SizedBox(height: 18),

                  // --------------------------------------------- title
                  if (title != null && title!.isNotEmpty) ...[
                    Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // --------------------------------------------- message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // --------------------------------------------- confirm
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            style.color,
                            style.color.withValues(alpha: 0.78),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: style.color.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
