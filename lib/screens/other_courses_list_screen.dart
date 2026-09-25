import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'other_course_detail_screen.dart';

/// "Other Courses" tab — marketplace catalog of standalone prep courses
/// (CTET / UPTET / REET / SUPER TET / KVS etc, each its own purchasable
/// OtherCourse). Category chips filter by course name, cards show real
/// stats pulled from the backend (subjects/chapters/topics/questions +
/// enrolled-student count) and the cheapest active plan price — no
/// fabricated ratings/reviews since the backend has no such data.
class OtherCoursesListScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const OtherCoursesListScreen({super.key, this.onNavigateTab});

  @override
  State<OtherCoursesListScreen> createState() => _OtherCoursesListScreenState();
}

class _OtherCoursesListScreenState extends State<OtherCoursesListScreen> {
  static const Color _navy = AppColors.navy;

  List<Map<String, dynamic>> _courses = [];
  Set<String> _ownedIds = {};
  bool _isLoading = true;
  String _selectedChip = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      APIService.getApiCaller(context: context, url: ApiUrls.getOtherCourses, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyOtherCourses, showLoader: false),
    ]);

    if (results[0] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[0]);
        final data = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _courses = data.map<Map<String, dynamic>>((e) => e as Map<String, dynamic>).toList();
        });
      } catch (_) {}
    }

    if (results[1] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[1]);
        final list = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _ownedIds = list
              .where((e) => e['subscribed'] == true)
              .map<String>((e) => e['otherCourseId']?.toString() ?? '')
              .toSet();
        });
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  void _openCourse(Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherCourseDetailScreen(
          course: course,
          isOwned: _ownedIds.contains(course['_id']?.toString() ?? ''),
        ),
      ),
    ).then((_) => _fetchCourses());
  }

  List<Map<String, dynamic>> get _filteredCourses {
    var list = _selectedChip == 'All'
        ? _courses
        : _courses.where((c) => (c['name']?.toString() ?? '') == _selectedChip).toList();
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name']?.toString() ?? '').toLowerCase();
        final fullName = (c['fullName']?.toString() ?? '').toLowerCase();
        return name.contains(query) || fullName.contains(query);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchCourses,
          color: AppColors.primaryBlue,
          child: _isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  children: [
                    const Text(
                      'Other Courses',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _navy),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Specialised prep courses beyond your board or exam.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    _buildBanner(),
                    const SizedBox(height: 20),
                    _buildSearchField(),
                    const SizedBox(height: 14),
                    _buildChips(),
                    const SizedBox(height: 18),
                    if (_courses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('No courses available yet.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else if (_filteredCourses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('No courses match your search.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ..._filteredCourses.map((course) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CourseCard(
                              course: course,
                              isOwned: _ownedIds.contains(course['_id']?.toString() ?? ''),
                              onTap: () => _openCourse(course),
                            ),
                          )),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search courses...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level up with expert-led courses',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                SizedBox(height: 3),
                Text(
                  'Step-by-step solutions, audio explanations & progress tracking.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    final chips = ['All', ..._courses.map((c) => c['name']?.toString() ?? '').where((n) => n.isNotEmpty)];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final isSelected = _selectedChip == chip;
          return GestureDetector(
            onTap: () => setState(() => _selectedChip = chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _navy,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isOwned;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.isOwned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = course['name']?.toString() ?? '';
    final fullName = course['fullName']?.toString() ?? '';
    final imageUrl = course['imageUrl']?.toString() ?? '';
    final stats = course['stats'] as Map<String, dynamic>? ?? {};
    final logo = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course covers are tall posters (title/branding printed
                // on the image itself), not square logos like board/exam
                // icons — a square BoxFit.cover box cropped most of the
                // poster away. Portrait box + BoxFit.contain always shows
                // the whole cover, whatever aspect ratio gets uploaded.
                Container(
                  width: 56,
                  height: 74,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(logo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                          ),
                        )
                      : Center(
                          child: Text(logo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      if (fullName.isNotEmpty && fullName != name) ...[
                        const SizedBox(height: 2),
                        Text(
                          fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOwned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Owned', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statChip(Icons.menu_book_rounded, '${stats['subjectsCount'] ?? 0}', 'Subjects'),
                const SizedBox(width: 8),
                _statChip(Icons.bookmark_outline_rounded, '${stats['chaptersCount'] ?? 0}', 'Chapters'),
                const SizedBox(width: 8),
                _statChip(Icons.quiz_outlined, '${stats['questionsCount'] ?? 0}', 'Questions'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    isOwned ? 'Continue' : 'Start Learning',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: AppColors.backgroundColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 15, color: AppColors.primaryBlue),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.navy)),
            Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
