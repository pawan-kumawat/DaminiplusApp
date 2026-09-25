import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'main_screen.dart';

class ExamSubscriptionScreen extends StatefulWidget {
  final String examId;
  final String examName;

  const ExamSubscriptionScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  @override
  State<ExamSubscriptionScreen> createState() => _ExamSubscriptionScreenState();
}

class _ExamSubscriptionScreenState extends State<ExamSubscriptionScreen> {
  List<Map<String, dynamic>> _plans = [];
  String? _selectedPlanId;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _alreadySubscribed = false;
  String _activeExpiryLabel = '';

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getExamSubscriptions(widget.examId),
        showLoader: false,
      ),
      APIService.getApiCaller(
        context: context,
        url: ApiUrls.getExamsProgress,
        showLoader: false,
      ),
    ]);

    if (results[0] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[0]);
        final data = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _plans = data.map((e) => {
            '_id':          e['_id']?.toString() ?? '',
            'name':         e['name']?.toString() ?? 'Plan',
            'price':        e['price'] ?? 0,
            'durationDays': e['durationDays'] ?? 365,
            'detail':       e['detail']?.toString() ?? '',
          }).toList();
          if (_plans.isNotEmpty) _selectedPlanId = _plans.first['_id'];
        });
      } catch (_) {}
    }

    // Already-subscribed check — is exam ke liye pehle se koi active
    // enrollment ho to purchase flow dikhana hi nahi hai.
    if (results[1] != "Error" && mounted) {
      try {
        final json = jsonDecode(results[1]);
        final data = json['data'] as List<dynamic>? ?? [];
        final match = data.firstWhere(
          (e) => (e['examId']?.toString() ?? '') == widget.examId,
          orElse: () => null,
        );
        if (match != null && match['subscribed'] == true) {
          final expiry = match['subscriptionExpiry']?.toString();
          setState(() {
            _alreadySubscribed = true;
            _activeExpiryLabel = expiry != null && DateTime.tryParse(expiry) != null
                ? '${DateTime.parse(expiry).day}/${DateTime.parse(expiry).month}/${DateTime.parse(expiry).year}'
                : '';
          });
        }
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  Future<void> _purchase() async {
    if (_selectedPlanId == null) return;
    _showPaymentSheet();
  }

  void _showPaymentSheet() {
    final plan = _plans.firstWhere((p) => p['_id'] == _selectedPlanId,
        orElse: () => _plans.first);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamPaymentSheet(
        plan: plan,
        onConfirm: (paymentId, couponCode) => _confirmPurchase(paymentId, couponCode: couponCode),
      ),
    );
  }

  Future<void> _confirmPurchase(String paymentId, {String? couponCode}) async {
    setState(() => _isPurchasing = true);

    final response = await APIService.postApiCaller(
      context: context,
      url: ApiUrls.purchaseExamSubscription,
      body: {
        "examSubscriptionId": _selectedPlanId,
        "paymentId":          paymentId,
        if (couponCode != null && couponCode.isNotEmpty) "couponCode": couponCode,
      },
    );

    setState(() => _isPurchasing = false);

    if (response == "Error" || !mounted) return;

    await AppSharedPreferencesData.saveExam(examId: widget.examId, examName: widget.examName);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExamSuccessDialog(examName: widget.examName),
    );

    if (!mounted) return;
    // Board flow ki tarah — MainScreen (bottom-nav wale Home) pe jaao.
    // HomeScreen khud exam subjects dikha degi.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  String _durationLabel(int days) {
    if (days >= 365) return '${(days / 365).round()} Year';
    if (days >= 30) return '${(days / 30).round()} Months';
    return '$days Days';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _alreadySubscribed) {
      return _ExamAlreadySubscribedView(
        examName: widget.examName,
        expiryLabel: _activeExpiryLabel,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.primaryBlue.withOpacity(0.75),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.lock_outline,
                                    color: Colors.white, size: 44),
                                const SizedBox(height: 12),
                                Text(
                                  '${widget.examName} Content is Locked',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Subscribe to unlock all subjects for ${widget.examName}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Choose a Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_plans.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Text(
                                  'No plans available for this exam.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          else
                            ...List.generate(_plans.length, (i) {
                              final p = _plans[i];
                              final isSelected = _selectedPlanId == p['_id'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedPlanId = p['_id']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryBlue
                                          : Colors.grey.shade200,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryBlue.withOpacity(0.15),
                                              blurRadius: 15,
                                              offset: const Offset(0, 6),
                                            )
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryBlue
                                                : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppColors.primaryBlue
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p['name'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Valid for ${_durationLabel(p['durationDays'])}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if ((p['detail'] as String).isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                p['detail'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${p['price']}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.primaryBlue
                                                  : AppColors.navy,
                                            ),
                                          ),
                                          const Text(
                                            'one-time',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    color: AppColors.backgroundColor,
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: (_selectedPlanId == null || _isPurchasing) ? null : _purchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 4,
                          shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: _isPurchasing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_open_outlined, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedPlanId != null
                                        ? 'Subscribe for ₹${_plans.firstWhere((p) => p['_id'] == _selectedPlanId, orElse: () => _plans.first)['price']}'
                                        : 'Subscribe',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Already Subscribed ───────────────────────────────────────
class _ExamAlreadySubscribedView extends StatelessWidget {
  final String examName;
  final String expiryLabel;

  const _ExamAlreadySubscribedView({
    required this.examName,
    required this.expiryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Center(
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
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Already Subscribed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  expiryLabel.isNotEmpty
                      ? 'You already have an active subscription for $examName, valid till $expiryLabel.'
                      : 'You already have an active subscription for $examName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    ),
                    child: const Text(
                      'Continue Learning',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamPaymentSheet extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Future<void> Function(String paymentId, String? couponCode) onConfirm;

  const _ExamPaymentSheet({required this.plan, required this.onConfirm});

  @override
  State<_ExamPaymentSheet> createState() => _ExamPaymentSheetState();
}

class _ExamPaymentSheetState extends State<_ExamPaymentSheet> {
  final TextEditingController _couponController = TextEditingController();
  Map<String, dynamic>? _quote;
  bool _isQuoting = false;
  String? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  int _n(dynamic v, [int fallback = 0]) => (v is num) ? v.round() : fallback;

  Future<void> _fetchQuote({String? couponCode}) async {
    setState(() => _isQuoting = true);
    final res = await APIService.postApiCaller(
      context: context,
      url: ApiUrls.getPurchaseQuote,
      body: {
        "kind": "exam",
        "planId": widget.plan['_id'],
        if (couponCode != null && couponCode.isNotEmpty) "couponCode": couponCode,
      },
      showLoader: false,
    );
    if (!mounted) return;
    if (res != "Error") {
      try {
        final data = jsonDecode(res)['data'] as Map<String, dynamic>?;
        final hasCouponError = data != null && data['couponError'] != null;
        final couponWasApplied = couponCode != null && couponCode.isNotEmpty && !hasCouponError;
        String? newAppliedCoupon;
        if (couponWasApplied && data != null) {
          newAppliedCoupon = data['couponCode']?.toString();
        }
        setState(() {
          _quote = data;
          _appliedCoupon = newAppliedCoupon;
        });
      } catch (_) {}
    }
    setState(() => _isQuoting = false);
  }

  void _applyCoupon() {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    _fetchQuote(couponCode: code);
  }

  void _removeCoupon() {
    _couponController.clear();
    _fetchQuote();
  }

  String _dur(int days) {
    if (days >= 365) return '${(days / 365).round()} Year';
    if (days >= 30) return '${(days / 30).round()} Months';
    return '$days Days';
  }

  @override
  Widget build(BuildContext context) {
    final originalPrice = _n(_quote?['originalAmount'], _n(widget.plan['price']));
    final referralPct = (_quote?['referralDiscountPercent'] as num?)?.toDouble() ?? 0;
    final referralAmt = _n(_quote?['referralDiscountAmount']);
    final couponAmt = _n(_quote?['couponDiscountAmount']);
    final finalAmount = _n(_quote?['finalAmount'], originalPrice);
    final couponError = _quote?['couponError'] as String?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 20),
            _row('Plan', widget.plan['name']),
            const SizedBox(height: 8),
            _row('Valid for', _dur(widget.plan['durationDays'])),
            const SizedBox(height: 8),
            _row('Price', '₹$originalPrice'),
            if (referralPct > 0) ...[
              const SizedBox(height: 8),
              _row('Referral Discount (${referralPct.toStringAsFixed(0)}%)', '- ₹$referralAmt', color: Colors.green),
            ],
            if (couponAmt > 0) ...[
              const SizedBox(height: 8),
              _row('Coupon${_appliedCoupon != null ? ' ($_appliedCoupon)' : ''}', '- ₹$couponAmt', color: Colors.green),
            ],
            const Divider(height: 28),
            _row('Total', '₹$finalAmount', bold: true),
            const SizedBox(height: 20),

            if (_appliedCoupon == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Have a coupon code?',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isQuoting ? null : _applyCoupon,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Apply', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              if (couponError != null) ...[
                const SizedBox(height: 6),
                Text(couponError, style: const TextStyle(color: Colors.red, fontSize: 11.5)),
              ],
            ] else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Coupon "$_appliedCoupon" applied', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12.5))),
                    GestureDetector(onTap: _removeCoupon, child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await widget.onConfirm('dummy_payment_${DateTime.now().millisecondsSinceEpoch}', _appliedCoupon);
                },
                child: const Text(
                  'Pay Now',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _ExamSuccessDialog extends StatelessWidget {
  final String examName;
  const _ExamSuccessDialog({required this.examName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'Subscription Activated!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              '$examName content is now unlocked. Happy learning!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Start Learning',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
