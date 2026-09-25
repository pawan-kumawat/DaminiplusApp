import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'subscription_screen.dart';
import 'exam_subscription_screen.dart';
import 'other_course_subscription_screen.dart';
import 'courses_screen.dart';
import 'course_subjects_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const ProfileScreen({super.key, this.onNavigateTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProgressSummary {
  final List<Map<String, dynamic>> list;
  final int completed;
  final int total;
  final int completedChapters;
  final int totalChapters;
  final double avgScore;
  const _ProgressSummary(
    this.list,
    this.completed,
    this.total,
    this.completedChapters,
    this.totalChapters,
    this.avgScore,
  );
}

// ── Boards / exams / other-courses teeno ko isi common shape mein
// convert karte hain taaki "My Courses" card render karna simple ho.
class _CourseItem {
  final String title; // e.g. "CBSE Class 12"
  final String tag; // e.g. "Science Stream" — badge shown on banner (optional)
  final String subtitle; // e.g. "Science Stream" — shown under title
  final IconData bannerIcon;
  final Color color; // brand accent: progress/button/badges
  final bool subscribed;
  final dynamic rawProgress;
  final String? validTill; // ISO/plain string agar backend bhejta hai
  final String? lastStudied; // agar backend bhejta hai
  final int? totalQuestions; // agar backend bhejta hai
  final VoidCallback onSubscribe;
  final String kind; // 'board' | 'exam' | 'otherCourse' — "Continue" ka target
  final Map<String, dynamic>
  entry; // raw board/exam/otherCourse entry (ids for navigation)
  const _CourseItem({
    required this.title,
    required this.tag,
    required this.subtitle,
    required this.bannerIcon,
    required this.color,
    required this.subscribed,
    required this.rawProgress,
    required this.onSubscribe,
    required this.kind,
    required this.entry,
    this.validTill,
    this.lastStudied,
    this.totalQuestions,
  });
}

class _CoursesStats {
  final int coursesPurchased;
  final int subjectsEnrolled;
  final int chaptersStudied;
  final int overallProgressPct;
  const _CoursesStats(
    this.coursesPurchased,
    this.subjectsEnrolled,
    this.chaptersStudied,
    this.overallProgressPct,
  );
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';

  List<Map<String, dynamic>> _boardEntries = [];
  List<Map<String, dynamic>> _examEntries = [];
  List<Map<String, dynamic>> _otherCourseEntries = [];

  bool _isLoading = true;

  String _selectedFilter = 'All Courses';
  static const List<String> _filters = [
    'All Courses',
    'In Progress',
    'Completed',
    'Expired',
  ];
  static const Map<String, IconData> _filterIcons = {
    'All Courses': Icons.menu_book_rounded,
    'In Progress': Icons.access_time_rounded,
    'Completed': Icons.check_circle_rounded,
    'Expired': Icons.cached_rounded,
  };
  static const Map<String, Color> _filterIconColors = {
    'In Progress': Color(0xFF3B4453),
    'Completed': Color(0xFF2E9E5B),
    'Expired': Color(0xFFE0622F),
  };

  // Brand accent colors — banner shade nikalta hai isi se (darker tint).
  static const List<Color> _colorCycle = [
    AppColors.primaryBlue,
    Color(0xFF2E9E5B),
    Color(0xFF7A4FD1),
    Colors.orange,
    Colors.teal,
  ];

