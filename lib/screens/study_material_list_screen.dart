// ─────────────────────────────────────────────────────────────
// study_material_list_screen.dart
// Home screen ke "Books" / "Notes" / "Previous Papers" tiles se
// khulti hai — is TYPE ke liye jitne bhi subjects ke paas PDF hai
// (student ke saare subscribed boards+classes me se) unke cards.
//
// Visual design yahan reference screenshot ke mutabiq banaya gaya
// hai: 3-column grid, "All / Class / Board" filter chips (Medium
// aur Subject dropdown skip kiye hain kyunki backend data me wo
// field hi nahi hai), aur "Total X / Sort" header row.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../widgets/book_cover.dart';
import 'study_material_detail_screen.dart';

class StudyMaterialListScreen extends StatefulWidget {
  final String type; // book | model_paper | practice_set | current_affairs | all
  final String title; // e.g. "Books", "Model Paper", "All"

  // Library hub se ek specific board/exam ke avatar par tap karke
  // seedha usi board/exam par pre-filtered list kholne ke liye —
  // optional hai, na diya jaaye to purana "All" wala default behavior.
  final String? initialBoardFilter;
  final String? initialExamFilter;
  final String? initialOtherCourseFilter;

  // Library's category tiles (e.g. "School Books" vs "Competitive Books")
  // pre-narrow to one or more kinds ('board' | 'exam' | 'otherCourse')
  // without pinning to one specific board/exam name. Null = no restriction.
  final Set<String>? initialKinds;

  const StudyMaterialListScreen({
    super.key,
    required this.type,
    required this.title,
    this.initialBoardFilter,
    this.initialExamFilter,
    this.initialOtherCourseFilter,
    this.initialKinds,
  });

  @override
  State<StudyMaterialListScreen> createState() =>
      _StudyMaterialListScreenState();
}

