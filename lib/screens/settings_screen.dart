import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'edit_profile_screen.dart';
import 'app_settings_screen.dart';

/// Bottom-nav "Profile" tab (person icon, last tab). Shows the rich
/// profile/study-stats view. Preferences, Rewards, Support, Legal,
/// Account and Logout live on a separate "Settings" page reached via
/// the gear icon.
///
/// A few stat labels from the reference design were adjusted to only
/// show real, tracked data (no fabricated numbers): "Books Completed" →
/// "Subjects Enrolled" (a real count; the app doesn't track per-book
/// completion), "Chapters Completed" folded into "Topics Completed"
/// (the app tracks topic-level completion, not chapter-level), and the
/// "Chapter Progress Overview" card is "Topic Progress Overview" for
/// the same reason (its "In Progress" bucket is dropped — a topic is
/// simply done or not-done here, there's no partial state to report).
class SettingsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const SettingsScreen({super.key, this.onNavigateTab});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = '';
  String _userId = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String? _photoUrl;
  bool _isVerified = false;
  bool _isTeacher = false;
  bool _isLoading = true;

  String _boardName = '';
  String _className = '';
  String _gradeGroup = '';
  String _mediumName = '';
  String _examName = '';

  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _resume;

  static const List<Color> _subjectColorCycle = [
    AppColors.primaryBlue,
    Color(0xFF2E9E5B),
    Color(0xFF7A4FD1),
    Colors.orange,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    _name = await AppSharedPreferencesData.getUserName();
    _userId = await AppSharedPreferencesData.getUserId();
    _isTeacher = await AppSharedPreferencesData.getIsTeacher();

    final results = await Future.wait([
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getProfile,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getProfileStats,
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getResume,
        showLoader: false,
      ),
    ]);

    if (results[0] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[0]);
        final data = json['data'] ?? json;
        if (data['role'] != null) {
          final role = data['role'].toString();
          AppSharedPreferencesData.saveRole(role);
          _isTeacher = role == 'teacher';
        }
        setState(() {
          _name = data['name']?.toString() ?? _name;
          _userId =
              (_isTeacher ? data['teacherId'] : data['studentId'])
                  ?.toString() ??
              data['id']?.toString() ??
              _userId;
          _email = data['email']?.toString() ?? '';
          _phone = data['phone']?.toString() ?? '';
          _address = data['address']?.toString() ?? '';
          _photoUrl = (data['photoUrl']?.toString().isNotEmpty ?? false)
              ? data['photoUrl'].toString()
              : null;
          _isVerified = data['isVerified'] == true;
          _boardName = data['boardId'] is Map
              ? data['boardId']['name']?.toString() ?? ''
              : '';
          _className = data['classId'] is Map
              ? data['classId']['name']?.toString() ?? ''
              : '';
          _gradeGroup = data['classId'] is Map
              ? data['classId']['gradeGroup']?.toString() ?? ''
              : '';
          _mediumName = data['languageId'] is Map
              ? data['languageId']['name']?.toString() ?? ''
              : '';
          _examName = data['examId'] is Map
              ? data['examId']['name']?.toString() ?? ''
              : '';
        });
      } catch (_) {}
    }

    if (results[1] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[1]);
        setState(() => _stats = json['data'] as Map<String, dynamic>? ?? {});
      } catch (_) {}
    }

    if (results[2] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[2]);
        final data = json['data'] as Map<String, dynamic>?;
        final subject = data?['subject'] as Map<String, dynamic>?;
        final topic = data?['topic'] as Map<String, dynamic>?;
        final progress = data?['progress'] as Map<String, dynamic>?;
        if (subject != null && topic != null) {
          setState(() {
            _resume = {
              'subjectName': subject['name']?.toString() ?? 'Subject',
              'topicName': topic['name']?.toString() ?? '',
              'percentage': progress?['percentage'] is num
                  ? (progress!['percentage'] as num).toDouble()
                  : 0.0,
            };
          });
        }
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  Future<void> _openEditProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: _name,
          phone: _phone,
          address: _address,
          photoUrl: _photoUrl,
        ),
      ),
    );
    if (changed == true && mounted) _loadUserInfo();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
    ).then((_) => _loadUserInfo());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserInfo,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).text('Profile'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.navy,
                        ),
                        onPressed: _openSettings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfileCard(),
                const SizedBox(height: 16),
                if (_boardName.isNotEmpty || _examName.isNotEmpty) ...[
                  _buildAcademicDetails(),
                  const SizedBox(height: 16),
                ],
                _buildStudyProgressCard(),
                const SizedBox(height: 16),
                if (_resume != null) ...[
                  _buildRecentlyStudiedCard(),
                  const SizedBox(height: 16),
                ],
                if ((_stats['subjects'] as List?)?.isNotEmpty ?? false) ...[
                  _sectionTitle('Subject Progress'),
                  const SizedBox(height: 12),
                  _buildSubjectProgressRow(),
                  const SizedBox(height: 16),
                ],
                _buildTopicProgressOverview(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _sectionTitle(String title) => Text(
    AppLocalizations.of(context).text(title),
    style: const TextStyle(
      fontSize: 15.5,
      fontWeight: FontWeight.bold,
      color: AppColors.navy,
    ),
  );

  Widget _groupHeader(IconData icon, String title) => Row(
    children: [
      Icon(icon, size: 17, color: AppColors.primaryBlue),
      const SizedBox(width: 8),
      Text(
        AppLocalizations.of(context).text(title),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
    ],
  );

  Widget _buildProfileCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: _photoUrl == null
                    ? const Icon(
                        Icons.person,
                        color: AppColors.primaryBlue,
                        size: 42,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _name.isEmpty
                                ? AppLocalizations.of(
                                    context,
                                  ).text(_isTeacher ? 'Teacher' : 'Student')
                                : _name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        if (_isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primaryBlue,
                            size: 17,
                          ),
                        ],
                      ],
                    ),
                    if (_userId.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${AppLocalizations.of(context).text(_isTeacher ? 'Teacher' : 'Student')} ID: $_userId',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_phone.isNotEmpty)
                        _infoRow(Icons.call_outlined, _phone),
                      if (_phone.isNotEmpty && _email.isNotEmpty)
                        const SizedBox(height: 4),
                      if (_email.isNotEmpty)
                        _infoRow(Icons.email_outlined, _email),
                    ],
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openEditProfile,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  side: BorderSide(
                    color: AppColors.primaryBlue.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: AppColors.primaryBlue,
                ),
                label: const Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),

          if (_address.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _address,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.navy,
                      height: 1.4,
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

  Widget _infoRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  );

  Widget _buildAcademicDetails() {
    final items = [
      ('Board', _boardName, Icons.account_balance_outlined),
      ('Class', _className, Icons.class_outlined),
      if (_gradeGroup.isNotEmpty)
        ('Stream', _gradeGroup, Icons.category_outlined),
      ('Medium', _mediumName, Icons.translate_rounded),
      (
        'Competitive Exam',
        _examName.isNotEmpty ? _examName : 'Not Selected',
        Icons.emoji_events_outlined,
      ),
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupHeader(Icons.school_rounded, 'Academic Details'),
          const SizedBox(height: 14),
          // 2 per row — 5-across squeezed values like "Competitive
          // Exam" too badly on real phone widths.
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  item.$3,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context).text(item.$1),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$2.isNotEmpty ? item.$2 : '—',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudyProgressCard() {
    final subjectsEnrolled = _stats['subjectsEnrolled'] ?? 0;
    final completedTopics = _stats['completedTopics'] ?? 0;
    final totalTopics = _stats['totalTopics'] ?? 0;
    final completedQuestions = _stats['completedQuestions'] ?? 0;
    final totalQuestions = _stats['totalQuestions'] ?? 0;
    final overallPct = _stats['overallPercentage'] ?? 0;
    final streak = _stats['currentStreak'] ?? 0;

    final pills = [
      (
        Icons.menu_book_rounded,
        '$subjectsEnrolled',
        'Subjects\nEnrolled',
        const Color(0xFF6FCF97),
      ),
      (
        Icons.list_alt_rounded,
        '$completedTopics/$totalTopics',
        'Topics\nCompleted',
        const Color(0xFFF2994A),
      ),
      (
        Icons.quiz_rounded,
        '$completedQuestions/$totalQuestions',
        'Questions\nSolved',
        const Color(0xFFEB5757),
      ),
      (
        Icons.donut_large_rounded,
        '$overallPct%',
        'Overall\nProgress',
        const Color(0xFF56CCF2),
      ),
      (
        Icons.local_fire_department_rounded,
        '$streak',
        'Study\nStreak',
        const Color(0xFFF2C94C),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).text('Overall Study Progress'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: pills
                .map(
                  (p) => Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: p.$4.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.$1, size: 15, color: p.$4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 8.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyStudiedCard() {
    final r = _resume!;
    final pct = (r['percentage'] as double).clamp(0.0, 100.0);
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).text('Recently Studied'),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r['subjectName']}${(r['topicName'] as String).isNotEmpty ? ' · ${r['topicName']}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressRow() {
    final subjects = ((_stats['subjects'] as List?) ?? []).take(5).toList();
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = subjects[i] as Map<String, dynamic>;
          final color = _subjectColorCycle[i % _subjectColorCycle.length];
          // Backend's pct() already returns a 0-100 integer, not a 0-1 fraction.
          final displayPct = (s['percentage'] is num)
              ? (s['percentage'] as num).round()
              : 0;
          return SizedBox(
            width: 78,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    (s['name'] as String).isNotEmpty
                        ? (s['name'] as String)[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '$displayPct%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicProgressOverview() {
    final completed = _stats['completedTopics'] ?? 0;
    final total = _stats['totalTopics'] ?? 0;
    final remaining = (total is int && completed is int)
        ? (total - completed).clamp(0, total)
        : 0;
    final pct = _stats['overallPercentage'] ?? 0;

    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Topic Progress Overview'),
                const SizedBox(height: 14),
                _statPair('Total Topics', '$total'),
                const SizedBox(height: 8),
                _statPair('Completed', '$completed', color: Colors.green),
                const SizedBox(height: 8),
                _statPair('Remaining', '$remaining', color: Colors.orange),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (pct as num) / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryBlue,
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPair(String label, String value, {Color? color}) => Row(
    children: [
      Text(
        AppLocalizations.of(context).text(label),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.navy,
        ),
      ),
    ],
  );
}
