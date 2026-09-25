import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();
  bool _isLoading = false;
  bool _showReferralField = false;

  @override
  void dispose() {
    _emailController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_isLoading) return;
    final t = AppLocalizations.of(context);

    final email = _emailController.text.trim();
    // Design mein sirf email hai; backend contract same rakhne ke liye
    // name silently default hota hai.
    const name = 'Student';

    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.enterEmail)));
      return;
    }

    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.validEmail)));
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final response = await APIService.postApiCaller(
      context: context,
      url: ApiUrls.sendOtp,
      body: {"email": email, "name": name},
      auth: false,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response != "Error") {
      final referralCode = _referralController.text.trim();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: email,
            name: name,
            referralCode: referralCode.isNotEmpty ? referralCode : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      // Keyboard layout ko squeeze na kare — screen fixed rehti hai,
      // isliye kabhi scroll/overflow nahi hota.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Logo + tagline ────────────────────────
              Image.asset(
                'assets/images/AppLogo.png',
                width: w * 0.45,
              ),
              const SizedBox(height: 4),
              const Text(
                'A NEW GLOW IN EDUCATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(flex: 2),

              Text(
                t.welcome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Start your learning journey with us.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const Spacer(flex: 2),

              // ── Email ─────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.emailAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                onSubmitted: (_) => _sendOtp(),
                decoration: InputDecoration(
                  hintText: t.emailHint,
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon:
                  const Icon(Icons.email_outlined, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primaryBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "We'll send a 6-digit verification code to this email.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Referral code (optional) ──────────────
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => setState(() => _showReferralField = !_showReferralField),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard_rounded, size: 15, color: AppColors.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        'Have a referral code?',
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Icon(
                        _showReferralField ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showReferralField) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _referralController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Enter referral code',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.card_giftcard_outlined, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // ── Send OTP button ───────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor:
                    AppColors.primaryBlue.withOpacity(0.7),
                    elevation: 3,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.sendOtp,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Trust badge ───────────────────────────
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'Secure  •  Fast  •  Reliable',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // ── "Everything you need to succeed" divider ──
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Everything you need to succeed',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 14),

              // ── Feature cards — 4 in ONE row (like design) ──
              const Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.school_outlined,
                      iconColor: AppColors.primaryBlue,
                      label: '100+\nCourses',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.menu_book_outlined,
                      iconColor: Color(0xFF2FA86A),
                      label: 'Study\nMaterial',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.assignment_turned_in_outlined,
                      iconColor: Color(0xFFE08A2C),
                      label: 'Test\nSeries',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.emoji_events_outlined,
                      iconColor: Color(0xFF8E5CE0),
                      label: 'Board &\nCompetitive\nExams',
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // ── Footer ────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  t.termsText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small feature card ──
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}