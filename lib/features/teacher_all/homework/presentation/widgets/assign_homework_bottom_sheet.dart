import 'package:intl/intl.dart';

import 'package:aula360/features/share/export/screen_export.dart';
import 'package:aula360/features/teacher_all/classes/presentation/controllers/teacher_classes_controller.dart';
import 'package:aula360/features/teacher_all/classes/presentation/providers/teacher_classes_providers.dart';
import 'package:aula360/features/teacher_all/home/presentation/controllers/teacher_home_controller.dart';
import 'package:aula360/features/teacher_all/homework/presentation/controllers/teacher_homework_controller.dart';
import 'package:aula360/features/teacher_all/homework/presentation/providers/teacher_homework_providers.dart';

bool isUuid(String? str) {
  if (str == null) return false;
  final trimmed = str.trim();
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(trimmed);
}

Future<bool?> showAssignHomeworkBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  String? cohortId,
  String? cohortName,
  String? subjectId,
  String? subjectName,
  String? sessionId,
  String? initialTitle,
  String? initialDescription,
}) async {
  String? resolvedCohortId = isUuid(cohortId) ? cohortId : null;
  String? resolvedSubjectId = isUuid(subjectId) ? subjectId : null;
  final String? resolvedSessionId = isUuid(sessionId)
      ? sessionId
      : (sessionId != null && sessionId.isNotEmpty ? sessionId : null);

  String resolvedCohortName = (cohortName != null && cohortName.isNotEmpty)
      ? cohortName
      : (cohortId != null && !isUuid(cohortId) ? cohortId : '');
  String resolvedSubjectName = (subjectName != null && subjectName.isNotEmpty)
      ? subjectName
      : (subjectId != null && !isUuid(subjectId) ? subjectId : '');

  // 1. Try to fetch session detail if either cohortId or subjectId is missing and sessionId is valid
  if ((resolvedCohortId == null || resolvedSubjectId == null) &&
      resolvedSessionId != null) {
    try {
      final sessionDetail = await ref
          .read(teacherClassesRepositoryProvider)
          .getSessionDetail(resolvedSessionId);
      if (resolvedCohortId == null && isUuid(sessionDetail.cohortId)) {
        resolvedCohortId = sessionDetail.cohortId;
      }
      if (resolvedSubjectId == null && isUuid(sessionDetail.subjectId)) {
        resolvedSubjectId = sessionDetail.subjectId;
      }
      if (resolvedCohortName.isEmpty && sessionDetail.cohortName.isNotEmpty) {
        resolvedCohortName = sessionDetail.cohortName;
      }
      if (resolvedSubjectName.isEmpty && sessionDetail.subjectName.isNotEmpty) {
        resolvedSubjectName = sessionDetail.subjectName;
      }
      if (resolvedSubjectId == null && isUuid(sessionDetail.scheduleId)) {
        resolvedSubjectId = sessionDetail.scheduleId;
      }
    } catch (e) {
      debugPrint('AssignHomeworkBottomSheet: error fetching session detail: $e');
    }
  }

  // 2. Search teacher classes (today & upcoming)
  TeacherClassesState? classesState;
  try {
    classesState = ref.read(teacherClassesControllerProvider);
  } catch (_) {
    classesState = null;
  }
  final allClasses = [
    if (classesState != null) ...classesState.todayClasses,
    if (classesState != null) ...classesState.upcomingClasses,
  ];

  if (resolvedSessionId != null) {
    final matches = allClasses.where((c) => c.id == resolvedSessionId);
    if (matches.isNotEmpty) {
      final cls = matches.first;
      if (resolvedCohortId == null && isUuid(cls.cohortId)) {
        resolvedCohortId = cls.cohortId;
      }
      if (resolvedSubjectId == null && isUuid(cls.subjectId)) {
        resolvedSubjectId = cls.subjectId;
      }
      if (resolvedCohortName.isEmpty && cls.group.isNotEmpty) {
        resolvedCohortName = cls.group;
      }
      if (resolvedSubjectName.isEmpty && cls.title.isNotEmpty) {
        resolvedSubjectName = cls.title;
      }
      if (resolvedSubjectId == null && isUuid(cls.scheduleId)) {
        resolvedSubjectId = cls.scheduleId;
      }
    }
  }

  // 3. Match by cohort or subject name in allClasses
  if (resolvedCohortId == null && resolvedCohortName.isNotEmpty) {
    final match = allClasses.where(
      (c) => c.group.trim().toLowerCase() == resolvedCohortName.trim().toLowerCase(),
    );
    if (match.isNotEmpty && isUuid(match.first.cohortId)) {
      resolvedCohortId = match.first.cohortId;
    }
  }

  if (resolvedSubjectId == null && resolvedSubjectName.isNotEmpty) {
    final match = allClasses.where(
      (c) => c.title.trim().toLowerCase() == resolvedSubjectName.trim().toLowerCase(),
    );
    if (match.isNotEmpty && isUuid(match.first.subjectId)) {
      resolvedSubjectId = match.first.subjectId;
    }
  }

  // 4. Check existing homework assignments created by teacher
  if (resolvedSubjectId == null || resolvedCohortId == null) {
    try {
      final existingHwList = await ref.read(teacherHomeworkRepositoryProvider).getHomework();
      for (final hw in existingHwList.items) {
        if (resolvedSubjectId == null &&
            resolvedSubjectName.isNotEmpty &&
            hw.subjectName.trim().toLowerCase() == resolvedSubjectName.trim().toLowerCase() &&
            isUuid(hw.subjectId)) {
          resolvedSubjectId = hw.subjectId;
        }
        if (resolvedCohortId == null &&
            resolvedSessionId != null &&
            hw.sessionId == resolvedSessionId &&
            isUuid(hw.cohortId)) {
          resolvedCohortId = hw.cohortId;
        }
      }
    } catch (_) {}
  }

  // 5. Fallback from allClasses if generic opening
  if (resolvedCohortId == null && allClasses.isNotEmpty) {
    final valid = allClasses.where((c) => isUuid(c.cohortId));
    if (valid.isNotEmpty) {
      resolvedCohortId = valid.first.cohortId;
      if (resolvedCohortName.isEmpty) resolvedCohortName = valid.first.group;
    }
  }
  if (resolvedSubjectId == null && allClasses.isNotEmpty) {
    final valid = allClasses.where((c) => isUuid(c.subjectId));
    if (valid.isNotEmpty) {
      resolvedSubjectId = valid.first.subjectId;
      if (resolvedSubjectName.isEmpty) resolvedSubjectName = valid.first.title;
    }
  }

  if (!context.mounted) return null;

  final titleController = TextEditingController(
    text: initialTitle?.isNotEmpty == true
        ? initialTitle!
        : (resolvedSubjectName.isNotEmpty
            ? '$resolvedSubjectName - ${ref.watchTr(AppStrings.homeworkTitle)}'
            : ''),
  );
  final descriptionController = TextEditingController(
    text: initialDescription ?? '',
  );
  DateTime selectedDueDate = DateTime.now().add(const Duration(days: 7));

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) {
      return Consumer(
        builder: (sheetCtx, sheetRef, _) {
          final tr = sheetRef.watchTr;
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 18.h,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.h,
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 36.w,
                            height: 4.h,
                            margin: EdgeInsets.only(bottom: 14.h),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundsLinesColor,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),

                        // Header Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr(AppStrings.createHomeworkSheetTitle),
                                style: TxtStyle.titleLarge(
                                  fontSize: 19.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(sheetContext).pop(false),
                            ),
                          ],
                        ),

                        // Class & Cohort Context Card
                        if (resolvedSubjectName.isNotEmpty || resolvedCohortName.isNotEmpty) ...[
                          SizedBox(height: 10.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blueSoft.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.primaryDark.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38.w,
                                  height: 38.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 20.sp,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        resolvedSubjectName.isNotEmpty
                                            ? resolvedSubjectName
                                            : tr(AppStrings.defaultSubjectName),
                                        style: TxtStyle.titleMedium(
                                          color: AppColors.text,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        resolvedCohortName.isNotEmpty
                                            ? resolvedCohortName
                                            : tr(AppStrings.bachillerato1),
                                        style: TxtStyle.bodySmall(
                                          color: AppColors.subtitleTextColor,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUuid(resolvedCohortId) && isUuid(resolvedSubjectId)) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F8F0),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 13.sp,
                                          color: AppColors.emeraldGreenColor,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          tr(AppStrings.activeStatus),
                                          style: TxtStyle.labelSmall(
                                            color: AppColors.emeraldGreenColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 16.h),

                        // Title TextField
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: tr(AppStrings.homeworkTitleField),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Instructions / Description TextField
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: tr(AppStrings.homeworkInstructionsField),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Due Date ListTile
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.event_outlined,
                            color: AppColors.primaryDark,
                          ),
                          title: Text(
                            '${tr(AppStrings.dueDateLabel)}: ${DateFormat('d MMM, yyyy').format(selectedDueDate)}',
                            style: TxtStyle.bodyMedium(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: TextButton(
                            child: Text(tr(AppStrings.changeBtn)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: sheetContext,
                                initialDate: selectedDueDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDueDate = picked);
                              }
                            },
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // Publish Button
                        Consumer(
                          builder: (innerCtx, innerRef, _) {
                            final actionState = innerRef.watch(
                              teacherHomeworkControllerProvider,
                            );
                            return SizedBox(
                              width: double.infinity,
                              child: AulaPrimaryButton(
                                text: tr(AppStrings.publishHomeworkBtn),
                                isLoading: actionState.isLoading,
                                onTap: () async {
                                  final titleText = titleController.text.trim();
                                  if (titleText.isEmpty) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr(AppStrings.homeworkTitleField),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }

                                  if (resolvedCohortId == null || !isUuid(resolvedCohortId)) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr(AppStrings.loadHomeworkError),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }

                                  if (resolvedSubjectId == null || !isUuid(resolvedSubjectId)) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr(AppStrings.loadHomeworkError),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }

                                  final effectiveSessionId =
                                      isUuid(resolvedSessionId)
                                          ? resolvedSessionId
                                          : (sessionId != null && sessionId.isNotEmpty
                                              ? sessionId
                                              : null);

                                  final success = await innerRef
                                      .read(teacherHomeworkControllerProvider.notifier)
                                      .createHomework(
                                        cohortId: resolvedCohortId,
                                        subjectId: resolvedSubjectId,
                                        sessionId: effectiveSessionId,
                                        title: titleText,
                                        description: descriptionController.text.trim().isEmpty
                                            ? null
                                            : descriptionController.text.trim(),
                                        startDate: DateTime.now(),
                                        dueDate: selectedDueDate,
                                      );

                                  if (success && sheetContext.mounted) {
                                    // 1. Close bottom sheet
                                    Navigator.of(sheetContext).pop(true);

                                    // 2. Refresh class session details and related lists
                                    if (resolvedCohortId != null) {
                                      ref.invalidate(teacherHomeworkListProvider(resolvedCohortId));
                                    }
                                    ref.invalidate(teacherHomeworkListProvider(null));

                                    if (effectiveSessionId != null && effectiveSessionId.isNotEmpty) {
                                      ref.invalidate(teacherSessionDetailProvider(effectiveSessionId));
                                      try {
                                        await ref.read(teacherSessionDetailProvider(effectiveSessionId).future);
                                      } catch (e) {
                                        debugPrint('Error refreshing class session details: $e');
                                      }
                                    }
                                    ref.invalidate(teacherClassesControllerProvider);
                                    ref.invalidate(teacherHomeControllerProvider);

                                    // 3. Show feedback snackbar
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.emeraldGreenColor,
                                          content: Text(
                                            tr(AppStrings.homeworkCreatedSuccess),
                                          ),
                                        ),
                                      );
                                    }

                                    // 4. Redirect back to class details
                                    if (context.mounted &&
                                        effectiveSessionId != null &&
                                        effectiveSessionId.isNotEmpty) {
                                      String? currentRoute;
                                      try {
                                        final state = GoRouterState.of(context);
                                        currentRoute = state.name ?? state.uri.path;
                                      } catch (_) {
                                        currentRoute = null;
                                      }
                                      final isAlreadyOnClassDetail = currentRoute != null &&
                                          (currentRoute == RoutePath.teacherClassDetail ||
                                              currentRoute.contains(RoutePath.teacherClassDetail));
                                      if (!isAlreadyOnClassDetail) {
                                        try {
                                          context.push(
                                            RoutePath.teacherClassDetail,
                                            extra: effectiveSessionId,
                                          );
                                        } catch (_) {}
                                      }
                                    }
                                  } else if (!success && sheetContext.mounted) {
                                    final err = innerRef.read(teacherHomeworkControllerProvider).error;
                                    if (err != null && err.isNotEmpty) {
                                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.error,
                                          content: Text(err),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
