import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../Helper/LocaleProvider.dart';
import '../Helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'courses_screen.dart';
import 'app_language_selection_screen.dart';
import 'refer_earn_screen.dart';
import 'notifications_screen.dart';
import 'webviewscreen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isLoading = true;

  bool _studyReminder = true;
  bool _examAlerts = true;
  bool _courseUpdates = true;
  bool _generalNotifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.notificationPreferences,
      showLoader: false,
    );
    if (!mounted) return;

    if (result != "Error") {
      try {
        final data = jsonDecode(result)['data'] as Map<String, dynamic>?;
        setState(() {
          _studyReminder = data?['studyReminder'] ?? true;
          _examAlerts = data?['examAlerts'] ?? true;
          _courseUpdates = data?['courseUpdates'] ?? true;
          _generalNotifications = data?['generalNotifications'] ?? true;
        });
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleNotificationPreference(String key, bool value) async {
    await APIService.putApiCaller(
      context: context,
      url: ApiUrls.notificationPreferences,
      body: {key: value},
      showLoader: false,
    );
  }

  void _openWebView(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewScreen(title: title, url: url),
      ),
    );
  }

  void _openAddCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesScreen()),
    ).then((_) => _load());
  }

  void _openLanguageSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppLanguageSelectionScreen(fromSettings: true),
      ),
    );
  }

  void _openReferEarn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReferEarnScreen()),
    );
  }

  Future<void> _logout() async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          t.text('Logout'),
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          t.logoutConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.text('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              t.text('Logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AppSharedPreferencesData.logout();
    OneSignal.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _openDeleteAccountSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final canConfirm = controller.text.trim().toUpperCase() == 'DELETE';
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              24 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Delete Account?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'This will deactivate your account and log you out everywhere. You will not be able to log back in with this email, and access to all your subscriptions and study progress will be lost.\n\nYour data is retained for our records as required, but your account is permanently marked as deleted and cannot be reactivated from the app. This action cannot be undone — if you change your mind later, you will need to contact support.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Type DELETE to confirm',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canConfirm
                        ? () => _confirmDeleteAccount(sheetContext)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.red.withValues(
                        alpha: 0.3,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    final response = await APIService.deleteApiCaller(
      context: context,
      url: ApiUrls.deleteAccount,
    );
    if (response == "Error" || !mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Account Deleted',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your account has been deleted. You will not be able to log in again with this email.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await AppSharedPreferencesData.logout();
    OneSignal.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LocaleProvider>().isHindi;
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.text('Settings'),
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
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
                      _groupHeader(Icons.school_rounded, t.text('My Courses')),
                      const SizedBox(height: 12),
                      _buildAddCourseCard(),

                      const SizedBox(height: 26),
                      _groupHeader(Icons.tune_rounded, t.text('Preferences')),
                      const SizedBox(height: 12),
                      _settingsTile(
                        icon: Icons.translate_rounded,
                        title: t.text('Language'),
                        subtitle: isHindi ? 'हिंदी' : 'English',
                        onTap: _openLanguageSettings,
                      ),
                      const SizedBox(height: 10),
                      _toggleTile(
                        icon: Icons.alarm_rounded,
                        title: t.text('Study Reminder'),
                        value: _studyReminder,
                        onChanged: (v) {
                          setState(() => _studyReminder = v);
                          _toggleNotificationPreference('studyReminder', v);
                        },
                      ),
                      const SizedBox(height: 10),
                      _toggleTile(
                        icon: Icons.notifications_active_outlined,
                        title: t.text('Test & Exam Alerts'),
                        value: _examAlerts,
                        onChanged: (v) {
                          setState(() => _examAlerts = v);
                          _toggleNotificationPreference('examAlerts', v);
                        },
                      ),
                      const SizedBox(height: 10),
                      _toggleTile(
                        icon: Icons.new_releases_outlined,
                        title: t.text('New Course Updates'),
                        value: _courseUpdates,
                        onChanged: (v) {
                          setState(() => _courseUpdates = v);
                          _toggleNotificationPreference('courseUpdates', v);
                        },
                      ),
                      const SizedBox(height: 10),
                      _toggleTile(
                        icon: Icons.local_offer_outlined,
                        title: t.text('Offers & Announcements'),
                        subtitle: t.text(
                          'Coupons, referral updates and other news',
                        ),
                        value: _generalNotifications,
                        onChanged: (v) {
                          setState(() => _generalNotifications = v);
                          _toggleNotificationPreference(
                            'generalNotifications',
                            v,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _settingsTile(
                        icon: Icons.notifications_outlined,
                        title: t.text('Notifications'),
                        subtitle: t.text('View all your notifications'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),
                      _groupHeader(
                        Icons.card_giftcard_rounded,
                        t.text('Rewards'),
                      ),
                      const SizedBox(height: 12),
                      _settingsTile(
                        icon: Icons.group_add_rounded,
                        title: t.text('Refer & Earn'),
                        subtitle: t.text('Invite friends, get rewarded'),
                        onTap: _openReferEarn,
                      ),

                      const SizedBox(height: 26),
                      _groupHeader(
                        Icons.support_agent_rounded,
                        t.text('Support'),
                      ),
                      const SizedBox(height: 12),
                      _settingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'FAQ',
                        onTap: () => _openWebView(
                          'FAQ',
                          'https://daminiplus.com/faq.html',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _settingsTile(
                        icon: Icons.headset_mic_outlined,
                        title: t.text('Help'),
                        onTap: () => _openWebView(
                          'Help',
                          'https://daminiplus.com/help-support.html',
                        ),
                      ),

                      const SizedBox(height: 26),
                      _groupHeader(Icons.gavel_rounded, t.text('Legal')),
                      const SizedBox(height: 12),
                      _settingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: t.text('Privacy Policy'),
                        onTap: () => _openWebView(
                          'Privacy Policy',
                          'https://daminiplus.com/privacy-policy.html',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _settingsTile(
                        icon: Icons.description_outlined,
                        title: t.text('Terms & Conditions'),
                        onTap: () => _openWebView(
                          'Terms & Conditions',
                          'https://daminiplus.com/terms-conditions.html',
                        ),
                      ),

                      const SizedBox(height: 26),
                      _groupHeader(
                        Icons.manage_accounts_rounded,
                        t.text('Account'),
                      ),
                      const SizedBox(height: 12),
                      _settingsTile(
                        icon: Icons.delete_outline_rounded,
                        title: t.text('Delete Account'),
                        destructive: true,
                        onTap: _openDeleteAccountSheet,
                      ),

                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                          label: Text(
                            t.text('Logout'),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
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

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _groupHeader(IconData icon, String title) => Row(
    children: [
      Icon(icon, size: 17, color: AppColors.primaryBlue),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
    ],
  );

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? Colors.red : AppColors.navy;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (destructive ? Colors.red : AppColors.primaryBlue)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: destructive ? Colors.red : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: destructive
                  ? Colors.red.withValues(alpha: 0.6)
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAddCourseCard() {
    final label = AppLocalizations.of(
      context,
    ).text('Add Another Board / Exam / Course');
    return GestureDetector(
      onTap: _openAddCourse,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
