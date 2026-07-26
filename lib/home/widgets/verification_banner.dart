import 'package:flutter/material.dart';

class VerificationBanner extends StatelessWidget {
  final bool show;
  final bool isResending;
  final Duration? resendCooldown;
  final VoidCallback onResend;
  final VoidCallback onDismiss;

  const VerificationBanner({
    super.key,
    required this.show,
    required this.isResending,
    required this.resendCooldown,
    required this.onResend,
    required this.onDismiss,
  });

  String _formatCooldown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? const Color(0xFF2D1A00) : const Color(0xFFFFF3E0);
    final borderColor =
        isDark ? const Color(0xFFBF6000) : const Color(0xFFFFB74D);
    final titleColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    final bodyColor =
        isDark ? const Color(0xFFCC8800) : const Color(0xFFF57C00);
    final iconColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);

    final bool onCooldown = resendCooldown != null;
    final bool busy = isResending;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_unread_outlined, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please check your inbox and verify your email address to secure your account.',
                  style: TextStyle(fontSize: 13, color: bodyColor, height: 1.4),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: (busy || onCooldown) ? null : onResend,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      busy
                          ? 'Sending...'
                          : onCooldown
                          ? 'Resend in ${_formatCooldown(resendCooldown!)}'
                          : 'Resend email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (busy || onCooldown) ? bodyColor : titleColor,
                        decoration:
                            (busy || onCooldown)
                                ? TextDecoration.none
                                : TextDecoration.underline,
                        decorationColor: titleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 18, color: iconColor),
          ),
        ],
      ),
    );
  }
}
