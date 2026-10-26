/// ===============================================================
/// PROFILE DATA
/// ===============================================================
library;

import '../reports/data/dtos/teacher_report_dto.dart';
import 'teacher_enums.dart';

class TeacherProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String designation;
  final String office;
  final String bio;
  final String language;
  final String? profileImagePath;

  const TeacherProfileData({
    this.id = '',
    required this.name,
    required this.email,
    required this.phone,
    this.department = 'Matemáticas y Física',
    this.designation = 'Faculty',
    this.office = '',
    this.bio =
        'Docente titular de matemáticas especializado en bachillerato, álgebra y preparación académica.',
    this.language = 'Español',
    this.profileImagePath,
  });

  TeacherProfileData copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? designation,
    String? office,
    String? bio,
    String? language,
    String? profileImagePath,
  }) {
    return TeacherProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      office: office ?? this.office,
      bio: bio ?? this.bio,
      language: language ?? this.language,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

/// ===============================================================
/// CLASS MODEL
/// ===============================================================

class AcademyClass {
  final String id;
  final String scheduleId;
  final String time;
  final String title;
  final String subtitle;
  final String room;
  final String group;
  final int students;
  final ClassStatus status;
  final String rawStatus;
  final String? cohortId;
  final String? subjectId;

  const AcademyClass({
    this.id = '',
    this.scheduleId = '',
    required this.time,
    required this.title,
    required this.subtitle,
    required this.room,
    required this.group,
    required this.students,
    required this.status,
    this.rawStatus = 'SCHEDULED',
    this.cohortId,
    this.subjectId,
  });

  AcademyClass copyWith({
    String? id,
    String? scheduleId,
    String? time,
    String? title,
    String? subtitle,
    String? room,
    String? group,
    int? students,
    ClassStatus? status,
    String? rawStatus,
    String? cohortId,
    String? subjectId,
  }) {
    return AcademyClass(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      time: time ?? this.time,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      room: room ?? this.room,
      group: group ?? this.group,
      students: students ?? this.students,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      cohortId: cohortId ?? this.cohortId,
      subjectId: subjectId ?? this.subjectId,
    );
  }
}

/// ===============================================================
/// STUDENT MODEL
/// ===============================================================

class AttendanceStudent {
  final String id;
  final String name;
  final String initials;
  final String desk;
  TeacherAttendanceStatus status;

  AttendanceStudent({
    this.id = '',
    required this.name,
    required this.initials,
    required this.desk,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE / MOCK DATA (Spanish Academy Context)
// ─────────────────────────────────────────────────────────────────────────────

const List<AcademyClass> todayClasses = [
  AcademyClass(
    time: '09:00 – 10:30',
    title: 'Matemáticas Avanzadas',
    subtitle: 'Cálculo y Álgebra',
    room: 'Aula 2',
    group: 'Grupo A',
    students: 18,
    status: ClassStatus.next,
  ),
  AcademyClass(
    time: '11:00 – 12:30',
    title: 'Estadística y Probabilidad',
    subtitle: 'Análisis e Inferencia',
    room: 'Aula 1',
    group: 'Grupo B',
    students: 22,
    status: ClassStatus.scheduled,
  ),
  AcademyClass(
    time: '14:00 – 15:30',
    title: 'Álgebra Lineal',
    subtitle: 'Espacios Vectoriales',
    room: 'Aula 2',
    group: 'Grupo A',
    students: 16,
    status: ClassStatus.scheduled,
  ),
  AcademyClass(
    time: '16:00 – 17:30',
    title: 'Seminario de Bachillerato',
    subtitle: 'Ecuaciones Diferenciales',
    room: 'Aula Magna',
    group: 'Grupo Superior',
    students: 14,
    status: ClassStatus.scheduled,
  ),
];

const List<AcademyClass> upcomingClasses = [
  AcademyClass(
    time: '09:00 – 10:30',
    title: 'Matemáticas II',
    subtitle: 'Técnicas de Integración',
    room: 'Aula 2',
    group: 'Grupo A',
    students: 18,
    status: ClassStatus.scheduled,
  ),
  AcademyClass(
    time: '11:00 – 12:30',
    title: 'Física y Química',
    subtitle: 'Cinemática y Dinámica',
    room: 'Aula 1',
    group: 'Grupo B',
    students: 20,
    status: ClassStatus.scheduled,
  ),
];

/// ===============================================================
/// HOME CLASS MODEL
/// ===============================================================

class HomeScheduleItem {
  final String id;
  final String scheduleId;
  final String startTime;
  final String endTime;
  final String title;
  final String subtitle;
  final String room;
  final String group;
  final int students;
  final HomeClassType type;
  final String rawStatus;

  const HomeScheduleItem({
    this.id = '',
    this.scheduleId = '',
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.subtitle,
    required this.room,
    required this.group,
    required this.students,
    required this.type,
    this.rawStatus = 'SCHEDULED',
  });
}

const List<HomeScheduleItem> homeSchedule = [
  HomeScheduleItem(
    startTime: '09:00',
    endTime: '10:30',
    title: 'Matemáticas II',
    subtitle: '',
    room: 'Aula 2',
    group: 'Grupo A',
    students: 18,
    type: HomeClassType.next,
  ),
  HomeScheduleItem(
    startTime: '11:00',
    endTime: '12:30',
    title: 'Física y Química',
    subtitle: '',
    room: 'Laboratorio 1',
    group: 'Grupo B',
    students: 16,
    type: HomeClassType.scheduled,
  ),
  HomeScheduleItem(
    startTime: '13:45',
    endTime: '15:15',
    title: 'Química Orgánica',
    subtitle: '',
    room: 'Aula 3',
    group: 'Grupo A',
    students: 20,
    type: HomeClassType.scheduled,
  ),
  HomeScheduleItem(
    startTime: '15:45',
    endTime: '17:00',
    title: 'Taller de Resolución de Problemas',
    subtitle: '',
    room: 'Aula Magna',
    group: 'Grupo C',
    students: 24,
    type: HomeClassType.scheduled,
  ),
];

//
class TeacherStudent {
  final String name;
  final String id;
  final StudentGroup group;
  final String room;
  final String desk;
  final int attendance;
  final StudentStatus status;
  final String initials;
  final String? avatarUrl;
  final String? gradeLevel;
  final String? enrollmentNumber;

  const TeacherStudent({
    required this.name,
    required this.id,
    required this.group,
    required this.room,
    required this.desk,
    required this.attendance,
    required this.status,
    required this.initials,
    this.avatarUrl,
    this.gradeLevel,
    this.enrollmentNumber,
  });
}

class TeacherReport {
  final String? id;
  final String? sessionId;
  final String? cohortId;
  final String? cohortName;
  final String? subjectId;
  final String? subjectName;
  final ReportCategory category;
  final StudentGroup group;
  final String? grade;
  final String? room;
  final String title;
  final String subtitle;
  final String date;
  final String time;
  final ReportStatus status;
  final String rawStatus;
  final String? studentName;
  final String? studentId;
  final String? contentCovered;
  final String? homeworkAssigned;
  final String? attitudeRating;
  final String? workEffortRating;
  final String? observations;
  final String? submittedAt;
  final String? reviewedAt;
  final String? reviewNote;
  final String? startTime;
  final String? endTime;
  final String? entryTime;
  final String? exitTime;
  final List<TeacherReportStudentAttendanceDto> attendances;
  final TeacherReportAttendanceSummaryDto? attendanceSummary;

  const TeacherReport({
    this.id,
    this.sessionId,
    this.cohortId,
    this.cohortName,
    this.subjectId,
    this.subjectName,
    required this.category,
    required this.group,
    this.grade,
    this.room,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.status,
    this.rawStatus = 'SUBMITTED',
    this.studentName,
    this.studentId,
    this.contentCovered,
    this.homeworkAssigned,
    this.attitudeRating,
    this.workEffortRating,
    this.observations,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
    this.startTime,
    this.endTime,
    this.entryTime,
    this.exitTime,
    this.attendances = const [],
    this.attendanceSummary,
  });

  TeacherReport copyWith({
    String? id,
    String? sessionId,
    String? cohortId,
    String? cohortName,
    String? subjectId,
    String? subjectName,
    ReportCategory? category,
    StudentGroup? group,
    String? grade,
    String? room,
    String? title,
    String? subtitle,
    String? date,
    String? time,
    ReportStatus? status,
    String? rawStatus,
    String? studentName,
    String? studentId,
    String? contentCovered,
    String? homeworkAssigned,
    String? attitudeRating,
    String? workEffortRating,
    String? observations,
    String? submittedAt,
    String? reviewedAt,
    String? reviewNote,
    String? startTime,
    String? endTime,
    String? entryTime,
    String? exitTime,
    List<TeacherReportStudentAttendanceDto>? attendances,
    TeacherReportAttendanceSummaryDto? attendanceSummary,
  }) {
    return TeacherReport(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      cohortId: cohortId ?? this.cohortId,
      cohortName: cohortName ?? this.cohortName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      category: category ?? this.category,
      group: group ?? this.group,
      grade: grade ?? this.grade,
      room: room ?? this.room,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      contentCovered: contentCovered ?? this.contentCovered,
      homeworkAssigned: homeworkAssigned ?? this.homeworkAssigned,
      attitudeRating: attitudeRating ?? this.attitudeRating,
      workEffortRating: workEffortRating ?? this.workEffortRating,
      observations: observations ?? this.observations,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      attendances: attendances ?? this.attendances,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
    );
  }
}

final List<TeacherStudent> students = const [
  TeacherStudent(
    name: 'Lucas Rivera',
    id: '#ST-2041',
    group: StudentGroup.groupA,
    room: 'Aula 2',
    desk: 'Mesa 14',
    attendance: 96,
    status: StudentStatus.present,
    initials: 'LR',
  ),
  TeacherStudent(
    name: 'Sofia Chen',
    id: '#ST-1988',
    group: StudentGroup.groupA,
    room: 'Aula 2',
    desk: 'Mesa 02',
    attendance: 100,
    status: StudentStatus.present,
    initials: 'SC',
  ),
  TeacherStudent(
    name: 'Marcos Williams',
    id: '#ST-2104',
    group: StudentGroup.groupB,
    room: 'Aula 1',
    desk: 'Mesa 10',
    attendance: 89,
    status: StudentStatus.needsCheckIn,
    initials: 'MW',
  ),
  TeacherStudent(
    name: 'Elena Rostova',
    id: '#ST-2079',
    group: StudentGroup.groupA,
    room: 'Aula 2',
    desk: 'Mesa 08',
    attendance: 98,
    status: StudentStatus.present,
    initials: 'ER',
  ),
  TeacherStudent(
    name: 'Noah Kim',
    id: '#ST-2135',
    group: StudentGroup.groupB,
    room: 'Aula 1',
    desk: 'Mesa 05',
    attendance: 94,
    status: StudentStatus.present,
    initials: 'NK',
  ),
  TeacherStudent(
    name: 'Maya Patel',
    id: '#ST-2180',
    group: StudentGroup.groupB,
    room: 'Aula 1',
    desk: 'Mesa 22',
    attendance: 92,
    status: StudentStatus.present,
    initials: 'MP',
  ),
];

//
final List<TeacherReport> reports = const [
  TeacherReport(
    category: ReportCategory.classReport,
    group: StudentGroup.groupA,
    grade: '1º Bachillerato',
    room: 'Aula 2',
    title: 'Matemáticas Avanzadas',
    subtitle: 'Regla de la Cadena y Ejercicios • Asistencia 18/18',
    date: 'Jue, 24 Oct',
    time: '10:28',
    status: ReportStatus.filed,
  ),
  TeacherReport(
    category: ReportCategory.classReport,
    group: StudentGroup.groupB,
    grade: '4º ESO',
    room: 'Aula 1',
    title: 'Física y Química',
    subtitle: 'Identidades y Leyes de Newton',
    date: 'Mar, 22 Oct',
    time: '11:15',
    status: ReportStatus.filed,
  ),
  TeacherReport(
    category: ReportCategory.studentReport,
    studentName: 'Lucas Rivera',
    studentId: '#ST-2041',
    title: 'Refuerzo de Álgebra (Individual)',
    subtitle: 'Ecuaciones de 2º grado y factorización',
    date: 'Lun, 21 Oct',
    time: '15:45',
    status: ReportStatus.submitted,
    group: StudentGroup.groupA,
  ),
  TeacherReport(
    category: ReportCategory.classReport,
    group: StudentGroup.groupA,
    grade: '2º Bachillerato',
    room: 'Aula 2',
    title: 'Preparación PAU / EvAU',
    subtitle: "Regla de L'Hôpital y archivo de exámenes",
    date: 'Vie, 18 Oct',
    time: '16:30',
    status: ReportStatus.filed,
  ),
  TeacherReport(
    category: ReportCategory.classReport,
    group: StudentGroup.groupB,
    grade: '4º ESO',
    room: 'Aula 1',
    title: 'Geometría y Trigonometría',
    subtitle: 'Construcciones con compás y teoremas',
    date: 'Mié, 16 Oct',
    time: '09:00',
    status: ReportStatus.filed,
  ),
];
