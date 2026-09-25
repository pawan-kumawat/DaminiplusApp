import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';

/// Every purchase the student has ever made, across board+exam+other-
/// course, newest first — real amount/date/plan straight from the
/// purchase records.
class SubscriptionHistoryScreen extends StatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  State<SubscriptionHistoryScreen> createState() => _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends State<SubscriptionHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      APIService.getApiCaller(context: context, url: ApiUrls.getMyPurchases, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyExamPurchases, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyOtherCoursePurchases, showLoader: false),
    ]);
    if (!mounted) return;

    final purchases = <Map<String, dynamic>>[];

    if (results[0] != "Error") {
      try {
        final list = (jsonDecode(results[0])['data'] as List<dynamic>? ?? []);
        for (final p in list) {
          final board = p['boardId'] as Map<String, dynamic>?;
          final cls = p['classId'] as Map<String, dynamic>?;
          final sub = p['subscriptionId'] as Map<String, dynamic>?;
          purchases.add({
            'kind': 'board',
            'icon': Icons.school_outlined,
            'label': [board?['name'], cls?['name']].whereType<String>().join(' · '),
            'planName': sub?['name']?.toString() ?? '',
            'amount': p['amount'],
            'originalAmount': p['originalAmount'],
            'referralDiscountAmount': p['referralDiscountAmount'],
            'couponCode': p['couponCode'],
            'couponDiscountAmount': p['couponDiscountAmount'],
            'createdAt': p['createdAt']?.toString() ?? '',
          });
        }
      } catch (_) {}
    }

    if (results[1] != "Error") {
      try {
        final list = (jsonDecode(results[1])['data'] as List<dynamic>? ?? []);
        for (final p in list) {
          final exam = p['examId'] as Map<String, dynamic>?;
          final sub = p['examSubscriptionId'] as Map<String, dynamic>?;
          purchases.add({
            'kind': 'exam',
            'icon': Icons.emoji_events_outlined,
            'label': exam?['name']?.toString() ?? 'Exam',
            'planName': sub?['name']?.toString() ?? '',
            'amount': p['amount'],
            'originalAmount': p['originalAmount'],
            'referralDiscountAmount': p['referralDiscountAmount'],
            'couponCode': p['couponCode'],
            'couponDiscountAmount': p['couponDiscountAmount'],
            'createdAt': p['createdAt']?.toString() ?? '',
          });
        }
      } catch (_) {}
    }

    if (results[2] != "Error") {
      try {
        final list = (jsonDecode(results[2])['data'] as List<dynamic>? ?? []);
        for (final p in list) {
          final course = p['otherCourseId'] as Map<String, dynamic>?;
          final sub = p['otherCourseSubscriptionId'] as Map<String, dynamic>?;
          purchases.add({
            'kind': 'otherCourse',
            'icon': Icons.workspace_premium_outlined,
            'label': course?['name']?.toString() ?? 'Course',
            'planName': sub?['name']?.toString() ?? '',
            'amount': p['amount'],
            'originalAmount': p['originalAmount'],
            'referralDiscountAmount': p['referralDiscountAmount'],
            'couponCode': p['couponCode'],
            'couponDiscountAmount': p['couponDiscountAmount'],
            'createdAt': p['createdAt']?.toString() ?? '',
          });
        }
      } catch (_) {}
    }

    purchases.sort((a, b) {
      final da = DateTime.tryParse(a['createdAt'] as String) ?? DateTime(2000);
      final db = DateTime.tryParse(b['createdAt'] as String) ?? DateTime(2000);
      return db.compareTo(da);
    });

    setState(() {
      _purchases = purchases;
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

  Widget _discountChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.green),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
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
        title: const Text('Subscription History', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.navy), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _purchases.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No purchases yet.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _purchases.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final p = _purchases[i];
                        final originalAmount = p['originalAmount'];
                        final referralDiscount = p['referralDiscountAmount'];
                        final couponCode = p['couponCode'] as String?;
                        final couponDiscount = p['couponDiscountAmount'];
                        final hasDiscount = (referralDiscount is num && referralDiscount > 0) ||
                            (couponDiscount is num && couponDiscount > 0);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(p['icon'] as IconData, color: AppColors.primaryBlue, size: 19),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(p['planName'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
                                        const SizedBox(height: 2),
                                        Text(_formatDate(p['createdAt'] as String), style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (hasDiscount && originalAmount is num && originalAmount > (p['amount'] as num))
                                        Text('₹$originalAmount', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
                                      Text('₹${p['amount']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                ],
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (referralDiscount is num && referralDiscount > 0)
                                      _discountChip(Icons.card_giftcard_rounded, 'Referral -₹$referralDiscount'),
                                    if (couponDiscount is num && couponDiscount > 0)
                                      _discountChip(Icons.local_offer_rounded, '${couponCode ?? 'Coupon'} -₹$couponDiscount'),
                                  ],
                                ),
                              ],
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
