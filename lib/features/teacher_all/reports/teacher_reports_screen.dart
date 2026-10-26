import '../../parent_all/helper/parent_home_helper.dart';
import '../../share/export/screen_export.dart';
import '../helper/teacher_enums.dart';
import '../helper/teacher_models.dart';
import 'presentation/controllers/teacher_reports_controller.dart';

/// ===============================================================
/// REPORTS SCREEN
/// ===============================================================

class TeacherReportsScreen extends ConsumerStatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  ConsumerState<TeacherReportsScreen> createState() =>
      _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends ConsumerState<TeacherReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (_isSearchOpen) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        ref.read(teacherReportsControllerProvider.notifier).clearSearch();
        _searchFocusNode.unfocus();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(teacherReportsControllerProvider.notifier).clearSearch();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherReportsControllerProvider);
    final controller = ref.read(teacherReportsControllerProvider.notifier);
    final filteredReports = state.filteredReports;
    final isQueryActive = state.searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AulaAppBar(
        title: _isSearchOpen ? '' : ref.watchTr(AppStrings.allReports),
        showBack: false,
        leadingWidth: _isSearchOpen ? double.infinity : null,
        leading: _isSearchOpen
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (val) => controller.setSearchQuery(val),
                          style: TxtStyle.bodyMedium(
                            color: AppColors.text,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: ref.watchTr(AppStrings.searchReportsHint),
                            hintStyle: TxtStyle.bodyMedium(
                              color: AppColors.subtitleTextColor,
                              fontSize: 13.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.subtitleTextColor,
                              size: 19.sp,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: AppColors.subtitleTextColor,
                                      size: 17.sp,
                                    ),
                                    onPressed: _clearSearch,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                : null,
                            contentPadding: EdgeInsets.symmetric(vertical: 9.h),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.subtitleTextColor,
                        size: 22.sp,
                      ),
                      onPressed: _toggleSearch,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              )
            : null,
        actions: _isSearchOpen
            ? null
            : [
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: AppColors.text,
                    size: 21.sp,
                  ),
                  onPressed: _toggleSearch,
                  tooltip: ref.watchTr(AppStrings.searchReportsHint),
                ),
                SizedBox(width: 8.w),
              ],
      ),
      body: (state.isLoading && state.reports.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : (state.error != null && state.reports.isEmpty)
              ? _errorState(ref, state.error!, controller)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isSearchOpen) ...[
                      _header(ref, state.reports.length),
                      _searchBar(controller),
                      _statusFilters(ref, state.statusFilter, controller),
                    ],
                    if (isQueryActive)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${filteredReports.length} ${filteredReports.length == 1 ? ref.watchTr(AppStrings.searchResultCount) : ref.watchTr(AppStrings.searchResultsCount)}',
                              style: TxtStyle.bodyMedium(
                                color: AppColors.subtitleTextColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _clearSearch,
                              child: Text(
                                ref.watchTr(AppStrings.allReports),
                                style: TxtStyle.bodyMedium(
                                  color: AppColors.primary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.refresh,
                        color: AppColors.primary,
                        child: filteredReports.isEmpty
                            ? _emptySearchState(
                                ref,
                                isQueryActive,
                                state.reports.isNotEmpty,
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 30.h),
                                itemCount: filteredReports.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 9.h),
                                    child: _reportCard(
                                      context,
                                      ref,
                                      filteredReports[index],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _searchBar(TeacherReportsController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9.r),
          border: Border.all(color: AppColors.backgroundsLinesColor),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => controller.setSearchQuery(val),
          style: TxtStyle.bodyMedium(color: AppColors.text, fontSize: 14.sp),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: ref.watchTr(AppStrings.searchReportsHint),
            hintStyle: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.subtitleTextColor,
              size: 19.sp,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.subtitleTextColor,
                      size: 17.sp,
                    ),
                    onPressed: _clearSearch,
                    padding: EdgeInsets.zero,
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(vertical: 9.h),
          ),
        ),
      ),
    );
  }

  Widget _emptySearchState(
    WidgetRef ref,
    bool isQueryActive, [
    bool hasAnyReports = true,
  ]) {
    if (!hasAnyReports) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primaryDark,
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                ref.watchTr(AppStrings.noCompletedClassReports),
                textAlign: TextAlign.center,
                style: TxtStyle.titleLarge(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                ref.watchTr(AppStrings.noCompletedClassReportsDesc),
                textAlign: TextAlign.center,
                style: TxtStyle.bodyMedium(
                  color: AppColors.subtitleTextColor,
                  fontSize: 13.5.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 40.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: AppColors.primary,
                size: 27.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              ref.watchTr(AppStrings.noReportsMatchSearch),
              textAlign: TextAlign.center,
              style: TxtStyle.titleLarge(
                color: AppColors.text,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              ref.watchTr(AppStrings.noReportsForCategory),
              textAlign: TextAlign.center,
              style: TxtStyle.bodyMedium(
                color: AppColors.subtitleTextColor,
                fontSize: 13.5.sp,
              ),
            ),
            if (isQueryActive) ...[
              SizedBox(height: 14.h),
              OutlinedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  ref.watchTr(AppStrings.allReports),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _header(WidgetRef ref, int totalCount) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 11.h, 16.w, 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watchTr(AppStrings.allReports),
                  style: TxtStyle.titleLarge(
                    color: AppColors.text,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  ref.watchTr(AppStrings.recordedSessionsSubtitle),
                  style: TxtStyle.bodyMedium(
                    color: AppColors.subtitleTextColor,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Text(
              '$totalCount ${ref.watchTr(AppStrings.inTotal)}',
              style: TxtStyle.bodyMedium(
                color: AppColors.primary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilters(
    WidgetRef ref,
    String? currentFilter,
    TeacherReportsController controller,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          _statusPill(
            label: ref.watchTr(AppStrings.allTab),
            isSelected: currentFilter == null,
            onTap: () => controller.setStatusFilter(null),
          ),
          SizedBox(width: 8.w),
          _statusPill(
            label: ref.watchTr(AppStrings.submitted),
            isSelected: currentFilter == 'SUBMITTED',
            onTap: () => controller.setStatusFilter('SUBMITTED'),
          ),
          SizedBox(width: 8.w),
          _statusPill(
            label: ref.watchTr(AppStrings.reviewed),
            isSelected: currentFilter == 'REVIEWED',
            onTap: () => controller.setStatusFilter('REVIEWED'),
          ),
        ],
      ),
    );
  }

  Widget _statusPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.backgroundsLinesColor,
          ),
        ),
        child: Text(
          label,
          style: TxtStyle.titleLarge(
            color: isSelected ? Colors.white : AppColors.secondaryText,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _errorState(
    WidgetRef ref,
    String error,
    TeacherReportsController controller,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48.sp, color: Colors.redAccent),
            SizedBox(height: 12.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TxtStyle.bodyMedium(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => controller.loadReports(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(
    BuildContext context,
    WidgetRef ref,
    TeacherReport report,
  ) {
    final isReviewed = report.rawStatus.toUpperCase() == 'REVIEWED' ||
        report.status == ReportStatus.reviewed;

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () {
        context.push(RoutePath.teacherReportDetail, extra: report);
      },
      child: Container(
        padding: EdgeInsets.all(11.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.backgroundsLinesColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _reportLocation(ref, report),
                    style: TxtStyle.bodyMedium(
                      color: AppColors.subtitleTextColor,
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isReviewed
                        ? const Color(0xFFE7FAF2)
                        : AppColors.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    isReviewed
                        ? ref.watchTr(AppStrings.reviewed)
                        : ref.watchTr(AppStrings.submitted),
                    style: TxtStyle.bodyMedium(
                      color: isReviewed
                          ? const Color(0xff18b86b)
                          : AppColors.primaryDark,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: TxtStyle.titleLarge(
                      color: AppColors.text,
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.subtitleTextColor,
                  size: 19.sp,
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              report.subtitle,
              style: TxtStyle.bodyMedium(
                color: AppColors.subtitleTextColor,
                fontSize: 15.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${report.date}  •  ${report.time}',
              style: TxtStyle.bodyMedium(
                color: AppColors.subtitleTextColor,
                fontSize: 13.5.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _reportLocation(WidgetRef ref, TeacherReport report) {
    if (report.category == ReportCategory.studentReport) {
      return '${report.studentName} (${report.studentId}) • ${ref.watchTr(AppStrings.aula1)}';
    }

    if (report.cohortName != null && report.cohortName!.isNotEmpty) {
      return report.cohortName!;
    }

    return '${ref.watchTr(report.group.stringKey)} • ${report.grade ?? ''} • ${report.room ?? ""}';
  }
}
