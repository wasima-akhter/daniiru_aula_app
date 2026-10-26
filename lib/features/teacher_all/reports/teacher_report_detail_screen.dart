import '../../auth/presentation/controllers/auth_controller.dart';
import '../../parent_all/helper/parent_home_helper.dart';
import '../../share/export/screen_export.dart';
import '../helper/teacher_enums.dart';
import '../helper/teacher_models.dart';
import 'presentation/controllers/teacher_reports_controller.dart';
import 'presentation/providers/teacher_reports_providers.dart';

/// ===============================================================
/// REPORT DETAILS SCREEN
/// ===============================================================

class TeacherReportDetailsScreen extends ConsumerStatefulWidget {
  final TeacherReport? report;
  final String? reportId;

  const TeacherReportDetailsScreen({
    super.key,
    this.report,
    this.reportId,
  });

  @override
  ConsumerState<TeacherReportDetailsScreen> createState() =>
      _TeacherReportDetailsScreenState();
}

class _TeacherReportDetailsScreenState
    extends ConsumerState<TeacherReportDetailsScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _percentage = 0;
  String? _downloadedFilePath;
  bool _downloadSuccess = false;
  bool _isSharing = false;

  String? get _resolvedId => widget.reportId ?? widget.report?.id;

  Future<void> _startDownload(TeacherReport report, {bool andShare = false}) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _percentage = 0;
      _downloadSuccess = false;
    });

    final facultyName =
        ref.read(authControllerProvider).user?.fullName.isNotEmpty == true
            ? ref.read(authControllerProvider).user!.fullName
            : 'Docente Aula 360';

    final downloadService = ref.read(fileDownloadServiceProvider);
    final result = await downloadService.downloadTeacherReport(
      report: report,
      facultyName: facultyName,
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

      if (andShare) {
        await _sharePdfFile(result.path, report);
      }
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

  Future<void> _sharePdfFile(String filePath, TeacherReport report) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final shareService = ref.read(fileShareServiceProvider);
      await shareService.shareFile(
        filePath: filePath,
        subject: 'Informe Aula 360 - ${report.title}',
        text:
            'Adjunto el informe oficial de ${report.title} (${report.date} • ${report.time}) de Aula 360.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleShare(TeacherReport report) async {
    if (_downloadedFilePath != null) {
      await _sharePdfFile(_downloadedFilePath!, report);
    } else {
      await _startDownload(report, andShare: true);
    }
  }

  Future<void> _openPdfFile(String filePath, BuildContext context) async {
    final pdfService = ref.read(pdfViewerServiceProvider);
    final success = await pdfService.openLocalFile(filePath);

    if (!success && context.mounted) {
      ApiSnackbar.show('${ref.readTr(AppStrings.openPdf)}: $filePath');
    }
  }

  void _showReportPreviewModal(
    BuildContext context,
    String filePath,
    TeacherReport report,
  ) {
    final facultyName =
        ref.read(authControllerProvider).user?.fullName.isNotEmpty == true
            ? ref.read(authControllerProvider).user!.fullName
            : 'Docente Aula 360';

    final isReviewed = report.rawStatus.toUpperCase() == 'REVIEWED' ||
        report.status == ReportStatus.reviewed;

    final attendanceSummary = report.attendanceSummary;
    final total = attendanceSummary?.total ?? 0;
    final present = attendanceSummary?.present ?? 0;
    final attendanceText = total > 0
        ? '$present / $total ${ref.watchTr(AppStrings.present)} (${((present / total) * 100).round()}%)'
        : '18 / 18 ${ref.watchTr(AppStrings.present)} (100%)';

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
                                color: isReviewed
                                    ? const Color(0xFFE7FAF2)
                                    : AppColors.primaryDark.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                isReviewed
                                    ? ref.watchTr(AppStrings.reviewed)
                                    : ref.watchTr(AppStrings.submitted),
                                style: TxtStyle.titleLarge(
                                  color: isReviewed
                                      ? AppColors.emeraldGreenColor
                                      : AppColors.primaryDark,
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
                          report.title,
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.group),
                          report.cohortName != null && report.cohortName!.isNotEmpty
                              ? report.cohortName!
                              : '${ref.watchTr(report.group.stringKey)} • ${report.grade ?? ""} • ${report.room ?? "Aula"}',
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.teacherLabel),
                          facultyName,
                        ),
                        if (report.studentName != null) ...[
                          SizedBox(height: 6.h),
                          _previewRow(
                            ref.watchTr(AppStrings.studentLabel),
                            '${report.studentName} (${report.studentId ?? ""})',
                          ),
                        ],
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.date),
                          '${report.date} • ${report.time}',
                        ),
                        SizedBox(height: 6.h),
                        _previewRow(
                          ref.watchTr(AppStrings.attendance),
                          attendanceText,
                        ),
                        if ((report.contentCovered != null &&
                                report.contentCovered!.isNotEmpty) ||
                            report.subtitle.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          _previewRow(
                            ref.watchTr(AppStrings.todaysTopic),
                            (report.contentCovered != null &&
                                    report.contentCovered!.isNotEmpty)
                                ? report.contentCovered!
                                : report.subtitle,
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(modalContext).pop();
                            _sharePdfFile(filePath, report);
                          },
                          icon: Icon(
                            Icons.share_outlined,
                            color: AppColors.primaryDark,
                            size: 16.sp,
                          ),
                          label: Text(
                            ref.watchTr(AppStrings.shareReport),
                            style: TxtStyle.titleLarge(
                              color: AppColors.primaryDark,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryDark,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openPdfFile(filePath, modalContext),
                          icon: Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.white,
                            size: 17.sp,
                          ),
                          label: Text(
                            ref.watchTr(AppStrings.openPdf),
                            style: TxtStyle.titleLarge(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildEmptyState(WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.reportDetailTitle),
        showBack: true,
      ),
      body: Center(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedId = _resolvedId;
    AsyncValue<TeacherReport>? detailAsync;
    if (resolvedId != null && resolvedId.isNotEmpty) {
      detailAsync = ref.watch(teacherReportDetailProvider(resolvedId));
    }

    TeacherReport? report;
    if (detailAsync != null && detailAsync.hasValue) {
      report = detailAsync.value;
    } else if (widget.report != null) {
      report = widget.report;
    } else {
      final all = ref.watch(teacherReportsControllerProvider).reports;
      if (all.isNotEmpty) {
        if (resolvedId != null) {
          final match = all.where((r) => r.id == resolvedId).toList();
          report = match.isNotEmpty ? match.first : all.first;
        } else {
          report = all.first;
        }
      }
    }

    if (report == null) {
      if (detailAsync != null && detailAsync.isLoading) {
        return Scaffold(
          backgroundColor: AppColors.softBackground,
          appBar: AulaAppBar(
            title: ref.watchTr(AppStrings.reportDetailTitle),
            showBack: true,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (detailAsync != null && detailAsync.hasError) {
        return Scaffold(
          backgroundColor: AppColors.softBackground,
          appBar: AulaAppBar(
            title: ref.watchTr(AppStrings.reportDetailTitle),
            showBack: true,
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48.sp, color: Colors.redAccent),
                  SizedBox(height: 12.h),
                  Text(
                    detailAsync.error.toString(),
                    textAlign: TextAlign.center,
                    style: TxtStyle.bodyMedium(fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                      teacherReportDetailProvider(resolvedId!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Reintentar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return _buildEmptyState(ref);
    }

    final isDetailLoading = detailAsync?.isLoading == true;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.reportDetailTitle),
        showBack: true,
        actions: [
          IconButton(
            onPressed: () => _handleShare(report!),
            icon: Icon(
              Icons.share_outlined,
              color: AppColors.subtitleTextColor,
              size: 20.sp,
            ),
            tooltip: ref.watchTr(AppStrings.shareReport),
          ),
          SizedBox(width: 6.w),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (resolvedId != null && resolvedId.isNotEmpty) {
              ref.invalidate(teacherReportDetailProvider(resolvedId));
            }
          },
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 30.h),
            children: [
              if (isDetailLoading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              _recordHeader(ref, report),
              SizedBox(height: 17.h),
              _attendanceSection(ref, report),
              SizedBox(height: 17.h),
              _contentSection(ref, report),
              SizedBox(height: 17.h),
              _homeworkSection(ref, report),
              SizedBox(height: 17.h),
              _facultyObservation(ref, report),
              if (report.reviewNote != null || report.reviewedAt != null) ...[
                SizedBox(height: 17.h),
                _reviewSection(ref, report),
              ],
              SizedBox(height: 19.h),
              _reportActionsArea(ref, report),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recordHeader(WidgetRef ref, TeacherReport report) {
    final facultyName =
        ref.watch(authControllerProvider).user?.fullName.isNotEmpty == true
            ? ref.watch(authControllerProvider).user!.fullName
            : 'Docente Aula 360';

    final isReviewed = report.rawStatus.toUpperCase() == 'REVIEWED' ||
        report.status == ReportStatus.reviewed;

    final idTag = (report.id != null && report.id!.isNotEmpty)
        ? (report.id!.length > 8
            ? report.id!.substring(0, 8).toUpperCase()
            : report.id!.toUpperCase())
        : '8041';

    final sessionTime = (report.startTime != null && report.endTime != null)
        ? '${report.startTime} - ${report.endTime}'
        : report.time;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${ref.watchTr(AppStrings.attendanceRecordTitle)} • #AR-$idTag',
              style: TxtStyle.titleLarge(
                color: AppColors.subtitleTextColor,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
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
                style: TxtStyle.titleLarge(
                  color: isReviewed
                      ? AppColors.emeraldGreenColor
                      : AppColors.primaryDark,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        Text(
          report.title,
          style: TxtStyle.titleLarge(
            color: AppColors.text,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          report.cohortName != null && report.cohortName!.isNotEmpty
              ? report.cohortName!
              : '${ref.watchTr(report.group.stringKey)}  •  ${report.grade ?? ""}  •  ${report.room ?? ref.watchTr(AppStrings.aula2)}',
          style: TxtStyle.bodyMedium(
            color: AppColors.subtitleTextColor,
            fontSize: 15.sp,
          ),
        ),
        SizedBox(height: 5.h),
        RichText(
          text: TextSpan(
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 15.sp,
            ),
            children: [
              TextSpan(text: ref.watchTr(AppStrings.facultyPrefix)),
              TextSpan(
                text: facultyName,
                style: TxtStyle.bodyMedium(
                  color: AppColors.text,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${report.date}${sessionTime.isNotEmpty ? " • $sessionTime" : ""}',
          style: TxtStyle.bodyMedium(
            color: AppColors.subtitleTextColor,
            fontSize: 14.sp,
          ),
        ),
        if (report.entryTime != null || report.exitTime != null) ...[
          SizedBox(height: 6.h),
          _timingRow(report),
        ],
      ],
    );
  }

  Widget _timingRow(TeacherReport report) {
    String formatIsoTime(String? iso) {
      if (iso == null || iso.isEmpty) return '--:--';
      if (iso.length >= 16) return iso.substring(11, 16);
      return iso;
    }

    return Row(
      children: [
        if (report.entryTime != null) ...[
          Icon(Icons.login_rounded, size: 14.sp, color: AppColors.subtitleTextColor),
          SizedBox(width: 4.w),
          Text(
            'Entrada: ${formatIsoTime(report.entryTime)}',
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 13.sp,
            ),
          ),
        ],
        if (report.entryTime != null && report.exitTime != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text('•', style: TextStyle(color: AppColors.subtitleTextColor)),
          ),
        if (report.exitTime != null) ...[
          Icon(Icons.logout_rounded, size: 14.sp, color: AppColors.subtitleTextColor),
          SizedBox(width: 4.w),
          Text(
            'Salida: ${formatIsoTime(report.exitTime)}',
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 13.sp,
            ),
          ),
        ],
      ],
    );
  }

  Widget _attendanceSection(WidgetRef ref, TeacherReport report) {
    final summary = report.attendanceSummary;
    final total = summary?.total ?? 0;
    final present = summary?.present ?? 0;
    final absent = summary?.absent ?? 0;
    final lateCount = summary?.late ?? 0;
    final excused = summary?.excused ?? 0;
    final pct = total > 0 ? ((present / total) * 100).round() : 100;

    return _detailSection(
      title: ref.watchTr(AppStrings.attendanceAndParticipationTitle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total > 0
                ? '$present / $total ${ref.watchTr(AppStrings.present)} ($pct%)'
                : '18 / 18 ${ref.watchTr(AppStrings.present)} (100%)',
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (summary != null) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _summaryChip('Total', total, const Color(0xFFF3F4F6), AppColors.text),
                _summaryChip('Presentes', present, const Color(0xFFE7FAF2), const Color(0xFF18B86B)),
                if (absent > 0)
                  _summaryChip('Ausentes', absent, const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
                if (lateCount > 0)
                  _summaryChip('Tarde', lateCount, const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                if (excused > 0)
                  _summaryChip('Justificados', excused, const Color(0xFFE0E7FF), const Color(0xFF4F46E5)),
              ],
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _ratingBadge(
                  ref.watchTr(AppStrings.conductAndAttitudeTitle),
                  report.attitudeRating ?? 'SATISFACTORY',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ratingBadge(
                  'Esfuerzo y Trabajo',
                  report.workEffortRating ?? 'ON_TRACK',
                ),
              ),
            ],
          ),
          if (report.attendances.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Text(
              'Alumnos (${report.attendances.length})',
              style: TxtStyle.titleLarge(
                color: AppColors.text,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.attendances.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: AppColors.backgroundsLinesColor.withValues(alpha: 0.6),
              ),
              itemBuilder: (context, index) {
                final student = report.attendances[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 7.h),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14.r,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: (student.avatarUrl != null &&
                                student.avatarUrl!.isNotEmpty)
                            ? NetworkImage(student.avatarUrl!)
                            : null,
                        child: (student.avatarUrl == null ||
                                student.avatarUrl!.isEmpty)
                            ? Text(
                                student.studentName.isNotEmpty
                                    ? student.studentName.substring(0, 1).toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          student.studentName,
                          style: TxtStyle.bodyMedium(
                            color: AppColors.text,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _attendanceStatusPill(student.status),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color bg, Color text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: text,
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _ratingBadge(String label, String value) {
    String displayVal = value;
    final valUpper = value.toUpperCase();
    if (valUpper == 'SATISFACTORY') displayVal = 'Satisfactorio';
    if (valUpper == 'NEEDS_ATTENTION') displayVal = 'Requiere atención';
    if (valUpper == 'EXCELLENT') displayVal = 'Excelente';
    if (valUpper == 'ON_TRACK') displayVal = 'Adecuado';
    if (valUpper == 'MODERATE') displayVal = 'Moderado';
    if (valUpper == 'HIGH_EFFORT') displayVal = 'Alto rendimiento';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
          SizedBox(height: 2.h),
          Text(
            displayVal,
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

  Widget _attendanceStatusPill(String status) {
    Color bg;
    Color text;
    String label;
    switch (status.toUpperCase()) {
      case 'PRESENT':
        bg = const Color(0xFFE7FAF2);
        text = const Color(0xFF18B86B);
        label = 'Presente';
        break;
      case 'ABSENT':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        label = 'Ausente';
        break;
      case 'LATE':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        label = 'Tarde';
        break;
      case 'EXCUSED':
        bg = const Color(0xFFE0E7FF);
        text = const Color(0xFF4F46E5);
        label = 'Justificado';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = AppColors.text;
        label = status;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _contentSection(WidgetRef ref, TeacherReport report) {
    final contentText = (report.contentCovered != null &&
            report.contentCovered!.isNotEmpty)
        ? report.contentCovered!
        : (report.subtitle.isNotEmpty
            ? report.subtitle
            : ref.watchTr(AppStrings.contentDeliveredTitle));

    return _detailSection(
      title: ref.watchTr(AppStrings.contentDeliveredTitle).toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.watchTr(AppStrings.sessionInfoTitle),
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            contentText,
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 16.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeworkSection(WidgetRef ref, TeacherReport report) {
    final homeworkText = (report.homeworkAssigned != null &&
            report.homeworkAssigned!.isNotEmpty)
        ? report.homeworkAssigned!
        : ref.watchTr(AppStrings.assignedTasksTitle);

    return _detailSection(
      title: ref.watchTr(AppStrings.assignedTasksTitle).toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.watchTr(AppStrings.homeworkTitle),
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            homeworkText,
            style: TxtStyle.bodyMedium(
              color: AppColors.subtitleTextColor,
              fontSize: 16.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _facultyObservation(WidgetRef ref, TeacherReport report) {
    final observationText = report.observations?.isNotEmpty == true
        ? report.observations!
        : ref.watchTr(AppStrings.facultyObservationTitle);

    return _detailSection(
      title: ref.watchTr(AppStrings.facultyObservationTitle),
      child: Container(
        padding: EdgeInsets.only(left: 10.w),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primaryDark, width: 2),
          ),
        ),
        child: Text(
          '"$observationText"',
          style: TxtStyle.bodyMedium(
            color: AppColors.subtitleTextColor,
            fontSize: 16.sp,
            height: 1.55,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _reviewSection(WidgetRef ref, TeacherReport report) {
    String reviewedDateStr = '';
    if (report.reviewedAt != null && report.reviewedAt!.length >= 10) {
      reviewedDateStr = report.reviewedAt!.substring(0, 10);
    }

    return _detailSection(
      title: 'REVISIÓN ACADÉMICA',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.backgroundsLinesColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reviewedDateStr.isNotEmpty) ...[
              Text(
                'Revisado el $reviewedDateStr',
                style: TxtStyle.bodyMedium(
                  color: AppColors.subtitleTextColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
            ],
            if (report.reviewNote != null && report.reviewNote!.isNotEmpty)
              Text(
                report.reviewNote!,
                style: TxtStyle.bodyMedium(
                  color: AppColors.text,
                  fontSize: 14.sp,
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection({
    required String title,
    required Widget child,
    String? trailing,
  }) {
    return Container(
      padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.backgroundsLinesColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TxtStyle.titleLarge(
                    color: AppColors.subtitleTextColor,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .45,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Gap(12.w),
                Flexible(
                  child: Text(
                    trailing,
                    textAlign: TextAlign.end,
                    style: TxtStyle.bodyMedium(
                      color: AppColors.subtitleTextColor,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 9.h),
          child,
        ],
      ),
    );
  }

  Widget _reportActionsArea(WidgetRef ref, TeacherReport report) {
    if (_isDownloading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
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
                      AppColors.primaryDark,
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
                    color: AppColors.primaryDark,
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
                  AppColors.primaryDark,
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
                  onPressed: () => _startDownload(report),
                  icon: Icon(
                    Icons.download_outlined,
                    color: AppColors.primaryDark,
                    size: 15.sp,
                  ),
                  label: Text(
                    ref.watchTr(AppStrings.downloadReport),
                    style: TxtStyle.titleLarge(
                      color: AppColors.primaryDark,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryDark),
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showReportPreviewModal(context, _downloadedFilePath!, report),
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: Colors.white,
                    size: 15.sp,
                  ),
                  label: Text(
                    ref.watchTr(AppStrings.previewReport),
                    style: TxtStyle.titleLarge(
                      color: Colors.white,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton.filled(
                onPressed: () => _sharePdfFile(_downloadedFilePath!, report),
                icon: Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 17.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.all(10.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                tooltip: ref.watchTr(AppStrings.shareReport),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _startDownload(report),
        icon: Icon(Icons.download_outlined, size: 18.sp, color: Colors.white),
        label: Text(
          ref.watchTr(AppStrings.downloadOfficialRecordPdf),
          style: TxtStyle.titleLarge(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 13.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}
