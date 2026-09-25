import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'other_course_language_selection_screen.dart';
import 'main_screen.dart';

/// Course detail / marketplace landing page for a single Other Course.
/// Shows real backend stats (subjects/chapters/topics/questions +
/// enrolled-student count) and a static, truthful feature checklist —
/// no fabricated ratings/reviews/"Bestseller" badges since the backend
/// has no such data. Buy Now goes straight to payment (unlike Competitive
/// Exam, which lets you browse locked content and pay later) — payment
/// happens first here, then the subscription screen hands off into
/// language selection, then home.
class OtherCourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final bool isOwned;

  const OtherCourseDetailScreen({super.key, required this.course, this.isOwned = false});

  @override
  State<OtherCourseDetailScreen> createState() => _OtherCourseDetailScreenState();
}

class _OtherCourseDetailScreenState extends State<OtherCourseDetailScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _subjectsExpanded = false;
  bool _loadingSubjects = true;

  String get _courseId => widget.course['_id']?.toString() ?? '';
  String get _name => widget.course['name']?.toString() ?? '';
  String get _fullName => widget.course['fullName']?.toString() ?? '';
  String get _imageUrl => widget.course['imageUrl']?.toString() ?? '';
  String get _description => widget.course['description']?.toString() ?? '';

  Map<String, dynamic> get _stats => widget.course['stats'] as Map<String, dynamic>? ?? {};

  @override
  void initState() {
    super.initState();
    _fetchSubjectsPreview();
  }

  Future<void> _fetchSubjectsPreview() async {
    if (_courseId.isEmpty) {
      setState(() => _loadingSubjects = false);
      return;
    }
    final response = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.getOtherCourseSubjectsPreview(_courseId),
      showLoader: false,
    );
    if (response != "Error" && mounted) {
      try {
        final json = jsonDecode(response);
        final data = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _subjects = data.map<Map<String, dynamic>>((e) => {
            'name': e['name']?.toString() ?? '',
            'imageUrl': e['imageUrl']?.toString() ?? '',
          }).toList();
        });
      } catch (_) {}
    }
    if (mounted) setState(() => _loadingSubjects = false);
  }

  void _onCta() {
    if (widget.isOwned) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
      return;
    }
    // Subscriptions are off — every course is free, so this goes
    // straight to (free) language selection instead of payment.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherCourseLanguageSelectionScreen(
          otherCourseId: _courseId,
          otherCourseName: _name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languages = (widget.course['languageIds'] as List<dynamic>? ?? [])
        .map((l) => (l is Map ? l['name']?.toString() : null) ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final visibleSubjects = _subjectsExpanded ? _subjects : _subjects.take(6).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navy)),
                          if (_fullName.isNotEmpty && _fullName != _name) ...[
                            const SizedBox(height: 4),
                            Text(_fullName, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.groups_rounded, size: 15, color: Colors.grey.shade500),
                              const SizedBox(width: 5),
                              Text(
                                '${_stats['studentsCount'] ?? 0} students enrolled',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          if (languages.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _badge(Icons.translate_rounded, languages.join(', ')),
                                _badge(Icons.record_voice_over_rounded, 'Audio Explanations'),
                              ],
                            ),
                          ],
                          const SizedBox(height: 22),
                          _buildStatsGrid(),
                          const SizedBox(height: 26),
                          if (_loadingSubjects)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_subjects.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Included Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                                if (_subjects.length > 6)
                                  GestureDetector(
                                    onTap: () => setState(() => _subjectsExpanded = !_subjectsExpanded),
                                    child: Text(
                                      _subjectsExpanded ? 'View Less' : 'View All (${_subjects.length})',
                                      style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12.5),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: visibleSubjects.map((s) => _subjectChip(s)).toList(),
                            ),
                            const SizedBox(height: 26),
                          ],
                          const Text("You'll Get", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                          const SizedBox(height: 14),
                          _buildChecklist(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Course covers are tall posters with title/branding printed on
        // them, not landscape banners — BoxFit.cover here used to crop
        // most of a portrait poster away. BoxFit.contain always shows
        // the whole cover, letterboxed on the tinted background if its
        // ratio doesn't match this banner's shape.
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _imageUrl.isNotEmpty
              ? Image.network(
                  _imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.school_rounded, size: 64, color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                  ),
                )
              : Center(
                  child: Icon(Icons.school_rounded, size: 64, color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.navy),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryBlue),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      ('Subjects', _stats['subjectsCount'], Icons.menu_book_rounded),
      ('Chapters', _stats['chaptersCount'], Icons.bookmark_outline_rounded),
      ('Topics', _stats['topicsCount'], Icons.play_circle_outline_rounded),
      ('Questions', _stats['questionsCount'], Icons.quiz_outlined),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: items.map((item) {
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.$3, size: 18, color: AppColors.primaryBlue),
              const SizedBox(height: 6),
              Text('${item.$2 ?? 0}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
              Text(item.$1, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _subjectChip(Map<String, dynamic> subject) {
    final name = subject['name']?.toString() ?? '';
    final imageUrl = subject['imageUrl']?.toString() ?? '';
    final logo = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.backgroundColor, shape: BoxShape.circle),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(child: Text(logo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy))),
                  )
                : Center(child: Text(logo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy))),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    // Admin-editable per-course pitch (one line per feature) — falls
    // back to a generic, still-truthful checklist for courses nobody
    // has written a description for yet, so this section never shows
    // empty.
    final customLines = _description.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final features = customLines.isNotEmpty
        ? customLines
        : const [
            'Practice questions with step-by-step solutions',
            'Audio explanations (text-to-speech) for every step',
            'Topic-wise progress tracking',
            'Photo-based answer submission with AI evaluation',
            'Unlimited access for your plan duration',
          ];
    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, size: 17, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: AppColors.navy, height: 1.35))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _onCta,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(
            widget.isOwned ? 'Continue Learning' : 'Start Learning — Free',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
