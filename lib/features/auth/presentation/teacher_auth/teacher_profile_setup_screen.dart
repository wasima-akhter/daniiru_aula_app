import 'dart:io';

import '../../../nav/user_role/user_role_provider.dart';
import '../../../share/export/screen_export.dart';
import '../../../share/widgets/text_field/custom_text_field.dart';
import '../../../share/widgets/text_field/description_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class TeacherProfileSetupScreen extends ConsumerStatefulWidget {
  const TeacherProfileSetupScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<TeacherProfileSetupScreen> createState() =>
      _TeacherProfileSetupScreenState();
}

class _TeacherProfileSetupScreenState
    extends ConsumerState<TeacherProfileSetupScreen> {
  late final TextEditingController departmentController;
  late final TextEditingController designationController;
  late final TextEditingController bioController;

  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    departmentController = TextEditingController(text: user?.department ?? '');
    designationController =
        TextEditingController(text: user?.designation ?? '');
    bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    departmentController.dispose();
    designationController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void _previewProfilePhoto() {
    if (_profileImage == null) return;
    ImageViewerService.open(
      context,
      imageFile: _profileImage,
      title: designationController.text.isNotEmpty
          ? designationController.text
          : ref.tr(AppStrings.chooseProfilePhoto),
    );
  }

  Future<void> _showImagePicker() async {
    final image = await AppImagePicker.showImagePickerBottomSheet(
      context,
      ref: ref,
      showPreviewOption: _profileImage != null,
      onPreviewPhoto: _previewProfilePhoto,
      showRemoveOption: _profileImage != null,
      onRemovePhoto: () => setState(() => _profileImage = null),
    );

    if (image == null || !mounted) return;

    setState(() => _profileImage = image);
  }

  Future<void> _completeProfile() async {
    final langCode =
        ref.read(languageProvider).valueOrNull?.languageCode ??
        AulaValidation.activeLanguageCode;

    final department = departmentController.text.trim();
    final designation = designationController.text.trim();
    final bio = bioController.text.trim();

    if (!AulaValidation.required(
      value: department,
      fieldName: ref.tr(AppStrings.teacherDepartment),
      languageCode: langCode,
    )) {
      return;
    }

    if (!AulaValidation.required(
      value: designation,
      fieldName: ref.tr(AppStrings.teacherDesignation),
      languageCode: langCode,
    )) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .setupTeacherProfile(
          avatarFile: _profileImage,
          department: department.isNotEmpty ? department : null,
          designation: designation.isNotEmpty ? designation : null,
          bio: bio.isNotEmpty ? bio : null,
        );

    if (!mounted) return;

    if (success) {
      ref.read(userRoleProvider.notifier).loginAsTeacher();
      context.go(RoutePath.navigationPages);
    } else {
      final authState = ref.read(authControllerProvider);
      if (authState.userMessage != null) {
        ApiSnackbar.showUserMessage(authState.userMessage!);
      } else {
        final resolved = AppErrorResolver.resolve(
          authState.errorMessage,
          languageCode: langCode,
        );
        ApiSnackbar.showUserMessage(resolved);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15.sp,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 14, 22, 25 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        ref.watchTr(AppStrings.facultyProfileTitle),
                        style: TxtStyle.titleLarge(
                          color: AppColors.text,
                          fontSize: 25.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        ref.watchTr(AppStrings.facultyProfileDesc),
                        textAlign: TextAlign.center,
                        style: TxtStyle.titleLarge(
                          color: AppColors.secondaryText,
                          fontSize: 15.sp,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _profileImage != null
                                ? _previewProfilePhoto
                                : _showImagePicker,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipOval(
                                child: _profileImage != null
                                    ? Image.file(
                                        _profileImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: const Color(0xFFF0F4F8),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          size: 56,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImagePicker,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _sectionTitle(ref.watchTr(AppStrings.academicIdentity)),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: departmentController,
                      label: ref.watchTr(AppStrings.teacherDepartment),
                      hint: ref.watchTr(AppStrings.teacherDepartmentHint),
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 15),
                    AppTextField(
                      controller: designationController,
                      label: ref.watchTr(AppStrings.teacherDesignation),
                      hint: ref.watchTr(AppStrings.teacherDesignationHint),
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _fieldLabel(ref.watchTr(AppStrings.facultyBioFocus)),
                        Text(
                          ref.watchTr(AppStrings.optional),
                          style: TxtStyle.titleLarge(
                            color: AppColors.secondaryText,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    DescriptionTextField(
                      controller: bioController,
                      maxLines: 4,
                      hintText: ref.watchTr(AppStrings.facultyBioHint),
                    ),
                    const SizedBox(height: 28),
                    AulaPrimaryButton(
                      text: ref.watchTr(AppStrings.btnCompleteTeacherSetup),
                      isLoading: authState.isLoading,
                      onTap: _completeProfile,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        ref.watchTr(AppStrings.navigatesToFacultyDashboard),
                        style: TxtStyle.titleLarge(
                          color: AppColors.secondaryText,
                          fontSize: 15.sp,
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TxtStyle.titleLarge(
        color: AppColors.text,
        fontSize: 15.5.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TxtStyle.labelLarge(
        color: AppColors.text,
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
