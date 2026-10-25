import 'package:aula360/features/teacher_all/data/datasources/teacher_remote_data_source.dart';
import 'package:aula360/features/teacher_all/helper/teacher_enums.dart';
import 'package:aula360/features/teacher_all/helper/teacher_models.dart';
import 'package:aula360/features/teacher_all/reports/domain/repositories/teacher_reports_repository.dart';

class TeacherReportsRepositoryImpl implements TeacherReportsRepository {
  final TeacherRemoteDataSource? _remoteDataSource;
  final List<TeacherReport> _submittedReports = [];

  TeacherReportsRepositoryImpl([this._remoteDataSource]);

  @override
  Future<List<TeacherReport>> getReports() async {
    final list = <TeacherReport>[..._submittedReports];
    final remote = _remoteDataSource;
    if (remote != null) {
      try {
        final sessions = await remote.getSessions();
        for (final s in sessions) {
          if (s.status == 'COMPLETED') {
            final dateStr = s.sessionDate.length >= 10
                ? s.sessionDate.substring(0, 10)
                : s.sessionDate;
            list.add(
              TeacherReport(
                category: ReportCategory.classReport,
                group: StudentGroup.groupA,
                room: s.classroomRoomNumber,
                title: s.subjectName,
                subtitle: s.cohortName,
                date: dateStr,
                time: '${s.startTime} - ${s.endTime}',
                status: ReportStatus.submitted,
              ),
            );
          }
        }
      } catch (_) {}
    }
    return list;
  }

  @override
  Future<void> submitReport(TeacherReport report) async {
    _submittedReports.insert(0, report);
  }
}
