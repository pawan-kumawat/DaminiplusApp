import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppSharedPreferencesData.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  // Admin-controlled force-update check — kicked off in parallel with the
  // splash's own delay so it never adds extra startup time on top of the
  // branding pause. Fails open (returns null) on any error/timeout so a
  // backend hiccup never bricks app launch for everyone.
  Future<Map<String, dynamic>?> _fetchUpdateInfo() async {
    try {
      return await _fetchUpdateInfoInner().timeout(const Duration(seconds: 6));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchUpdateInfoInner() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    final url = '${ApiUrls.versionCheck}?platform=android&versionCode=$versionCode';
    final res = await APIService.rawGet(url, const {'Accept': 'application/json'});
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['status'] != true) return null;
    return json['data'] as Map<String, dynamic>?;
  }

  Future<void> _decideRoute() async {
    final updateCheck = _fetchUpdateInfo();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final info = await updateCheck;
    if (!mounted) return;
    if (info != null && info['updateAvailable'] == true) {
      _showForceUpdateSheet(info); // blocks here forever, no navigation onward
      return;
    }

    // ── Onboarding sirf EK baar dikhti hai — login/logout/kabhi
    // login na kiya ho, farak nahi padta. Flag ek baar set (ya
    // skip) hone ke baad dobara kabhi nahi dikhti.
    final onboardingDone = await AppSharedPreferencesData.getOnboardingDone();
    if (!mounted) return;

    if (!onboardingDone) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final isLogin = await AppSharedPreferencesData.getIsLogin();
    if (!mounted) return;

    if (!isLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Har app-start par re-identify karte hain (not just at login) —
    // OneSignal ka apna local ID reset ho sakta hai (reinstall, cache
    // clear) even though hamara saved session wahi rehta hai, isliye
    // sirf login ke time login() call karna kaafi nahi hai.
    final mongoId = await AppSharedPreferencesData.getMongoId();
    if (mongoId.isNotEmpty) {
      OneSignal.login(mongoId);
    }

    // Login ho chuka hai — seedha Home (teacher ho ya student, dono
    // bilkul same HomeScreen/MainScreen use karte hain — teacher sirf
    // question screen par ek extra "Record" button dekhta hai), chahe
    // board/exam abhi tak
    // select kiya ho ya nahi (naye user ko bhi ab board-selection se
    // gate nahi karte, HomeScreen/CoursesScreen se hi browse kar
    // sakta hai).
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  // Permanent block — no back button, no swipe, no dismiss. Only way
  // out is the Update Now button (opens the admin-set store link).
  void _showForceUpdateSheet(Map<String, dynamic> info) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (sheetContext) => PopScope(
        canPop: false,
        child: _UpdateSheet(info: info),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/AppLogo.png',
          width: MediaQuery.of(context).size.width - 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _UpdateSheet extends StatelessWidget {
  final Map<String, dynamic> info;

  const _UpdateSheet({required this.info});

  Future<void> _openUpdateUrl() async {
    final url = info['updateUrl'] as String? ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final message = (info['message'] as String?)?.trim().isNotEmpty == true
        ? info['message'] as String
        : 'A new version of the app is available. Please update to continue.';

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.system_update_rounded, color: AppColors.primaryBlue, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Update Available',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openUpdateUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Update Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
