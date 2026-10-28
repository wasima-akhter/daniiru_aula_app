import 'package:intl/intl.dart';

import '../../parent_all/helper/parent_home_helper.dart';
import '../../share/export/screen_export.dart';
import 'data/dtos/teacher_homework_dto.dart';
import 'presentation/controllers/teacher_homework_controller.dart';
import 'presentation/providers/teacher_homework_providers.dart';
import 'presentation/widgets/assign_homework_bottom_sheet.dart';

class TeacherHomeworkScreen extends ConsumerStatefulWidget {
  final String? initialCohortId;
  final String? initialCohortName;
  final String? initialSubjectId;
  final String? initialSubjectName;
  final String? sessionId;
  final String? initialTitle;
  final String? initialDescription;
  final bool autoOpenCreateSheet;
  final bool fromClassFlow;

  const TeacherHomeworkScreen({
    super.key,
    this.initialCohortId,
    this.initialCohortName,
    this.initialSubjectId,
    this.initialSubjectName,
    this.sessionId,
    this.initialTitle,
    this.initialDescription,
    this.autoOpenCreateSheet = false,
    this.fromClassFlow = false,
  });

  static bool isValidUuid(String? str) {
    if (str == null) return false;
    final trimmed = str.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed);
  }

  @override
  ConsumerState<TeacherHomeworkScreen> createState() =>
      _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends ConsumerState<TeacherHomeworkScreen> {
  String? _selectedCohortId;
  final ScrollController _scrollController = ScrollController();
  late final AulaPagedScrollListener _pagedListener;

  @override
  void initState() {
    super.initState();
    if (widget.initialCohortId != null && widget.initialCohortId!.isNotEmpty) {
      _selectedCohortId = widget.initialCohortId;
    }
    _pagedListener = AulaPagedScrollListener(
      controller: _scrollController,
      onLoadMore: () =>
          ref.read(teacherHomeworkListControllerProvider.notifier).loadMore(),
    );

    if (widget.autoOpenCreateSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openCreateHomeworkSheet(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _pagedListener.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(teacherHomeworkListControllerProvider);
    final listController = ref.read(
      teacherHomeworkListControllerProvider.notifier,
    );
    final homeworkList = listState.items;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AulaAppBar(
        title: ref.watchTr(AppStrings.homeworkTitle),
        showBack: true,
        leading: widget.fromClassFlow
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.primaryDark,
                  size: 24.sp,
                ),
                tooltip: ref.watchTr(AppStrings.finishBtn),
                onPressed: () => context.go(RoutePath.navigationPages),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryDark,
              size: 24.sp,
            ),
            tooltip: ref.watchTr(AppStrings.newHomeworkTitle),
            onPressed: () => _openCreateHomeworkSheet(context),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: listController.refresh,
          child: Builder(
            builder: (context) {
              if (listState.isLoading && homeworkList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (listState.error != null && homeworkList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                          ref.watchTr(AppStrings.loadHomeworkError),
                          style: TxtStyle.titleLarge(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          AppErrorResolver.resolve(
                            listState.error!,
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
                          onTap: listController.loadInitial,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (homeworkList.isEmpty) {
                return _buildEmptyState(context);
              }

              final hasFooter =
                  listState.isLoadingMore ||
                  (listState.loadMoreError != null &&
                      listState.loadMoreError!.isNotEmpty);

              return ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                itemCount: homeworkList.length + (hasFooter ? 1 : 0),
                separatorBuilder: (_, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  if (index >= homeworkList.length) {
                    return AulaPagedFooter(
                      isLoadingMore: listState.isLoadingMore,
                      loadMoreError: listState.loadMoreError,
                      onRetry: listController.loadMore,
                    );
                  }
                  final item = homeworkList[index];
                  return _buildHomeworkCard(context, item);
                },
              );
            },
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: AppColors.primaryDark,
      //   onPressed: () => _openCreateHomeworkSheet(context),
      //   icon: const Icon(Icons.add, color: Colors.white),
      //   label: Text(
      //     ref.watchTr(AppStrings.newHomeworkTitle),
      //     style: TxtStyle.titleMedium(
      //       color: Colors.white,
      //       fontWeight: FontWeight.w700,
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: 100.h),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primaryDark,
                  size: 36.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                ref.watchTr(AppStrings.noHomeworkTeacher),
                style: TxtStyle.titleLarge(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                ref.watchTr(AppStrings.noHomeworkTeacherDesc),
                textAlign: TextAlign.center,
                style: TxtStyle.bodyMedium(
                  color: AppColors.subtitleTextColor,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: AulaPrimaryButton(
                  text: ref.watchTr(AppStrings.assignHomeworkBtn),
                  onTap: () => _openCreateHomeworkSheet(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworkCard(BuildContext context, TeacherHomeworkDto item) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  item.subjectName.isNotEmpty
                      ? item.subjectName
                      : ref.watchTr(AppStrings.defaultSubjectName),
                  style: TxtStyle.labelLarge(
                    color: AppColors.primaryDark,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14.sp,
                      color: AppColors.subtitleTextColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${item.submissionsCount} ${ref.watchTr(AppStrings.submissionsCountLabel)}',
                      style: TxtStyle.bodyMedium(
                        color: AppColors.subtitleTextColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            item.title,
            style: TxtStyle.titleLarge(
              color: AppColors.text,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              item.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TxtStyle.bodyMedium(
                color: AppColors.subtitleTextColor,
                fontSize: 13.5.sp,
                height: 1.35,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Divider(color: AppColors.backgroundsLinesColor, height: 1),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13.sp,
                color: AppColors.subtitleTextColor,
              ),
              SizedBox(width: 4.w),
              Text(
                '${ref.watchTr(AppStrings.duePrefix)}: ${_formatDate(item.dueDate)}',
                style: TxtStyle.bodyMedium(
                  color: AppColors.subtitleTextColor,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _openMarkSubmissionDialog(context, item),
                child: Text(
                  ref.watchTr(AppStrings.gradeBtn),
                  style: TxtStyle.titleMedium(
                    color: AppColors.primaryDark,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return ref.watchTr(AppStrings.soonLabel);
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('d MMM, yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _openCreateHomeworkSheet(BuildContext context) async {
    final created = await showAssignHomeworkBottomSheet(
      context: context,
      ref: ref,
      cohortId: widget.initialCohortId,
      cohortName: widget.initialCohortName,
      subjectId: widget.initialSubjectId,
      subjectName: widget.initialSubjectName,
      sessionId: widget.sessionId,
      initialTitle: widget.initialTitle,
      initialDescription: widget.initialDescription,
    );
    if (created == true && widget.fromClassFlow && context.mounted) {
      if (widget.sessionId == null || widget.sessionId!.isEmpty) {
        context.pop();
      }
    }
  }

  void _openMarkSubmissionDialog(
    BuildContext context,
    TeacherHomeworkDto item,
  ) {
    final noteController = TextEditingController();
    String selectedStatus = 'COMPLETED';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (dialogCtx, dialogRef, _) {
            final tr = dialogRef.watchTr;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(
                    tr(AppStrings.gradeSubmissionTitle),
                    style: TxtStyle.titleLarge(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tr(AppStrings.homeworkLabel)}: ${item.title}',
                        style: TxtStyle.bodyMedium(
                          fontSize: 14.sp,
                          color: AppColors.subtitleTextColor,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: tr(AppStrings.statusLabel),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'COMPLETED',
                            child: Text(tr(AppStrings.statusCompletedOption)),
                          ),
                          DropdownMenuItem(
                            value: 'NEEDS_REVISION',
                            child: Text(
                              tr(AppStrings.statusNeedsRevisionOption),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStatus = val);
                          }
                        },
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: tr(AppStrings.commentNoteField),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(tr(AppStrings.cancelBtn)),
                    ),
                    Consumer(
                      builder: (ctx, innerRef, _) {
                        final actionState = innerRef.watch(
                          teacherHomeworkControllerProvider,
                        );
                        return TextButton(
                          onPressed: actionState.isLoading
                              ? null
                              : () async {
                                  final success = await innerRef
                                      .read(
                                        teacherHomeworkControllerProvider
                                            .notifier,
                                      )
                                      .markHomeworkSubmission(
                                        homeworkId: item.id.isNotEmpty
                                            ? item.id
                                            : 'hw-1',
                                        studentId: 'student-1',
                                        status: selectedStatus,
                                        note: noteController.text.trim().isEmpty
                                            ? null
                                            : noteController.text.trim(),
                                      );
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                    innerRef.invalidate(
                                      teacherHomeworkListProvider(
                                        _selectedCohortId,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? tr(
                                                  AppStrings
                                                      .submissionGradedSuccess,
                                                )
                                              : tr(
                                                  AppStrings
                                                      .submissionGradedError,
                                                ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            tr(AppStrings.saveBtn),
                            style: TxtStyle.titleMedium(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/*


lib\features\teacher_all\homework\teacher_homework_screen.dart --> in the bottom sheet,
this is not properly implemented.
no validation snack, no message showing the reason why the publish homework failed.


*/
