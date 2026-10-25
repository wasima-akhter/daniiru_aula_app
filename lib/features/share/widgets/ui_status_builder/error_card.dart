import 'package:aula360/features/share/export/screen_export.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    required this.onTap,
    this.title,
    this.message,
    this.buttonText,
    this.icon,
    this.iconColor,
    this.showIcon = true,
    this.showShadow = false,
  });

  final VoidCallback onTap;
  final String? title;
  final String? message;
  final String? buttonText;
  final IconData? icon;
  final Color? iconColor;
  final bool showIcon;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resolved = message != null
        ? AppErrorResolver.resolve(
            message,
            languageCode: LanguageNotifier.activeLanguageCode,
          )
        : null;

    final isSpanish =
        LanguageNotifier.activeLanguageCode.toLowerCase().startsWith('es');
    final displayTitle = title ??
        resolved?.title ??
        (isSpanish ? 'Ha ocurrido un error' : 'Something went wrong');
    final displayMessage = resolved?.displayMessage ??
        (isSpanish
            ? 'Ha ocurrido un error inesperado. Inténtalo de nuevo.'
            : 'An unexpected error occurred. Please try again.');
    final displayButton = buttonText ?? (isSpanish ? 'Reintentar' : 'Retry');

    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (iconColor ?? AppColors.error).withValues(alpha: 0.15),
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(
                  icon ?? Icons.error_outline,
                  color: iconColor ?? AppColors.error,
                  size: 42,
                ),
              ),
            const Gap(16),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const Gap(8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.tertiaryTextColor,
                height: 1.4,
              ),
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueTextColor200,
                minimumSize: const Size(140, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                displayButton,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RetryButton extends StatelessWidget {
  final VoidCallback? onTap;
  const RetryButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          AppStrings.retry,
          style: context.bodySmall.copyWith(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
