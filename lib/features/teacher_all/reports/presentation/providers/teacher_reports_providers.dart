import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aula360/features/teacher_all/data/repositories/teacher_repository_impl.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/reports/data/repositories/teacher_reports_repository_impl.dart';
import 'package:aula360/features/teacher_all/reports/domain/repositories/teacher_reports_repository.dart';

final teacherReportsRepositoryProvider =
    Provider<TeacherReportsRepository>((ref) {
  final remote = ref.watch(teacherRemoteDataSourceProvider);
  return TeacherReportsRepositoryImpl(remote);
});

final teacherReportDetailProvider =
    FutureProvider.autoDispose.family<TeacherReport, String>((ref, id) async {
  final repository = ref.watch(teacherReportsRepositoryProvider);
  return repository.getReportDetail(id);
});
