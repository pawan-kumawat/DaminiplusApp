import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../widgets/progress_ring.dart';
import 'exam_topics_screen.dart';
import 'exam_subscription_screen.dart';

class ExamChaptersScreen extends StatefulWidget {
  final String examId;
  final String examName;
  final String examSubjectId;
  final String examSubjectName;
  final String subjectImageUrl;

  const ExamChaptersScreen({
    super.key,
    required this.examId,
    required this.examName,
    required this.examSubjectId,
    required this.examSubjectName,
    this.subjectImageUrl = '',
  });

  @override
  State<ExamChaptersScreen> createState() => _ExamChaptersScreenState();
}

class _ExamChaptersScreenState extends State<ExamChaptersScreen> {
  List<Map<String, dynamic>> _chapters = [];
  Map<String, List<Map<String, dynamic>>> _topicsByChapter = {};
  List<Map<String, dynamic>> _allTopics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _idOf(dynamic val) {
    if (val == null) return '';
    if (val is Map) return val['_id']?.toString() ?? '';
    return val.toString();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getExamChapters(widget.examSubjectId),
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getExamSubjectTopics(widget.examSubjectId),
        showLoader: false,
      ),
    ]);
    if (!mounted) return;

    var chapters = <Map<String, dynamic>>[];
    if (results[0] != "Error") {
      try {
        final data = jsonDecode(results[0])['data'] as List<dynamic>? ?? [];
        chapters =
            data
                .map<Map<String, dynamic>>(
                  (e) => {
                    '_id': e['_id']?.toString() ?? '',
                    'name': e['name']?.toString() ?? 'Chapter',
                    'sortOrder': _toInt(e['sortOrder']),
                  },
                )
                .toList()
              ..sort(
                (a, b) =>
                    (a['sortOrder'] as int).compareTo(b['sortOrder'] as int),
              );
      } catch (_) {}
    }

    var topics = <Map<String, dynamic>>[];
    if (results[1] != "Error") {
      try {
        final data = jsonDecode(results[1])['data'] as List<dynamic>? ?? [];
        topics =
            data
                .map<Map<String, dynamic>>(
                  (e) => {
                    '_id': e['_id']?.toString() ?? '',
                    'name': e['name']?.toString() ?? 'Topic',
                    'examChapterId': _idOf(e['examChapterId']),
                    'sortOrder': _toInt(e['sortOrder']),
                    'isLocked':
                        e['isLocked'] == true ||
                        e['access']?['isLocked'] == true,
                    'requiresSubscription':
                        e['requiresSubscription'] == true ||
                        e['access']?['requiresSubscription'] == true,
                    'freePreview':
                        e['freePreview'] == true ||
                        e['access']?['freePreview'] == true,
                    'lockedReason':
                        e['lockedReason']?.toString() ??
                        e['access']?['lockedReason']?.toString() ??
                        '',
                    'completedQuestions': _toInt(
                      e['progress']?['completedQuestions'],
                    ),
                    'totalQuestions': _toInt(e['progress']?['totalQuestions']),
                  },
                )
                .toList()
              ..sort(
                (a, b) =>
                    (a['sortOrder'] as int).compareTo(b['sortOrder'] as int),
              );
      } catch (_) {}
    }
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final topic in topics) {
      grouped
          .putIfAbsent(topic['examChapterId'] as String, () => [])
          .add(topic);
    }
    setState(() {
      _chapters = chapters;
      _topicsByChapter = grouped;
      _allTopics = topics;
      _isLoading = false;
    });
  }

  int _totalQuestionsAllChapters() => _allTopics.fold<int>(
    0,
    (sum, tp) => sum + (tp['totalQuestions'] as int? ?? 0),
  );

  Widget _subjectCoverFallback() => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: AppColors.primaryBlue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(
      Icons.menu_book_rounded,
      color: AppColors.primaryBlue,
      size: 28,
    ),
  );

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: widget.subjectImageUrl.isNotEmpty
                ? Image.network(
                    widget.subjectImageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _subjectCoverFallback(),
                  )
                : _subjectCoverFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.examSubjectName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.examName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _statPill('Chapters', '${_chapters.length}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statPill(
                        'Questions',
                        '${_totalQuestionsAllChapters()}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.navy),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubjectHeader(),
                      const SizedBox(height: 12),
                      const Text(
                        'Choose a chapter to continue.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Chapters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Total: ${_chapters.length}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_chapters.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              'No chapters yet.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_chapters.length, (i) {
                          final chapter = _chapters[i];
                          final chapterId = chapter['_id'] as String;
                          final topicsHere = _topicsByChapter[chapterId] ?? [];
                          var completed = 0;
                          var total = 0;
                          for (final topic in topicsHere) {
                            completed += topic['completedQuestions'] as int;
                            total += topic['totalQuestions'] as int;
                          }
                          final pct = total > 0
                              ? (completed / total) * 100
                              : 0.0;
                          final locked =
                              topicsHere.isNotEmpty &&
                              topicsHere.every(
                                (topic) => topic['isLocked'] == true,
                              );
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == _chapters.length - 1 ? 0 : 14,
                            ),
                            child: _buildChapterCard(
                              index: i + 1,
                              name: chapter['name'] as String,
                              topicCount: topicsHere.length,
                              totalQuestions: total,
                              percent: pct,
                              isLocked: locked,
                              onTap: () {
                                if (locked) {
                                  _openSubscription(
                                    topicsHere.first['lockedReason']
                                            ?.toString() ??
                                        '',
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExamTopicsScreen(
                                      examId: widget.examId,
                                      examName: widget.examName,
                                      examSubjectId: widget.examSubjectId,
                                      examSubjectName: widget.examSubjectName,
                                      chapterName: chapter['name'] as String,
                                      chapterIndex: i + 1,
                                      topics: topicsHere,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildChapterCard({
    required int index,
    required String name,
    required int topicCount,
    required int totalQuestions,
    required double percent,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    final subtitleParts = <String>[
      if (topicCount >= 0)
        '$topicCount ${topicCount == 1 ? 'Topic' : 'Topics'}',
      if (totalQuestions > 0) '$totalQuestions Questions',
    ];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleParts.join(' • '),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              )
            else if (totalQuestions > 0)
              ProgressRing(percent: percent, size: 40, strokeWidth: 3.5)
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  void _openSubscription(String reason) {
    if (reason.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(reason)));
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamSubscriptionScreen(
          examId: widget.examId,
          examName: widget.examName,
        ),
      ),
    );
  }
}
