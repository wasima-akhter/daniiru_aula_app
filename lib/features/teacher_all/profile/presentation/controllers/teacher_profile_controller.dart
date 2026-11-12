import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aula360/core/errors/app_error_resolver.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/core/services/notification/push_notification_service.dart';
import 'package:aula360/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aula360/features/auth/presentation/providers/auth_providers.dart';
import 'package:aula360/features/profile/data/dtos/teacher_profile_dto.dart';
import 'package:aula360/features/profile/domain/entities/teacher_profile_entity.dart';
import 'package:aula360/features/profile/presentation/providers/profile_providers.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';

class TeacherProfileState {
  final TeacherProfileData profile;
  final bool isSaving;
  final bool isLoading;
  final String? error;
  final UserFriendlyMessage? userMessage;

  const TeacherProfileState({
    this.profile = const TeacherProfileData(
      name: 'Educator',
      email: '',
      phone: '',
    ),
    this.isSaving = false,
    this.isLoading = false,
    this.error,
    this.userMessage,
  });

  TeacherProfileState copyWith({
    TeacherProfileData? profile,
    bool? isSaving,
    bool? isLoading,
    String? error,
    UserFriendlyMessage? userMessage,
  }) {
    return TeacherProfileState(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userMessage: userMessage,
    );
  }
}

final teacherProfileControllerProvider =
    NotifierProvider<TeacherProfileController, TeacherProfileState>(
      TeacherProfileController.new,
    );

class TeacherProfileController extends Notifier<TeacherProfileState> {
  bool _isFetching = false;
  bool _hasFetched = false;

