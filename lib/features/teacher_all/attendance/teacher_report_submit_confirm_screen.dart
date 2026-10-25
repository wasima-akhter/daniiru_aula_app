import 'package:intl/intl.dart';

import '../../share/export/screen_export.dart';
import '../classes/presentation/controllers/teacher_classes_controller.dart';
import '../helper/teacher_models.dart';

/// ===============================================================
/// 3. REPORT SUBMITTED SCREEN
/// ===============================================================

class TeacherReportSubmittedScreen extends ConsumerWidget {
  final String? sessionId;
  final String? homeworkText;
  final AcademyClass? initialClass;

  const TeacherReportSubmittedScreen({
    super.key,
    this.sessionId,
    this.homeworkText,
    this.initialClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(teacherClassesControllerProvider);
    final AcademyClass? activeClass;
    if (initialClass != null) {
      activeClass = initialClass;
    } else {
      final matches = classesState.todayClasses.where((c) => c.id == sessionId);
      if (matches.isNotEmpty) {
        activeClass = matches.first;
      } else {
        final upcomingMatches =
            classesState.upcomingClasses.where((c) => c.id == sessionId);
        if (upcomingMatches.isNotEmpty) {
          activeClass = upcomingMatches.first;
        } else if (classesState.todayClasses.isNotEmpty) {
          activeClass = classesState.todayClasses.first;
        } else if (classesState.upcomingClasses.isNotEmpty) {
          activeClass = classesState.upcomingClasses.first;
        } else {
          activeClass = null;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          ref.watchTr(AppStrings.reportSubmittedTitle),
          style: TxtStyle.titleLarge(
            color: AppColors.primaryColor,
            fontSize: 19.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go(RoutePath.navigationPages),
          icon: Icon(
            Icons.close,
            color: AppColors.subtitleTextColor,
            size: 20.sp,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.backgroundsLinesColor),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 70.h, 14.w, 24.h),
                child: Column(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE9FFF5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.emeraldGreenColor,
                        size: 28.sp,
                      ),
                    ),

                    SizedBox(height: 17.h),

                    Text(
                      ref.watchTr(AppStrings.reportSubmittedTitle),
                      style: TxtStyle.titleLarge(
                        color: AppColors.text,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      ref.watchTr(AppStrings.reportSubmittedSubtitle),
                      textAlign: TextAlign.center,
                      style: TxtStyle.bodyMedium(
                        color: AppColors.subtitleTextColor,
                        fontSize: 16.5.sp,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 30.h),

                    _reportSummary(ref, activeClass),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: AulaPrimaryButton(
                        onTap: () {
                          context.push(
                            RoutePath.teacherHomework,
                            extra: {
                              'sessionId': sessionId ?? activeClass?.id,
                              'cohortId': activeClass != null &&
                                      activeClass.group.isNotEmpty
                                  ? activeClass.group
                                  : 'Cohort-1',
                              'subjectId': activeClass != null &&
                                      activeClass.title.isNotEmpty
                                  ? activeClass.title
                                  : 'Subject-1',
                              'title': activeClass != null &&
                                      activeClass.title.isNotEmpty
                                  ? '${activeClass.title} - ${ref.watchTr(AppStrings.homeworkTitle)}'
                                  : ref.watchTr(AppStrings.newHomeworkTitle),
                              'description': homeworkText,
                              'autoOpenCreate': true,
                              'fromClassFlow': true,
                            },
                          );
                        },
                        text: ref.watchTr(AppStrings.assignHomeworkBtn),
                        trailing: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.go(RoutePath.navigationPages);
                        },
                        child: Text(
                          ref.watchTr(AppStrings.finishBtn),
                          style: TxtStyle.bodyMedium(
                            color: AppColors.subtitleTextColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _reportSummary(WidgetRef ref, AcademyClass? activeClass) {
    final langCode =
        ref.watch(languageProvider).valueOrNull?.language.code ?? 'en';
    final dateTimeStr = DateFormat(
      'd MMM yyyy • HH:mm',
      langCode,
    ).format(DateTime.now());

    final title = activeClass?.title.isNotEmpty == true
        ? activeClass!.title
        : ref.watchTr(AppStrings.subjectMathAdvanced);

    final groupSubtitle = activeClass != null && activeClass.group.isNotEmpty
        ? '${activeClass.group} • ${activeClass.subtitle}'
        : '${ref.watchTr(AppStrings.groupA)} • ${ref.watchTr(AppStrings.bachillerato1)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _summaryRow(
            label: ref.watchTr(AppStrings.classroom),
            value: title,
          ),
          SizedBox(height: 12.h),
          _summaryRow(
            label: ref.watchTr(AppStrings.group),
            value: groupSubtitle,
          ),
          SizedBox(height: 12.h),
          _summaryRow(
            label: ref.watchTr(AppStrings.dateTime),
            value: dateTimeStr,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({required String label, required String value}) {
    return Row(
      children: [
        Text(
          label,
          style: TxtStyle.bodyMedium(
            color: AppColors.subtitleTextColor,
            fontSize: 17.sp,
          ),
        ),
        const Spacer(),
        Text(
          value,
          textAlign: TextAlign.right,
          maxLines: 3,
          style: TxtStyle.bodyMedium(
            color: AppColors.text,
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
