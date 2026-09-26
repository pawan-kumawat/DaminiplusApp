// ─────────────────────────────────────────────────────────────
// library_screen.dart
// Bottom-nav "Library" tab — student apne saare (subscribed) boards/
// exams/other-courses ka study material yahan se browse karta hai:
// Books, Competitive Exams (model/previous papers), Current Affairs,
// Practice Set — 4 genuinely distinct backend resource types.
//
// Reference screenshot ke structure ko closely follow karta hai — top
// type-filter chips, "Explore by Category" grid, "Select Board/Exam"
// avatar row, "Recent Added" flat file feed (capped to the latest 10).
// Ek cheez reference se jaanboojh kar alag hai: reference me row par
// download icon hai, lekin app me kahin bhi asli download feature
// nahi hai (sirf in-app PDF view) — isliye yahan bhi view/eye icon
// use kiya hai, existing pattern ke hi mutabiq.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AdHelper.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../utils/format_utils.dart';
import '../widgets/book_cover.dart';
import 'study_material_list_screen.dart';
import 'study_material_detail_screen.dart';
import 'pdf_viewer_screen.dart';
import 'courses_screen.dart';
import 'other_courses_list_screen.dart';

class LibraryScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const LibraryScreen({super.key, this.onNavigateTab});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _byType = {
    'book': [],
    'model_paper': [],
    'practice_set': [],
    'current_affairs': [],
  };
  List<Map<String, dynamic>> _boards = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _otherCourses = [];
  List<Map<String, dynamic>> _recentItems = [];

  // Top chips filter the "Recent Added" feed only — 'all' | 'book' |
  // 'model_paper' | 'practice_set' | 'current_affairs' (the 4 real
  // backend types now shown in the app; legacy 'notes' uploads still
  // exist in the DB but aren't surfaced here anymore).
  String _typeChip = 'all';

  // Search — tapping the search icon swaps the whole page for a search
  // bar + a combined books/model-papers/notes results grid.
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // 5 distinct blocks — Books/Competitive Exam share the same 'book'
  // backend type but are split by source (board vs exam+otherCourse)
  // so they read as two separate categories in the explore grid.
  static const List<Map<String, dynamic>> _exploreCategories = [
    {
      'label': 'All',
      'type': 'all',
      'kinds': null,
      'icon': Icons.apps_rounded,
      'color': Color(0xFF1F2D3D),
    },
    {
      'label': 'Books',
      'type': 'book',
      'kinds': {'board'},
      'icon': Icons.auto_stories_rounded,
      'color': Color(0xFF3757C9),
    },
    {
      'label': 'Competitive Exam',
      'type': 'book',
      'kinds': {'exam', 'otherCourse'},
      'icon': Icons.emoji_events_outlined,
      'color': Color(0xFF3D9142),
    },
    {
      'label': 'Model Paper',
      'type': 'model_paper',
      'kinds': null,
      'icon': Icons.description_outlined,
      'color': Color(0xFFED8646),
    },
    {
      'label': 'Current Affairs',
      'type': 'current_affairs',
      'kinds': null,
      'icon': Icons.newspaper_rounded,
      'color': Color(0xFF16A085),
    },
    {
      'label': 'Practice Set',
      'type': 'practice_set',
      'kinds': null,
      'icon': Icons.fact_check_rounded,
      'color': Color(0xFF8B4FD1),
    },
  ];

  static const Map<String, String> _typeTitle = {
    'book': 'Books',
    'model_paper': 'Model Paper',
    'current_affairs': 'Current Affairs',
    'practice_set': 'Practice Set',
  };

  static const List<Map<String, String>> _chipDefs = [
    {'key': 'all', 'label': 'All'},
    {'key': 'book', 'label': 'Books'},
    {'key': 'model_paper', 'label': 'Model Paper'},
    {'key': 'current_affairs', 'label': 'Current Affairs'},
    {'key': 'practice_set', 'label': 'Practice Set'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // Books + Model Papers + Notes ek hi combined, searchable list —
  // har subject apne resource type ke saath tagged.
  List<Map<String, dynamic>> get _searchResults {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return [];
    final combined = <Map<String, dynamic>>[];
    for (final type in [
      'book',
      'model_paper',
      'practice_set',
      'current_affairs',
    ]) {
      for (final subject in _byType[type] ?? []) {
        combined.add({...subject, '_resourceType': type});
      }
    }
    return combined.where((s) {
      final name = (s['name'] as String).toLowerCase();
      final group = [
        s['boardName'],
        s['examName'],
        s['otherCourseName'],
      ].whereType<String>().join(' ').toLowerCase();
      return name.contains(query) || group.contains(query);
    }).toList();
  }

  String _idOf(dynamic val) {
    if (val == null) return '';
    if (val is Map) return val['_id']?.toString() ?? '';
    return val.toString();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getStudyMaterial('book'),
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getStudyMaterial('model_paper'),
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getStudyMaterial('practice_set'),
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getStudyMaterial('current_affairs'),
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
        url: ApiUrls.getMyOtherCourses,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getRecentStudyMaterial(limit: 10),
        showLoader: false,
      ),
    ]);
    if (!mounted) return;

    setState(() {
      _byType = {
        'book': _parseSubjects(results[0]),
        'model_paper': _parseSubjects(results[1]),
        'practice_set': _parseSubjects(results[2]),
        'current_affairs': _parseSubjects(results[3]),
      };
      _boards = _parseBoards(results[4]);
      _exams = _parseExams(results[5]);
      _otherCourses = _parseOtherCourses(results[6]);
      _recentItems = _parseRecent(results[7]);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _parseSubjects(dynamic result) {
    if (result == "Error" || result == null) return [];
    try {
      final json = jsonDecode(result);
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map<Map<String, dynamic>>(
            (e) => {
              'kind': e['kind']?.toString() ?? 'board',
              'subjectId': _idOf(e['subjectId']),
              'name': e['name']?.toString() ?? 'Subject',
              'iconUrl': e['iconUrl']?.toString() ?? '',
              'boardId': _idOf(e['boardId']),
              'boardName': e['boardName']?.toString() ?? '',
              'classId': _idOf(e['classId']),
              'className': e['className']?.toString() ?? '',
              'examId': _idOf(e['examId']),
              'examName': e['examName']?.toString() ?? '',
              'otherCourseId': _idOf(e['otherCourseId']),
              'otherCourseName': e['otherCourseName']?.toString() ?? '',
              'resourceCount': e['resourceCount'] is int
                  ? e['resourceCount']
                  : int.tryParse(e['resourceCount']?.toString() ?? '') ?? 0,
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _parseBoards(dynamic result) {
    if (result == "Error" || result == null) return [];
    try {
      final json = jsonDecode(result);
      final list = json['data'] as List<dynamic>? ?? [];
      // Library ka access poori tarah free hai — subscribed==true se
      // filter nahi karte, warna sirf-select-kiya-but-abhi-tak-paid-
      // nahi-kiya board yahan gayab ho jaata tha.
      // getMyBoards ek row per (board, class) enrollment deta hai, ek
      // hi board ke multiple classes select karne par board yahan
      // baar-baar duplicate ho jaata — id se dedupe karke ek hi rakhte.
      final seen = <String>{};
      final boards = <Map<String, dynamic>>[];
      for (final e in list) {
        final board = e['board'] as Map<String, dynamic>?;
        final id = _idOf(e['boardId']);
        if (id.isEmpty || !seen.add(id)) continue;
        boards.add({
          'id': id,
          'name': board?['name']?.toString() ?? 'Board',
          'imageUrl': board?['imageUrl']?.toString() ?? '',
        });
      }
      return boards;
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _parseExams(dynamic result) {
    if (result == "Error" || result == null) return [];
    try {
      final json = jsonDecode(result);
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map<Map<String, dynamic>>((e) {
        final exam = e['exam'] as Map<String, dynamic>?;
        return {
          'id': _idOf(e['examId']),
          'name': exam?['name']?.toString() ?? 'Exam',
          'imageUrl': exam?['imageUrl']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _parseOtherCourses(dynamic result) {
    if (result == "Error" || result == null) return [];
    try {
      final json = jsonDecode(result);
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map<Map<String, dynamic>>((e) {
        final course = e['otherCourse'] as Map<String, dynamic>?;
        return {
          'id': _idOf(e['otherCourseId']),
          'name': course?['name']?.toString() ?? 'Course',
          'imageUrl': course?['imageUrl']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _parseRecent(dynamic result) {
    if (result == "Error" || result == null) return [];
    try {
      final json = jsonDecode(result);
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map<Map<String, dynamic>>(
            (e) => {
              '_id': e['_id']?.toString() ?? '',
              'type': e['type']?.toString() ?? 'book',
              'title': e['title']?.toString() ?? 'Untitled',
              'fileUrl': e['fileUrl']?.toString() ?? '',
              'fileSize': e['fileSize'] is int
                  ? e['fileSize']
                  : int.tryParse(e['fileSize']?.toString() ?? '') ?? 0,
              'imageUrl': e['imageUrl']?.toString() ?? '',
              'createdAt': e['createdAt']?.toString() ?? '',
              'kind': e['kind']?.toString() ?? 'board',
              'subjectName': e['subjectName']?.toString() ?? '',
              'groupName': e['groupName']?.toString() ?? '',
              'className': e['className']?.toString() ?? '',
            },
          )
          .where((e) => (e['fileUrl'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get _filteredRecent {
    if (_typeChip == 'all') return _recentItems;
    return _recentItems.where((e) => e['type'] == _typeChip).toList();
  }

  bool _isRecent(String createdAt) {
    final date = DateTime.tryParse(createdAt);
    if (date == null) return false;
    return DateTime.now().difference(date).inDays <= 7;
  }

  void _openCategory(Map<String, dynamic> cat) {
    final type = cat['type'] as String;
    final kinds = cat['kinds'] as Set<String>?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyMaterialListScreen(
          type: type,
          title: (cat['label'] as String).replaceAll('\n', ' '),
          initialKinds: kinds,
        ),
      ),
    ).then((_) => _loadAll());
  }

  void _openType(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyMaterialListScreen(
          type: type,
          title: _typeTitle[type] ?? 'Library',
        ),
      ),
    ).then((_) => _loadAll());
  }

  // Select Board/Exam avatar tap — seedha us board/exam ke saare
  // material types (books/papers/practice sets/current affairs) ek
  // combined "All" page par, already us board/exam se filtered.
  void _openBoardExamOrCourse({required String name, required String kind}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyMaterialListScreen(
          type: 'all',
          title: name,
          initialBoardFilter: kind == 'board' ? name : null,
          initialExamFilter: kind == 'exam' ? name : null,
          initialOtherCourseFilter: kind == 'otherCourse' ? name : null,
        ),
      ),
    ).then((_) => _loadAll());
  }

  void _openPdf(String title, String url) {
    AdHelper.showRewardedAd(
      onComplete: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(title: title, url: url),
          ),
        );
      },
    );
  }

  // Bottom-nav tab 1 is now "Other Courses" (OtherCoursesListScreen),
  // not the board/exam browse screen — CoursesScreen isn't a tab
  // anymore, so this always has to push it directly.
  void _goToCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesScreen()),
    ).then((_) => _loadAll());
  }

  void _goToOtherCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OtherCoursesListScreen()),
    ).then((_) => _loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final hasAnySubscription =
        _boards.isNotEmpty || _exams.isNotEmpty || _otherCourses.isNotEmpty;
    final hasAnyMaterial = _byType.values.any((list) => list.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isSearching
            ? _buildSearchView()
            : RefreshIndicator(
                onRefresh: _loadAll,
                color: AppColors.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildTypeChips(),
                      const SizedBox(height: 22),
                      _sectionHeader('Explore by Category'),
                      const SizedBox(height: 12),
                      _buildCategoryGrid(),
                      const SizedBox(height: 26),
                      if (hasAnySubscription) ...[
                        _sectionHeader('Select Board / Exam'),
                        const SizedBox(height: 12),
                        _buildBoardExamRow(),
                        const SizedBox(height: 26),
                      ],
                      if (_filteredRecent.isNotEmpty) ...[
                        _sectionHeader('Recent Added'),
                        const SizedBox(height: 12),
                        _buildRecentList(),
                        const SizedBox(height: 26),
                      ],
                      if (!hasAnyMaterial && _filteredRecent.isEmpty)
                        _buildEmptyState(hasAnySubscription)
                      else
                        for (final type in [
                          'book',
                          'model_paper',
                          'practice_set',
                          'current_affairs',
                        ])
                          if ((_byType[type] ?? []).isNotEmpty) ...[
                            _buildPreviewSection(type, _byType[type]!),
                            const SizedBox(height: 26),
                          ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).text('Library'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(
                  context,
                ).text('All study materials in one place'),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: AppColors.navy),
            onPressed: _startSearch,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchView() {
    final results = _searchResults;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _stopSearch,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.navy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      ).text('Search books, model papers, notes...'),
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_searchQuery.trim().isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).text('Search across Books, Model Papers and Notes.'),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else if (results.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No results for "$_searchQuery".',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.56,
                ),
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final subject = results[i];
                  return _buildPreviewCard(
                    subject['_resourceType'] as String,
                    subject,
                    _gridCardWidth(context),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chipDefs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = _chipDefs[i];
          final isSelected = _typeChip == chip['key'];
          return GestureDetector(
            onTap: () => setState(() => _typeChip = chip['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                AppLocalizations.of(context).text(chip['label']!),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.navy,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    VoidCallback? onViewAll,
    String viewAllLabel = 'View All',
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).text(title),
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              '${AppLocalizations.of(context).text(viewAllLabel)} →',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: _exploreCategories.map((cat) {
        return GestureDetector(
          onTap: () => _openCategory(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (cat['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: cat['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat['label'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      height: 1.2,
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

  Widget _buildBoardExamRow() {
    final entries = [
      ..._boards.map((b) => {...b, 'kind': 'board'}),
      ..._exams.map((e) => {...e, 'kind': 'exam'}),
      ..._otherCourses.map((c) => {...c, 'kind': 'otherCourse'}),
    ];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final entry = entries[i];
          final imageUrl = entry['imageUrl'] as String? ?? '';
          final name = entry['name'] as String;
          return _avatarTile(
            label: name,
            child: imageUrl.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.network(
                      imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _initialsAvatar(name),
                    ),
                  )
                : _initialsAvatar(name),
            onTap: () => _openBoardExamOrCourse(
              name: name,
              kind: entry['kind'] as String,
            ),
          );
        },
      ),
    );
  }

  Widget _initialsAvatar(String name) => Text(
    name.isNotEmpty ? name[0].toUpperCase() : '?',
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryBlue,
    ),
  );

  Widget _avatarTile({
    required String label,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: child,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, Color> _kindColor = {
    'board': AppColors.primaryBlue,
    'exam': Color(0xFF3D8337),
    'otherCourse': Color(0xFF8B4FD1),
  };

  Widget _buildRecentList() {
    return Column(
      children: _filteredRecent.map((item) {
        final imageUrl = item['imageUrl'] as String;
        final fileSize = item['fileSize'] as int;
        final title = item['title'] as String;
        final groupName = item['groupName'] as String;
        final subjectName = item['subjectName'] as String;
        final className = item['className'] as String;
        final kind = item['kind'] as String;
        final color = _kindColor[kind] ?? AppColors.primaryBlue;
        final subtitleParts = [
          groupName,
          if (className.isNotEmpty) className,
          subjectName,
        ].where((s) => s.isNotEmpty).join(' · ');
        final isNew = _isRecent(item['createdAt'] as String);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _openPdf(title, item['fileUrl'] as String),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 56,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.picture_as_pdf_outlined,
                              color: color,
                            ),
                          )
                        : Icon(Icons.picture_as_pdf_outlined, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'New',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitleParts.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitleParts,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fileSize > 0
                                  ? 'PDF · ${formatFileSize(fileSize)}'
                                  : 'PDF',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // StudyMaterialListScreen ki grid EXACTLY yahi maths use karti hai:
  // horizontal padding 20+20, 3 columns, crossAxisSpacing 12,
  // childAspectRatio 0.56 — Library ke preview cards ko usi Books-page
  // ke card se "exact same size" dikhna chahiye, isliye wahi formula
  // yahan bhi laga rahe hain instead of ek alag hardcoded size.
  double _gridCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 40 - 24) / 3;
  }

  Widget _buildPreviewSection(
    String type,
    List<Map<String, dynamic>> subjects,
  ) {
    final preview = subjects.take(8).toList();
    final cardWidth = _gridCardWidth(context);
    final cardHeight = cardWidth / 0.56;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          _typeTitle[type] ?? type,
          onViewAll: () => _openType(type),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                _buildPreviewCard(type, preview[i], cardWidth),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(
    String type,
    Map<String, dynamic> subject,
    double cardWidth,
  ) {
    final kind = subject['kind'] as String;
    final isExam = kind == 'exam';
    final isOtherCourse = kind == 'otherCourse';
    final groupName = isExam
        ? subject['examName'] as String
        : isOtherCourse
        ? subject['otherCourseName'] as String
        : subject['boardName'] as String;
    final resourceCount = subject['resourceCount'] as int;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudyMaterialDetailScreen(
            type: type,
            kind: kind,
            subjectId: subject['subjectId'] as String,
            boardId: subject['boardId'] as String,
            classId: subject['classId'] as String,
            examId: subject['examId'] as String,
            otherCourseId: subject['otherCourseId'] as String,
            fallbackName: subject['name'] as String,
            fallbackIconUrl: subject['iconUrl'] as String,
            fallbackBoardName: groupName,
            fallbackClassName: (isExam || isOtherCourse)
                ? ''
                : subject['className'] as String,
          ),
        ),
      ),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: BookCover(
                  title: subject['name'] as String,
                  subtitle: (isExam || isOtherCourse)
                      ? ''
                      : subject['className'] as String,
                  badge: groupName,
                  imageUrl: subject['iconUrl'] as String,
                  borderRadius: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subject['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'PDF',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    resourceCount == 1 ? '1 file' : '$resourceCount files',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasAnySubscription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            color: AppColors.primaryBlue,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            hasAnySubscription
                ? 'No study material uploaded yet for your boards/exams/courses.'
                : 'Subscribe to a board, competitive exam, or other course to unlock its library.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (!hasAnySubscription) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _goToCourses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Browse Courses',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: _goToOtherCourses,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Browse Other Courses',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
