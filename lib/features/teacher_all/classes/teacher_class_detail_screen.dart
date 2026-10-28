import 'package:intl/intl.dart';

import '../../parent_all/helper/parent_home_helper.dart';
import '../../share/export/screen_export.dart';
import '../data/dtos/class_session_dto.dart';
import '../helper/teacher_models.dart';
import '../home/presentation/controllers/teacher_home_controller.dart';
import '../homework/presentation/widgets/assign_homework_bottom_sheet.dart';
import 'presentation/controllers/teacher_classes_controller.dart';
import 'presentation/providers/teacher_classes_providers.dart';

/// ===============================================================
/// CLASS DETAILS SCREEN
/// Fetches and displays class session details by ID from:
/// GET /api/v1/teacher/sessions/{id}
/// ===============================================================

class TeacherClassDetailScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final AcademyClass? academyClass;

  const TeacherClassDetailScreen({
    super.key,
    this.sessionId,
    this.academyClass,
  });

  @override
  ConsumerState<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState
    extends ConsumerState<TeacherClassDetailScreen> {
  String? _effectiveId;

  @override
  void initState() {
    super.initState();
    // Compute effective ID and invalidate provider so data is always fresh
    // when this screen is visited.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final classesState = ref.read(teacherClassesControllerProvider);
      _effectiveId = (widget.sessionId != null && widget.sessionId!.isNotEmpty)
          ? widget.sessionId
          : (widget.academyClass?.id.isNotEmpty == true
                ? widget.academyClass!.id
                : (classesState.todayClasses.isNotEmpty
                      ? classesState.todayClasses.first.id
                      : (classesState.upcomingClasses.isNotEmpty
                            ? classesState.upcomingClasses.first.id
                            : null)));
      if (_effectiveId != null) {
        ref.invalidate(teacherSessionDetailProvider(_effectiveId!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesState = ref.watch(teacherClassesControllerProvider);
    final effectiveId = (widget.sessionId != null && widget.sessionId!.isNotEmpty)
        ? widget.sessionId
        : (widget.academyClass?.id.isNotEmpty == true
              ? widget.academyClass!.id
              : (classesState.todayClasses.isNotEmpty
                    ? classesState.todayClasses.first.id
                    : (classesState.upcomingClasses.isNotEmpty
                          ? classesState.upcomingClasses.first.id
                          : null)));

    if (effectiveId == null) {
      return _buildNoClassScreen(ref);
    }

    final sessionDetailAsync = ref.watch(
      teacherSessionDetailProvider(effectiveId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.classDetailsTitle),
        showBack: true,
      ),
      body: sessionDetailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    ref.watchTr(AppStrings.somethingWentWrong),
                    style: TxtStyle.titleLarge(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    AppErrorResolver.resolve(
                      error,
                      languageCode:
                          ref
                              .watch(languageProvider)
                              .valueOrNull
                              ?.languageCode ??
                          LanguageNotifier.activeLanguageCode,
                    ).displayMessage,
                    textAlign: TextAlign.center,
                    style: TxtStyle.bodyMedium(
                      color: AppColors.subtitleTextColor,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  AulaPrimaryButton(
                    text: ref.watchTr(AppStrings.retry),
                    onTap: () {
                      ref.invalidate(teacherSessionDetailProvider(effectiveId));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (session) => RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: () async {
            ref.invalidate(teacherSessionDetailProvider(effectiveId));
            await ref.read(teacherSessionDetailProvider(effectiveId).future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 19.h, 16.w, 35.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _groupLabel(ref, session),
                      SizedBox(height: 7.h),
                      Text(
                        '${session.subjectName}\n(${session.cohortName})',
                        style: TxtStyle.titleLarge(
                          color: AppColors.text,
                          fontSize: 27.sp,
                          height: 1.16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.4,
                        ),
                      ),
                      SizedBox(height: 17.h),
                      Divider(
                        color: AppColors.backgroundsLinesColor,
                        height: 1,
                      ),
                      SizedBox(height: 17.h),
                      _detailsRow(
                        label: ref.watchTr(AppStrings.dateTime),
                        value: _formatSessionDateTime(ref, session),
                      ),
                      _divider(),
                      _detailsRow(
                        label: ref.watchTr(AppStrings.classroom),
                        value: session.classroomRoomNumber.isNotEmpty
                            ? session.classroomRoomNumber
                            : ref.watchTr(AppStrings.aula2),
                      ),
                      _divider(),
                      _detailsRow(
                        label: ref.watchTr(AppStrings.enrollment),
                        value:
                            '${session.students.length} ${ref.watchTr(AppStrings.studentsCount)}',
                      ),
                      SizedBox(height: 23.h),
                      Divider(
                        color: AppColors.backgroundsLinesColor,
                        height: 1,
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        ref.watchTr(AppStrings.sessionInfoTitle),
                        style: TxtStyle.titleLarge(
                          color: AppColors.subtitleTextColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _infoCard(
                        title: ref.watchTr(AppStrings.todaysTopic),
                        value: _resolveTopic(session),
                      ),
                      SizedBox(height: 10.h),
                      _roomStatusCard(ref, session),
                      SizedBox(height: 14.h),
                      _sessionActivitiesChecklist(context, ref, session),
                      if (session.students.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _studentRosterCard(ref, session.students),
                      ],
                      if (session.hasReport && session.report != null) ...[
                        _reportCard(ref, session.report!),
                      ],
                      if (session.hasHomework &&
                          session.homework != null &&
                          session.homework!.isNotEmpty) ...[
                        _homeworkCard(ref, session.homework!),
                      ],
                      SizedBox(height: 34.h),
                      _buildActionButtons(context, ref, session),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoClassScreen(WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.classDetailsTitle),
        showBack: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primaryDark,
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                ref.watchTr(AppStrings.noClassesToday),
                textAlign: TextAlign.center,
                style: TxtStyle.titleLarge(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                ref.watchTr(AppStrings.noClassesTodayDesc),
                textAlign: TextAlign.center,
                style: TxtStyle.bodyMedium(
                  color: AppColors.subtitleTextColor,
                  fontSize: 13.5.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSessionDateTime(WidgetRef ref, ClassSessionDto session) {
    DateTime? date;
    if (session.sessionDate.isNotEmpty) {
      date = DateTime.tryParse(session.sessionDate);
    }
    final langCode =
        ref.watch(languageProvider).valueOrNull?.language.code ?? 'en';
    final formattedDate = date != null
        ? DateFormat('d MMM', langCode).format(date.toLocal())
        : DateFormat('d MMM', langCode).format(DateTime.now());

    final isToday = date != null
        ? (date.toLocal().year == DateTime.now().year &&
              date.toLocal().month == DateTime.now().month &&
              date.toLocal().day == DateTime.now().day)
        : true;
    final prefix = isToday ? '${ref.watchTr(AppStrings.today)}, ' : '';
    final timeRange =
        (session.startTime.isNotEmpty && session.endTime.isNotEmpty)
        ? '${session.startTime} - ${session.endTime}'
        : session.startTime;
    return '$prefix$formattedDate • $timeRange';
  }

  String _resolveTopic(ClassSessionDto session) {
    if (session.report != null &&
        session.report!['contentCovered'] is String &&
        (session.report!['contentCovered'] as String).isNotEmpty) {
      return session.report!['contentCovered'] as String;
    }
    return session.cohortName.isNotEmpty
        ? session.cohortName
        : session.subjectName;
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ClassSessionDto session,
  ) {
    final classesState = ref.watch(teacherClassesControllerProvider);
    final classesController = ref.read(
      teacherClassesControllerProvider.notifier,
    );

    if (session.status == 'SCHEDULED') {
      return SizedBox(
        width: double.infinity,
        child: AulaPrimaryButton(
          isLoading: classesState.isStartingSession,
          onTap: classesState.isStartingSession
              ? null
              : () async {
                  final success = await classesController.startSession(
                    session.id,
                  );
                  if (context.mounted) {
                    if (success) {
                      ref.invalidate(teacherSessionDetailProvider(session.id));
                      ref
                          .read(teacherHomeControllerProvider.notifier)
                          .loadHomeData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.emeraldGreenColor,
                          content: Text(
                            ref.watchTr(AppStrings.startClassSuccess),
                          ),
                        ),
                      );
                    } else {
                      final err = ref
                          .read(teacherClassesControllerProvider)
                          .actionError;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(
                            err ?? ref.watchTr(AppStrings.startClassError),
                          ),
                        ),
                      );
                    }
                  }
                },
          text: ref.watchTr(AppStrings.startClassBtn),
          backgroundColor: AppColors.primaryDark,
          trailing: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
      );
    } else if (session.status == 'COMPLETED') {
      final hasPendingActivities =
          !session.hasAttendance || !session.hasHomework || !session.hasReport;

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.softSlateBgColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.emeraldGreenColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  ref.watchTr(AppStrings.classCompletedBadge),
                  style: TxtStyle.titleMedium(
                    color: AppColors.emeraldGreenColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasPendingActivities) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFFD97706),
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      ref.watchTr(AppStrings.pendingActivitiesAlert),
                      style: TxtStyle.bodySmall(
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: AulaPrimaryButton(
              onTap: () async {
                await context.push(
                  RoutePath.teacherAttendance,
                  extra: session.id,
                );
                ref.invalidate(teacherSessionDetailProvider(session.id));
                ref
                    .read(teacherClassesControllerProvider.notifier)
                    .loadClasses();
                ref.read(teacherHomeControllerProvider.notifier).loadHomeData();
              },
              text: ref.watchTr(AppStrings.takeAttendance),
              trailing: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(
                  color: AppColors.primaryDark,
                  width: 1.5,
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: () async {
                await context.push(
                  RoutePath.teacherEndClass,
                  extra: session.id,
                );
                ref.invalidate(teacherSessionDetailProvider(session.id));
                ref
                    .read(teacherClassesControllerProvider.notifier)
                    .loadClasses();
                ref.read(teacherHomeControllerProvider.notifier).loadHomeData();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_circle_outlined, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    ref.watchTr(AppStrings.endClassTitle),
                    style: TxtStyle.titleMedium(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _groupLabel(WidgetRef ref, ClassSessionDto session) {
    final groupName = session.cohortName.isNotEmpty
        ? session.cohortName
        : session.subjectName;
    return Text(
      '${groupName.toUpperCase()} • ${ref.watchTr(AppStrings.bachillerato1).toUpperCase()}',
      style: TxtStyle.bodyMedium(
        color: AppColors.subtitleTextColor,
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: .4,
      ),
    );
  }

  Widget _detailsRow({required String label, required String value}) {
    return Row(
      children: [
        Text(
          label,
          style: TxtStyle.bodyMedium(
            color: AppColors.subtitleTextColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Divider(color: AppColors.backgroundsLinesColor, height: 1),
    );
  }

  Widget _infoCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TxtStyle.labelLarge(
              color: AppColors.subtitleTextColor,
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 16.5.sp,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomStatusCard(WidgetRef ref, ClassSessionDto session) {
    final roomName = session.classroomRoomNumber.isNotEmpty
        ? session.classroomRoomNumber
        : ref.watchTr(AppStrings.aula2);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 20.sp,
            color: AppColors.subtitleTextColor,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '$roomName • ${ref.watchTr(AppStrings.floor1)}',
              style: TxtStyle.bodyMedium(
                color: AppColors.subtitleTextColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xffe8f8f0),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              ref.watchTr(AppStrings.activeStatus),
              style: TxtStyle.labelLarge(
                color: AppColors.emeraldGreenColor,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentRosterCard(
    WidgetRef ref,
    List<SessionDetailStudentDto> students,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ref.watchTr(AppStrings.rosterAssignedTitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TxtStyle.labelLarge(
                    color: AppColors.subtitleTextColor,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${students.length} ${ref.watchTr(AppStrings.studentsCount)}',
                style: TxtStyle.bodySmall(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length > 5 ? 5 : students.length,
            separatorBuilder: (context, index) => Divider(
              color: AppColors.backgroundsLinesColor.withValues(alpha: 0.5),
              height: 16.h,
            ),
            itemBuilder: (context, index) {
              final student = students[index];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 16.r,
                    backgroundColor: AppColors.primaryDark.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage:
                        (student.avatarUrl != null &&
                            student.avatarUrl!.isNotEmpty)
                        ? NetworkImage(student.avatarUrl!)
                        : null,
                    child:
                        (student.avatarUrl == null ||
                            student.avatarUrl!.isEmpty)
                        ? Text(
                            student.initials,
                            style: TxtStyle.labelSmall(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: TxtStyle.titleMedium(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (student.enrollmentNumber.isNotEmpty)
                          Text(
                            student.enrollmentNumber,
                            style: TxtStyle.bodySmall(
                              color: AppColors.subtitleTextColor,
                              fontSize: 12.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (student.attendanceStatus != null &&
                      student.attendanceStatus!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: _attendanceBadgeColor(
                          student.attendanceStatus!,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        student.attendanceStatus!,
                        style: TxtStyle.labelSmall(
                          color: _attendanceBadgeColor(
                            student.attendanceStatus!,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (students.length > 5) ...[
            SizedBox(height: 8.h),
            Center(
              child: Text(
                '+ ${students.length - 5} ${ref.watchTr(AppStrings.inTotal)}',
                style: TxtStyle.bodySmall(
                  color: AppColors.subtitleTextColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reportCard(WidgetRef ref, Map<String, dynamic> report) {
    final observations = report['observations'] as String?;
    final homework = report['homeworkAssigned'] as String?;
    if ((observations == null || observations.isEmpty) &&
        (homework == null || homework.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      margin: EdgeInsets.only(top: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.watchTr(AppStrings.latestClassReportTitle),
            style: TxtStyle.labelLarge(
              color: AppColors.subtitleTextColor,
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (observations != null && observations.isNotEmpty) ...[
            SizedBox(height: 5.h),
            Text(
              observations,
              style: TxtStyle.bodyMedium(
                color: AppColors.text,
                fontSize: 14.sp,
              ),
            ),
          ],
          if (homework != null && homework.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 16.sp,
                  color: AppColors.primaryDark,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    homework,
                    style: TxtStyle.bodySmall(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _homeworkCard(WidgetRef ref, List<dynamic> homeworkList) {
    if (homeworkList.isEmpty) return const SizedBox.shrink();
    final first = homeworkList.first;
    if (first is! Map) return const SizedBox.shrink();
    final title = first['title'] as String? ?? '';
    final description = first['description'] as String?;
    final dueDateRaw = first['dueDate'] as String?;

    String formattedDueDate = '';
    if (dueDateRaw != null && dueDateRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(dueDateRaw);
        final lang =
            ref.watch(languageProvider).valueOrNull?.language.code ?? 'en';
        formattedDueDate = DateFormat('d MMM, yyyy', lang).format(dt);
      } catch (_) {
        formattedDueDate = dueDateRaw;
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      margin: EdgeInsets.only(top: 10.h),
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
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 16.sp,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  ref.watchTr(AppStrings.homeworkActivityTitle),
                  style: TxtStyle.labelLarge(
                    color: AppColors.subtitleTextColor,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (formattedDueDate.isNotEmpty)
                Text(
                  '${ref.watchTr(AppStrings.dueDateLabel)}: $formattedDueDate',
                  style: TxtStyle.labelSmall(
                    color: AppColors.subtitleTextColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (title.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              title,
              style: TxtStyle.titleMedium(
                color: AppColors.text,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (description != null && description.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TxtStyle.bodySmall(
                color: AppColors.subtitleTextColor,
                fontSize: 13.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sessionActivitiesChecklist(
    BuildContext context,
    WidgetRef ref,
    ClassSessionDto session,
  ) {
    int completedCount = 0;
    if (session.hasAttendance) completedCount++;
    if (session.hasHomework) completedCount++;
    if (session.hasReport) completedCount++;

    final allDone = completedCount == 3;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 19.sp,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  ref.watchTr(AppStrings.sessionChecklistTitle).toUpperCase(),
                  style: TxtStyle.labelLarge(
                    color: AppColors.subtitleTextColor,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: allDone
                      ? const Color(0xFFE8F8F0)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      allDone
                          ? Icons.check_circle_rounded
                          : Icons.pending_actions_rounded,
                      size: 13.sp,
                      color: allDone
                          ? AppColors.emeraldGreenColor
                          : const Color(0xFFD97706),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$completedCount/3',
                      style: TxtStyle.labelSmall(
                        color: allDone
                            ? AppColors.emeraldGreenColor
                            : const Color(0xFFD97706),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(2.r),
            child: LinearProgressIndicator(
              value: completedCount / 3.0,
              minHeight: 4.h,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? AppColors.emeraldGreenColor : AppColors.primaryDark,
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // 1. Attendance Item
          _activityItem(
            context: context,
            ref: ref,
            title: ref.watchTr(AppStrings.attendanceActivityTitle),
            subtitle: session.hasAttendance
                ? '${ref.watchTr(AppStrings.activityCompletedStatus)} • ${session.students.length} ${ref.watchTr(AppStrings.studentsCount)}'
                : ref.watchTr(AppStrings.attendancePendingDesc),
            isDone: session.hasAttendance,
            actionLabel: ref.watchTr(AppStrings.takeAttendance),
            actionIcon: Icons.how_to_reg_rounded,
            onAction: () async {
              await context.push(
                RoutePath.teacherAttendance,
                extra: session.id,
              );
              ref.invalidate(teacherSessionDetailProvider(session.id));
              ref.read(teacherClassesControllerProvider.notifier).loadClasses();
              ref.read(teacherHomeControllerProvider.notifier).loadHomeData();
            },
          ),
          Divider(
            color: AppColors.backgroundsLinesColor.withValues(alpha: 0.6),
            height: 18.h,
          ),

          // 2. Homework Item
          _activityItem(
            context: context,
            ref: ref,
            title: ref.watchTr(AppStrings.homeworkActivityTitle),
            subtitle: session.hasHomework
                ? ref.watchTr(AppStrings.homeworkAssignedSubtitle)
                : ref.watchTr(AppStrings.noHomeworkAssignedDesc),
            isDone: session.hasHomework,
            actionLabel: ref.watchTr(AppStrings.assignHomeworkBtn),
            actionIcon: Icons.add_task_rounded,
            onAction: () async {
              final classesState = ref.read(teacherClassesControllerProvider);
              final allClasses = [
                ...classesState.todayClasses,
                ...classesState.upcomingClasses,
              ];
              final matchedClass = allClasses
                  .where(
                    (c) =>
                        c.id == session.id ||
                        (session.scheduleId.isNotEmpty &&
                            c.scheduleId == session.scheduleId),
                  )
                  .firstOrNull;

              final effectiveCohortId =
                  (session.cohortId != null && session.cohortId!.isNotEmpty)
                  ? session.cohortId
                  : (widget.academyClass?.cohortId != null &&
                            widget.academyClass!.cohortId!.isNotEmpty
                        ? widget.academyClass!.cohortId
                        : matchedClass?.cohortId);

              final effectiveSubjectId =
                  (session.subjectId != null && session.subjectId!.isNotEmpty)
                  ? session.subjectId
                  : (widget.academyClass?.subjectId != null &&
                            widget.academyClass!.subjectId!.isNotEmpty
                        ? widget.academyClass!.subjectId
                        : (matchedClass?.subjectId != null &&
                                  matchedClass!.subjectId!.isNotEmpty
                              ? matchedClass.subjectId
                              : (session.scheduleId.isNotEmpty
                                    ? session.scheduleId
                                    : null)));

              final effectiveCohortName = session.cohortName.isNotEmpty
                  ? session.cohortName
                  : (widget.academyClass?.group.isNotEmpty == true
                        ? widget.academyClass!.group
                        : (matchedClass?.group ?? ''));

              final effectiveSubjectName = session.subjectName.isNotEmpty
                  ? session.subjectName
                  : (widget.academyClass?.title.isNotEmpty == true
                        ? widget.academyClass!.title
                        : (matchedClass?.title ?? ''));

              final created = await showAssignHomeworkBottomSheet(
                context: context,
                ref: ref,
                cohortId: effectiveCohortId,
                cohortName: effectiveCohortName,
                subjectId: effectiveSubjectId,
                subjectName: effectiveSubjectName,
                sessionId: session.id,
              );
              if (created == true) {
                ref.invalidate(teacherSessionDetailProvider(session.id));
                try {
                  await ref.read(
                    teacherSessionDetailProvider(session.id).future,
                  );
                } catch (_) {}
                ref
                    .read(teacherClassesControllerProvider.notifier)
                    .loadClasses();
                ref.read(teacherHomeControllerProvider.notifier).loadHomeData();
              }
            },
          ),
          Divider(
            color: AppColors.backgroundsLinesColor.withValues(alpha: 0.6),
            height: 18.h,
          ),

          // 3. Class Report Item
          _activityItem(
            context: context,
            ref: ref,
            title: ref.watchTr(AppStrings.reportActivityTitle),
            subtitle: session.hasReport
                ? ref.watchTr(AppStrings.reportSubmittedSubtitle)
                : ref.watchTr(AppStrings.reportPendingDesc),
            isDone: session.hasReport,
            actionLabel: ref.watchTr(AppStrings.submitReportBtn),
            actionIcon: Icons.edit_note_rounded,
            onAction: () async {
              await context.push(
                RoutePath.teacherPostClassReport,
                extra: session.id,
              );
              ref.invalidate(teacherSessionDetailProvider(session.id));
              ref.read(teacherClassesControllerProvider.notifier).loadClasses();
              ref.read(teacherHomeControllerProvider.notifier).loadHomeData();
            },
          ),
        ],
      ),
    );
  }

  Widget _activityItem({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required bool isDone,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? const Color(0xFFE8F8F0) : const Color(0xFFFFF7ED),
          ),
          child: Icon(
            isDone ? Icons.check_circle_rounded : actionIcon,
            size: 18.sp,
            color: isDone
                ? AppColors.emeraldGreenColor
                : const Color(0xFFD97706),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TxtStyle.titleMedium(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TxtStyle.bodySmall(
                  color: AppColors.subtitleTextColor,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        if (isDone)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 13.sp,
                  color: AppColors.emeraldGreenColor,
                ),
                SizedBox(width: 3.w),
                Text(
                  ref.watchTr(AppStrings.activityCompletedStatus),
                  style: TxtStyle.labelSmall(
                    color: AppColors.emeraldGreenColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(6.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actionIcon, size: 13.sp, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(
                      actionLabel,
                      style: TxtStyle.labelSmall(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _attendanceBadgeColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AppColors.emeraldGreenColor;
      case 'ABSENT':
        return AppColors.error;
      case 'LATE':
        return const Color(0xfff59e0b);
      case 'EXCUSED':
        return AppColors.primaryDark;
      default:
        return AppColors.subtitleTextColor;
    }
  }
}
