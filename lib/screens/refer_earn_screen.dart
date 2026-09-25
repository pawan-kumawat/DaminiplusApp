import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';

/// Refer & Earn — simplified to just "invite friends" once subscriptions
/// (and with them, the whole purchase-linked discount reward) went away
/// app-wide. A referral is just "someone signed up with my code", no
/// pending/confirmed distinction or reward tracking needed anymore.
class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  bool _isLoading = true;
  String? _referralCode;
  int _totalReferrals = 0;
  List<Map<String, dynamic>> _referrals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      APIService.getApiCaller(context: context, url: ApiUrls.getReferralInfo, showLoader: false),
      APIService.getApiCaller(context: context, url: ApiUrls.getMyReferrals, showLoader: false),
    ]);
    if (!mounted) return;
    if (results[0] != "Error") {
      try {
        final data = jsonDecode(results[0])['data'] as Map<String, dynamic>?;
        setState(() {
          _referralCode = data?['referralCode']?.toString();
          _totalReferrals = (data?['totalReferrals'] as num?)?.toInt() ?? 0;
        });
      } catch (_) {}
    }
    if (results[1] != "Error") {
      try {
        final list = jsonDecode(results[1])['data'] as List<dynamic>? ?? [];
        setState(() => _referrals = list.cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  String _formatJoinDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _share() {
    if (_referralCode == null || _referralCode!.isEmpty) return;
    Share.share(
      'Join Damini+ using my referral code $_referralCode and start smart studying today!',
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
        title: const Text('Refer & Earn', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.navy), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.75)]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 32),
                            SizedBox(height: 12),
                            Text('Invite friends to Damini Plus',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(height: 8),
                            Text(
                              'Share your referral code and get your friends learning too.',
                              style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Referral code + share
                      if (_referralCode != null && _referralCode!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              const Text('Your Referral Code', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(_referralCode!,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 3)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _share,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                                  label: const Text('Share Referral Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      _statCard(
                        icon: Icons.people_alt_rounded,
                        value: '$_totalReferrals',
                        label: 'Referrals So Far',
                        color: const Color(0xFF2E9E5B),
                      ),
                      const SizedBox(height: 24),

                      const Text('My Referrals', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 4),
                      const Text(
                        'People who joined Damini Plus using your code.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      if (_referrals.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                          child: const Center(
                            child: Text('No referrals yet — share your code to get started.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ),
                        )
                      else
                        ..._referrals.map((r) => _referralRow(r)),
                      const SizedBox(height: 24),

                      const Text('How It Works', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 14),
                      _stepRow(1, Icons.ios_share_rounded, 'Share your referral code', 'Send your code to friends via the Share button above.'),
                      _stepRow(2, Icons.person_add_alt_1_rounded, 'Friend signs up with your code', 'They appear in your referrals list as soon as they join.'),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _referralRow(Map<String, dynamic> r) {
    final name = (r['name'] as String?)?.trim();
    final photoUrl = r['photoUrl'] as String?;
    final joined = _formatJoinDate(r['createdAt']?.toString() ?? '');
    final displayName = (name != null && name.isNotEmpty) ? name : 'Student';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.navy)),
                if (joined.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Joined $joined', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _stepRow(int step, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryBlue, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
