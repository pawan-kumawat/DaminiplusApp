import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'language_selection_screen.dart';
import 'exam_language_selection_screen.dart';

/// "Our Courses" tab — ek jagah pe saare boards aur competitive
/// exams dikhata hai (single /app/courses API se). User yahan se
/// jitne chahe utne boards/exams khareed sakta hai — sab ek hi
/// account par saath rehte hain (alag-alag enrollments hain
/// backend mein, ek doosre ko overwrite nahi karte). Jo bhi already
/// khareeda hua hai usi par green tick dikhta hai — chahe woh
/// abhi Home par "active" ho ya na ho.
///
/// Visual language Home screen ke reference design se match karti
/// hai: same navy/orange palette, 5-column circular grid, bina
/// leading-icon ke bold section headers.
class CoursesScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const CoursesScreen({super.key, this.onNavigateTab});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  static const int _pageSize = 10;
  static const Color _navy = Color(0xFF16388F);

  List<Map<String, dynamic>> _boards = [];
  List<Map<String, dynamic>> _exams = [];
  Set<String> _ownedBoardIds = {};
  Set<String> _ownedExamIds = {};
  bool _isLoading = true;
  bool _boardsExpanded = false;
  bool _examsExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      APIService.getApiCaller(context: context, url: ApiUrls.getCourses, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyBoards, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyExams, showLoader: false),
    ]);

    if (results[0] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[0]);
        final data = json['data'] ?? {};
        setState(() {
          _boards = ((data['boards'] as List<dynamic>?) ?? []).map((e) => {
            '_id': e['_id']?.toString() ?? '',
            'name': e['name']?.toString() ?? '',
            'fullName': e['fullName']?.toString() ?? e['name']?.toString() ?? '',
            'imageUrl': e['imageUrl']?.toString() ?? '',
            'hasPlans': e['hasPlans'] == true,
          }).toList();
          _exams = ((data['exams'] as List<dynamic>?) ?? []).map((e) => {
            '_id': e['_id']?.toString() ?? '',
            'name': e['name']?.toString() ?? '',
            'fullName': e['fullName']?.toString() ?? e['name']?.toString() ?? '',
            'imageUrl': e['imageUrl']?.toString() ?? '',
            'hasPlans': e['hasPlans'] == true,
          }).toList();
        });
      } catch (_) {}
    }

    if (results[1] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[1]);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _ownedBoardIds = list
              .where((e) => e['subscribed'] == true)
              .map<String>((e) => e['boardId']?.toString() ?? '')
              .toSet();
        });
      } catch (_) {}
    }

    if (results[2] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[2]);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _ownedExamIds = list
              .where((e) => e['subscribed'] == true)
              .map<String>((e) => e['examId']?.toString() ?? '')
              .toSet();
        });
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  void _openBoard(Map<String, dynamic> board) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LanguageSelectionScreen(
          boardId: board['_id'] as String,
          boardName: board['name'] as String,
        ),
      ),
    ).then((_) => _fetchCourses());
  }

  void _openExam(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamLanguageSelectionScreen(
          examId: exam['_id'] as String,
          examName: exam['name'] as String,
        ),
      ),
    ).then((_) => _fetchCourses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: AppColors.backgroundColor, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: _navy),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchCourses,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Our Courses',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _navy),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse every board and competitive exam. Add one alongside what you already study.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 22),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                else ...[
                  _buildSectionHeader(
                    'Major Boards',
                    expanded: _boardsExpanded,
                    showToggle: _boards.length > _pageSize,
                    onToggle: () => setState(() => _boardsExpanded = !_boardsExpanded),
                  ),
                  const SizedBox(height: 14),
                  if (_boards.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('No boards available yet.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    _buildGrid(_boards, _ownedBoardIds, _openBoard, _boardsExpanded),

                  const SizedBox(height: 26),
                  _buildSectionHeader(
                    'Competitive Exams',
                    expanded: _examsExpanded,
                    showToggle: _exams.length > _pageSize,
                    onToggle: () => setState(() => _examsExpanded = !_examsExpanded),
                  ),
                  const SizedBox(height: 14),
                  if (_exams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('No competitive exams available yet.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    _buildGrid(_exams, _ownedExamIds, _openExam, _examsExpanded),
                ],

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String label, {
        bool expanded = false,
        bool showToggle = false,
        VoidCallback? onToggle,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
          ),
        ),
        if (showToggle)
          GestureDetector(
            onTap: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    expanded ? 'View Less' : 'View All',
                    key: ValueKey(expanded),
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: expanded ? 0.5 : 0.0,
                  child: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryBlue, size: 17),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items, Set<String> ownedIds, void Function(Map<String, dynamic>) onTap, bool expanded) {
    final visible = expanded ? items : items.take(_pageSize).toList();
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
                          child: Text(logo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _navy)),
                        ),
                      ),
                    )
                        : Center(
                      child: Text(logo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _navy)),
                    ),
                  ),
                  if (isOwned)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: _navy, height: 1.1),
              ),
            ],
          ),
        );
      },
    );
  }
}