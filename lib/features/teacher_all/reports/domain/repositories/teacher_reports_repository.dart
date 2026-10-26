import 'package:aula360/features/teacher_all/helper/teacher_models.dart';

abstract class TeacherReportsRepository {
  Future<List<TeacherReport>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? cohortId,
  });
  Future<TeacherReport> getReportDetail(String id);
  Future<void> submitReport(TeacherReport report);
}
