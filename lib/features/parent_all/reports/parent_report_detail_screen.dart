import 'package:intl/intl.dart';

import '../../share/export/screen_export.dart';
import '../data/dtos/child_report_dto.dart';
import '../helper/parent_home_helper.dart';
import '../presentation/controllers/parent_children_controller.dart';
import '../presentation/controllers/parent_reports_controller.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  final String? childId;
  final String reportId;
  final ReportModel? initialReport;

  const ReportDetailsScreen({
    super.key,
    this.childId,
    required this.reportId,
    this.initialReport,
  });

  @override
  ConsumerState<ReportDetailsScreen> createState() =>
      _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  bool showFullNote = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _percentage = 0;
  String? _downloadedFilePath;
  bool _downloadSuccess = false;

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(parentChildrenControllerProvider);
    final effectiveChildId = widget.childId?.isNotEmpty == true
        ? widget.childId!
        : (childrenState.selectedChild?.id ??
            (childrenState.children.isNotEmpty
                ? childrenState.children.first.id
                : ''));

    final reportsState = ref.watch(parentReportsControllerProvider);
    StudentModel? currentStudent;
    if (effectiveChildId.isNotEmpty) {
      final childIdx =
          childrenState.children.indexWhere((c) => c.id == effectiveChildId);
      if (childIdx >= 0 && childIdx < reportsState.students.length) {
        currentStudent = reportsState.students[childIdx];
      }
    }
    currentStudent ??= reportsState.students.isNotEmpty
        ? reportsState.students[reportsState.selectedStudentIndex.clamp(
            0,
            reportsState.students.length - 1,
          )]
        : null;

    final studentName =
        currentStudent?.name ?? ref.watchTr(AppStrings.studentLabel);
    final studentClass = currentStudent?.grade ?? '';

    // If reportId is empty, try extracting from initialReport
    final effectiveReportId = widget.reportId.isNotEmpty
        ? widget.reportId
        : (widget.initialReport?.id ?? '');

    if (effectiveChildId.isEmpty || effectiveReportId.isEmpty) {
      if (widget.initialReport != null) {
        final fallback = _fallbackFromReportModel(widget.initialReport!);
        return _buildScaffold(context, fallback, studentName, studentClass);
      }
      return Scaffold(
        backgroundColor: const Color(0xFFF8F7FC),
        appBar: AulaAppBar(
          title: ref.watchTr(AppStrings.reportDetailTitle),
          showBack: true,
        ),
        body: Center(
          child: Text(
            ref.watchTr(AppStrings.noReportsFound),
            style: TxtStyle.bodyMedium(
              color: AppColors.secondaryText,
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    }

    final detailAsync = ref.watch(
      childReportDetailProvider(
        ChildReportDetailParams(
          childId: effectiveChildId,
          reportId: effectiveReportId,
        ),
      ),
    );

    return detailAsync.when(
      data: (detail) =>
          _buildScaffold(context, detail, studentName, studentClass),
      loading: () {
        if (widget.initialReport != null) {
          final fallback = _fallbackFromReportModel(widget.initialReport!);
          return _buildScaffold(context, fallback, studentName, studentClass);
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF8F7FC),
          appBar: AulaAppBar(
            title: ref.watchTr(AppStrings.reportDetailTitle),
            showBack: true,
          ),
          body: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        );
      },
      error: (error, stack) {
        if (widget.initialReport != null) {
          final fallback = _fallbackFromReportModel(widget.initialReport!);
          return _buildScaffold(context, fallback, studentName, studentClass);
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF8F7FC),
          appBar: AulaAppBar(
            title: ref.watchTr(AppStrings.reportDetailTitle),
            showBack: true,
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.sp,
                    color: Colors.redAccent,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TxtStyle.bodyMedium(
                      color: AppColors.secondaryText,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(
                        childReportDetailProvider(
                          ChildReportDetailParams(
                            childId: effectiveChildId,
                            reportId: effectiveReportId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      ref.watchTr(AppStrings.retry),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ChildReportDetailDto _fallbackFromReportModel(ReportModel r) {
    return ChildReportDetailDto(
      id: r.id ?? '',
      reportDate: r.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
      subjectName: r.subject,
      teacherName: r.teacher,
      contentCovered: r.note,
      observations: r.note,
      attitudeRating: 'SATISFACTORY',
      workEffortRating: 'ON_TRACK',
      studentAttendanceStatus: r.status,
      startTime: r.time,
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ChildReportDetailDto detail,
    String studentName,
    String studentClass,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.reportDetailTitle),
        showBack: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final childrenState = ref.read(parentChildrenControllerProvider);
            final effectiveChildId = widget.childId?.isNotEmpty == true
                ? widget.childId!
                : (childrenState.selectedChild?.id ??
                    (childrenState.children.isNotEmpty
                        ? childrenState.children.first.id
                        : ''));
            final effectiveReportId = widget.reportId.isNotEmpty
                ? widget.reportId
                : (widget.initialReport?.id ?? '');
            if (effectiveChildId.isNotEmpty && effectiveReportId.isNotEmpty) {
              ref.invalidate(
                childReportDetailProvider(
                  ChildReportDetailParams(
                    childId: effectiveChildId,
                    reportId: effectiveReportId,
                  ),
                ),
              );
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 30.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _header(detail),
                    SizedBox(height: 18.h),
                    _contentCoveredSection(detail),
                    _homeworkSection(detail),
                    SizedBox(height: 16.h),
                    _teacherObservation(detail),
                    SizedBox(height: 16.h),
                    _attendanceSection(detail),
                    SizedBox(height: 16.h),
                    _reportAction(detail, studentName, studentClass),
                    SizedBox(height: 10.h),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatReportDate(String? rawDate, WidgetRef ref) {
    if (rawDate == null || rawDate.isEmpty) return '';
    final langCode =
        ref.watch(languageProvider).valueOrNull?.language.code ?? 'en';
    final dt = DateTime.tryParse(rawDate);
    if (dt != null) {
      try {
        return DateFormat('EEEE, d MMM', langCode).format(dt);
      } catch (_) {
        try {
          return DateFormat('EEEE, d MMM').format(dt);
        } catch (_) {
          return rawDate;
        }
      }
    }
    return rawDate;
  }

  String _formatTimeRange(ChildReportDetailDto detail) {
    final start = detail.startTime ?? '';
    final end = detail.endTime ?? '';
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    } else if (start.isNotEmpty) {
      return start;
    } else if (end.isNotEmpty) {
      return end;
    }
    final dt = DateTime.tryParse(detail.reportDate);
    if (dt != null) {
      return DateFormat('HH:mm').format(dt);
    }
    return '10:00';
  }

  (String, Color) _statusPillData(WidgetRef ref, String? rawStatus) {
    final status = rawStatus?.toUpperCase() ?? 'PRESENT';
    switch (status) {
      case 'PRESENT':
        return (ref.watchTr(AppStrings.present), const Color(0xFF14B87A));
      case 'ABSENT':
        return (ref.watchTr(AppStrings.absent), const Color(0xFFDC2626));
      case 'LATE':
        return (ref.watchTr(AppStrings.late), const Color(0xFFD97706));
      case 'EXCUSED':
        return (ref.watchTr(AppStrings.excused), const Color(0xFF4F46E5));
      default:
        return (rawStatus ?? ref.watchTr(AppStrings.present), const Color(0xFF14B87A));
    }
  }

  Widget _header(ChildReportDetailDto detail) {
    final pillData = _statusPillData(ref, detail.studentAttendanceStatus);

    return AulaCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.subjectName,
                      style: TxtStyle.titleLarge(
                        color: AppColors.text,
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      detail.teacherName,
                      style: TxtStyle.titleLarge(
                        color: AppColors.secondaryText,
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: pillData.$1,
                color: pillData.$2,
              ),
            ],
          ),

          if ((detail.classroomRoomNumber != null &&
                  detail.classroomRoomNumber!.isNotEmpty) ||
              (detail.cohortName != null && detail.cohortName!.isNotEmpty)) ...[
            SizedBox(height: 10.h),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                if (detail.classroomRoomNumber != null &&
                    detail.classroomRoomNumber!.isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        size: 15.sp,
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        detail.classroomRoomNumber!,
                        style: TxtStyle.bodyMedium(
                          color: AppColors.secondaryText,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (detail.classroomRoomNumber != null &&
                    detail.classroomRoomNumber!.isNotEmpty &&
                    detail.cohortName != null &&
                    detail.cohortName!.isNotEmpty)
                  Text(
                    '•',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                if (detail.cohortName != null &&
                    detail.cohortName!.isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 15.sp,
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        detail.cohortName!,
                        style: TxtStyle.bodyMedium(
                          color: AppColors.secondaryText,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],

          SizedBox(height: 15.h),
          Divider(height: 1, color: AppColors.backgroundsLinesColor),
          SizedBox(height: 13.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16.sp,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: 7.w),
                    Flexible(
                      child: Text(
                        _formatReportDate(detail.reportDate, ref),
                        style: TxtStyle.titleLarge(
                          color: AppColors.secondaryText,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16.sp,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        _formatTimeRange(detail),
                        style: TxtStyle.titleLarge(
                          color: AppColors.secondaryText,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contentCoveredSection(ChildReportDetailDto detail) {
    if (detail.contentCovered == null ||
        detail.contentCovered!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _sectionCard(
          title: ref.watchTr(AppStrings.contentDeliveredTitle),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(9.r),
              border: Border.all(
                color: AppColors.backgroundsLinesColor.withValues(alpha: 0.8),
              ),
            ),
            child: Text(
              detail.contentCovered!,
              style: TxtStyle.bodyMedium(
                color: AppColors.text,
                fontSize: 14.5.sp,
                height: 1.45,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _homeworkSection(ChildReportDetailDto detail) {
    final hasHomework = detail.homeworkAssigned != null &&
        detail.homeworkAssigned!.trim().isNotEmpty;

    return _sectionCard(
      title: ref.watchTr(AppStrings.homeworkAndTasks),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.subjectName.isNotEmpty
                ? '${detail.subjectName}: ${ref.watchTr(AppStrings.homeworkTitle)}'
                : ref.watchTr(AppStrings.homeworkAndTasks),
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            '${ref.watchTr(AppStrings.duePrefix)} ${_formatReportDate(detail.reportDate, ref)}',
            style: TxtStyle.titleLarge(
              color: const Color(0xFFE68A27),
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            hasHomework
                ? detail.homeworkAssigned!
                : ref.watchTr(AppStrings.noHomeworkAssigned),
            style: TxtStyle.bodyMedium(
              color: hasHomework
                  ? AppColors.secondaryText
                  : AppColors.subtitleTextColor,
              fontSize: 14.5.sp,
              height: 1.45,
            ),
          ),
          SizedBox(height: 13.h),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                context.push(RoutePath.homework);
              },
              child: Text(
                ref.watchTr(AppStrings.viewHomework),
                style: TxtStyle.titleLarge(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherObservation(ChildReportDetailDto detail) {
    final note = detail.observations?.trim().isNotEmpty == true
        ? detail.observations!
        : (detail.contentCovered?.trim().isNotEmpty == true
            ? detail.contentCovered!
            : '');

    String initials = 'DOC';
    if (detail.teacherName.trim().isNotEmpty) {
      final parts = detail.teacherName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = detail.teacherName.substring(0, 1).toUpperCase();
      }
    }

    return _sectionCard(
      title: ref.watchTr(AppStrings.teacherObservation),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(initials: initials, size: 36),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.teacherName,
                      style: TxtStyle.titleLarge(
                        color: AppColors.text,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      detail.subjectName,
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
          if (note.isNotEmpty) ...[
            SizedBox(height: 13.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FF),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Text(
                '"$note"',
                maxLines: showFullNote ? null : 4,
                overflow: showFullNote
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TxtStyle.bodyMedium(
                  color: AppColors.text,
                  fontSize: 14.5.sp,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () {
                setState(() {
                  showFullNote = !showFullNote;
                });
              },
              child: Text(
                showFullNote
                    ? ref.watchTr(AppStrings.showLess)
                    : ref.watchTr(AppStrings.readFullNote),
                style: TxtStyle.titleLarge(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (detail.attitudeRating != null ||
              detail.workEffortRating != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                if (detail.attitudeRating != null)
                  Expanded(
                    child: _ratingBadge(
                      ref,
                      ref.watchTr(AppStrings.conductAndAttitudeTitle),
                      _formatRating(ref, detail.attitudeRating),
                    ),
                  ),
                if (detail.attitudeRating != null &&
                    detail.workEffortRating != null)
                  SizedBox(width: 8.w),
                if (detail.workEffortRating != null)
                  Expanded(
                    child: _ratingBadge(
                      ref,
                      ref.watchTr(AppStrings.effortAndDedicationTitle),
                      _formatRating(ref, detail.workEffortRating),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratingBadge(WidgetRef ref, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.backgroundsLinesColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 11.5.sp,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(String? start, String? end) {
    if (start == null || end == null || start.isEmpty || end.isEmpty) {
      return '1h 30min';
    }
    try {
      final startParts = start.split(':').map(int.parse).toList();
      final endParts = end.split(':').map(int.parse).toList();
      final startMinutes = startParts[0] * 60 + startParts[1];
      final endMinutes = endParts[0] * 60 + endParts[1];
      int diffMinutes = endMinutes - startMinutes;
      if (diffMinutes < 0) diffMinutes += 24 * 60;
      final hours = diffMinutes ~/ 60;
      final minutes = diffMinutes % 60;
      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}min';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}min';
      }
    } catch (_) {
      return '1h 30min';
    }
  }

  String _formatRating(WidgetRef ref, String? rating) {
    if (rating == null || rating.isEmpty) {
      return ref.watchTr(AppStrings.conductSatisfactory);
    }
    final valUpper = rating.toUpperCase();
    if (valUpper == 'SATISFACTORY') {
      return ref.watchTr(AppStrings.conductSatisfactory);
    } else if (valUpper == 'NEEDS_ATTENTION' ||
        valUpper == 'NEEDS_IMPROVEMENT') {
      return ref.watchTr(AppStrings.conductNeedsAttention);
    } else if (valUpper == 'EXCELLENT' || valUpper == 'OUTSTANDING') {
      return ref.watchTr(AppStrings.conductExcellent);
    } else if (valUpper == 'ON_TRACK' || valUpper == 'ADEQUATE') {
      return ref.watchTr(AppStrings.effortAdequate);
    } else if (valUpper == 'MODERATE') {
      return ref.watchTr(AppStrings.effortModerate);
    } else if (valUpper == 'HIGH_EFFORT' || valUpper == 'HIGH_PERFORMANCE') {
      return ref.watchTr(AppStrings.effortHighPerformance);
    }
    return rating;
  }

  Widget _attendanceSection(ChildReportDetailDto detail) {
    final pillData = _statusPillData(ref, detail.studentAttendanceStatus);
    final duration = _calculateDuration(detail.startTime, detail.endTime);
    final participation =
        _formatRating(ref, detail.attitudeRating ?? detail.workEffortRating);

    return _sectionCard(
      title: ref.watchTr(AppStrings.attendance),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              ref.watchTr(AppStrings.status),
              pillData.$1,
              pillData.$2,
            ),
          ),
          Expanded(
            child: _statItem(
              ref.watchTr(AppStrings.duration),
              duration,
              AppColors.primary,
            ),
          ),
          Expanded(
            child: _statItem(
              ref.watchTr(AppStrings.participation),
              participation,
              const Color(0xFF7656D8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TxtStyle.titleLarge(
            color: AppColors.secondaryText,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TxtStyle.titleLarge(
            color: color,
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Future<void> _startDownload(
    ReportModel report,
    String studentName,
    String studentClass,
  ) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _percentage = 0;
      _downloadSuccess = false;
    });

    final downloadService = ref.read(fileDownloadServiceProvider);
    final result = await downloadService.downloadReport(
      report: report,
      studentName: studentName,
      studentClass: studentClass,
      languageCode: LanguageNotifier.activeLanguageCode,
      onProgress: (received, total) {
        if (!mounted || total <= 0) return;
        setState(() {
          _downloadProgress = (received / total).clamp(0.0, 1.0);
          _percentage = ((received / total) * 100).toInt().clamp(0, 100);
        });
      },
    );

    if (!mounted) return;

    if (result is DownloadSuccess) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
        _percentage = 100;
        _downloadSuccess = true;
        _downloadedFilePath = result.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  ref.readTr(AppStrings.reportDownloadedSuccess),
                  style: TextStyle(fontSize: 13.5.sp),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.emeraldGreenColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    } else if (result is DownloadFailure) {
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openPdfFile(String filePath, BuildContext context) async {
    final pdfService = ref.read(pdfViewerServiceProvider);
    final success = await pdfService.openLocalFile(filePath);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${ref.readTr(AppStrings.openPdf)}: $filePath',
            style: TextStyle(fontSize: 12.5.sp),
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showReportPreviewModal(
    BuildContext context,
    String filePath,
    ChildReportDetailDto detail,
    String studentName,
    String studentClass,
  ) {
    final pillData = _statusPillData(ref, detail.studentAttendanceStatus);
    final duration = _calculateDuration(detail.startTime, detail.endTime);
    final participation =
        _formatRating(ref, detail.attitudeRating ?? detail.workEffortRating);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ref.watchTr(AppStrings.previewReport),
                        style: TxtStyle.titleLarge(
                          color: AppColors.primaryDark,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(modalContext).pop(),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.subtitleTextColor,
                          size: 20.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/images/app_logo.png',
                              height: 28.h,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                'AULA 360',
                                style: TxtStyle.titleLarge(
                                  color: AppColors.primaryDark,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: pillData.$2.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                pillData.$1,
                                style: TxtStyle.titleLarge(
                                  color: pillData.$2,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        const Divider(
                          height: 1,
                          color: AppColors.backgroundsLinesColor,
                        ),
                        SizedBox(height: 12.h),
                        _previewRow(
                          ref.watchTr(AppStrings.subjectLabel),
                          detail.subjectName,
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.teacherLabel),
                          detail.teacherName,
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.studentLabel),
                          '$studentName • $studentClass',
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.date),
                          '${_formatReportDate(detail.reportDate, ref)} • ${_formatTimeRange(detail)}',
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.attendance),
                          pillData.$1,
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.duration),
                          duration,
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.participation),
                          participation,
                        ),
                        if (detail.observations != null &&
                            detail.observations!.trim().isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          _previewRow(
                            ref.watchTr(AppStrings.teacherObservation),
                            detail.observations!.length > 60
                                ? '${detail.observations!.substring(0, 60)}...'
                                : detail.observations!,
                          ),
                        ],
                        if (detail.contentCovered != null &&
                            detail.contentCovered!.trim().isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          _previewRow(
                            ref.watchTr(AppStrings.contentDeliveredTitle),
                            detail.contentCovered!.length > 60
                                ? '${detail.contentCovered!.substring(0, 60)}...'
                                : detail.contentCovered!,
                          ),
                        ],
                        SizedBox(height: 12.h),
                        const Divider(
                          height: 1,
                          color: AppColors.backgroundsLinesColor,
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                color: AppColors.subtitleTextColor,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  filePath,
                                  style: TxtStyle.titleLarge(
                                    color: AppColors.subtitleTextColor,
                                    fontSize: 11.5.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () => _openPdfFile(filePath, modalContext),
                    icon: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                    label: Text(
                      ref.watchTr(AppStrings.openPdf),
                      style: TxtStyle.titleLarge(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _previewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TxtStyle.titleLarge(
              color: AppColors.subtitleTextColor,
              fontSize: 13.sp,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _reportAction(
    ChildReportDetailDto detail,
    String studentName,
    String studentClass,
  ) {
    final reportModel = detail.toReportModel();

    if (_isDownloading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    ref.watchTr(AppStrings.downloadingReport),
                    style: TxtStyle.titleLarge(
                      color: AppColors.text,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$_percentage%',
                  style: TxtStyle.titleLarge(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 6.h,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_downloadSuccess && _downloadedFilePath != null) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FAF2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.emeraldGreenColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.emeraldGreenColor,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    ref.watchTr(AppStrings.reportDownloadedSuccess),
                    style: TxtStyle.titleLarge(
                      color: AppColors.emeraldGreenColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _startDownload(reportModel, studentName, studentClass),
                  icon: Icon(
                    Icons.download_outlined,
                    color: AppColors.primary,
                    size: 16.sp,
                  ),
                  label: Text(
                    ref.watchTr(AppStrings.downloadReport),
                    style: TxtStyle.titleLarge(
                      color: AppColors.primary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReportPreviewModal(
                    context,
                    _downloadedFilePath!,
                    detail,
                    studentName,
                    studentClass,
                  ),
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  label: Text(
                    ref.watchTr(AppStrings.previewReport),
                    style: TxtStyle.titleLarge(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _startDownload(reportModel, studentName, studentClass),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(11.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_outlined,
              color: Colors.white,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              ref.watchTr(AppStrings.downloadReport),
              style: TxtStyle.titleLarge(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return AulaCard(
      padding: EdgeInsets.all(15.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}
