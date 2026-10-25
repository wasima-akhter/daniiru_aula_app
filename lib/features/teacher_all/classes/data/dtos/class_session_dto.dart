class SessionDetailStudentDto {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String enrollmentNumber;

  const SessionDetailStudentDto({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.enrollmentNumber,
  });

  factory SessionDetailStudentDto.fromJson(Map<String, dynamic> json) {
    return SessionDetailStudentDto(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      enrollmentNumber: json['enrollmentNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'enrollmentNumber': enrollmentNumber,
      };

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '--';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class ClassSessionDto {
  final String id;
  final String scheduleId;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? entryTime;
  final String? exitTime;
  final String subjectName;
  final String cohortName;
  final String teacherName;
  final String classroomRoomNumber;
  final List<SessionDetailStudentDto> students;

  const ClassSessionDto({
    required this.id,
    required this.scheduleId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.entryTime,
    this.exitTime,
    required this.subjectName,
    required this.cohortName,
    required this.teacherName,
    required this.classroomRoomNumber,
    this.students = const [],
  });

  factory ClassSessionDto.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['students'];
    final parsedStudents = <SessionDetailStudentDto>[];
    if (rawStudents is List) {
      for (final s in rawStudents) {
        if (s is Map<String, dynamic>) {
          parsedStudents.add(SessionDetailStudentDto.fromJson(s));
        }
      }
    }

    return ClassSessionDto(
      id: json['id'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? '',
      sessionDate: json['sessionDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? 'SCHEDULED',
      entryTime: json['entryTime'] as String?,
      exitTime: json['exitTime'] as String?,
      subjectName: json['subjectName'] as String? ?? '',
      cohortName: json['cohortName'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      classroomRoomNumber: json['classroomRoomNumber'] as String? ?? '',
      students: parsedStudents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'sessionDate': sessionDate,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      if (entryTime != null) 'entryTime': entryTime,
      if (exitTime != null) 'exitTime': exitTime,
      'subjectName': subjectName,
      'cohortName': cohortName,
      'teacherName': teacherName,
      'classroomRoomNumber': classroomRoomNumber,
      'students': students.map((s) => s.toJson()).toList(),
    };
  }
}
