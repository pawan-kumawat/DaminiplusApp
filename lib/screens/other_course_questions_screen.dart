import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../widgets/math_text.dart';
import 'explanation_solution_screen.dart';
import 'rough_work_solve_screen.dart';
import 'teacher_record_screen.dart';

class OtherCourseQuestionsScreen extends StatefulWidget {
  final String otherCourseId;
  final String otherCourseName;
  final String otherCourseSubjectId;
  final String otherCourseSubjectName;
  final String topicId;
  final String topicName;

  const OtherCourseQuestionsScreen({
    super.key,
    required this.otherCourseId,
    required this.otherCourseName,
    required this.otherCourseSubjectId,
    required this.otherCourseSubjectName,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<OtherCourseQuestionsScreen> createState() =>
      _OtherCourseQuestionsScreenState();
}

class _OtherCourseQuestionsScreenState
    extends State<OtherCourseQuestionsScreen> {
  final List<Map<String, dynamic>> _questions = [];
  final Map<int, Map<String, dynamic>> _submissions = {};
  // answer instead, so each one needs its own persisted controller
  // (keyed by question index, same as _submissions).

  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  int _total = 0;

  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSubmittingAnswer = false;
  bool _topicReadOnly = false;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    AppSharedPreferencesData.getIsTeacher().then((value) {
      if (mounted) setState(() => _isTeacher = value);
    });
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    await _fetchQuestions();
    if (!mounted) return;
    await _jumpToResumePosition();
  }

  // Opens on the first question that has no submission yet instead of
  // always Q1 — paginates in more pages if every loaded question is
  // already answered, so a student resuming a long topic doesn't have
  // to page through everything they already did.
  Future<void> _jumpToResumePosition() async {
    if (_topicReadOnly) {
      if (mounted) setState(() => _currentIndex = 0);
      return;
    }

    int firstUnanswered() {
      for (var i = 0; i < _questions.length; i++) {
        if (_questions[i]['questionType'] != 'theory' &&
            _submissions[i] == null) {
          return i;
        }
      }
      return -1;
    }

    var idx = firstUnanswered();
    while (idx == -1 && _hasMore && mounted) {
      await _fetchQuestions(isLoadMore: true);
      if (!mounted) return;
      idx = firstUnanswered();
    }
    if (idx == -1) idx = 0;
    if (idx > 0 && mounted) setState(() => _currentIndex = idx);
  }

  dynamic _pick(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json[k] != null) return json[k];
    }
    return null;
  }

  Future<void> _fetchQuestions({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    final response = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.getOtherCourseQuestions(
        widget.otherCourseSubjectId,
        widget.topicId,
        page: _page,
        limit: _limit,
      ),
      showLoader: false,
    );

    if (response != "Error" && mounted) {
      try {
        final json = jsonDecode(response);
        final rawData = json['data'];

        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
          _hasMore = list.length >= _limit;
        } else if (rawData is Map) {
          list =
              (rawData['questions'] ??
                      rawData['items'] ??
                      rawData['list'] ??
                      [])
                  as List<dynamic>;
          final t = rawData['total'] ?? rawData['totalCount'];
          if (t != null) _total = int.tryParse(t.toString()) ?? 0;
          final hm = rawData['hasMore'];
          _hasMore = hm != null ? hm == true : list.length >= _limit;
          _topicReadOnly =
              rawData['readOnly'] == true ||
              (rawData['topicProgress'] is Map &&
                  rawData['topicProgress']['readOnly'] == true);
        }

        final startIndex = _questions.length;
        final parsed = list.map<Map<String, dynamic>>((e) {
          final m = e as Map<String, dynamic>;
          final rawOptions = (m['options'] is List)
              ? (m['options'] as List)
              : const [];
          final options = List<String>.generate(
            4,
            (i) => i < rawOptions.length ? rawOptions[i].toString() : '',
          );
          final rawOptionImages = (m['optionImageUrls'] is List)
              ? (m['optionImageUrls'] as List)
              : const [];
          final optionImageUrls = List<String>.generate(
            4,
            (i) =>
                i < rawOptionImages.length ? rawOptionImages[i].toString() : '',
          );
          return <String, dynamic>{
            '_id': m['_id']?.toString() ?? '',
            'questionText':
                _pick(m, [
                  'questionText',
                  'text',
                  'title',
                  'question',
                ])?.toString() ??
                '',
            'note': _pick(m, ['note', 'instruction', 'hint'])?.toString() ?? '',
            'questionType': m['questionType']?.toString() ?? 'mcq',
            'answerText': m['answerText']?.toString() ?? '',
            'options': options,
            'correctOptionIndex':
                int.tryParse(m['correctOptionIndex']?.toString() ?? '') ?? 0,
            'questionImageUrl': m['questionImageUrl']?.toString() ?? '',
            'optionImageUrls': optionImageUrls,
            'explanationVideoUrl': m['explanationVideoUrl']?.toString() ?? '',
            'explanationImageUrl': m['explanationImageUrl']?.toString() ?? '',
            'explanationDescription':
                m['explanationDescription']?.toString() ?? '',
            'level':
                _pick(m, [
                  'level',
                  'difficultyLevel',
                  'difficulty',
                ])?.toString() ??
                '',
            'maxMarks': m['maxMarks'] ?? m['totalMarks'] ?? 10,
            'readOnly': m['readOnly'] == true,
            'isCompleted': m['isCompleted'] == true,
            'submission': m['submission'],
          };
        }).toList();

        setState(() {
          _questions.addAll(parsed);
          // Only populate past submissions if topic is in-progress (not completed).
          // For completed topics, student enters to practice fresh, so questions start clear.
          if (!_topicReadOnly) {
            for (var i = 0; i < parsed.length; i++) {
              final submission = parsed[i]['submission'];
              if (submission is Map<String, dynamic>) {
                _submissions[startIndex + i] = {
                  'selectedOptionIndex':
                      int.tryParse(
                        submission['selectedOptionIndex']?.toString() ?? '',
                      ) ??
                      0,
                  'isCorrect': submission['isCorrect'] == true,
                  'answerText': submission['answerText']?.toString() ?? '',
                };
              }
            }
          }
        });
      } catch (_) {}
    }

    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _selectOption(int optionIndex) async {
    if (_isSubmittingAnswer || _submissions[_currentIndex] != null) return;
    final question = _questions[_currentIndex];
    final questionId = question['_id'] as String;
    if (questionId.isEmpty) return;

    setState(() => _isSubmittingAnswer = true);

    final response = await APIService.postApiCaller(
      context: context,
      url: ApiUrls.submitOtherCourseAnswer(questionId),
      body: {'selectedOptionIndex': optionIndex},
      showLoader: false,
    );

    if (!mounted) return;

    if (response != "Error") {
      try {
        final json = jsonDecode(response);
        final data = json['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _submissions[_currentIndex] = {
            'selectedOptionIndex': optionIndex,
            'isCorrect': data['isCorrect'] == true,
          };
          _isSubmittingAnswer = false;
        });
      } catch (_) {
        setState(() => _isSubmittingAnswer = false);
      }
    } else if (_topicReadOnly) {
      // Local practice evaluation if topic is read-only / completed
      final correctIdx = question['correctOptionIndex'] as int;
      setState(() {
        _submissions[_currentIndex] = {
          'selectedOptionIndex': optionIndex,
          'isCorrect': optionIndex == correctIdx,
        };
        _isSubmittingAnswer = false;
      });
    } else {
      setState(() => _isSubmittingAnswer = false);
    }
  }

  // Teacher-only — records this exact question's explanation video for
  // whichever other-course language is currently active on this account
  // (no per-screen language param here — it lives on the profile, see
  // AppSharedPreferencesData). Once recorded, the button for this
  // question+language never comes back.
  Future<void> _openTeacherRecord() async {
    final question = _questions[_currentIndex];
    final questionId = question['_id'] as String;
    if (questionId.isEmpty) return;
    final languageId =
        await AppSharedPreferencesData.getOtherCourseLanguageId();
    if (languageId.isEmpty || !mounted) return;
    final url = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherRecordScreen(
          questionId: questionId,
          languageId: languageId,
          pillar: 'otherCourse',
          questionTitle: question['questionText'] as String,
          questionImageUrl: question['questionImageUrl'] as String,
        ),
      ),
    );
    if (url != null && url.isNotEmpty && mounted) {
      setState(() => _questions[_currentIndex]['explanationVideoUrl'] = url);
    }
  }

  void _goToPrevious() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex--;
    });
  }

  Future<bool> _markTheoryRead(Map<String, dynamic> question) async {
    if (_topicReadOnly || _submissions[_currentIndex] != null) return true;
    final questionId = question['_id'] as String;
    if (questionId.isEmpty) return false;
    final response = await APIService.postApiCaller(
      context: context,
      url: ApiUrls.submitOtherCourseAnswer(questionId),
      body: {'readOnly': true},
      showLoader: false,
    );
    if (response == "Error" || !mounted) return false;
    setState(() => _submissions[_currentIndex] = {'readOnly': true});
    return true;
  }

  Future<void> _goToNext() async {
    final currentQ = _questions[_currentIndex];
    final isTheory = currentQ['questionType'] == 'theory';
    if (!_topicReadOnly && isTheory && !await _markTheoryRead(currentQ)) return;
    if (!_topicReadOnly && !isTheory && _submissions[_currentIndex] == null) {
      return;
    }

    final isLastLoaded = _currentIndex >= _questions.length - 1;

    if (isLastLoaded && _hasMore) {
      _page++;
      await _fetchQuestions(isLoadMore: true);
    }

    if (!mounted) return;

    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      if (!_topicReadOnly) {
        final response = await APIService.postApiCaller(
          context: context,
          url: ApiUrls.completeOtherCourseTopic(widget.topicId),
          body: {},
          showLoader: true,
        );
        if (response == "Error") return;
        _topicReadOnly = true;
      }
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All Done!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You've finished this topic.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.navy),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'No questions available for this topic yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final submission = _submissions[_currentIndex];
    final isTheory = question['questionType'] == 'theory';
    final questionReadOnly = _topicReadOnly || question['readOnly'] == true;
    final totalKnown = _total > 0 ? _total : _questions.length;
    final note = question['note'] as String;
    final options = question['options'] as List<String>;
    final optionImageUrls = question['optionImageUrls'] as List<String>;
    final explanationVideoUrl = question['explanationVideoUrl'] as String;
    final explanationImageUrl = question['explanationImageUrl'] as String;
    final explanationDescription = question['explanationDescription'] as String;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.topicName,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // ── Teacher-only recording button — hidden the moment
                    // this question already has a video for the current
                    // other-course language, never shown to students at all. ──
                    if (_isTeacher) ...[
                      SizedBox(
                        width: double.infinity,
                        child: explanationVideoUrl.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Explanation recorded',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _openTeacherRecord,
                                icon: const Icon(
                                  Icons.videocam_rounded,
                                  size: 18,
                                ),
                                label: const Text('Record Explanation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Question card ──────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((question['questionImageUrl'] as String? ??
                                        '')
                                    .isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      question['questionImageUrl'] as String,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if ((question['questionText'] as String)
                                    .isNotEmpty)
                                  MathText(
                                    question['questionText'] as String,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                      height: 1.4,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -18,
                            left: -18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Q${_currentIndex + 1}/$totalKnown',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                          if (note.isNotEmpty)
                            Positioned(
                              top: -18,
                              right: -18,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 92),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── MCQ options or the theory reading answer ──
                    question['questionType'] == 'theory'
                        ? _buildTheoryAnswerPanel(submission)
                        : _buildOptionsPanel(
                            options,
                            optionImageUrls,
                            submission,
                          ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _navButton(
                      icon: Icons.chevron_left_rounded,
                      label: 'Previous',
                      enabled: _currentIndex > 0,
                      onTap: _goToPrevious,
                      filled: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _toolTileButton(
                      icon: Icons.edit_outlined,
                      label: 'Board',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoughWorkSolveScreen(
                            questionText: question['questionText'] as String,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _toolTileButton(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Solution',
                      enabled:
                          explanationVideoUrl.isNotEmpty ||
                          explanationImageUrl.isNotEmpty ||
                          explanationDescription.isNotEmpty,
                      onTap:
                          (explanationVideoUrl.isEmpty &&
                              explanationImageUrl.isEmpty &&
                              explanationDescription.isEmpty)
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExplanationSolutionScreen(
                                  questionText:
                                      question['questionText'] as String,
                                  videoUrl: explanationVideoUrl,
                                  imageUrl: explanationImageUrl,
                                  description: explanationDescription,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _navButton(
                      icon: Icons.chevron_right_rounded,
                      label: _currentIndex >= _questions.length - 1
                          ? 'Finish'
                          : 'Next',
                      enabled:
                          !_isSubmittingAnswer &&
                          (questionReadOnly || isTheory || submission != null),
                      onTap: _goToNext,
                      filled: true,
                      iconTrailing: true,
                      loading: _isLoadingMore,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTheoryAnswerPanel(Map<String, dynamic>? submission) {
    final question = _questions[_currentIndex];
    final answer = (question['answerText'] ?? '').toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).text('Answer'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          MathText(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.navy,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPanel(
    List<String> options,
    List<String> optionImageUrls,
    Map<String, dynamic>? submission,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).text('Choose the correct answer'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < options.length; i++)
            _buildOptionTile(
              i,
              options[i],
              i < optionImageUrls.length ? optionImageUrls[i] : '',
              submission,
            ),
          if (_isSubmittingAnswer)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(minHeight: 2.5),
            ),
          if (submission != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  submission['isCorrect'] == true
                      ? Icons.celebration_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: submission['isCorrect'] == true
                      ? Colors.green
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    submission['isCorrect'] == true
                        ? 'Correct answer!'
                        : 'Not quite — the correct option is highlighted above.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: submission['isCorrect'] == true
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    required bool filled,
    bool iconTrailing = false,
    bool loading = false,
  }) {
    final color = filled
        ? Colors.white
        : (enabled ? AppColors.navy : Colors.grey.shade400);
    final content = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: iconTrailing
                ? [
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).text(label),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: color,
                        ),
                      ),
                    ),
                    Icon(icon, size: 20, color: color),
                  ]
                : [
                    Icon(icon, size: 20, color: color),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).text(label),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: color,
                        ),
                      ),
                    ),
                  ],
          );
    return SizedBox(
      height: 52,
      child: filled
          ? ElevatedButton(
              onPressed: enabled ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(
                  0.35,
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: enabled ? onTap : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: content,
            ),
    );
  }

  Widget _toolTileButton({
    required IconData icon,
    required String label,
    bool enabled = true,
    required VoidCallback? onTap,
  }) {
    final color = enabled ? AppColors.navy : Colors.grey.shade300;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context).text(label),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    int index,
    String text,
    String imageUrl,
    Map<String, dynamic>? submission,
  ) {
    final question = _questions[_currentIndex];
    final correctIndex = question['correctOptionIndex'] as int;
    final answered = submission != null;
    final isSelected = submission?['selectedOptionIndex'] == index;
    final isCorrectOption = answered && correctIndex == index;
    final isWrongSelected =
        answered && isSelected && submission['isCorrect'] != true;

    Color borderColor = Colors.grey.shade200;
    Color bgColor = Colors.white;
    Color textColor = AppColors.navy;
    IconData? trailingIcon;
    Color? trailingColor;

    if (isCorrectOption) {
      borderColor = Colors.green;
      bgColor = Colors.green.withOpacity(0.08);
      textColor = Colors.green.shade800;
      trailingIcon = Icons.check_circle;
      trailingColor = Colors.green;
    } else if (isWrongSelected) {
      borderColor = Colors.red;
      bgColor = Colors.red.withOpacity(0.08);
      textColor = Colors.red.shade800;
      trailingIcon = Icons.cancel;
      trailingColor = Colors.red;
    } else if (answered) {
      textColor = AppColors.textSecondary;
    }

    final label = String.fromCharCode(65 + index);

    return GestureDetector(
      onTap: (answered || _isSubmittingAnswer)
          ? null
          : () => _selectOption(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: (isCorrectOption || isWrongSelected) ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrectOption
                    ? Colors.green
                    : (isWrongSelected
                          ? Colors.red
                          : AppColors.backgroundColor),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: (isCorrectOption || isWrongSelected)
                      ? Colors.white
                      : AppColors.navy,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 100),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (text.isNotEmpty)
                    MathText(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: (isCorrectOption || isWrongSelected)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: trailingColor, size: 20),
          ],
        ),
      ),
    );
  }
}
