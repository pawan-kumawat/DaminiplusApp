import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'chapters_screen.dart';
import 'exam_chapters_screen.dart';
import 'other_course_chapters_screen.dart';

/// Subject picker shown between "Continue" (on My Courses) and the
/// Chapters screen — tapping Continue used to jump straight into
/// whichever subject had the least progress, skipping subject choice
/// entirely. This screen lists every subject for the course so the
/// student picks one first, same as the Home screen's inline subject
/// grid.
class CourseSubjectsScreen extends StatefulWidget {
  final String kind; // 'board' | 'exam' | 'otherCourse'
  final String courseTitle;
  // board
  final String boardId;
  final String classId;
  final String languageId;
  // exam
  final String examId;
  // otherCourse
  final String otherCourseId;

  const CourseSubjectsScreen({
    super.key,
    required this.kind,
    required this.courseTitle,
    this.boardId = '',
    this.classId = '',
    this.languageId = '',
    this.examId = '',
    this.otherCourseId = '',
  });

  @override
  State<CourseSubjectsScreen> createState() => _CourseSubjectsScreenState();
}

class _CourseSubjectsScreenState extends State<CourseSubjectsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];

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
    Color(0xFF2E9E5B),
    Color(0xFF7A4FD1),
    Colors.orange,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  IconData _iconFor(String name) {
    final key = name.toLowerCase();
    for (final entry in _iconMap.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return Icons.menu_book_outlined;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    String url;
    switch (widget.kind) {
      case 'exam':
        url = ApiUrls.getExamSubjects(widget.languageId, examId: widget.examId);
        break;
      case 'otherCourse':
        url = ApiUrls.getOtherCourseSubjects(widget.languageId, otherCourseId: widget.otherCourseId);
        break;
      default:
        url = ApiUrls.getSubjects(widget.languageId, boardId: widget.boardId, classId: widget.classId);
    }
    final res = await APIService.getApiCaller(context: context, url: url, showLoader: false);
    if (!mounted) return;
    if (res != "Error") {
      try {
        final data = jsonDecode(res)['data'] as List<dynamic>? ?? [];
        setState(() {
          _subjects = data.map<Map<String, dynamic>>((e) => {
            '_id': e['_id']?.toString() ?? '',
            'name': e['name']?.toString() ?? 'Subject',
            'imageUrl': e['iconUrl']?.toString() ?? e['imageUrl']?.toString() ?? '',
          }).toList();
        });
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  void _openSubject(Map<String, dynamic> subject) {
    final subjectId = subject['_id'] as String;
    final subjectName = subject['name'] as String;
    final subjectImageUrl = subject['imageUrl'] as String? ?? '';
    if (subjectId.isEmpty) return;

    switch (widget.kind) {
      case 'exam':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamChaptersScreen(
              examId: widget.examId,
              examName: widget.courseTitle,
              examSubjectId: subjectId,
              examSubjectName: subjectName,
              subjectImageUrl: subjectImageUrl,
            ),
          ),
        );
        break;
      case 'otherCourse':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherCourseChaptersScreen(
              otherCourseId: widget.otherCourseId,
              otherCourseName: widget.courseTitle,
              otherCourseSubjectId: subjectId,
              otherCourseSubjectName: subjectName,
              subjectImageUrl: subjectImageUrl,
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChaptersScreen(
              subjectId: subjectId,
              subjectName: subjectName,
              languageId: widget.languageId,
              subjectImageUrl: subjectImageUrl,
              boardName: widget.kind == 'board' ? widget.courseTitle : '',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.courseTitle, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.navy), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _subjects.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No subjects available yet.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _subjects.length,
                    itemBuilder: (_, i) {
                      final subject = _subjects[i];
                      final name = subject['name'] as String;
                      final imageUrl = subject['imageUrl'] as String;
                      final color = _colorCycle[i % _colorCycle.length];
                      return GestureDetector(
                        onTap: () => _openSubject(subject),
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
                              imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                          child: Icon(_iconFor(name), color: color, size: 22),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                      child: Icon(_iconFor(name), color: color, size: 22),
                                    ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
