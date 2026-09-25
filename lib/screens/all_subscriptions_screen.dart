import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'subscription_screen.dart';
import 'exam_subscription_screen.dart';
import 'other_course_subscription_screen.dart';

/// Every active plan across every pillar (board+class, competitive
/// exam, other course), flattened into one browsable list — real
/// price/duration straight from the backend, no fabricated data.
class AllSubscriptionsScreen extends StatefulWidget {
  const AllSubscriptionsScreen({super.key});

  @override
  State<AllSubscriptionsScreen> createState() => _AllSubscriptionsScreenState();
}

class _AllSubscriptionsScreenState extends State<AllSubscriptionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];
  String _filter = 'all';

  static const List<Map<String, String>> _chips = [
    {'key': 'all', 'label': 'All'},
    {'key': 'board', 'label': 'Boards'},
    {'key': 'exam', 'label': 'Exams'},
    {'key': 'otherCourse', 'label': 'Other Courses'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await APIService.getApiCaller(context: context, url: ApiUrls.getAllSubscriptions, showLoader: false);
    if (!mounted) return;
    if (res != "Error") {
      try {
        final json = jsonDecode(res);
        final data = json['data'] as List<dynamic>? ?? [];
        setState(() => _plans = data.cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _plans;
    return _plans.where((p) => p['kind'] == _filter).toList();
  }

  String _durationLabel(dynamic days) {
    final value = int.tryParse(days?.toString() ?? '') ?? 0;
    if (value <= 0) return '';
    if (value >= 365) return '${(value / 365).round()} Year';
    if (value >= 30) return '${(value / 30).round()} Months';
    return '$value Days';
  }

  void _openPlan(Map<String, dynamic> plan) {
    final kind = plan['kind'] as String;
    if (kind == 'board') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionScreen(
            boardId: plan['boardId']?.toString() ?? '',
            classId: plan['classId']?.toString() ?? '',
            boardName: plan['groupName']?.toString() ?? 'Board',
            className: plan['subGroupName']?.toString() ?? 'your class',
          ),
        ),
      );
    } else if (kind == 'exam') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamSubscriptionScreen(
            examId: plan['examId']?.toString() ?? '',
            examName: plan['groupName']?.toString() ?? 'Exam',
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtherCourseSubscriptionScreen(
            otherCourseId: plan['otherCourseId']?.toString() ?? '',
            otherCourseName: plan['groupName']?.toString() ?? 'Course',
          ),
        ),
      );
    }
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'exam':
        return Icons.emoji_events_outlined;
      case 'otherCourse':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('All Subscriptions', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.navy), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final chip = _chips[i];
                        final selected = _filter == chip['key'];
                        return GestureDetector(
                          onTap: () => setState(() => _filter = chip['key']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selected ? AppColors.primaryBlue : Colors.grey.shade300),
                            ),
                            child: Text(chip['label']!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.navy)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No plans available right now.', style: TextStyle(color: AppColors.textSecondary)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final plan = filtered[i];
                                final kind = plan['kind'] as String;
                                final groupName = plan['groupName']?.toString() ?? '';
                                final subGroupName = plan['subGroupName']?.toString() ?? '';
                                final label = subGroupName.isNotEmpty ? '$groupName · $subGroupName' : groupName;
                                return GestureDetector(
                                  onTap: () => _openPlan(plan),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44, height: 44,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                                          child: Icon(_kindIcon(kind), color: AppColors.primaryBlue, size: 20),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 2),
                                              Text(plan['planName']?.toString() ?? 'Plan', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.navy)),
                                              if ((plan['detail']?.toString() ?? '').isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(plan['detail'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('₹${plan['price']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                            Text(_durationLabel(plan['durationDays']), style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
