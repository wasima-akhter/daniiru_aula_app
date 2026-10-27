import 'dart:io';

import '../../../../core/utils/validators.dart';
import '../../../nav/user_role/user_role_provider.dart';
import '../../../share/export/screen_export.dart';
import '../../../share/widgets/dropdown/custom_dropdown_field.dart';
import '../../../share/widgets/text_field/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final TextEditingController occupationController;
  late final TextEditingController addressController;

  static const List<String> _relationshipKeys = [
    AppStrings.relationshipMother,
    AppStrings.relationshipFather,
    AppStrings.relationshipGuardian,
  ];

  String _selectedRelationshipKey = AppStrings.relationshipMother;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    occupationController = TextEditingController(text: user?.occupation ?? '');
    addressController = TextEditingController(text: user?.address ?? '');

    if (user?.relationWithChild != null &&
        user!.relationWithChild!.trim().isNotEmpty) {
      final rawRel = user.relationWithChild!.trim().toLowerCase();
      if (rawRel.contains('fath') || rawRel.contains('padr')) {
        _selectedRelationshipKey = AppStrings.relationshipFather;
      } else if (rawRel.contains('guard') || rawRel.contains('tutor')) {
        _selectedRelationshipKey = AppStrings.relationshipGuardian;
      } else {
        _selectedRelationshipKey = AppStrings.relationshipMother;
      }
    }
  }

  @override
  void dispose() {
    occupationController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _previewProfilePhoto() {
    if (_profileImage == null) return;
    ImageViewerService.open(
      context,
      imageFile: _profileImage,
      title: occupationController.text.isNotEmpty
          ? occupationController.text
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

    if (_profileImage == null) {
      ApiSnackbar.showUserMessage(
        UserFriendlyMessage(
          title: ref.tr(AppStrings.validationError),
          message: ref.tr(AppStrings.profileImageRequired),
        ),
        type: SnackbarType.error,
      );
      return;
    }

    final occupation = occupationController.text.trim();
    if (!AulaValidation.required(
      value: occupation,
      fieldName: ref.tr(AppStrings.occupation),
      languageCode: langCode,
    )) {
      return;
    }

    final address = addressController.text.trim();
    if (!AulaValidation.required(
      value: address,
      fieldName: ref.tr(AppStrings.residentialAddress),
      languageCode: langCode,
    )) {
      return;
    }

    final String relationValue;
    switch (_selectedRelationshipKey) {
      case AppStrings.relationshipMother:
        relationValue = 'Mother';
        break;
      case AppStrings.relationshipFather:
        relationValue = 'Father';
        break;
      case AppStrings.relationshipGuardian:
      default:
        relationValue = 'Guardian';
        break;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .setupParentProfile(
          avatarFile: _profileImage,
          address: address.isNotEmpty ? address : null,
          occupation: occupation.isNotEmpty ? occupation : null,
          relationWithChild: relationValue,
        );

    if (!mounted) return;

    if (success) {
      ref.read(userRoleProvider.notifier).loginAsParent();
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
            if (context.canPop())
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                        ref.watchTr(AppStrings.completeYourProfile),
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
                        ref.watchTr(AppStrings.completeYourProfileDesc),
                        textAlign: TextAlign.center,
                        style: TxtStyle.titleLarge(
                          color: AppColors.secondaryText,
                          fontSize: 15.sp,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _profileImage != null
                                ? _previewProfilePhoto
                                : _showImagePicker,
                            child: Container(
                              width: 70.w,
                              height: 70.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF7F8FA),
                                border: Border.all(
                                  color: const Color(0xFFD4DAE3),
                                ),
                              ),
                              child: ClipOval(
                                child: _profileImage != null
                                    ? Image.file(
                                        _profileImage!,
                                        width: 70.w,
                                        height: 70.w,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.person_outline_rounded,
                                        size: 27.sp,
                                        color: AppColors.secondaryText,
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _showImagePicker,
                              child: Container(
                                width: 26.w,
                                height: 26.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 16.h,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      ref.watchTr(AppStrings.relationshipToStudent),
                      style: context.titleMedium.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    CustomDropdownField<String>(
                      hintText: ref.watchTr(AppStrings.selectRelationship),
                      items: _relationshipKeys,
                      value: _selectedRelationshipKey,
                      labelBuilder: (key) => ref.watchTr(key),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedRelationshipKey = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: occupationController,
                      label: ref.watchTr(AppStrings.occupation),
                      hint: ref.watchTr(AppStrings.occupationHint),
                      icon: Icons.work_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: addressController,
                      label: ref.watchTr(AppStrings.residentialAddress),
                      hint: ref.watchTr(AppStrings.residentialAddressHint),
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 24),
                    AulaPrimaryButton(
                      text: ref.watchTr(AppStrings.btnCompleteProfile),
                      isLoading: authState.isLoading,
                      onTap: _completeProfile,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        ref.watchTr(AppStrings.navigatesToParentDashboard),
                        style: TxtStyle.titleSmall(
                          color: AppColors.secondaryText,
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
}