class _StudyMaterialListScreenState extends State<StudyMaterialListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];
  String _query = '';
  late String _boardFilter = widget.initialBoardFilter ?? 'All';
  late String _examFilter = widget.initialExamFilter ?? 'All';
  late String _otherCourseFilter = widget.initialOtherCourseFilter ?? 'All';
  String _classFilter = 'All';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _idOf(dynamic val) {
    if (val == null) return '';
    if (val is Map) return val['_id']?.toString() ?? '';
    return val.toString();
  }

  static const List<String> _allTypes = ['book', 'model_paper', 'practice_set', 'current_affairs'];

  IconData get _typeIcon {
    switch (widget.type) {
      case 'model_paper':
        return Icons.emoji_events_outlined;
      case 'practice_set':
        return Icons.fact_check_rounded;
      case 'current_affairs':
        return Icons.newspaper_rounded;
      case 'all':
        return Icons.apps_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  List<Map<String, dynamic>> _parseSubjects(dynamic result, String resourceType) {
    if (result == "Error") return [];
    try {
      final json = jsonDecode(result);
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map<Map<String, dynamic>>(
            (e) => {
          'resourceType': resourceType,
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

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> subjects = [];
    if (widget.type == 'all') {
      final results = await Future.wait([
        for (final t in _allTypes) APIService.getApiCaller(context: context, url: ApiUrls.getStudyMaterial(t), showLoader: false),
      ]);
      if (!mounted) return;
      for (var i = 0; i < _allTypes.length; i++) {
        subjects.addAll(_parseSubjects(results[i], _allTypes[i]));
      }
    } else {
      final result = await APIService.getApiCaller(context: context, url: ApiUrls.getStudyMaterial(widget.type), showLoader: false);
      if (!mounted) return;
      subjects = _parseSubjects(result, widget.type);
    }

    setState(() {
      _subjects = subjects;
      _isLoading = false;
    });
  }

  // Board items ka boardName, exam items ka examName, other-course items
  // ka otherCourseName — teeno ek hi "which board/exam/course is this
  // from" filter/label me use hote hain.
  String _groupName(Map<String, dynamic> subject) {
    switch (subject['kind']) {
      case 'exam':
        return subject['examName'] as String;
      case 'otherCourse':
        return subject['otherCourseName'] as String;
      default:
        return subject['boardName'] as String;
    }
  }

  List<String> get _boardOptions {
    final boards = _subjects
        .where((s) => s['kind'] == 'board')
        .map(_groupName)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return boards;
  }

  List<String> get _examOptions {
    final exams = _subjects
        .where((s) => s['kind'] == 'exam')
        .map(_groupName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return exams;
  }

  List<String> get _otherCourseOptions {
    final courses = _subjects
        .where((s) => s['kind'] == 'otherCourse')
        .map(_groupName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return courses;
  }

  List<String> get _classOptions {
    final classes = _subjects
        .map((s) => s['className'] as String)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return classes;
  }

  List<Map<String, dynamic>> get _filtered {
    return _subjects.where((s) {
      final isExam = s['kind'] == 'exam';
      final isOtherCourse = s['kind'] == 'otherCourse';
      final matchesKind = widget.initialKinds == null || widget.initialKinds!.contains(s['kind']);
      final matchesQuery = _query.trim().isEmpty ||
          (s['name'] as String).toLowerCase().contains(
            _query.trim().toLowerCase(),
          );
      final matchesBoard = _boardFilter == 'All' ||
          (s['kind'] == 'board' && s['boardName'] == _boardFilter);
      final matchesExam = _examFilter == 'All' ||
          (isExam && s['examName'] == _examFilter);
      final matchesOtherCourse = _otherCourseFilter == 'All' ||
          (isOtherCourse && s['otherCourseName'] == _otherCourseFilter);
      final matchesClass =
          _classFilter == 'All' || s['className'] == _classFilter;
      return matchesKind && matchesQuery && matchesBoard && matchesExam && matchesOtherCourse && matchesClass;
    }).toList();
  }

  void _openFilterSheet({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final all = ['All', ...options];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'Filter by $title',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: all.length,
                    itemBuilder: (_, i) {
                      final option = all[i];
                      final isSelected = option == selected;
                      return ListTile(
                        title: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryBlue
                                : AppColors.navy,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryBlue,
                          size: 20,
                        )
                            : null,
                        onTap: () {
                          onSelect(option);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final boardOptions = _boardOptions;
    final examOptions = _examOptions;
    final otherCourseOptions = _otherCourseOptions;
    final classOptions = _classOptions;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
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
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon, color: AppColors.primaryBlue, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    widget.type == 'all' ? 'Books, papers, practice sets & more — all in one place' : 'All your study ${widget.title.toLowerCase()} in one place',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              focusNode: _searchFocusNode,
                              onChanged: (v) =>
                                  setState(() => _query = v),
                              decoration: InputDecoration(
                                hintText:
                                'Search ${widget.title.toLowerCase()} by name, class, subject...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _boardFilter == 'All' &&
                          _examFilter == 'All' &&
                          _otherCourseFilter == 'All' &&
                          _classFilter == 'All',
                      onTap: () => setState(() {
                        _boardFilter = 'All';
                        _examFilter = 'All';
                        _otherCourseFilter = 'All';
                        _classFilter = 'All';
                      }),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _classFilter == 'All'
                          ? 'Class'
                          : _classFilter,
                      selected: _classFilter != 'All',
                      showDropdownIcon: true,
                      onTap: () => _openFilterSheet(
                        title: 'Class',
                        options: classOptions,
                        selected: _classFilter,
                        onSelect: (v) =>
                            setState(() => _classFilter = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _boardFilter == 'All'
                          ? 'Board'
                          : _boardFilter,
                      selected: _boardFilter != 'All',
                      showDropdownIcon: true,
                      onTap: () => _openFilterSheet(
                        title: 'Board',
                        options: boardOptions,
                        selected: _boardFilter,
                        onSelect: (v) => setState(() {
                          _boardFilter = v;
                          _examFilter = 'All';
                          _otherCourseFilter = 'All';
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _examFilter == 'All' ? 'Exam' : _examFilter,
                      selected: _examFilter != 'All',
                      showDropdownIcon: true,
                      onTap: () => _openFilterSheet(
                        title: 'Exam',
                        options: examOptions,
                        selected: _examFilter,
                        onSelect: (v) => setState(() {
                          _examFilter = v;
                          _boardFilter = 'All';
                          _otherCourseFilter = 'All';
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _otherCourseFilter == 'All' ? 'Other Course' : _otherCourseFilter,
                      selected: _otherCourseFilter != 'All',
                      showDropdownIcon: true,
                      onTap: () => _openFilterSheet(
                        title: 'Other Course',
                        options: otherCourseOptions,
                        selected: _otherCourseFilter,
                        onSelect: (v) => setState(() {
                          _otherCourseFilter = v;
                          _boardFilter = 'All';
                          _examFilter = 'All';
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.type == 'all' ? 'Total Items: ${filtered.length}' : 'Total ${widget.title}: ${filtered.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Sort: Newest',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.swap_vert,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                  child: Text(
                    _subjects.isEmpty
                        ? 'Nothing uploaded here yet.'
                        : 'No results found.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.56,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _buildSubjectCard(filtered[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final resourceCount = subject['resourceCount'] as int;
    final kind = subject['kind'] as String;
    final isExam = kind == 'exam';
    final isOtherCourse = kind == 'otherCourse';
    final groupName = _groupName(subject);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudyMaterialDetailScreen(
            type: subject['resourceType'] as String? ?? widget.type,
            kind: kind,
            subjectId: subject['subjectId'] as String,
            boardId: subject['boardId'] as String,
            classId: subject['classId'] as String,
            examId: subject['examId'] as String,
            otherCourseId: subject['otherCourseId'] as String,
            fallbackName: subject['name'] as String,
            fallbackIconUrl: subject['iconUrl'] as String,
            fallbackBoardName: groupName,
            fallbackClassName: (isExam || isOtherCourse) ? '' : subject['className'] as String,
          ),
        ),
      ),
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
                subtitle: (isExam || isOtherCourse) ? '' : subject['className'] as String,
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
                padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showDropdownIcon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDropdownIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.navy,
              ),
            ),
            if (showDropdownIcon) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: selected ? Colors.white : AppColors.navy,
              ),
            ],
          ],
        ),
      ),
    );
  }
}