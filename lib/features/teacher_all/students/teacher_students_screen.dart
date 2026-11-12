import 'package:aula360/core/helper/text_utils/string_extension.dart';

import '../../parent_all/helper/parent_home_helper.dart';
import '../../share/export/screen_export.dart';
import '../helper/teacher_enums.dart';
import '../helper/teacher_models.dart';
import 'presentation/controllers/teacher_students_controller.dart';

/// ===============================================================
/// TEACHER STUDENTS SCREEN
/// ===============================================================

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() =>
      _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  AulaPagedScrollListener? _pagedListener;

  @override
  void initState() {
    super.initState();
    _pagedListener = AulaPagedScrollListener(
      controller: _scrollController,
      onLoadMore: () =>
          ref.read(teacherStudentsControllerProvider.notifier).loadMore(),
    );
  }

  @override
  void dispose() {
    _pagedListener?.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherStudentsControllerProvider);
    final controller = ref.read(teacherStudentsControllerProvider.notifier);
    final filteredStudents = state.filteredStudents;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.myStudentsTitle),
        showBack: false,
      ),
      body: PendingPollEffect(
        hasPending: anyLocalizationPending(
          state.students.map((s) => s.localization),
        ),
        onPoll: () => controller.refresh(),
        child: Column(
          children: [
          _searchSection(ref, state, controller),
          // _filterSection(ref, state, controller),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? _errorView(ref, state.error!, controller)
                : RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: filteredStudents.isEmpty
                        ? _emptyView(ref, state, controller)
                        : ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 30.h),
                            children: [
                              _rosterHeader(ref, state.students),
                              SizedBox(height: 7.h),
                              _studentList(context, ref, filteredStudents),
                              AulaPagedFooter(
                                isLoadingMore: state.isLoadingMore,
                                loadMoreError: state.loadMoreError,
                                onRetry: controller.loadMore,
                                indicatorColor: AppColors.primaryDark,
                              ),
                            ],
                          ),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _searchSection(
    WidgetRef ref,
    TeacherStudentsState state,
    TeacherStudentsController controller,
  ) {
    final hasSearch =
        state.searchQuery.isNotEmpty || _searchController.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: hasSearch
                ? AppColors.primaryDark
                : AppColors.backgroundsLinesColor,
            width: hasSearch ? 1.2 : 1.0,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: controller.setSearchQuery,
          textInputAction: TextInputAction.search,
          onSubmitted: controller.searchImmediately,
          style: TxtStyle.bodyMedium(color: AppColors.text, fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: ref.watchTr(AppStrings.searchStudentHint),
            hintStyle: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 15.sp,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20.sp,
              color: hasSearch
                  ? AppColors.primaryDark
                  : AppColors.subtitleTextColor,
            ),
            suffixIcon: hasSearch
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18.sp,
                      color: AppColors.subtitleTextColor,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      controller.clearSearch();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterSection(
    WidgetRef ref,
    TeacherStudentsState state,
    TeacherStudentsController controller,
  ) {
    return SizedBox(
      height: 42.h,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(
            ref,
            filter: StudentGroupFilter.all,
            selectedFilter: state.selectedFilter,
            label: ref.watchTr(AppStrings.allTab),
            count: state.students.length,
            onTap: () => controller.selectFilter(StudentGroupFilter.all),
          ),
          SizedBox(width: 8.w),
          _filterChip(
            ref,
            filter: StudentGroupFilter.groupA,
            selectedFilter: state.selectedFilter,
            label: ref.watchTr(StudentGroup.groupA.stringKey),
            onTap: () => controller.selectFilter(StudentGroupFilter.groupA),
          ),
          SizedBox(width: 8.w),
          _filterChip(
            ref,
            filter: StudentGroupFilter.groupB,
            selectedFilter: state.selectedFilter,
            label: ref.watchTr(StudentGroup.groupB.stringKey),
            onTap: () => controller.selectFilter(StudentGroupFilter.groupB),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    WidgetRef ref, {
    required StudentGroupFilter filter,
    required StudentGroupFilter selectedFilter,
    required String label,
    int? count,
    required VoidCallback onTap,
  }) {
    final selected = selectedFilter == filter;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 13.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected
                ? AppColors.primaryDark
                : AppColors.backgroundsLinesColor,
          ),
        ),
        child: Text(
          count == null ? label : '$label ($count)',
          style: TxtStyle.titleLarge(
            color: selected ? Colors.white : AppColors.subtitleTextColor,
            fontSize: 15.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _rosterHeader(WidgetRef ref, List<TeacherStudent> students) {
    final presentStudentsCount = students
        .where((s) => s.status == StudentStatus.present)
        .length;

    return Row(
      children: [
        Text(
          ref.watchTr(AppStrings.rosterAssignedTitle),
          style: TxtStyle.titleLarge(
            color: AppColors.subtitleTextColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: .45,
          ),
        ),
        const Spacer(),
        Container(
          width: 6.w,
          height: 6.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xff22b573),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          '$presentStudentsCount ${ref.watchTr(AppStrings.present)}',
          style: TxtStyle.bodyMedium(
            color: AppColors.subtitleTextColor,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _studentList(
    BuildContext context,
    WidgetRef ref,
    List<TeacherStudent> filteredStudents,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        children: [
          ...filteredStudents.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;

            return _studentTile(
              context,
              ref,
              student,
              showBottomBorder: index != filteredStudents.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _studentTile(
    BuildContext context,
    WidgetRef ref,
    TeacherStudent student, {
    required bool showBottomBorder,
  }) {
    return InkWell(
      onTap: () {
        context.push(RoutePath.teacherStudentDetail, extra: student.id);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? Border(
                  bottom: BorderSide(color: AppColors.backgroundsLinesColor),
                )
              : null,
        ),
        child: Row(
          children: [
            _studentAvatar(student),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          student.name.capitalizeWords(),
                          overflow: TextOverflow.ellipsis,
                          style: TxtStyle.titleLarge(
                            color: AppColors.text,
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TranslationStatusBadge.fromMeta(
                        student.localization,
                        padding: EdgeInsets.only(left: 6.w),
                      ),
                      // SizedBox(width: 6.w),
                      // Text(
                      //   student.name,
                      //   style: TxtStyle.bodyMedium(
                      //     color: AppColors.subtitleTextColor,
                      //     fontSize: 16.sp,
                      //   ),
                      // ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${ref.watchTr(student.group.stringKey)} • ${student.room} (${student.desk})',
                    style: TxtStyle.bodyMedium(
                      color: AppColors.subtitleTextColor,
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 5.w),
            _attendanceText(ref, student),
            SizedBox(width: 5.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: AppColors.subtitleTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentAvatar(TeacherStudent student) {
    return Stack(
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xffe8edf5),
          ),
          child: ClipOval(
            child: (student.avatarUrl != null && student.avatarUrl!.isNotEmpty)
                ? CustomNetworkImage(
                    imageUrl: student.avatarUrl!,
                    fit: BoxFit.cover,
                    width: 38.w,
                    height: 38.w,
                    boxShape: BoxShape.circle,
                    errorWidget: Center(
                      child: Text(
                        student.initials,
                        style: TxtStyle.titleLarge(
                          color: AppColors.primaryDark,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      student.initials,
                      style: TxtStyle.titleLarge(
                        color: AppColors.primaryDark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: student.status == StudentStatus.needsCheckIn
                  ? const Color(0xffffa726)
                  : const Color(0xff18b86b),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _attendanceText(WidgetRef ref, TeacherStudent student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${student.attendance}%',
          style: TxtStyle.titleLarge(
            color: student.status == StudentStatus.needsCheckIn
                ? const Color(0xffdf8a00)
                : const Color(0xff15965a),
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (student.status == StudentStatus.needsCheckIn)
          Text(
            ref.watchTr(student.status.stringKey),
            style: TxtStyle.bodyMedium(
              color: const Color(0xffdf8a00),
              fontSize: 11.sp,
            ),
          ),
      ],
    );
  }

  Widget _errorView(
    WidgetRef ref,
    String error,
    TeacherStudentsController controller,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: AppColors.redColor,
            ),
            SizedBox(height: 12.h),
            Text(
              ref.watchTr(AppStrings.loadStudentsError),
              style: TxtStyle.titleLarge(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              AppErrorResolver.resolve(
                error,
                languageCode:
                    ref.watch(languageProvider).valueOrNull?.languageCode ??
                    LanguageNotifier.activeLanguageCode,
              ).displayMessage,
              textAlign: TextAlign.center,
              style: TxtStyle.bodyMedium(
                fontSize: 14.sp,
                color: AppColors.subtitleTextColor,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                ref.watchTr(AppStrings.retry),
                style: TxtStyle.bodyMedium(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(
    WidgetRef ref,
    TeacherStudentsState state,
    TeacherStudentsController controller,
  ) {
    final tr = ref.watchTr;
    final isSearching = state.isSearching;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 48.sp,
              color: AppColors.subtitleTextColor,
            ),
            SizedBox(height: 12.h),
            Text(
              tr(AppStrings.noStudentsFound),
              style: TxtStyle.titleLarge(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              tr(AppStrings.noStudentsFilterDesc),
              textAlign: TextAlign.center,
              style: TxtStyle.bodyMedium(
                fontSize: 14.sp,
                color: AppColors.subtitleTextColor,
              ),
            ),
            if (isSearching) ...[
              SizedBox(height: 16.h),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  controller.clearSearch();
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(
                  ref.watchTr(AppStrings.allTab),
                  style: TxtStyle.bodyMedium(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primaryDark),
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
}
