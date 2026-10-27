import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aula360/core/session/session_invalidator.dart';
import 'package:aula360/features/auth/domain/entities/auth_user.dart';
import 'package:aula360/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aula360/features/nav/presentation/screens/navigation_provider.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/domain/models/parent_models.dart';
import 'package:aula360/features/parent_all/domain/repositories/parent_repository.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_children_controller.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_home_controller.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_profile_controller.dart';
import 'package:aula360/features/profile/data/dtos/parent_profile_dto.dart';
import 'package:aula360/features/profile/data/dtos/teacher_profile_dto.dart';
import 'package:aula360/features/profile/domain/entities/parent_profile_entity.dart';
import 'package:aula360/features/profile/domain/entities/teacher_profile_entity.dart';
import 'package:aula360/features/profile/domain/repositories/profile_repository.dart';
import 'package:aula360/features/profile/presentation/providers/profile_providers.dart';
import 'package:aula360/features/teacher_all/classes/data/dtos/class_session_dto.dart';
import 'package:aula360/features/teacher_all/classes/domain/repositories/teacher_classes_repository.dart';
import 'package:aula360/features/teacher_all/classes/presentation/providers/teacher_classes_providers.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/home/presentation/controllers/teacher_home_controller.dart';
import 'package:aula360/features/teacher_all/profile/presentation/controllers/teacher_profile_controller.dart';
import 'package:aula360/utils/enum/app_enum.dart';

class DynamicProfileRepository implements ProfileRepository {
  DynamicProfileRepository(this.ref);
  final Ref ref;

  @override
  Future<ParentProfileEntity> getParentProfile() async {
    final currentUserId = ref.read(authControllerProvider).user?.id ?? '';
    return ParentProfileEntity(
      userId: currentUserId,
      fullName: currentUserId == 'parent-user-b' ? 'Jane Smith' : 'John Doe',
      email: currentUserId == 'parent-user-b'
          ? 'jane.smith@example.com'
          : 'john.doe@example.com',
      phone: currentUserId == 'parent-user-b' ? '+1987654321' : '+1234567890',
      avatarUrl: currentUserId == 'parent-user-b'
          ? 'https://example.com/jane.jpg'
          : 'https://example.com/john.jpg',
    );
  }

  @override
  Future<TeacherProfileEntity> getTeacherProfile() async {
    final currentUserId = ref.read(authControllerProvider).user?.id ?? '';
    return TeacherProfileEntity(
      userId: currentUserId,
      fullName: currentUserId == 'teacher-user-b'
          ? 'Prof. Robert Taylor'
          : 'Dr. Sarah Jenkins',
      email: currentUserId == 'teacher-user-b'
          ? 'robert.taylor@example.com'
          : 'sarah.jenkins@example.com',
      phone: currentUserId == 'teacher-user-b' ? '+1444555666' : '+15552045',
      department: currentUserId == 'teacher-user-b' ? 'Physics' : 'Mathematics',
      designation: currentUserId == 'teacher-user-b'
          ? 'Professor'
          : 'Head of Mathematics',
      bio: 'Educator profile bio',
      avatarUrl: currentUserId == 'teacher-user-b'
          ? 'https://example.com/robert.jpg'
          : 'https://example.com/sarah.jpg',
    );
  }

  @override
  Future<ParentProfileEntity> updateParentProfile(UpdateParentProfileDto dto) =>
      throw UnimplementedError();

  @override
  Future<TeacherProfileEntity> updateTeacherProfile(
    UpdateTeacherProfileDto dto,
  ) =>
      throw UnimplementedError();
}

class DynamicParentRepository implements ParentRepository {
  DynamicParentRepository(this.ref);
  final Ref ref;

