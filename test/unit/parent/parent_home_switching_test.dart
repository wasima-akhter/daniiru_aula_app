import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aula360/core/network/api_client.dart';
import 'package:aula360/features/parent_all/data/datasources/parent_remote_data_source.dart';
import 'package:aula360/features/parent_all/data/repositories/parent_repository_impl.dart';
import 'package:aula360/features/parent_all/presentation/controllers/parent_home_controller.dart';

class ParentHomeMockApiClient extends ApiClient {
  ParentHomeMockApiClient() : super(Dio());

  dynamic responseData;
  String? lastGetPath;
  Map<String, dynamic>? lastGetParams;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    lastGetParams = queryParameters;
    if (path.contains('/schedule')) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: {
          'success': true,
          'data': [
            {
              'id': 'session-1',
              'subject': 'Math - ${path.split('/')[4]}',
              'classroom': 'Room 1A',
              'teacherName': 'Prof Euler',
              'startTime': '09:00',
              'endTime': '10:00',
            }
          ],
        } as T,
        statusCode: 200,
      );
    }

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: responseData as T,
      statusCode: 200,
    );
  }
}

void main() {
  late ParentHomeMockApiClient mockClient;
  late ParentRepositoryImpl repository;

  setUp(() {
    mockClient = ParentHomeMockApiClient();
    final dataSource = ParentRemoteDataSourceImpl(mockClient);
    repository = ParentRepositoryImpl(parentRemoteDataSource: dataSource);
  });

  test('ParentHomeController loads children and defaults to first child', () async {
    mockClient.responseData = {
      'success': true,
      'data': [
        {
          'id': 'child-01',
          'fullName': 'Child One',
          'gradeLevel': '2nd Grade Primary',
          'enrollmentNumber': '111',
          'avatarUrl': '',
        },
        {
          'id': 'child-02',
          'fullName': 'Child Two',
          'gradeLevel': '1st ESO',
          'enrollmentNumber': '222',
          'avatarUrl': '',
        },
      ],
    };

    final container = ProviderContainer(
      overrides: [
        parentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(parentHomeControllerProvider.notifier).loadDashboardData();
    final state = container.read(parentHomeControllerProvider);

    expect(state.children.length, 2);
    expect(state.selectedChild?.id, 'child-01');
    expect(state.selectedChild?.name, 'Child One');
  });

  test('ParentHomeController switches to second child and reloads today classes', () async {
    mockClient.responseData = {
      'success': true,
      'data': [
        {
          'id': 'child-01',
          'fullName': 'Child One',
          'gradeLevel': '2nd Grade Primary',
        },
        {
          'id': 'child-02',
          'fullName': 'Child Two',
          'gradeLevel': '1st ESO',
        },
      ],
    };

    final container = ProviderContainer(
      overrides: [
        parentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // Allow build() microtask to finish
    container.read(parentHomeControllerProvider);
    await pumpEventQueue();
    final child2 = container.read(parentHomeControllerProvider).children[1];

    await container.read(parentHomeControllerProvider.notifier).selectChild(child2);
    final state = container.read(parentHomeControllerProvider);

    expect(state.selectedChild?.id, 'child-02');
    expect(state.selectedChild?.name, 'Child Two');
    expect(mockClient.lastGetPath, '/parent/children/child-02/schedule');
  });

  test('ParentHomeController switchToNextChild toggles in place between 2 children', () async {
    mockClient.responseData = {
      'success': true,
      'data': [
        {
          'id': 'child-01',
          'fullName': 'Child One',
          'gradeLevel': '2nd Grade Primary',
        },
        {
          'id': 'child-02',
          'fullName': 'Child Two',
          'gradeLevel': '1st ESO',
        },
      ],
    };

    final container = ProviderContainer(
      overrides: [
        parentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // Allow build() microtask to finish
    container.read(parentHomeControllerProvider);
    await pumpEventQueue();
    expect(container.read(parentHomeControllerProvider).selectedChild?.id, 'child-01');

    // Toggle 1 -> Child Two
    await container.read(parentHomeControllerProvider.notifier).switchToNextChild();
    expect(container.read(parentHomeControllerProvider).selectedChild?.id, 'child-02');
    expect(mockClient.lastGetPath, '/parent/children/child-02/schedule');

    // Toggle 2 -> Child One
    await container.read(parentHomeControllerProvider.notifier).switchToNextChild();
    expect(container.read(parentHomeControllerProvider).selectedChild?.id, 'child-01');
    expect(mockClient.lastGetPath, '/parent/children/child-01/schedule');
  });

  test('loadDashboardData preserves currently selected child if still valid', () async {
    mockClient.responseData = {
      'success': true,
      'data': [
        {
          'id': 'child-01',
          'fullName': 'Child One',
          'gradeLevel': '2nd Grade Primary',
        },
        {
          'id': 'child-02',
          'fullName': 'Child Two',
          'gradeLevel': '1st ESO',
        },
      ],
    };

    final container = ProviderContainer(
      overrides: [
        parentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // Allow build() microtask to finish
    container.read(parentHomeControllerProvider);
    await pumpEventQueue();
    final child2 = container.read(parentHomeControllerProvider).children[1];
    await container.read(parentHomeControllerProvider.notifier).selectChild(child2);
    expect(container.read(parentHomeControllerProvider).selectedChild?.id, 'child-02');

    // Pull to refresh / reload
    await container.read(parentHomeControllerProvider.notifier).loadDashboardData();
    expect(container.read(parentHomeControllerProvider).selectedChild?.id, 'child-02');
  });
}
