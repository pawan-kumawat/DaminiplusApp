import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'chapters_screen.dart';
import 'exam_chapters_screen.dart';
import 'other_course_chapters_screen.dart';
import 'lesson_content_screen.dart';
import 'courses_screen.dart';
import 'study_material_list_screen.dart';
import 'profile_screen.dart';
import 'app_settings_screen.dart';
import 'notifications_screen.dart';
import 'language_selection_screen.dart';
import 'exam_language_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Reference-design colors (sampled from the target screenshot) ──
  // AppColors.primaryBlue already matches this navy across the app,
  // these three are new accents that didn't exist before.
  static const Color _navy = Color(0xFF16388F);
  static const Color _orange = Color(0xFFED8646);
  static const Color _lightBlue = Color(0xFFEAF1FC);
  static const Color _lightGreen = Color(0xFFEDF6E8);
  static const Color _green = Color(0xFF3D8337);

  String _userName = '';
  String _userId = '';
  bool _isLoading = true;

  // ── "Discover" catalogue — /app/courses se saare boards/exams
  // (jaise Our Courses tab par), taaki home par bhi tap-and-browse
  // ho sake. Ownership (green tick) getMyBoards / getMyExams se.
  List<Map<String, dynamic>> _catalogueBoards = [];
  List<Map<String, dynamic>> _catalogueExams = [];
  Set<String> _ownedExamIds = {};

  // Board-selection layer skip karte hain — client ke paas aksar 1-2
  // board hi hote hain, isliye "pehle board chuno, phir class" ekstra
  // step lagta hai. Har board ki classes seedha yahan flatten karke
  // dikhate hain (RBSE ki 5,6,7...10 sab apni tile), tap karte hi
  // us exact class me seedha enroll.
  List<Map<String, dynamic>> _catalogueClasses = [];
  Set<String> _ownedClassIds = {};

  // ── "My Learning" — jo boards/exams/other-courses already subscribed
  // hain, unki subject list (pehle jaisa home screen behaviour).
  List<Map<String, dynamic>> _boardSections = [];
  List<Map<String, dynamic>> _examSections = [];
  List<Map<String, dynamic>> _otherCourseSections = [];

  // ── Dashboard se: recommended courses. Recently added courses aur
  // home sliders admin-curated hain (App Settings), apne alag
  // endpoints se aate hain. Dono list me sirf 2 items dikhte hain,
  // "View All" tap karne par poori list inline expand ho jaati hai
  // (kahin navigate nahi karte).
  List<Map<String, dynamic>> _recommendedCourses = [];
  List<Map<String, dynamic>> _recentCourses = [];
  List<Map<String, dynamic>> _homeSliders = [];
  bool _showAllRecommended = false;
  bool _showAllRecent = false;

  // ── Continue Learning card ab /resume (last visited subject+topic,
  // uske apne accurate %) se aata hai — pehle ye currently ACTIVE
  // class ke subjects me se pehla "incomplete" subject utha leta tha,
  // jo asal me student ne last kya khola tha usse bilkul alag ho
  // sakta hai (khaaskar ab jab ek board ki multiple classes saath
  // enrolled ho sakti hain) — isliye home aur profile ka % kabhi match
  // hi nahi karta tha.
  Map<String, dynamic>? _resume;

  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  static const Map<String, IconData> _iconMap = {
    'math': Icons.functions,
    'mathematics': Icons.functions,
    'science': Icons.science_outlined,
    'social': Icons.book_outlined,
    'english': Icons.language,
    'hindi': Icons.translate,
    'history': Icons.history_edu,
    'geography': Icons.public,
    'computer': Icons.computer,
    'physics': Icons.bolt,
    'chemistry': Icons.science,
    'biology': Icons.biotech,
    'reasoning': Icons.psychology_outlined,
    'aptitude': Icons.calculate_outlined,
    'gk': Icons.public,
    'general': Icons.public,
    'current': Icons.newspaper_outlined,
  };

  static const List<Color> _colorCycle = [
    AppColors.primaryBlue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
  ];

  final List<Map<String, dynamic>> _quickLinks = const [
    {
      'icon': Icons.auto_stories_rounded,
      'label': 'Books',
      'color': Color(0xFF3757C9),
    },
    {
      'icon': Icons.edit_note_rounded,
      'label': 'Notes',
      'color': Color(0xFF3D9142),
    },
    {
      'icon': Icons.smart_display_rounded,
      'label': 'YouTube',
      'color': Color(0xFFDC4B4B),
    },
    {
      'icon': Icons.article_rounded,
      'label': 'Previous Papers',
      'color': Color(0xFFED8646),
    },
    {
      'icon': Icons.fact_check_rounded,
      'label': 'Practice Set',
      'color': Color(0xFF2F5FD6),
    },
    {
      'icon': Icons.newspaper_rounded,
      'label': 'Current Affairs',
      'color': Color(0xFF8B4FD1),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _userName = await AppSharedPreferencesData.getUserName();
    _userId = await AppSharedPreferencesData.getUserId();

    final results = await Future.wait([
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getDashboard,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getCourses,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getMyBoards,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getMyExams,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getResume,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getRecentCourses,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getHomeSliders,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getMyOtherCourses,
        showLoader: false,
      ),
    ]);

    final dashRes = results[0];
    final coursesRes = results[1];
    final boardsRes = results[2];
    final examsRes = results[3];
    final resumeRes = results[4];
    final recentRes = results[5];
    final slidersRes = results[6];
    final otherCoursesRes = results[7];

    if (recentRes != "Error") {
      try {
        final json = jsonDecode(recentRes);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() => _recentCourses = list.cast<Map<String, dynamic>>());
      } catch (_) {}
    }

    if (slidersRes != "Error") {
      try {
        final json = jsonDecode(slidersRes);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _homeSliders = list
              .map<Map<String, dynamic>>(
                (e) => {'imageUrl': e['imageUrl']?.toString() ?? ''},
              )
              .where((e) => (e['imageUrl'] as String).isNotEmpty)
              .toList();
        });
      } catch (_) {}
    }

    if (resumeRes != "Error") {
      try {
        final json = jsonDecode(resumeRes);
        final data = json['data'] as Map<String, dynamic>? ?? {};
        final subject = data['subject'] as Map<String, dynamic>?;
        final topic = data['topic'] as Map<String, dynamic>?;
        final progress = data['progress'] as Map<String, dynamic>?;
        if (subject != null && topic != null) {
          final board = subject['boardId'] as Map<String, dynamic>?;
          final cls = subject['classId'] as Map<String, dynamic>?;
          setState(() {
            _resume = {
              'subjectId': subject['_id']?.toString() ?? '',
              'subjectName': subject['name']?.toString() ?? 'Subject',
              'boardId': board?['_id']?.toString() ?? '',
              'classId': cls?['_id']?.toString() ?? '',
              'topicId': topic['_id']?.toString() ?? '',
              'topicName': topic['name']?.toString() ?? '',
              'percentage': progress?['percentage'] is num
                  ? (progress!['percentage'] as num).toDouble()
                  : 0.0,
            };
          });
        } else {
          setState(() => _resume = null);
        }
      } catch (_) {}
    }

    if (dashRes != "Error") {
      try {
        final json = jsonDecode(dashRes);
        final data = json['data'] ?? {};
        final user = data['user'] ?? {};
        final recommended =
            (data['recommendedCourses'] as List<dynamic>?) ?? [];
        if (user['role'] != null) {
          AppSharedPreferencesData.saveRole(user['role'].toString());
        }
        setState(() {
          _userName = user['name'] ?? _userName;
          _userId =
              user['studentId']?.toString() ??
              user['id']?.toString() ??
              _userId;
          _recommendedCourses = recommended.cast<Map<String, dynamic>>();
        });
      } catch (_) {}
    }

    if (coursesRes != "Error") {
      try {
        final json = jsonDecode(coursesRes);
        final data = json['data'] ?? {};
        setState(() {
          _catalogueBoards = ((data['boards'] as List<dynamic>?) ?? [])
              .map(
                (e) => {
                  '_id': e['_id']?.toString() ?? '',
                  'name': e['name']?.toString() ?? '',
                  'fullName':
                      e['fullName']?.toString() ?? e['name']?.toString() ?? '',
                  'imageUrl': e['imageUrl']?.toString() ?? '',
                },
              )
              .toList();
          _catalogueExams = ((data['exams'] as List<dynamic>?) ?? [])
              .map(
                (e) => {
                  '_id': e['_id']?.toString() ?? '',
                  'name': e['name']?.toString() ?? '',
                  'fullName':
                      e['fullName']?.toString() ?? e['name']?.toString() ?? '',
                  'imageUrl': e['imageUrl']?.toString() ?? '',
                },
              )
              .toList();
        });
      } catch (_) {}
    }

    // ── Board select karte hi (subscription se pehle bhi) "My
    // Learning" me section dikhna chahiye — subjects hamesha browsable
    // hain, sirf ek subject ka pehla topic free hai, baaki content
    // subscription se unlock hota hai. Isliye yahan `subscribed==true`
    // se filter NAHI karte — jo bhi board/exam enroll kiya hai (select
    // kiya hai) uska section banta hai; `subscribed` sirf per-entry
    // metadata rehta hai.
    List<Map<String, dynamic>> enrolledBoards = [];
    if (boardsRes != "Error") {
      try {
        final json = jsonDecode(boardsRes);
        final list = json['data'] as List<dynamic>? ?? [];
        enrolledBoards = list.cast<Map<String, dynamic>>().toList();
      } catch (_) {}
    }

    List<Map<String, dynamic>> enrolledExams = [];
    if (examsRes != "Error") {
      try {
        final json = jsonDecode(examsRes);
        final list = json['data'] as List<dynamic>? ?? [];
        enrolledExams = list.cast<Map<String, dynamic>>().toList();
        setState(() {
          _ownedExamIds = enrolledExams
              .map<String>((e) => e['examId']?.toString() ?? '')
              .toSet();
        });
      } catch (_) {}
    }

    List<Map<String, dynamic>> enrolledOtherCourses = [];
    if (otherCoursesRes != "Error") {
      try {
        final json = jsonDecode(otherCoursesRes);
        final list = json['data'] as List<dynamic>? ?? [];
        enrolledOtherCourses = list.cast<Map<String, dynamic>>().toList();
      } catch (_) {}
    }

    // Board-selection layer skip karte hain — har catalogue board ki
    // classes fetch karke ek flat list banate hain (RBSE ki 5,6,7...10
    // sab apni tile), taaki Home par seedha class tap karke enroll ho
    // sake, "pehle board chuno phir class" wala extra step nahi.
    if (_catalogueBoards.isNotEmpty) {
      final ownedClassIds = enrolledBoards
          .map<String>((e) => e['classId']?.toString() ?? '')
          .toSet();
      final classResults = await Future.wait(
        _catalogueBoards.map(
          (board) => APIService.getApiCaller(
            context: context,
            url: ApiUrls.getClasses(board['_id'] as String),
            showLoader: false,
          ),
        ),
      );
      if (!mounted) return;
      final classes = <Map<String, dynamic>>[];
      for (var i = 0; i < _catalogueBoards.length; i++) {
        final board = _catalogueBoards[i];
        final res = classResults[i];
        if (res == "Error") continue;
        try {
          final json = jsonDecode(res);
          final list = json['data'] as List<dynamic>? ?? [];
          for (final c in list) {
            final classImageUrl = c['imageUrl']?.toString() ?? '';
            classes.add({
              '_id': c['_id']?.toString() ?? '',
              'name': c['name']?.toString() ?? '',
              'imageUrl': classImageUrl.isNotEmpty
                  ? classImageUrl
                  : (board['imageUrl'] ?? ''),
              'boardId': board['_id'],
              'boardName': board['name'],
            });
          }
        } catch (_) {}
      }
      setState(() {
        _catalogueClasses = classes;
        _ownedClassIds = ownedClassIds;
      });
    }

    final boardSections = await Future.wait(
      enrolledBoards.map((entry) async {
        final boardId = entry['boardId']?.toString() ?? '';
        final classId = entry['classId']?.toString() ?? '';
        final languageId = entry['language'] is Map
            ? entry['language']['_id']?.toString() ?? ''
            : '';
        List<Map<String, dynamic>> subjects = [];
        if (boardId.isNotEmpty && classId.isNotEmpty) {
          final res = await APIService.getApiCaller(
            context: context,
            url: ApiUrls.getSubjects(
              languageId,
              boardId: boardId,
              classId: classId,
            ),
            showLoader: false,
          );
          if (res != "Error") {
            try {
              final json = jsonDecode(res);
              final data = json['data'] as List<dynamic>? ?? [];
              subjects = data
                  .map<Map<String, dynamic>>(
                    (e) => {
                      '_id': e['_id']?.toString() ?? '',
                      'name': e['name']?.toString() ?? 'Subject',
                      'icon': e['icon']?.toString() ?? '',
                      'iconUrl': e['iconUrl']?.toString() ?? '',
                    },
                  )
                  .toList();
            } catch (_) {}
          }
        }
        return {
          'boardId': boardId,
          'classId': classId,
          'languageId': languageId,
          'boardName': entry['board']?['name']?.toString() ?? 'Board',
          'className': entry['class']?['name']?.toString() ?? '',
          'subjects': subjects,
        };
      }),
    );

    final examSections = await Future.wait(
      enrolledExams.map((entry) async {
        final examId = entry['examId']?.toString() ?? '';
        final languageId = entry['language'] is Map
            ? entry['language']['_id']?.toString() ?? ''
            : '';
        List<Map<String, dynamic>> subjects = [];
        if (examId.isNotEmpty) {
          final res = await APIService.getApiCaller(
            context: context,
            url: ApiUrls.getExamSubjects(languageId, examId: examId),
            showLoader: false,
          );
          if (res != "Error") {
            try {
              final json = jsonDecode(res);
              final data = json['data'] as List<dynamic>? ?? [];
              subjects = data
                  .map<Map<String, dynamic>>(
                    (e) => {
                      '_id': e['_id']?.toString() ?? '',
                      'name': e['name']?.toString() ?? 'Subject',
                      'icon': '',
                      'iconUrl': e['imageUrl']?.toString() ?? '',
                    },
                  )
                  .toList();
            } catch (_) {}
          }
        }
        return {
          'examId': examId,
          'examName': entry['exam']?['name']?.toString() ?? 'Exam',
          'subjects': subjects,
        };
      }),
    );

    final otherCourseSections = await Future.wait(
      enrolledOtherCourses.map((entry) async {
        final otherCourseId = entry['otherCourseId']?.toString() ?? '';
        final languageId = entry['language'] is Map
            ? entry['language']['_id']?.toString() ?? ''
            : '';
        List<Map<String, dynamic>> subjects = [];
        if (otherCourseId.isNotEmpty) {
          final res = await APIService.getApiCaller(
            context: context,
            url: ApiUrls.getOtherCourseSubjects(
              languageId,
              otherCourseId: otherCourseId,
            ),
            showLoader: false,
          );
          if (res != "Error") {
            try {
              final json = jsonDecode(res);
              final data = json['data'] as List<dynamic>? ?? [];
              subjects = data
                  .map<Map<String, dynamic>>(
                    (e) => {
                      '_id': e['_id']?.toString() ?? '',
                      'name': e['name']?.toString() ?? 'Subject',
                      'icon': '',
                      'iconUrl': e['imageUrl']?.toString() ?? '',
                    },
                  )
                  .toList();
            } catch (_) {}
          }
        }
        return {
          'otherCourseId': otherCourseId,
          'otherCourseName':
              entry['otherCourse']?['name']?.toString() ?? 'Course',
          'subjects': subjects,
        };
      }),
    );

    if (!mounted) return;
    setState(() {
      _boardSections = boardSections;
      _examSections = examSections;
      _otherCourseSections = otherCourseSections;
      _isLoading = false;
    });
  }

  IconData _iconFor(String name) {
    final key = name.toLowerCase();
    for (final entry in _iconMap.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return Icons.menu_book_outlined;
  }

  Future<void> _openBoardSubject(
    Map<String, dynamic> section,
    Map<String, dynamic> subject,
  ) async {
    // Chapters/Topics/Questions screens active board se scope hote
    // hain — is board ko active banao, phir navigate karo.
    await APIService.putApiCaller(
      context: context,
      url: ApiUrls.switchBoard,
      // Ab ek board ki multiple class-enrollments ho sakti hain (e.g.
      // CBSE Class 9 + Class 10 dono saath), isliye classId bhejna
      // zaroori hai taaki EXACT wahi class active bane jiske subjects
      // yahan se open kiye ja rahe hain — sirf boardId se ambiguous ho
      // jaata.
      body: {"boardId": section['boardId'], "classId": section['classId']},
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChaptersScreen(
          subjectId: subject['_id'],
          subjectName: subject['name'],
          languageId: section['languageId'],
          subjectImageUrl: subject['iconUrl'] as String? ?? '',
          boardName: section['boardName']?.toString() ?? '',
          className: section['className']?.toString() ?? '',
        ),
      ),
      // Yahin se student topics/questions tak jaakar progress badalta
      // hai — is push ke baad reload na karne par Home ka progress
      // stale reh jaata tha (Profile tab par sahi % dikhta, Home par
      // purana), isliye baaki catalogue navigations ki tarah yahan bhi
      // return par _loadData() chalate hain.
    ).then((_) => _loadData());
  }

  Future<void> _openExamSubject(
    Map<String, dynamic> section,
    Map<String, dynamic> subject,
  ) async {
    await APIService.putApiCaller(
      context: context,
      url: ApiUrls.switchExam,
      body: {"examId": section['examId']},
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamChaptersScreen(
          examId: section['examId'],
          examName: section['examName'],
          examSubjectId: subject['_id'],
          examSubjectName: subject['name'],
          subjectImageUrl: subject['iconUrl'] as String? ?? '',
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _openOtherCourseSubject(
    Map<String, dynamic> section,
    Map<String, dynamic> subject,
  ) async {
    await APIService.putApiCaller(
      context: context,
      url: ApiUrls.switchOtherCourse,
      body: {"otherCourseId": section['otherCourseId']},
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherCourseChaptersScreen(
          otherCourseId: section['otherCourseId'],
          otherCourseName: section['otherCourseName'],
          otherCourseSubjectId: subject['_id'],
          otherCourseSubjectName: subject['name'],
          subjectImageUrl: subject['iconUrl'] as String? ?? '',
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openClassCatalogue(Map<String, dynamic> cls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LanguageSelectionScreen(
          boardId: cls['boardId'] as String,
          boardName: cls['boardName'] as String,
          preselectedClassId: cls['_id'] as String,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openExamCatalogue(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamLanguageSelectionScreen(
          examId: exam['_id'] as String,
          examName: exam['name'] as String,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openRecommended(Map<String, dynamic> item) {
    final type = item['type']?.toString();
    if (type == 'board') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LanguageSelectionScreen(
            boardId: item['boardId']?.toString() ?? '',
            boardName: item['title']?.toString() ?? 'Board',
          ),
        ),
      ).then((_) => _loadData());
    } else if (type == 'exam') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamLanguageSelectionScreen(
            examId: item['examId']?.toString() ?? '',
            examName: item['title']?.toString() ?? 'Exam',
          ),
        ),
      ).then((_) => _loadData());
    }
  }

  // Bottom-tab indices — matches MainScreen's _navItems order:
  // 0 Home, 1 Other Courses, 2 My Course (progress), 3 Library, 4 Profile (settings).
  static const int _tabProfile = 2;

  // CoursesScreen (board/exam browse) isn't a bottom-nav tab anymore —
  // tab 1 is Other Courses now — so this always pushes it directly.
  void _goToCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesScreen()),
    ).then((_) => _loadData());
  }

  /// "Continue Learning" ab /resume se aaye last-visited topic par
  /// seedha resume karta hai — chahe wo kisi bhi enrolled class ka ho.
  Future<void> _continueLearning(Map<String, dynamic> resume) async {
    final boardId = resume['boardId']?.toString() ?? '';
    final classId = resume['classId']?.toString() ?? '';
    if (boardId.isNotEmpty && classId.isNotEmpty) {
      // Topic jis board+class ka hai use active banao — content
      // endpoints active board/class se hi scope hote hain.
      await APIService.putApiCaller(
        context: context,
        url: ApiUrls.switchBoard,
        body: {"boardId": boardId, "classId": classId},
      );
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonContentScreen(
          topicId: resume['topicId']?.toString() ?? '',
          topicName: resume['topicName']?.toString() ?? 'Topic',
          subjectId: resume['subjectId']?.toString() ?? '',
          subjectName: resume['subjectName']?.toString() ?? 'Subject',
          languageId: '',
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _buildTopBar(t),
                ),
                const SizedBox(height: 16),
                _buildBanner(),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Discover: saare boards ki classes seedha (Our Courses
                        // jaisi API), board-selection step skip karke ──
                        if (_catalogueClasses.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Select Class',
                            onViewAll: _goToCourses,
                          ),
                          const SizedBox(height: 14),
                          _buildCatalogueGrid(
                            _catalogueClasses,
                            _ownedClassIds,
                            _openClassCatalogue,
                          ),
                          const SizedBox(height: 22),
                        ],
                        if (_catalogueExams.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Competitive Exams',
                            onViewAll: _goToCourses,
                          ),
                          const SizedBox(height: 14),
                          _buildCatalogueGrid(
                            _catalogueExams,
                            _ownedExamIds,
                            _openExamCatalogue,
                          ),
                          const SizedBox(height: 22),
                        ],

                        // ── Quick links row ──
                        _buildSectionHeader('Books & More'),
                        const SizedBox(height: 14),
                        _buildQuickLinks(),
                        const SizedBox(height: 8),
                        const Divider(height: 32, color: Color(0xFFEFEFEF)),

                        // ── Continue learning ──
                        if (_resume != null) ...[
                          _buildSectionHeader('Continue Learning'),
                          const SizedBox(height: 14),
                          _buildContinueLearningCard(_resume!),
                          const SizedBox(height: 22),
                        ],

                        // ── Recommended courses (admin-curated) ──
                        if (_recommendedCourses.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Recommended Courses',
                            onViewAll: _recommendedCourses.length > 2
                                ? () => setState(
                                    () => _showAllRecommended =
                                        !_showAllRecommended,
                                  )
                                : null,
                            viewAllLabel: _showAllRecommended
                                ? 'Show Less'
                                : 'View All',
                          ),
                          const SizedBox(height: 14),
                          _buildCourseGrid(
                            _recommendedCourses,
                            _showAllRecommended,
                          ),
                          const SizedBox(height: 22),
                        ],

                        // ── Recently added courses (admin-curated) ──
                        if (_recentCourses.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Recently Added Courses',
                            onViewAll: _recentCourses.length > 2
                                ? () => setState(
                                    () => _showAllRecent = !_showAllRecent,
                                  )
                                : null,
                            viewAllLabel: _showAllRecent
                                ? 'Show Less'
                                : 'View All',
                          ),
                          const SizedBox(height: 14),
                          _buildCourseGrid(_recentCourses, _showAllRecent),
                          const SizedBox(height: 22),
                        ],

                        // ── My learning: already subscribed boards/exams/other-courses ──
                        if (_boardSections.isNotEmpty ||
                            _examSections.isNotEmpty ||
                            _otherCourseSections.isNotEmpty) ...[
                          for (final section in _boardSections) ...[
                            _buildSectionHeader(
                              (section['className'] as String).isNotEmpty
                                  ? '${section['boardName']} · ${section['className']}'
                                  : section['boardName'].toString(),
                            ),
                            const SizedBox(height: 14),
                            if ((section['subjects'] as List).isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Text(
                                  t.text('No subjects available yet.'),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...List.generate(
                                (section['subjects'] as List).length,
                                (i) {
                                  final s =
                                      (section['subjects'] as List)[i]
                                          as Map<String, dynamic>;
                                  return _buildSubjectCard(
                                    _iconFor(s['name']),
                                    s['name'],
                                    _colorCycle[i % _colorCycle.length],
                                    imageUrl: s['iconUrl'] as String?,
                                    onTap: s['_id'].toString().isEmpty
                                        ? null
                                        : () => _openBoardSubject(section, s),
                                  );
                                },
                              ),
                            const SizedBox(height: 20),
                          ],
                          for (final section in _examSections) ...[
                            _buildSectionHeader(section['examName'].toString()),
                            const SizedBox(height: 14),
                            if ((section['subjects'] as List).isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Text(
                                  t.text('No subjects available yet.'),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...List.generate(
                                (section['subjects'] as List).length,
                                (i) {
                                  final s =
                                      (section['subjects'] as List)[i]
                                          as Map<String, dynamic>;
                                  return _buildSubjectCard(
                                    _iconFor(s['name']),
                                    s['name'],
                                    _colorCycle[i % _colorCycle.length],
                                    imageUrl: s['iconUrl'] as String?,
                                    onTap: s['_id'].toString().isEmpty
                                        ? null
                                        : () => _openExamSubject(section, s),
                                  );
                                },
                              ),
                            const SizedBox(height: 20),
                          ],
                          for (final section in _otherCourseSections) ...[
                            _buildSectionHeader(
                              section['otherCourseName'].toString(),
                            ),
                            const SizedBox(height: 14),
                            if ((section['subjects'] as List).isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Text(
                                  t.text('No subjects available yet.'),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              ...List.generate(
                                (section['subjects'] as List).length,
                                (i) {
                                  final s =
                                      (section['subjects'] as List)[i]
                                          as Map<String, dynamic>;
                                  return _buildSubjectCard(
                                    _iconFor(s['name']),
                                    s['name'],
                                    _colorCycle[i % _colorCycle.length],
                                    imageUrl: s['iconUrl'] as String?,
                                    onTap: s['_id'].toString().isEmpty
                                        ? null
                                        : () => _openOtherCourseSubject(
                                            section,
                                            s,
                                          ),
                                  );
                                },
                              ),
                            const SizedBox(height: 20),
                          ],
                        ] else ...[
                          GestureDetector(
                            onTap: _goToCourses,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _lightBlue,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.explore_outlined,
                                    color: AppColors.primaryBlue,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      t.text(
                                        'Pick a board or competitive exam to get started.',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _navy,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 13,
                                    color: AppColors.primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar: brand + notification + settings + avatar ──────────────
  Widget _buildTopBar(AppLocalizations t) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.school,
            color: AppColors.primaryBlue,
            size: 19,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  children: [
                    TextSpan(
                      text: 'Damini ',
                      style: TextStyle(color: _navy),
                    ),
                    TextSpan(
                      text: 'Plus',
                      style: TextStyle(color: _orange),
                    ),
                  ],
                ),
              ),
              Text(
                t.text('Study. Learn. Succeed.'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _topBarAction(
          icon: Icons.notifications_none,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        const SizedBox(width: 6),
        _topBarAction(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
          ),
        ),
      ],
    );
  }

  // Consistent tap-target/spacing so every trailing icon sits the same
  // visual distance apart (IconButton's built-in padding used to make
  // gaps look uneven).
  Widget _topBarAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: _navy, size: 22),
      ),
    );
  }

  // ── Banner carousel ──────────────────────────────────────────────
  Widget _buildBanner() {
    // Pehle load ke dauraan seedha static fallback cards dikh jaate
    // the (chahe admin ne slider upload kar rakha ho) — kyunki
    // _homeSliders shuru me khaali hoti hai, data aane tak. Isse
    // ek jhatka sa lagta tha (static → real slider swap). Ab loading
    // ke time shimmer dikhate hain, aur sirf load poora hone ke baad
    // hi decide karte hain ki admin ka slider dikhana hai ya fallback.
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: _ShimmerBox(
          height: 176,
          borderRadius: BorderRadius.circular(22),
        ),
      );
    }

    // Admin (App Settings → Homepage Sliders) ne images upload ki hon
    // to wahi dikhate hain; kuch upload na hua ho to purane 2
    // functional cards (Continue Learning / Explore Courses) hi
    // fallback ke roop me dikhte hain, taaki banner khaali na rahe.
    final pages = _homeSliders.isNotEmpty
        ? _homeSliders
              .map((s) => _sliderImageCard(s['imageUrl'] as String))
              .toList()
        : <Widget>[
            _bannerCard(
              title: 'Keep The Streak Going!',
              subtitle: _userName.isNotEmpty
                  ? 'Welcome back, $_userName — continue where you left off.'
                  : 'Continue where you left off and finish your syllabus.',
              buttonLabel: 'Continue Learning',
              badgeText: 'GO',
              onTap: () {
                final r = _resume;
                if (r != null) {
                  _continueLearning(r);
                } else {
                  _goToCourses();
                }
              },
            ),
            _bannerCard(
              title: 'Explore More Courses',
              subtitle:
                  'Add another board or competitive exam alongside what you already study.',
              buttonLabel: 'Browse Courses',
              badgeText: 'NEW',
              onTap: _goToCourses,
            ),
          ];

    return Column(
      children: [
        SizedBox(
          height: 176,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: pages[i],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (i) {
            final active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _navy : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _sliderImageCard(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: _lightBlue,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
            size: 32,
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: _lightBlue,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _bannerCard({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 6),
                      width: 34,
                      height: 3,
                      color: _orange,
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCBD6F2),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _navy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.school, color: Color(0x33FFFFFF), size: 56),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header — bold title + optional "View All" (no leading icon,
  // matches the reference design exactly) ────────────────────────────
  Widget _buildSectionHeader(
    String label, {
    VoidCallback? onViewAll,
    String viewAllLabel = 'View All',
  }) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            t.text(label),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.text(viewAllLabel),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryBlue,
                  size: 17,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Catalogue grid (boards / exams) — 5 columns, circular logos,
  // matches the reference design exactly ──────────────────────────
  Widget _buildCatalogueGrid(
    List<Map<String, dynamic>> items,
    Set<String> ownedIds,
    void Function(Map<String, dynamic>) onTap,
  ) {
    final visible = items.take(10).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 14,
        crossAxisSpacing: 6,
        childAspectRatio: 0.72,
      ),
      itemCount: visible.length,
      itemBuilder: (_, i) {
        final item = visible[i];
        final isOwned = ownedIds.contains(item['_id']);
        final name = (item['name'] as String? ?? '').trim();
        final logo = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
        final imageUrl = item['imageUrl'] as String? ?? '';
        return GestureDetector(
          onTap: () => onTap(item),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.network(
                              imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  logo,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: _navy,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              logo,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _navy,
                              ),
                            ),
                          ),
                  ),
                  if (isOwned)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                  height: 1.1,
                ),
              ),
              if ((item['boardName'] as String? ?? '').isNotEmpty)
                Text(
                  item['boardName'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Quick links row (Books & More) — rounded-square colored icons,
  // matches reference design exactly. Row is top-aligned and every
  // label sits in a fixed-height box so 1-line and 2-line labels
  // (e.g. "Books" vs "Video Courses") don't push icons up/down.
  static const Map<String, String> _quickLinkResourceType = {
    'Books': 'book',
    'Notes': 'notes',
    'Previous Papers': 'model_paper',
    'Practice Set': 'practice_set',
    'Current Affairs': 'current_affairs',
  };

  static const String _youtubeChannelUrl =
      'https://www.youtube.com/channel/UCn7IWLzJrK2RJoQxherp8Yg';

  Widget _buildQuickLinks() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _quickLinks.map((link) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              final label = link['label'] as String;
              if (label == 'YouTube') {
                launchUrl(
                  Uri.parse(_youtubeChannelUrl),
                  mode: LaunchMode.externalApplication,
                );
                return;
              }
              final type = _quickLinkResourceType[label];
              if (type == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$label — coming soon')));
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StudyMaterialListScreen(type: type, title: label),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (link['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    link['icon'] as IconData,
                    color: link['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: Text(
                    AppLocalizations.of(context).text(link['label'] as String),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Continue learning card — matches reference design exactly ──────
  // `resume` yahan /resume API ka data hai: last-visited subject +
  // topic, aur USI topic ka apna accurate %. Pehle ye card currently
  // ACTIVE class ke subjects me se pehla incomplete subject utha leta
  // tha (jo student ne actually last khola tha usse alag ho sakta
  // tha), isliye % yahan aur Profile screen par match hi nahi karta
  // tha.
  Widget _buildContinueLearningCard(Map<String, dynamic> resume) {
    final pct = (resume['percentage'] is num)
        ? (resume['percentage'] as num).toDouble()
        : 0.0;
    final subjectName = resume['subjectName']?.toString() ?? 'Subject';
    final topicName = resume['topicName']?.toString().trim().isNotEmpty == true
        ? resume['topicName'].toString()
        : subjectName;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              subjectName.trim().isNotEmpty
                  ? subjectName.trim().substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _navy,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: const Color(0xFFEDEDED),
                          valueColor: const AlwaysStoppedAnimation(_navy),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () => _continueLearning(resume),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommended courses — 2-up grid. Subscriptions are off app-wide,
  // so no price/duration shown — every course is free to start. ──────
  // Recommended aur Recently Added — dono isi ek grid builder se
  // render hote hain. Collapsed state me sirf pehle 2 items (2-column
  // row jaisa hi dikhta hai), "View All" par poori list ek wrapped
  // 2-column grid me expand ho jaati hai (kahin navigate nahi karte).
  Widget _buildCourseGrid(List<Map<String, dynamic>> list, bool showAll) {
    final items = showAll ? list : list.take(2).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(width: cardWidth, child: _courseCard(item)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _courseCard(Map<String, dynamic> item) {
    final isExam = item['type']?.toString() == 'exam';
    final bg = isExam ? _lightGreen : _lightBlue;
    final accent = isExam ? _green : _navy;
    return GestureDetector(
      onTap: () => _openRecommended(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['title']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accent,
                      fontSize: 13,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (item['imageUrl']?.toString() ?? '').isNotEmpty
                      ? Image.network(
                          item['imageUrl'].toString(),
                          width: 26,
                          height: 26,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.school, color: accent, size: 24),
                        )
                      : Icon(Icons.school, color: accent, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item['subtitle']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openRecommended(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Learning',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    IconData icon,
    String title,
    Color iconColor, {
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            (imageUrl != null && imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// Lightweight shimmer placeholder — koi extra pub package nahi, sirf
// ek animated diagonal gradient sweep jo loading state me dikhta hai
// (banner slider ke liye).
class _ShimmerBox extends StatefulWidget {
  final double height;
  final BorderRadius borderRadius;
  const _ShimmerBox({required this.height, required this.borderRadius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.grey.shade300,
              Colors.grey.shade100,
              Colors.grey.shade300,
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1 - t * 2, 0),
            end: Alignment(1 - t * 2, 0),
          ).createShader(bounds),
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}