  @override
  Future<List<ChildModel>> getChildren() async {
    final currentUserId = ref.read(authControllerProvider).user?.id ?? '';
    if (currentUserId == 'parent-user-b') {
      return const [
        ChildModel(
          id: 'child-user-b-1',
          name: 'Bob Smith',
          grade: 'Grade 3',
          room: '102',
          imageUrl: 'https://example.com/bob.jpg',
          parentTeacher: 'Mrs. Davis',
          attendance: 98.0,
          present: 98,
          late: 1,
          absent: 1,
        ),
      ];
    } else {
      return const [
        ChildModel(
          id: 'child-user-a-1',
          name: 'Alice Doe',
          grade: 'Grade 5',
          room: '204',
          imageUrl: 'https://example.com/alice.jpg',
          parentTeacher: 'Mr. Johnson',
          attendance: 95.0,
          present: 95,
          late: 2,
          absent: 3,
        ),
      ];
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DynamicTeacherClassesRepository implements TeacherClassesRepository {
  DynamicTeacherClassesRepository(this.ref);
  final Ref ref;

  @override
  Future<List<ClassSessionDto>> getSessions({DateTime? date}) async {
    final currentUserId = ref.read(authControllerProvider).user?.id ?? '';
    return [
      ClassSessionDto(
        id: currentUserId == 'teacher-user-b' ? 'sess-b-1' : 'sess-a-1',
        scheduleId: 'sched-1',
        sessionDate: '2026-10-27',
        subjectName:
            currentUserId == 'teacher-user-b' ? 'Advanced Physics' : 'Calculus',
        cohortName: currentUserId == 'teacher-user-b' ? 'Physics 101' : 'Math A',
        teacherName: 'Teacher',
        classroomRoomNumber: '101',
        startTime: '09:00',
        endTime: '10:30',
        status: 'ONGOING',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  void loginAsUser(AuthUser user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      role: user.role,
      accessToken: 'token_${user.id}',
    );
    clearUserSessionState(ref);
  }

  void logoutUser() {
    clearUserSessionState(ref);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Switch & State Invalidation Tests', () {
    test(
      'Switching between two Parent accounts refreshes profile, children, and dashboard data',
      () async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(TestAuthController.new),
            profileRepositoryProvider.overrideWith(
              (ref) => DynamicProfileRepository(ref),
            ),
            parentRepositoryProvider.overrideWith(
              (ref) => DynamicParentRepository(ref),
            ),
          ],
        );
        addTearDown(container.dispose);

        final authNotifier =
            container.read(authControllerProvider.notifier) as TestAuthController;

        // 1. User A (John Doe) logs in
        const userA = AuthUser(
          id: 'parent-user-a',
          fullName: 'John Doe',
          email: 'john.doe@example.com',
          role: UserRole.parent,
          isProfileSetup: true,
        );
        authNotifier.loginAsUser(userA);

        // Move tab to tab 3 (Reports)
        container.read(navigationProvider.notifier).changeTab(3);
        expect(container.read(navigationProvider), equals(3));

        // Let async microtasks execute for User A
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final profileA = container.read(parentProfileControllerProvider);
        expect(profileA.name, equals('John Doe'));
        expect(profileA.email, equals('john.doe@example.com'));

        final childrenA = container.read(parentChildrenControllerProvider);
        expect(childrenA.children.length, equals(1));
        expect(childrenA.children.first.name, equals('Alice Doe'));

        final homeA = container.read(parentHomeControllerProvider);
        expect(homeA.children.first.name, equals('Alice Doe'));

        // 2. User A logs out
        authNotifier.logoutUser();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Navigation should be reset to tab 0
        expect(container.read(navigationProvider), equals(0));

        // 3. User B (Jane Smith) logs in
        const userB = AuthUser(
          id: 'parent-user-b',
          fullName: 'Jane Smith',
          email: 'jane.smith@example.com',
          role: UserRole.parent,
          isProfileSetup: true,
        );
        authNotifier.loginAsUser(userB);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // 4. Verify User B has fresh, refreshed data and DOES NOT see User A's data
        final profileB = container.read(parentProfileControllerProvider);
        expect(profileB.name, equals('Jane Smith'));
        expect(profileB.email, equals('jane.smith@example.com'));
        expect(profileB.userId, equals('parent-user-b'));

        final childrenB = container.read(parentChildrenControllerProvider);
        expect(childrenB.children.length, equals(1));
        expect(childrenB.children.first.name, equals('Bob Smith'));
        expect(childrenB.children.first.id, equals('child-user-b-1'));

        final homeB = container.read(parentHomeControllerProvider);
        expect(homeB.children.first.name, equals('Bob Smith'));
      },
    );

    test(
      'Switching between two Teacher accounts refreshes profile and home schedule data',
      () async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(TestAuthController.new),
            profileRepositoryProvider.overrideWith(
              (ref) => DynamicProfileRepository(ref),
            ),
            teacherClassesRepositoryProvider.overrideWith(
              (ref) => DynamicTeacherClassesRepository(ref),
            ),
          ],
        );
        addTearDown(container.dispose);

        final authNotifier =
            container.read(authControllerProvider.notifier) as TestAuthController;

        // 1. Teacher A (Sarah Jenkins) logs in
        const teacherA = AuthUser(
          id: 'teacher-user-a',
          fullName: 'Dr. Sarah Jenkins',
          email: 'sarah.jenkins@example.com',
          role: UserRole.teacher,
          isProfileSetup: true,
        );
        authNotifier.loginAsUser(teacherA);

        container.read(navigationProvider.notifier).changeTab(2);
        expect(container.read(navigationProvider), equals(2));

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final teacherProfileA =
            container.read(teacherProfileControllerProvider).profile;
        expect(teacherProfileA.name, equals('Dr. Sarah Jenkins'));
        expect(teacherProfileA.department, equals('Mathematics'));

        final homeA = container.read(teacherHomeControllerProvider);
        expect(homeA.schedule.first.title, equals('Calculus'));

        // 2. Teacher A logs out
        authNotifier.logoutUser();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(container.read(navigationProvider), equals(0));

        // 3. Teacher B (Robert Taylor) logs in
        const teacherB = AuthUser(
          id: 'teacher-user-b',
          fullName: 'Prof. Robert Taylor',
          email: 'robert.taylor@example.com',
          role: UserRole.teacher,
          isProfileSetup: true,
        );
        authNotifier.loginAsUser(teacherB);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // 4. Verify Teacher B sees their own fresh profile and schedule, not Teacher A's
        final teacherProfileB =
            container.read(teacherProfileControllerProvider).profile;
        expect(teacherProfileB.name, equals('Prof. Robert Taylor'));
        expect(teacherProfileB.department, equals('Physics'));
        expect(teacherProfileB.id, equals('teacher-user-b'));

        final homeB = container.read(teacherHomeControllerProvider);
        expect(homeB.schedule.first.title, equals('Advanced Physics'));
      },
    );
  });
}