  @override
  TeacherProfileState build() {
    final currentLang =
        ref.read(languageProvider).valueOrNull?.language.label ?? 'English';

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        _hasFetched = false;
        _isFetching = false;
        final nextUser = next.user;
        if (nextUser != null) {
          final nextProfile = TeacherProfileData(
            id: nextUser.id,
            name: nextUser.fullName.isNotEmpty
                ? nextUser.fullName
                : 'Educator',
            email: nextUser.email,
            phone: nextUser.phone ?? '',
            department: nextUser.department ?? 'Academics',
            designation: nextUser.designation ?? 'Faculty',
            bio: nextUser.bio ?? '',
            language: currentLang,
            profileImagePath: nextUser.avatarUrl,
          );
          state = TeacherProfileState(profile: nextProfile, isLoading: false);
          Future.microtask(() => loadProfile(force: true));
        } else {
          state = const TeacherProfileState(
            profile: TeacherProfileData(
              name: '',
              email: '',
              phone: '',
            ),
          );
        }
      }
    });

    ref.listen<AsyncValue<LanguageState>>(languageProvider, (previous, next) {
      final prevCode = previous?.asData?.value.languageCode;
      final nextCode = next.asData?.value.languageCode;
      if (prevCode != null && nextCode != null && prevCode != nextCode) {
        Future.microtask(() => loadProfile(force: true));
      }
    });

    final authUser = ref.read(authControllerProvider).user;

    final initialProfile = TeacherProfileData(
      id: authUser?.id ?? '',
      name: authUser?.fullName.isNotEmpty == true
          ? authUser!.fullName
          : 'Educator',
      email: authUser?.email.isNotEmpty == true ? authUser!.email : '',
      phone: authUser?.phone ?? '',
      department: authUser?.department ?? 'Academics',
      designation: authUser?.designation ?? 'Faculty',
      bio: authUser?.bio ?? '',
      language: currentLang,
      profileImagePath: authUser?.avatarUrl,
    );

    if (!_hasFetched && !_isFetching) {
      Future.microtask(() => loadProfile());
    }
    return TeacherProfileState(profile: initialProfile, isLoading: false);
  }

  UserFriendlyMessage _resolveError(Object error) {
    final langCode =
        ref.read(languageProvider).valueOrNull?.languageCode ?? 'en';
    return AppErrorResolver.resolve(error, languageCode: langCode);
  }

  /// Fetches the authenticated teacher profile from GET /api/v1/profile/teacher.
  Future<void> loadProfile({bool force = false}) async {
    if (!ref.mounted) return;
    if (_isFetching && !force) return;
    _isFetching = true;
    _hasFetched = true;
    state = state.copyWith(isLoading: true, error: null, userMessage: null);
    try {
      // Ensure the device FCM token is registered on the backend session
      try {
        final pushService = ref.read(pushNotificationServiceProvider);
        final token = await pushService.getCachedOrFetchToken();
        if (token != null && token.isNotEmpty) {
          debugPrint('══════════════════════════════════════════════════════════════');
          debugPrint('🌐 FCM PUSH TEST: Pre-syncing device token before GET profile');
          debugPrint('══════════════════════════════════════════════════════════════');
          debugPrint('ACTION    : Syncing active FCM token with backend session');
          debugPrint('ENDPOINT  : POST /api/v1/auth/check');
          debugPrint('TOKEN     : $token');
          debugPrint('TIMESTAMP : ${DateTime.now().toIso8601String()}');
          debugPrint('══════════════════════════════════════════════════════════════');
          await ref.read(checkSessionUseCaseProvider).call(fcmToken: token);
          debugPrint('✅ FCM Token successfully registered on backend session.');
        } else {
          debugPrint('⚠️ Warning: FCM token is null/empty. Push cannot be received.');
        }
      } catch (e) {
        debugPrint('⚠️ FCM Token pre-sync error: $e');
      }

      final p = await ref.read(getTeacherProfileUseCaseProvider).call();
      if (!ref.mounted) return;
      _applyProfile(p);
    } catch (e) {
      if (!ref.mounted) return;
      final msg = _resolveError(e);
      state = state.copyWith(
        isLoading: false,
        error: msg.displayMessage,
        userMessage: msg,
      );
    } finally {
      if (ref.mounted) {
        _isFetching = false;
      }
    }
  }

  /// Updates authenticated teacher profile via POST /api/v1/profile/teacher.
  Future<bool> updateProfile(
    TeacherProfileData newProfile, {
    File? avatarFile,
  }) async {
    state = state.copyWith(isSaving: true, error: null, userMessage: null);
    try {
      String? avatarUrl = newProfile.profileImagePath;

      // If user selected a new local file, upload it first to S3/CDN
      if (avatarFile != null) {
        final uploadedUrls = await ref
            .read(uploadMediaUseCaseProvider)
            .call(files: [avatarFile]);
        if (uploadedUrls.isNotEmpty) {
          avatarUrl = uploadedUrls.first;
        }
      }

      final dto = UpdateTeacherProfileDto(
        fullName: newProfile.name,
        avatarUrl: avatarUrl,
        phone: newProfile.phone,
        department: newProfile.department,
        designation: newProfile.designation.isNotEmpty
            ? newProfile.designation
            : 'Faculty',
        bio: newProfile.bio,
      );

      final updated =
          await ref.read(updateTeacherProfileUseCaseProvider).call(dto);

      _applyProfile(updated);
      return true;
    } catch (e) {
      final msg = _resolveError(e);
      state = state.copyWith(
        isSaving: false,
        error: msg.displayMessage,
        userMessage: msg,
      );
      return false;
    }
  }

  void _applyProfile(TeacherProfileEntity entity) {
    final updatedData = state.profile.copyWith(
      id: entity.userId,
      name: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      department: entity.department ?? state.profile.department,
      designation: entity.designation ?? state.profile.designation,
      bio: entity.bio ?? state.profile.bio,
      language: entity.language,
      profileImagePath: entity.avatarUrl ?? state.profile.profileImagePath,
    );

    state = state.copyWith(
      profile: updatedData,
      isLoading: false,
      isSaving: false,
      error: null,
      userMessage: null,
    );

    // Sync with AuthController only if data changed
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      final updatedAuthUser = currentUser.copyWith(
        fullName: entity.fullName,
        phone: entity.phone,
        avatarUrl: entity.avatarUrl,
        department: entity.department,
        designation: entity.designation,
        bio: entity.bio,
      );
      if (updatedAuthUser.fullName != currentUser.fullName ||
          updatedAuthUser.phone != currentUser.phone ||
          updatedAuthUser.avatarUrl != currentUser.avatarUrl ||
          updatedAuthUser.department != currentUser.department ||
          updatedAuthUser.designation != currentUser.designation ||
          updatedAuthUser.bio != currentUser.bio) {
        ref.read(authControllerProvider.notifier).updateUser(updatedAuthUser);
      }
    }
  }

  void updateProfileImage(String? imagePath) {
    state = state.copyWith(
      profile: state.profile.copyWith(profileImagePath: imagePath),
    );
  }
}
