import 'package:intl/intl.dart';

import '../../share/export/screen_export.dart';
import '../helper/parent_home_helper.dart';
import '../presentation/controllers/parent_children_controller.dart';
import '../presentation/controllers/parent_schedule_controller.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  static const int _centerDayIndex = 2;

  static List<Map<String, String>> _getCenteredDays(
    String langCode, [
    DateTime? anchor,
  ]) {
    final base = anchor ?? DateTime.now();
    final formatter = DateFormat.E(langCode);
    return List.generate(5, (index) {
      // index 2 is centered on base (offset 0)
      final d = base.add(Duration(days: index - _centerDayIndex));
      final rawDay = formatter.format(d);
      final dayLabel = rawDay.isNotEmpty
          ? rawDay[0].toUpperCase() + rawDay.substring(1).replaceAll('.', '')
          : rawDay;
      return {
        'day': dayLabel,
        'date': d.day.toString(),
        'fullDate': d.toIso8601String(),
      };
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(parentScheduleControllerProvider);
    final scheduleController = ref.read(
      parentScheduleControllerProvider.notifier,
    );
    final childrenState = ref.watch(parentChildrenControllerProvider);
    final children = childrenState.children;

    final selectedChild = (children.isNotEmpty &&
            scheduleState.selectedChildIndex < children.length)
        ? children[scheduleState.selectedChildIndex]
        : (childrenState.selectedChild ??
            (children.isNotEmpty ? children.first : null));
    final childId = selectedChild?.id ?? '';

    final langCode =
        ref.watch(languageProvider).valueOrNull?.language.code ?? 'en';
    final days = _getCenteredDays(langCode, scheduleState.anchorDate);
    final now = DateTime.now();
    final selectedIndex = scheduleState.selectedDayIndex.clamp(
      0,
      days.length - 1,
    );
    final selectedDayDate = scheduleState.selectedDate;
    final isSelectedDayToday =
        selectedDayDate.day == now.day &&
        selectedDayDate.month == now.month &&
        selectedDayDate.year == now.year;
    final hasCustomYear = selectedDayDate.year != now.year;
    final selectedDayTitle = DateFormat(
      hasCustomYear ? 'EEEE, d MMM y' : 'EEEE, d MMM',
      langCode,
    ).format(selectedDayDate);

    final selectedDaySessions = scheduleState.rawSessions.where((s) {
      if (s.sessionDate == null) return true;
      return s.sessionDate!.year == selectedDayDate.year &&
          s.sessionDate!.month == selectedDayDate.month &&
          s.sessionDate!.day == selectedDayDate.day;
    }).toList();

    final effectiveSessions = selectedDaySessions.isNotEmpty
        ? selectedDaySessions
        : (scheduleState.rawSessions.every((s) => s.sessionDate == null)
              ? scheduleState.rawSessions
              : selectedDaySessions);

    final upcomingClasses = effectiveSessions
        .where((s) => s.status != 'COMPLETED')
        .map((s) => s.toClassModel())
        .toList();

    final completedClasses = effectiveSessions
        .where((s) => s.status == 'COMPLETED')
        .map((s) => s.toClassModel())
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.navSchedule),
        showBack: false,
      ),
      body: PendingPollEffect(
        hasPending: anyLocalizationPending([
          ...upcomingClasses.map((c) => c.localization),
          ...completedClasses.map((c) => c.localization),
        ]),
        onPoll: () => scheduleController.refresh(),
        child: RefreshIndicator(
          onRefresh: scheduleController.refresh,
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 30.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // =================================================
                  // STUDENT
                  // =================================================
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ref
                              .watchTr(AppStrings.studentInfoTitle)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TxtStyle.titleLarge(
                            color: AppColors.secondaryText,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${children.length} ${ref.watchTr(AppStrings.active)}',
                        style: TxtStyle.titleLarge(
                          color: AppColors.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 9.h),

                  if (children.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.backgroundsLinesColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: AppColors.subtitleTextColor,
                            size: 24.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              ref.watchTr(AppStrings.noChildrenLinked),
                              style: TxtStyle.bodyMedium(
                                color: AppColors.subtitleTextColor,
                                fontSize: 13.5.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (children.length == 1)
                    _studentCard(
                      children[0],
                      scheduleState.selectedChildIndex == 0,
                      () => scheduleController.selectChild(0),
                    )
                  else
                    SizedBox(
                      height: 74.h,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            for (int i = 0; i < children.length; i++) ...[
                              SizedBox(
                                width: 185.w,
                                height: 74.h,
                                child: _studentCard(
                                  children[i],
                                  scheduleState.selectedChildIndex == i,
                                  () => scheduleController.selectChild(i),
                                ),
                              ),
                              if (i < children.length - 1)
                                SizedBox(width: 10.w),
                            ],
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 18.h),

                  // =================================================
                  // DATE SELECTOR
                  // =================================================
                  AulaCard(
                    padding: EdgeInsets.all(14.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: InkWell(
                                      onTap: () => _openDatePicker(
                                        context,
                                        ref,
                                        selectedDayDate,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              selectedDayTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TxtStyle.titleLarge(
                                                color: AppColors.text,
                                                fontSize: 16.5.sp,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: AppColors.secondaryText,
                                            size: 22.sp,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isSelectedDayToday) ...[
                                    SizedBox(width: 6.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 7.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6EDFF),
                                        borderRadius: BorderRadius.circular(
                                          5.r,
                                        ),
                                      ),
                                      child: Text(
                                        ref.watchTr(AppStrings.today),
                                        style: TxtStyle.titleLarge(
                                          color: AppColors.primary,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    SizedBox(width: 6.w),
                                    InkWell(
                                      onTap: () =>
                                          scheduleController.resetToToday(),
                                      borderRadius: BorderRadius.circular(5.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.today_rounded,
                                              size: 12.sp,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 3.w),
                                            Text(
                                              ref.watchTr(AppStrings.today),
                                              style: TxtStyle.titleLarge(
                                                color: AppColors.primary,
                                                fontSize: 11.5.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () => _openDatePicker(
                                context,
                                ref,
                                selectedDayDate,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6EDFF),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      color: AppColors.primary,
                                      size: 15.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      ref.watchTr(AppStrings.filterByDate),
                                      style: TxtStyle.titleLarge(
                                        color: AppColors.primary,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 15.h),

                        Row(
                          children: [
                            for (int i = 0; i < days.length; i++)
                              Expanded(
                                child: _dayItem(
                                  days,
                                  i,
                                  scheduleState.selectedDayIndex == i,
                                  () => scheduleController.selectDay(
                                    i,
                                    DateTime.parse(days[i]['fullDate']!),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25.h),

                  if (scheduleState.isLoading) ...[
                    const Center( 
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (scheduleState.error != null) ...[
                    _errorCard(
                      ref,
                      scheduleState.error!,
                      () => scheduleController.loadSchedule(selectedIndex),
                    ),
                  ] else if (upcomingClasses.isEmpty &&
                      completedClasses.isEmpty) ...[
                    _emptyScheduleCard(ref),
                  ] else ...[
                    if (upcomingClasses.isNotEmpty) ...[
                      SectionHeader(
                        title: ref.watchTr(AppStrings.upcomingClasses),
                        actionText: ref.watchTr(AppStrings.remainingToday),
                      ),
                      SizedBox(height: 12.h),
                      for (final classData in upcomingClasses) ...[
                        _scheduleClassCard(context, classData),
                        SizedBox(height: 12.h),
                      ],
                    ],

                    if (completedClasses.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      SectionHeader(
                        title: ref.watchTr(AppStrings.completedEarlier),
                        actionText: ref.watchTr(AppStrings.today),
                      ),
                      SizedBox(height: 12.h),
                      for (final classData in completedClasses) ...[
                        _completedClassCard(context, ref, classData, childId: childId),
                        SizedBox(height: 12.h),
                      ],
                    ],
                  ],
                ]),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _studentCard(ChildModel student, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.backgroundsLinesColor,
            width: selected ? 1.7.w : 1.w,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 37.w,
              height: 37.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueSoft,
              ),
              child: ClipOval(
                child: student.imageUrl.isNotEmpty
                    ? Image.network(
                        student.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            UserAvatar(initials: student.initials, size: 37),
                      )
                    : UserAvatar(initials: student.initials, size: 37),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TxtStyle.titleLarge(
                      color: AppColors.text,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    student.grade,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TxtStyle.titleLarge(
                      color: AppColors.secondaryText,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayItem(
    List<Map<String, String>> days,
    int index,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(
              days[index]['day']!,
              style: TxtStyle.titleLarge(
                color: selected
                    ? Colors.white.withValues(alpha: .8)
                    : AppColors.secondaryText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              days[index]['date']!,
              style: TxtStyle.titleLarge(
                color: selected ? Colors.white : AppColors.text,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleClassCard(BuildContext context, ClassModel classData) {
    return GestureDetector(
      onTap: () {
        context.push(RoutePath.classDetail, extra: classData);
      },
      child: AulaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${classData.time} – ${classData.duration}',
                  style: TxtStyle.titleLarge(
                    color: AppColors.secondaryText,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondaryText,
                  size: 20.sp,
                ),
              ],
            ),

            SizedBox(height: 8.h),

            Row(
              children: [
                Expanded(
                  child: Text(
                    classData.subject,
                    style: TxtStyle.titleLarge(
                      color: AppColors.text,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TranslationStatusBadge.fromMeta(classData.localization),
              ],
            ),

            if (classData.teacher.trim().isNotEmpty ||
                classData.room.trim().isNotEmpty ||
                classData.building.trim().isNotEmpty) ...[
              SizedBox(height: 13.h),

              Divider(color: AppColors.backgroundsLinesColor, height: 1),

              SizedBox(height: 11.h),

              Row(
                children: [
                  if (classData.teacher.trim().isNotEmpty) ...[
                    UserAvatar(
                      initials: _teacherInitials(classData.teacher),
                      size: 31,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        classData.teacher,
                        style: TxtStyle.titleLarge(
                          color: AppColors.text,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),

                  if (classData.room.trim().isNotEmpty ||
                      classData.building.trim().isNotEmpty)
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (classData.room.trim().isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15.sp,
                                  color: AppColors.secondaryText,
                                ),
                                SizedBox(width: 3.w),
                                Flexible(
                                  child: Text(
                                    classData.room,
                                    textAlign: TextAlign.end,
                                    style: TxtStyle.titleLarge(
                                      color: AppColors.secondaryText,
                                      fontSize: 13.5.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (classData.building.trim().isNotEmpty)
                            Text(
                              classData.building,
                              textAlign: TextAlign.end,
                              style: TxtStyle.titleLarge(
                                color: AppColors.secondaryText,
                                fontSize: 13.5.sp,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _completedClassCard(
    BuildContext context,
    WidgetRef ref,
    ClassModel classData, {
    String? childId,
  }) {
    void navigateToReportDetail() {
      final reportModel = ReportModel(
        id: classData.id,
        subject: classData.subject,
        teacher: classData.teacher,
        time: '${classData.time} – ${classData.duration}',
        category: classData.category,
        dateLabel: ref.readTr(AppStrings.today),
        status: ref.readTr(AppStrings.completedPresent),
        note: '',
        initials: classData.teacher.isNotEmpty
            ? classData.teacher[0].toUpperCase()
            : 'P',
      );

      context.push(
        RoutePath.reportDetail,
        extra: {
          'childId': childId ?? '',
          'reportId': classData.id ?? '',
          'initialReport': reportModel,
        },
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: navigateToReportDetail,
      child: AulaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(text: ref.watchTr(AppStrings.completedPresent)),
                const Spacer(),
                Text(
                  '${classData.time} – ${classData.duration}',
                  style: TxtStyle.titleLarge(
                    color: AppColors.secondaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 11.h),

            Row(
              children: [
                Expanded(
                  child: Text(
                    classData.subject,
                    style: TxtStyle.titleLarge(
                      color: AppColors.text,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TranslationStatusBadge.fromMeta(classData.localization),
              ],
            ),

            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16.sp,
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          classData.teacher,
                          style: TxtStyle.titleLarge(
                            color: AppColors.secondaryText,
                            fontSize: 14.5.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(12.w),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15.sp,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      classData.room,
                      style: TxtStyle.titleLarge(
                        color: AppColors.secondaryText,
                        fontSize: 13.5.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 13.h),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: navigateToReportDetail,
                child: Text(
                  ref.watchTr(AppStrings.classReportAction),
                  style: TxtStyle.titleLarge(
                    color: AppColors.primary,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _teacherInitials(String name) {
    final parts = name.split(' ');

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }

    return name.substring(0, 2).toUpperCase();
  }

  Widget _emptyScheduleCard(WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 40.sp,
            color: AppColors.subtitleTextColor,
          ),
          SizedBox(height: 10.h),
          Text(
            ref.watchTr(AppStrings.noScheduleFound),
            textAlign: TextAlign.center,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            ref.watchTr(AppStrings.noScheduleFoundDesc),
            textAlign: TextAlign.center,
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(WidgetRef ref, String error, VoidCallback onRetry) {
    final langCode =
        ref.watch(languageProvider).valueOrNull?.languageCode ??
        LanguageNotifier.activeLanguageCode;
    final resolved = AppErrorResolver.resolve(error, languageCode: langCode);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40.sp,
            color: AppColors.redColor,
          ),
          SizedBox(height: 10.h),
          Text(
            resolved.displayMessage,
            textAlign: TextAlign.center,
            style: TxtStyle.bodyMedium(color: AppColors.text, fontSize: 14.sp),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(ref.watchTr(AppStrings.retry)),
          ),
        ],
      ),
    );
  }

  Future<void> _openDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTime initialDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: ref.readTr(AppStrings.selectDate),
      cancelText: ref.readTr(AppStrings.cancelBtn),
      confirmText: ref.readTr(AppStrings.saveBtn),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(parentScheduleControllerProvider.notifier)
          .selectCustomDate(picked);
    }
  }
}
