import 'package:intl/intl.dart';

import '../../../../share/export/screen_export.dart';
import '../../../data/dtos/announcement_dto.dart';
import '../../../helper/parent_home_helper.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_announcements_controller.dart';

class ParentAnnouncementsScreen extends ConsumerStatefulWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  ConsumerState<ParentAnnouncementsScreen> createState() =>
      _ParentAnnouncementsScreenState();
}

class _ParentAnnouncementsScreenState
    extends ConsumerState<ParentAnnouncementsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(parentAnnouncementsControllerProvider.notifier).loadMore();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentAnnouncementsControllerProvider);
    final controller =
        ref.read(parentAnnouncementsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.announcementsTitle),
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.text,
              size: 22.sp,
            ),
            tooltip: 'Refresh',
            onPressed: () => controller.refresh(),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        color: AppColors.primary,
        child: _buildBody(context, ref, state, controller),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ParentAnnouncementsState state,
    ParentAnnouncementsController controller,
  ) {
    if (state.isLoading && state.announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.announcements.isEmpty) {
      return _buildErrorState(state.error!, controller);
    }

    if (state.announcements.isEmpty) {
      return _buildEmptyState(controller);
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: state.announcements.length +
          (state.isLoadingMore || state.loadMoreError != null ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        if (index >= state.announcements.length) {
          if (state.isLoadingMore) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          if (state.loadMoreError != null) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => controller.loadMore(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    ref.watchTr(AppStrings.retry),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final announcement = state.announcements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(AnnouncementDto announcement) {
    final audienceColor = _getAudienceColor(announcement.audience);
    final formattedDate =
        _formatDate(announcement.publishedAt ?? announcement.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.backgroundsLinesColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: audienceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      size: 14.sp,
                      color: audienceColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      announcement.audience.toUpperCase(),
                      style: TxtStyle.bodySmall(
                        color: audienceColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time_rounded,
                size: 14.sp,
                color: AppColors.subtitleTextColor,
              ),
              SizedBox(width: 4.w),
              Text(
                announcement.timeAgo,
                style: TxtStyle.bodySmall(
                  color: AppColors.subtitleTextColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: TxtStyle.titleMedium(
                    color: AppColors.text,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TranslationStatusBadge(
                translationStatus: announcement.translationStatus,
                isTranslated: announcement.isTranslated,
                sourceLocale: announcement.sourceLocale,
                displayedLocale: announcement.displayedLocale,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            announcement.body,
            style: TxtStyle.bodyMedium(
              color: AppColors.secondaryText,
              fontSize: 13.5.sp,
              height: 1.45,
            ),
          ),
          if (formattedDate.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Divider(
              color: AppColors.backgroundsLinesColor.withValues(alpha: 0.6),
              height: 1,
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formattedDate,
                style: TxtStyle.bodySmall(
                  color: AppColors.subtitleTextColor,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getAudienceColor(String audience) {
    switch (audience.toUpperCase()) {
      case 'PARENTS':
        return const Color(0xFF2E7D32); // Deep green
      case 'TEACHERS':
        return const Color(0xFF1565C0); // Deep blue
      case 'ALL':
      default:
        return AppColors.primary;
    }
  }

  Widget _buildEmptyState(ParentAnnouncementsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        size: 38.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      ref.watchTr(AppStrings.noAnnouncements),
                      textAlign: TextAlign.center,
                      style: TxtStyle.titleMedium(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      ref.watchTr(AppStrings.noAnnouncementsDesc),
                      textAlign: TextAlign.center,
                      style: TxtStyle.bodyMedium(
                        fontSize: 13.sp,
                        color: AppColors.subtitleTextColor,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton.icon(
                      onPressed: () => controller.refresh(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(ref.watchTr(AppStrings.retry)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    String error,
    ParentAnnouncementsController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 40.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48.sp,
                      color: Colors.redAccent,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TxtStyle.bodyMedium(
                        fontSize: 13.5.sp,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => controller.refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(ref.watchTr(AppStrings.retry)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
