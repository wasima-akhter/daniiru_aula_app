import 'package:aula360/core/localization/localization_meta.dart';
import 'package:aula360/core/localization/pending_refetch_controller.dart';
import 'package:aula360/core/service/language/language_provider.dart';
import 'package:aula360/features/legal/data/dtos/legal_content_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/announcement_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/child_homework_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/child_schedule_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/conversation_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/notification_dto.dart';
import 'package:aula360/features/parent_all/data/dtos/parent_invoice_dto.dart';
import 'package:aula360/features/share/widgets/translation/translation_status_badge.dart';
import 'package:aula360/features/teacher_all/classes/data/dtos/class_session_dto.dart';
import 'package:aula360/features/teacher_all/homework/data/dtos/teacher_homework_dto.dart';
import 'package:aula360/features/teacher_all/reports/data/dtos/teacher_report_dto.dart';
import 'package:aula360/utils/app_strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLanguageNotifier extends LanguageNotifier {
  @override
  Future<LanguageState> build() async {
    return const LanguageState(
      language: AppLanguage.english,
      strings: {
        AppStrings.translationStatusTranslating: 'Translating...',
        AppStrings.translationStatusTranslated: 'Translated',
        AppStrings.translationStatusFailed: 'Translation unavailable',
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizationMeta', () {
    test('parses flat root fields accurately', () {
      final meta = LocalizationMeta.tryParse({
        'sourceLocale': 'ES',
        'displayedLocale': 'EN',
        'isTranslated': true,
        'translationStatus': 'ready',
      });

      expect(meta, isNotNull);
      expect(meta!.sourceLocale, 'es');
      expect(meta.displayedLocale, 'en');
      expect(meta.isTranslated, isTrue);
      expect(meta.translationStatus, 'READY');
      expect(meta.isPending, isFalse);
      expect(meta.isFailed, isFalse);
      expect(meta.showTranslatedBadge, isTrue);
    });

    test('parses nested localization block and handles PENDING/PROCESSING/FAILED', () {
      final processing = LocalizationMeta.tryParse({
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': false,
          'translationStatus': 'PROCESSING',
        },
      });
      expect(processing, isNotNull);
      expect(processing!.isPending, isTrue);
      expect(processing.isFailed, isFalse);
      expect(processing.showTranslatedBadge, isFalse);

      final pending = LocalizationMeta.tryParse({
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': false,
          'translationStatus': 'PENDING',
        },
      });
      expect(pending!.isPending, isTrue);

      final failed = LocalizationMeta.tryParse({
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'es',
          'isTranslated': false,
          'translationStatus': 'FAILED',
        },
      });
      expect(failed!.isPending, isFalse);
      expect(failed.isFailed, isTrue);
      expect(failed.showTranslatedBadge, isFalse);
    });

    test('returns null from tryParse when no metadata fields exist', () {
      expect(LocalizationMeta.tryParse({'id': '1', 'title': 'Test'}), isNull);
    });
  });

  group('PendingRefetchController', () {
    test('anyLocalizationPending detects PENDING and PROCESSING accurately', () {
      expect(
        anyLocalizationPending([
          null,
          const LocalizationMeta(translationStatus: 'READY'),
          const LocalizationMeta(translationStatus: 'FAILED'),
        ]),
        isFalse,
      );
      expect(
        anyLocalizationPending([
          const LocalizationMeta(translationStatus: 'READY'),
          const LocalizationMeta(translationStatus: 'PROCESSING'),
        ]),
        isTrue,
      );
      expect(
        anyLocalizationPending([
          const LocalizationMeta(translationStatus: 'PENDING'),
        ]),
        isTrue,
      );
    });

    test('polls periodically when pending and stops when canceled or capped', () async {
      final poller = PendingRefetchController();
      int count = 0;

      poller.sync(
        hasPending: true,
        refetch: () => count++,
        interval: const Duration(milliseconds: 20),
      );

      await Future.delayed(const Duration(milliseconds: 75));
      poller.cancel();
      final countAtCancel = count;

      expect(countAtCancel, greaterThanOrEqualTo(2));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(count, equals(countAtCancel));

      poller.dispose();
    });

    test('invokes onTimeout after maxPolls and stops restarting while pending', () async {
      final poller = PendingRefetchController();
      int polls = 0;
      int timeouts = 0;

      poller.sync(
        hasPending: true,
        refetch: () => polls++,
        interval: const Duration(milliseconds: 15),
        maxPolls: 2,
        onTimeout: () => timeouts++,
      );

      await Future.delayed(const Duration(milliseconds: 80));
      expect(polls, equals(2));
      expect(timeouts, equals(1));
      expect(poller.isTimedOut, isTrue);

      // Calling sync again while still pending must not restart polling.
      poller.sync(
        hasPending: true,
        refetch: () => polls++,
        interval: const Duration(milliseconds: 15),
        maxPolls: 2,
        onTimeout: () => timeouts++,
      );
      await Future.delayed(const Duration(milliseconds: 40));
      expect(polls, equals(2));
      expect(timeouts, equals(1));

      poller.dispose();
    });
  });

  group('DTO & Model Nested Localization Parsing', () {
    test('AnnouncementDto & LegalContentDto support nested localization objects', () {
      final announcement = AnnouncementDto.fromJson({
        'id': 'a-1',
        'title': 'Holiday Notice',
        'body': 'School closed Friday',
        'audience': 'ALL',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': true,
          'translationStatus': 'READY',
        },
      });
      expect(announcement.localization.isTranslated, isTrue);
      expect(announcement.sourceLocale, 'es');
      expect(announcement.displayedLocale, 'en');

      final legal = LegalContentDto.fromJson({
        'legalContentType': 'ABOUT_US',
        'content': '<p>About</p>',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': false,
          'translationStatus': 'PROCESSING',
        },
      }).toEntity();
      expect(legal.localization.isPending, isTrue);
      expect(legal.translationStatus, 'PROCESSING');
    });

    test('ChildHomeworkDto & TeacherHomeworkDto support nested localization and empty fallbacks', () {
      final parentHw = ChildHomeworkDto.fromJson({
        'id': 'hw-1',
        'title': 'Fractions',
        'subjectName': 'Math',
        'dueDate': '2026-11-15T10:00:00.000Z',
        'status': 'PENDING',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': true,
          'translationStatus': 'READY',
        },
      }).toModel();
      expect(parentHw.teacher, isEmpty);
      expect(parentHw.period, isEmpty);
      expect(parentHw.localization.showTranslatedBadge, isTrue);

      final teacherHw = TeacherHomeworkDto.fromJson({
        'id': 'hw-2',
        'title': 'Essay',
        'cohortName': '10-A',
        'subjectName': 'Literature',
        'localization': {
          'sourceLocale': 'en',
          'displayedLocale': 'es',
          'isTranslated': false,
          'translationStatus': 'FAILED',
        },
      });
      expect(teacherHw.localization.isFailed, isTrue);
      expect(teacherHw.translationStatus, 'FAILED');
    });

    test('ParentInvoiceDto, NotificationDto, ChildScheduleSessionDto, TeacherReportDto, and Chat DTOs parse localization', () {
      final invoice = ParentInvoiceDto.fromJson({
        'id': 'inv-1',
        'feeTitle': 'November Tuition',
        'amount': 120,
        'dueDate': '2026-11-20T00:00:00.000Z',
        'status': 'PENDING',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': true,
          'translationStatus': 'READY',
        },
      }).toModel();
      expect(invoice.localization?.showTranslatedBadge, isTrue);

      final notif = NotificationDto.fromJson({
        'id': 'n-1',
        'title': 'Reminder',
        'message': 'Parent meeting tomorrow',
        'type': 'GENERAL',
        'isRead': false,
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': false,
          'translationStatus': 'PENDING',
        },
      }).toModel();
      expect(notif.localization?.isPending, isTrue);

      final schedule = ChildScheduleSessionDto.fromJson({
        'id': 's-1',
        'subjectName': 'Physics',
        'startTime': '09:00',
        'endTime': '10:00',
        'status': 'SCHEDULED',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': true,
          'translationStatus': 'READY',
        },
      }).toClassModel();
      expect(schedule.teacher, isEmpty);
      expect(schedule.localization?.showTranslatedBadge, isTrue);

      final teacherReport = TeacherReportDto.fromJson({
        'id': 'r-1',
        'cohortName': 'Cohort A',
        'subjectName': 'Biology',
        'contentCovered': 'Cells',
        'status': 'SUBMITTED',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': true,
          'translationStatus': 'READY',
        },
      }).toModel();
      expect(teacherReport.localization?.showTranslatedBadge, isTrue);

      final conv = ConversationDto.fromJson({
        'id': 'c-1',
        'lastMessage': 'Hello!',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': true,
          'translationStatus': 'READY',
        },
      });
      expect(conv.localization?.showTranslatedBadge, isTrue);

      final msg = ChatMessageDto.fromJson({
        'id': 'm-1',
        'conversationId': 'c-1',
        'body': 'Translated hello',
        'localization': {
          'sourceLocale': 'es',
          'displayedLocale': 'en',
          'isTranslated': false,
          'translationStatus': 'PROCESSING',
        },
      });
      expect(msg.localization?.isPending, isTrue);

      final sessionWithPendingStudent = ClassSessionDto.fromJson({
        'id': 'sess-1',
        'scheduleId': 'sched-1',
        'sessionDate': '2026-11-12T00:00:00.000Z',
        'startTime': '10:25',
        'endTime': '16:25',
        'status': 'COMPLETED',
        'subjectName': 'subject 2',
        'cohortName': 'group 1',
        'students': [
          {
            'id': 'stu-1',
            'fullName': 'student 2 asgdyhasd',
            'enrollmentNumber': 'ENR-2026-1760',
            'localization': {
              'sourceLocale': 'en',
              'displayedLocale': 'en',
              'isTranslated': false,
              'translationStatus': 'PENDING',
            },
          },
        ],
      });
      expect(sessionWithPendingStudent.localization, isNull);
      expect(sessionWithPendingStudent.hasAnyPendingLocalization, isTrue);
    });
  });

  group('TranslationStatusBadge Widget', () {
    Widget buildBadge(LocalizationMeta meta) {
      return ProviderScope(
        overrides: [
          languageProvider.overrideWith(_FakeLanguageNotifier.new),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: TranslationStatusBadge.fromMeta(meta),
            ),
          ),
        ),
      );
    }

    testWidgets('renders Translating chip for PENDING and PROCESSING', (tester) async {
      await tester.pumpWidget(
        buildBadge(
          const LocalizationMeta(
            sourceLocale: 'es',
            displayedLocale: 'en',
            isTranslated: false,
            translationStatus: 'PROCESSING',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Translating...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders FAILED chip for FAILED status', (tester) async {
      await tester.pumpWidget(
        buildBadge(
          const LocalizationMeta(
            sourceLocale: 'es',
            displayedLocale: 'es',
            isTranslated: false,
            translationStatus: 'FAILED',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Translation unavailable'), findsOneWidget);
    });

    testWidgets(
      'falls back to Original badge and notifies user via SnackBar when PendingPollEffect times out',
      (tester) async {
        int polls = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              languageProvider.overrideWith(_FakeLanguageNotifier.new),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, _) => MaterialApp(
                home: Scaffold(
                  body: PendingPollEffect(
                    hasPending: true,
                    interval: const Duration(milliseconds: 20),
                    maxPolls: 2,
                    onPoll: () => polls++,
                    child: const TranslationStatusBadge.fromMeta(
                      LocalizationMeta(
                        sourceLocale: 'en',
                        displayedLocale: 'en',
                        isTranslated: false,
                        translationStatus: 'PENDING',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Translating...'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 90));
        await tester.pump();

        expect(polls, equals(2));
        expect(find.text('Original (EN)'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.text('Translation is taking longer than expected. Showing original content.'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets('renders Translated chip when source and displayed differ', (tester) async {
      await tester.pumpWidget(
        buildBadge(
          const LocalizationMeta(
            sourceLocale: 'es',
            displayedLocale: 'en',
            isTranslated: true,
            translationStatus: 'READY',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Translated (ES → EN)'), findsOneWidget);
    });

    testWidgets('renders nothing for same-locale READY item', (tester) async {
      await tester.pumpWidget(
        buildBadge(
          const LocalizationMeta(
            sourceLocale: 'en',
            displayedLocale: 'en',
            isTranslated: false,
            translationStatus: 'READY',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Translating...'), findsNothing);
      expect(find.text('Translation unavailable'), findsNothing);
      expect(find.textContaining('Translated'), findsNothing);
    });

    testWidgets(
      'PendingPollEffect polls FutureProvider.family from PENDING to READY and updates UI',
      (tester) async {
        var fetchCount = 0;
        final sessionProvider =
            FutureProvider.autoDispose.family<ClassSessionDto, String>(
          (ref, id) async {
            fetchCount++;
            final isReady = fetchCount >= 2;
            return ClassSessionDto.fromJson({
              'id': id,
              'scheduleId': 'sched-1',
              'sessionDate': '2026-11-12T00:00:00.000Z',
              'startTime': '10:25',
              'endTime': '16:25',
              'status': 'COMPLETED',
              'subjectName': 'subject 2',
              'cohortName': 'group 1',
              'students': [
                {
                  'id': 'stu-1',
                  'fullName': isReady
                      ? 'estudiante 2 traducido'
                      : 'student 2 asgdyhasd',
                  'enrollmentNumber': 'ENR-2026-1760',
                  'localization': {
                    'sourceLocale': 'en',
                    'displayedLocale': isReady ? 'es' : 'en',
                    'isTranslated': isReady,
                    'translationStatus': isReady ? 'READY' : 'PENDING',
                  },
                },
              ],
            });
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              languageProvider.overrideWith(_FakeLanguageNotifier.new),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, _) => MaterialApp(
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      final asyncVal = ref.watch(sessionProvider('sess-1'));
                      return asyncVal.when(
                        skipLoadingOnReload: true,
                        skipLoadingOnRefresh: true,
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('err: $e'),
                        data: (session) => PendingPollEffect(
                          interval: const Duration(milliseconds: 100),
                          hasPending: session.hasAnyPendingLocalization,
                          onPoll: () =>
                              ref.invalidate(sessionProvider('sess-1')),
                          child: Column(
                            children: [
                              Text(session.students.first.fullName),
                              TranslationStatusBadge.fromMeta(
                                session.students.first.localization,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        expect(fetchCount, 1);
        expect(find.text('student 2 asgdyhasd'), findsOneWidget);
        expect(find.text('Translating...'), findsOneWidget);

        // Advance timer past polling interval so PendingPollEffect refetches
        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump();

        expect(fetchCount, 2);
        expect(find.text('estudiante 2 traducido'), findsOneWidget);
        expect(find.text('Translated (EN → ES)'), findsOneWidget);
      },
    );
  });
}