  Color _bannerShade(Color base) => Color.lerp(base, Colors.black, 0.55)!;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final profileRes = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.getProfile,
      showLoader: false,
    );
    if (profileRes != "Error" && mounted) {
      try {
        final json = jsonDecode(profileRes);
        final data = json['data'] ?? json;
        if (data['role'] != null) {
          AppSharedPreferencesData.saveRole(data['role'].toString());
        }
        setState(() {
          _name = data['name']?.toString() ?? '';
          _email = data['email']?.toString() ?? '';
        });
      } catch (_) {}
    }

    final results = await Future.wait([
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getBoardsProgress,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getExamsProgress,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getOtherCoursesProgress,
        showLoader: false,
      ),
    ]);

    if (results[0] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[0]);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _boardEntries = list
              .map<Map<String, dynamic>>(
                (e) => {
                  'boardId': e['boardId']?.toString() ?? '',
                  'boardName': e['boardName']?.toString() ?? 'Board',
                  'classId': e['classId']?.toString() ?? '',
                  'className': e['className']?.toString() ?? '',
                  'languageId': e['language'] is Map
                      ? e['language']['_id']?.toString() ?? ''
                      : '',
                  'stream': e['stream']?.toString() ?? '',
                  'subscribed': e['subscribed'] == true,
                  'progress': e['progress'],
                  // ── Ye teeno field abhi API mein nahi hain — jaise hi
                  // backend inhe bhejna start kare, yahan pick ho jaayenge.
                  'validTill':
                      e['validTill']?.toString() ?? e['expiryDate']?.toString(),
                  'lastStudied': e['lastStudiedText']?.toString(),
                  'totalQuestions': e['totalQuestions'],
                },
              )
              .toList();
        });
      } catch (_) {}
    }

    if (results[1] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[1]);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _examEntries = list
              .map<Map<String, dynamic>>(
                (e) => {
                  'examId': e['examId']?.toString() ?? '',
                  'examName': e['examName']?.toString() ?? 'Exam',
                  'subscribed': e['subscribed'] == true,
                  'progress': e['progress'],
                  'validTill':
                      e['validTill']?.toString() ?? e['expiryDate']?.toString(),
                  'lastStudied': e['lastStudiedText']?.toString(),
                  'totalQuestions': e['totalQuestions'],
                },
              )
              .toList();
        });
      } catch (_) {}
    }

    if (results[2] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[2]);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _otherCourseEntries = list
              .map<Map<String, dynamic>>(
                (e) => {
                  'otherCourseId': e['otherCourseId']?.toString() ?? '',
                  'otherCourseName':
                      e['otherCourseName']?.toString() ?? 'Course',
                  'subscribed': e['subscribed'] == true,
                  'progress': e['progress'],
                  'validTill':
                      e['validTill']?.toString() ?? e['expiryDate']?.toString(),
                  'lastStudied': e['lastStudiedText']?.toString(),
                  'totalQuestions': e['totalQuestions'],
                },
              )
              .toList();
        });
      } catch (_) {}
    }

    if (_name.isEmpty) {
      _name = await AppSharedPreferencesData.getUserName();
    }

    setState(() => _isLoading = false);
  }

  _ProgressSummary _extractProgress(dynamic data) {
    if (data is Map) {
      final subjects = data['subjects'] as List<dynamic>? ?? [];
      final overall = data['overall'] as Map?;
      final list = subjects
          .map<Map<String, dynamic>>(
            (e) => {
              'subjectId': e['subjectId']?.toString() ?? '',
              'name':
                  e['subjectName']?.toString() ??
                  e['name']?.toString() ??
                  'Subject',
              'progress': _toDouble(e['progress'] ?? e['percentage'] ?? 0),
            },
          )
          .toList();
      final completed = _toInt(
        data['completedTopics'] ??
            overall?['completedTopics'] ??
            subjects.fold<int>(
              0,
              (s, e) => s + _toInt((e as Map?)?['completedTopics']),
            ),
      );
      final total = _toInt(
        data['totalTopics'] ??
            overall?['totalTopics'] ??
            subjects.fold<int>(
              0,
              (s, e) => s + _toInt((e as Map?)?['totalTopics']),
            ),
      );
      final completedChapters = _toInt(
        data['completedChapters'] ??
            overall?['completedChapters'] ??
            subjects.fold<int>(
              0,
              (sum, e) => sum + _toInt((e as Map?)?['completedChapters']),
            ),
      );
      final totalChapters = _toInt(
        data['totalChapters'] ??
            overall?['totalChapters'] ??
            subjects.fold<int>(
              0,
              (sum, e) => sum + _toInt((e as Map?)?['totalChapters']),
            ),
      );
      final avg =
          _toDouble(overall?['percentage'] ?? data['averageScore'] ?? 0) * 100;
      return _ProgressSummary(
        list,
        completed,
        total,
        completedChapters,
        totalChapters,
        avg,
      );
    }
    return const _ProgressSummary([], 0, 0, 0, 0, 0);
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    final d = double.tryParse(val.toString()) ?? 0.0;
    return d > 1.0 ? d / 100.0 : d;
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    return int.tryParse(val.toString()) ?? 0;
  }

  void _openBoardSubscription(Map<String, dynamic> entry) {
    final boardId = entry['boardId'] as String;
    final classId = entry['classId'] as String;
    if (boardId.isEmpty || classId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          boardId: boardId,
          classId: classId,
          boardName: entry['boardName'] as String,
          className: (entry['className'] as String?)?.isNotEmpty == true
              ? entry['className'] as String
              : 'your class',
        ),
      ),
    ).then((_) => _loadProfile());
  }

  void _openExamSubscription(Map<String, dynamic> entry) {
    final examId = entry['examId'] as String;
    if (examId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamSubscriptionScreen(
          examId: examId,
          examName: entry['examName'] as String,
        ),
      ),
    ).then((_) => _loadProfile());
  }

  void _openOtherCourseSubscription(Map<String, dynamic> entry) {
    final otherCourseId = entry['otherCourseId'] as String;
    if (otherCourseId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherCourseSubscriptionScreen(
          otherCourseId: otherCourseId,
          otherCourseName: entry['otherCourseName'] as String,
        ),
      ),
    ).then((_) => _loadProfile());
  }

  // "Continue" par tap karte hi pehle subject-choice screen khulti hai
  // (Home ke inline subject-grid jaisi hi) — pehle seedha sabse kam-
  // progress wale subject ke chapters pe chala jaata tha, jo galat
  // tha: subject select karna student khud karega. Yahan se pehle
  // switchBoard/switchExam/switchOtherCourse call karke us course ko
  // "active" banate hain (Home/other pillars ki tarah), phir subject
  // list dikhate hain.
  Future<void> _openCourseSubjects(_CourseItem c) async {
    switch (c.kind) {
      case 'board':
        final boardId = c.entry['boardId'] as String? ?? '';
        final classId = c.entry['classId'] as String? ?? '';
        final languageId = c.entry['languageId'] as String? ?? '';
        if (boardId.isEmpty || classId.isEmpty) return;
        await APIService.putApiCaller(
          context: context,
          url: ApiUrls.switchBoard,
          body: {"boardId": boardId, "classId": classId},
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseSubjectsScreen(
              kind: 'board',
              courseTitle: c.title,
              boardId: boardId,
              classId: classId,
              languageId: languageId,
            ),
          ),
        ).then((_) => _loadProfile());
        break;

      case 'exam':
        final examId = c.entry['examId'] as String? ?? '';
        if (examId.isEmpty) return;
        await APIService.putApiCaller(
          context: context,
          url: ApiUrls.switchExam,
          body: {"examId": examId},
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseSubjectsScreen(
              kind: 'exam',
              courseTitle: c.entry['examName'] as String? ?? c.title,
              examId: examId,
            ),
          ),
        ).then((_) => _loadProfile());
        break;

      case 'otherCourse':
        final otherCourseId = c.entry['otherCourseId'] as String? ?? '';
        if (otherCourseId.isEmpty) return;
        await APIService.putApiCaller(
          context: context,
          url: ApiUrls.switchOtherCourse,
          body: {"otherCourseId": otherCourseId},
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseSubjectsScreen(
              kind: 'otherCourse',
              courseTitle: c.entry['otherCourseName'] as String? ?? c.title,
              otherCourseId: otherCourseId,
            ),
          ),
        ).then((_) => _loadProfile());
        break;
    }
  }

  // Unenrolls the student from this course (soft-delete on the backend
  // — progress data is kept). Every "my courses" list (Home, this
  // screen, dashboard) reads the same enrollment records, so this makes
  // the course disappear everywhere at once, not just here.
  Future<void> _removeCourse(_CourseItem c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Remove Course',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove "${c.title}"? You can add it back anytime from Other Courses.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    String url;
    switch (c.kind) {
      case 'board':
        final boardId = c.entry['boardId'] as String? ?? '';
        final classId = c.entry['classId'] as String? ?? '';
        if (boardId.isEmpty || classId.isEmpty) return;
        url = ApiUrls.removeBoardEnrollment(boardId, classId);
        break;
      case 'exam':
        final examId = c.entry['examId'] as String? ?? '';
        if (examId.isEmpty) return;
        url = ApiUrls.removeExamEnrollment(examId);
        break;
      case 'otherCourse':
        final otherCourseId = c.entry['otherCourseId'] as String? ?? '';
        if (otherCourseId.isEmpty) return;
        url = ApiUrls.removeOtherCourseEnrollment(otherCourseId);
        break;
      default:
        return;
    }
    final res = await APIService.deleteApiCaller(context: context, url: url);
    if (!mounted || res == "Error") return;
    _loadProfile();
  }

  List<_CourseItem> _buildCourseItems() {
    final items = <_CourseItem>[];
    var i = 0;

    for (final e in _boardEntries) {
      final className = (e['className'] as String?) ?? '';
      final stream = (e['stream'] as String?) ?? '';
      items.add(
        _CourseItem(
          title: className.isNotEmpty
              ? '${e['boardName']} $className'
              : e['boardName'].toString(),
          tag: stream,
          subtitle: stream.isNotEmpty ? stream : 'Board Course',
          bannerIcon: Icons.school_rounded,
          color: _colorCycle[i % _colorCycle.length],
          subscribed: e['subscribed'] == true,
          rawProgress: e['progress'],
          validTill: e['validTill'] as String?,
          lastStudied: e['lastStudied'] as String?,
          totalQuestions: e['totalQuestions'] is int
              ? e['totalQuestions'] as int
              : null,
          onSubscribe: () => _openBoardSubscription(e),
          kind: 'board',
          entry: e,
        ),
      );
      i++;
    }
    for (final e in _examEntries) {
      items.add(
        _CourseItem(
          title: e['examName'].toString(),
          tag: '',
          subtitle: 'Complete Course',
          bannerIcon: Icons.emoji_events_rounded,
          color: _colorCycle[i % _colorCycle.length],
          subscribed: e['subscribed'] == true,
          rawProgress: e['progress'],
          validTill: e['validTill'] as String?,
          lastStudied: e['lastStudied'] as String?,
          totalQuestions: e['totalQuestions'] is int
              ? e['totalQuestions'] as int
              : null,
          onSubscribe: () => _openExamSubscription(e),
          kind: 'exam',
          entry: e,
        ),
      );
      i++;
    }
    for (final e in _otherCourseEntries) {
      items.add(
        _CourseItem(
          title: e['otherCourseName'].toString(),
          tag: '',
          subtitle: 'Complete Course',
          bannerIcon: Icons.workspace_premium_rounded,
          color: _colorCycle[i % _colorCycle.length],
          subscribed: e['subscribed'] == true,
          rawProgress: e['progress'],
          validTill: e['validTill'] as String?,
          lastStudied: e['lastStudied'] as String?,
          totalQuestions: e['totalQuestions'] is int
              ? e['totalQuestions'] as int
              : null,
          onSubscribe: () => _openOtherCourseSubscription(e),
          kind: 'otherCourse',
          entry: e,
        ),
      );
      i++;
    }
    return items;
  }

  List<_CourseItem> _applyFilter(List<_CourseItem> subscribed) {
    if (_selectedFilter == 'All Courses') return subscribed;
    return subscribed.where((c) {
      final s = _extractProgress(c.rawProgress);
      final pct = s.total > 0 ? s.completed / s.total : (s.avgScore / 100);
      switch (_selectedFilter) {
        case 'In Progress':
          return pct > 0 && pct < 1;
        case 'Completed':
          return s.total > 0 && pct >= 1;
        case 'Expired':
          // TODO: backend abhi expiry/valid-till data nahi bhejta.
          return false;
        default:
          return true;
      }
    }).toList();
  }

  _CoursesStats _computeStats(List<_CourseItem> subscribed) {
    var subjects = 0;
    var completedTopics = 0;
    var totalTopics = 0;
    for (final c in subscribed) {
      final s = _extractProgress(c.rawProgress);
      subjects += s.list.length;
      completedTopics += s.completedChapters;
      totalTopics += s.total;
    }
    final overall = totalTopics > 0
        ? ((completedTopics / totalTopics) * 100).round()
        : 0;
    return _CoursesStats(subscribed.length, subjects, completedTopics, overall);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allCourses = _buildCourseItems();
    final subscribed = allCourses.where((c) => c.subscribed).toList();
    final locked = allCourses.where((c) => !c.subscribed).toList();
    final filtered = _applyFilter(subscribed);
    final stats = _computeStats(subscribed);
    final noCoursesAtAll = allCourses.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildFilterTabs(),
                const SizedBox(height: 16),
                _buildStatsRow(stats),
                const SizedBox(height: 24),

                if (!noCoursesAtAll) ...[
                  const Text(
                    'Your Enrolled Courses',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (filtered.isEmpty)
                  _buildEmptyState(noCoursesAtAll)
                else
                  for (final c in filtered) _buildCourseCard(c),

                if (locked.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Explore More',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final c in locked) _buildLockedCard(c),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────

  Widget _buildHeader() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'My Courses',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'All your enrolled courses in one place',
        style: TextStyle(fontSize: 13, color: Color(0xFF8A93A3)),
      ),
    ],
  );

  Widget _buildFilterTabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final f in _filters) ...[
          _buildFilterChip(f),
          const SizedBox(width: 10),
        ],
      ],
    ),
  );

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilter == label;
    final iconColor = selected
        ? Colors.white
        : (_filterIconColors[label] ?? const Color(0xFF3B4453));
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : const Color(0xFFE1E4EA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_filterIcons[label], size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(_CoursesStats stats) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            Icons.menu_book_rounded,
            const Color(0xFF7A4FD1),
            '${stats.coursesPurchased}',
            'Courses',
            'Enrolled',
          ),
        ),
        Expanded(
          child: _buildMiniStat(
            Icons.auto_stories_rounded,
            Colors.orange,
            '${stats.subjectsEnrolled}',
            'Subjects',
            'Enrolled',
          ),
        ),
        Expanded(
          child: _buildMiniStat(
            Icons.description_rounded,
            const Color(0xFF2E9E5B),
            '${stats.chaptersStudied}',
            'Chapters',
            'Studied',
          ),
        ),
        Expanded(
          child: _buildMiniStat(
            Icons.track_changes_rounded,
            AppColors.primaryBlue,
            '${stats.overallProgressPct}%',
            'Overall',
            'Progress',
          ),
        ),
      ],
    ),
  );

  Widget _buildMiniStat(
    IconData icon,
    Color color,
    String value,
    String line1,
    String line2,
  ) => Column(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(height: 8),
      Text(
        value,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        line1,
        style: const TextStyle(
          fontSize: 9.5,
          color: Color(0xFF9AA1AC),
          height: 1.2,
        ),
      ),
      Text(
        line2,
        style: const TextStyle(
          fontSize: 9.5,
          color: Color(0xFF9AA1AC),
          height: 1.2,
        ),
      ),
    ],
  );

  Widget _buildEmptyState(bool noCoursesAtAll) {
    if (noCoursesAtAll) {
      return GestureDetector(
        // Bottom-nav tab 1 is "Other Courses" now, not the board/exam
        // browse screen — always push CoursesScreen directly.
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CoursesScreen()),
        ).then((_) => _loadProfile()),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.explore_rounded,
                color: AppColors.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Pick a board or competitive exam to get started.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF9AA1AC),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off_rounded,
            size: 30,
            color: Color(0xFF9AA1AC),
          ),
          const SizedBox(height: 10),
          Text(
            'No courses in "$_selectedFilter" right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8A93A3), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(_CourseItem c) {
    final summary = _extractProgress(c.rawProgress);
    final pct = summary.total > 0
        ? summary.completed / summary.total
        : (summary.avgScore / 100).clamp(0.0, 1.0);

    Map<String, dynamic>? nextSubject;
    for (final s in summary.list) {
      if (nextSubject == null ||
          (s['progress'] as double) < (nextSubject['progress'] as double)) {
        nextSubject = s;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(c),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A93A3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F7EA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E9E5B),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _removeCourse(c),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFE0622F),
                            ),
                          ),
                        ),
                        if (c.validTill != null && c.validTill!.isNotEmpty) ...[
                          const Text(
                            'Valid till',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF9AA1AC),
                            ),
                          ),
                          Text(
                            c.validTill!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E9E5B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _metaChip(
                      Icons.menu_book_outlined,
                      '${summary.list.length} Subjects',
                    ),
                    _metaChip(
                      Icons.description_outlined,
                      '${summary.totalChapters} Chapters',
                    ),
                    if (c.totalQuestions != null)
                      _metaChip(
                        Icons.help_outline_rounded,
                        '${c.totalQuestions}+ Questions',
                      ),
                  ],
                ),
                if (nextSubject != null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'CURRENT SUBJECT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9AA1AC),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextSubject['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: c.color.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(c.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: c.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (c.lastStudied != null && c.lastStudied!.isNotEmpty) ...[
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Color(0xFF9AA1AC),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Last studied: ${c.lastStudied}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9AA1AC),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    ElevatedButton(
                      onPressed: () => _openCourseSubjects(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: const Color(0xFF9AA1AC)),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A3)),
      ),
    ],
  );

  // ── Banner: title, optional stream/tag pill, aur ek decorative icon
  // graphic. NOTE: screenshot mein jo hand-illustrated graphics hain
  // (cap+books, seal, police cap) wo custom art assets hain — inko
  // Flutter icons se hoobahu copy nahi kiya ja sakta, isliye closest
  // matching icon + colors use kiye hain.
  Widget _buildBanner(_CourseItem c) {
    final banner = _bannerShade(c.color);
    return Container(
      width: 92,
      height: 128,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: banner,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -14,
            child: Icon(
              c.bannerIcon,
              size: 64,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                c.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.tag.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9C158),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3B2A00),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(c.bannerIcon, color: Colors.white, size: 26),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCard(_CourseItem c) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE9EBEF)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: c.color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(c.bannerIcon, color: c.color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                c.subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A93A3)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: c.onSubscribe,
          style: TextButton.styleFrom(
            backgroundColor: c.color.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Subscribe',
            style: TextStyle(
              color: c.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}
