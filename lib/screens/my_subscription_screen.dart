import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';

/// The student's own active plans (board+class, exam, other course),
/// scrollable — real subscription data, one card per active plan.
class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _active = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      APIService.getApiCaller(context: context, url: ApiUrls.getMyBoards, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyExams, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyOtherCourses, showLoader: false),
    ]);
    if (!mounted) return;

    final active = <Map<String, dynamic>>[];

    if (results[0] != "Error") {
      try {
        final list = (jsonDecode(results[0])['data'] as List<dynamic>? ?? []);
        for (final e in list) {
          if (e['subscribed'] != true) continue;
          final board = e['board'] as Map<String, dynamic>?;
          final cls = e['class'] as Map<String, dynamic>?;
          final sub = e['subscription'] as Map<String, dynamic>?;
          active.add({
            'kind': 'board',
            'icon': Icons.school_outlined,
            'label': [board?['name'], cls?['name']].whereType<String>().join(' · '),
            'planName': sub?['name']?.toString() ?? '',
            'price': sub?['price'],
            'durationDays': sub?['durationDays'],
            'expiry': e['subscriptionExpiry']?.toString() ?? '',
          });
        }
      } catch (_) {}
    }

    if (results[1] != "Error") {
      try {
        final list = (jsonDecode(results[1])['data'] as List<dynamic>? ?? []);
        for (final e in list) {
          if (e['subscribed'] != true) continue;
          final exam = e['exam'] as Map<String, dynamic>?;
          final sub = e['subscription'] as Map<String, dynamic>?;
          active.add({
            'kind': 'exam',
            'icon': Icons.emoji_events_outlined,
            'label': exam?['name']?.toString() ?? 'Exam',
            'planName': sub?['name']?.toString() ?? '',
            'price': sub?['price'],
            'durationDays': sub?['durationDays'],
            'expiry': e['subscriptionExpiry']?.toString() ?? '',
          });
        }
      } catch (_) {}
    }

    if (results[2] != "Error") {
      try {
        final list = (jsonDecode(results[2])['data'] as List<dynamic>? ?? []);
        for (final e in list) {
          if (e['subscribed'] != true) continue;
          final course = e['otherCourse'] as Map<String, dynamic>?;
          final sub = e['subscription'] as Map<String, dynamic>?;
          active.add({
            'kind': 'otherCourse',
            'icon': Icons.workspace_premium_outlined,
            'label': course?['name']?.toString() ?? 'Course',
            'planName': sub?['name']?.toString() ?? '',
            'price': sub?['price'],
            'durationDays': sub?['durationDays'],
            'expiry': e['subscriptionExpiry']?.toString() ?? '',
          });
        }
      } catch (_) {}
    }

    setState(() {
      _active = active;
      _isLoading = false;
    });
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Subscription', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.navy), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _active.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No active subscriptions yet.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _active.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final s = _active[i];
                        final expiry = s['expiry'] as String;
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                                child: Icon(s['icon'] as IconData, color: Colors.green, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 3),
                                    Text(s['planName'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                        ),
                                        if (expiry.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text('Valid till ${_formatDate(expiry)}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (s['price'] != null)
                                Text('₹${s['price']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
