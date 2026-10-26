import 'package:aula360/features/teacher_all/data/datasources/teacher_remote_data_source.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/reports/domain/repositories/teacher_reports_repository.dart';

class TeacherReportsRepositoryImpl implements TeacherReportsRepository {
  final TeacherRemoteDataSource? _remoteDataSource;
  final List<TeacherReport> _submittedReports = [];

  TeacherReportsRepositoryImpl([this._remoteDataSource]);

  @override
  Future<List<TeacherReport>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? cohortId,
  }) async {
    final remote = _remoteDataSource;
    if (remote != null) {
      try {
        final dtoList = await remote.getTeacherReports(
          page: page,
          limit: limit,
          status: status,
          cohortId: cohortId,
        );
        final mapped = dtoList.map((d) => d.toModel()).toList();
        return [...mapped, ..._submittedReports];
      } catch (_) {}
    }
    return [..._submittedReports];
  }

  @override
  Future<TeacherReport> getReportDetail(String id) async {
    final remote = _remoteDataSource;
    if (remote != null) {
      final detailDto = await remote.getTeacherReportDetail(id);
      return detailDto.toModel();
    }
    final match = _submittedReports.firstWhere(
      (r) => r.id == id,
      orElse: () => _submittedReports.isNotEmpty
          ? _submittedReports.first
          : const TeacherReport(
              category: ReportCategory.classReport,
              group: StudentGroup.groupA,
              title: 'Class Report',
              subtitle: 'Cohort',
              date: '',
              time: '',
              status: ReportStatus.submitted,
            ),
    );
    return match;
  }

  @override
  Future<void> submitReport(TeacherReport report) async {
    _submittedReports.insert(0, report);
  }
}
