import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../Helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String name;
  final String? devOtp;
  final String? referralCode;

  const OtpScreen({
    super.key,
    required this.email,
    required this.name,
    this.devOtp,
    this.referralCode,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode  = FocusNode();

  Timer? _timer;
  int  _secondsRemaining = 119; // "OTP expires in 01:59" jaisa design
  bool _canResend        = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.devOtp != null && widget.devOtp!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpController.setText(widget.devOtp!);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() { _secondsRemaining = 119; _canResend = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) { _secondsRemaining--; }
        else { _canResend = true; _timer?.cancel(); }
      });
    });
  }

  String get _timerText {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resendOtp() async {
    final response = await APIService.postApiCaller(
      context: context,
      url: ApiUrls.sendOtp,
      body: {"email": widget.email, "name": widget.name},
      auth: false,
    );
    if (response != "Error") _startTimer();
  }

  Future<void> _verifyOtp() async {
    final t   = AppLocalizations.of(context);
    final otp = _otpController.text;
    if (otp.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.enterCompleteOtp)));
      return;
    }

    final response = await APIService.postApiCaller(
      context: context,
      url: ApiUrls.verifyOtp,
      body: {
        "email": widget.email,
        "otp": otp,
        "name": widget.name,
        if (widget.referralCode != null && widget.referralCode!.isNotEmpty) "referralCode": widget.referralCode,
      },
      auth: false,
    );

    if (response == "Error" || !mounted) return;

    final json   = jsonDecode(response);
    final data   = json['data'];
    final token  = data['token']?.toString() ?? '';
    final user   = data['user'] as Map<String, dynamic>? ?? {};

    final userId  = (user['id'] ?? user['_id'])?.toString() ?? '';
    final mongoId = user['mongoId']?.toString() ?? '';
    final name    = user['name']?.toString()  ?? widget.name;
    final email   = user['email']?.toString() ?? widget.email;
    final role    = (user['role'] ?? user['roleName'] ?? user['type'] ?? data['role'])?.toString() ?? 'student';

    // ── Board / Class / Language ──────────────────────────
    // Server boardId — could be string or object
    final boardRaw = user['boardId'];
    final boardId  = boardRaw is Map
        ? boardRaw['_id']?.toString() ?? ''
        : boardRaw?.toString() ?? '';

    final classRaw = user['classId'];
    final classId  = classRaw is Map
        ? classRaw['_id']?.toString() ?? ''
        : classRaw?.toString() ?? '';

    final langRaw    = user['languageId'];
    final languageId = langRaw is Map
        ? langRaw['_id']?.toString()
        : langRaw?.toString();

    // ── Exam (agar pehle se select kiya ho) ───────────────
    final examRaw = user['examId'];
    final examId  = examRaw is Map
        ? examRaw['_id']?.toString() ?? ''
        : examRaw?.toString() ?? '';
    final examName = examRaw is Map ? (examRaw['name']?.toString() ?? '') : '';

    final examLangRaw    = user['examLanguageId'];
    final examLanguageId = examLangRaw is Map
        ? examLangRaw['_id']?.toString()
        : examLangRaw?.toString();

    // ── isNewUser: board bhi nahi, exam bhi nahi select kiya ──
    final bool isNewUser = boardId.isEmpty && examId.isEmpty;

    await AppSharedPreferencesData.saveLoginData(
      token:      token,
      userId:     userId,
      name:       name,
      email:      email,
      isNewUser:  isNewUser,
      languageId: languageId,
      boardId:    boardId.isNotEmpty ? boardId : null,
      classId:    classId.isNotEmpty ? classId : null,
      mongoId:    mongoId.isNotEmpty ? mongoId : null,
      role:       role,
    );
    // Identifies this device to OneSignal as this exact student, so
    // the backend can target (or skip, per their Preferences toggles)
    // push notifications by user instead of only broadcasting.
    if (mongoId.isNotEmpty) {
      OneSignal.login(mongoId);
    }
    if (examId.isNotEmpty) {
      await AppSharedPreferencesData.saveExam(
        examId: examId,
        examName: examName,
        examLanguageId: examLanguageId,
      );
    }

    if (!mounted) return;

    // OTP verify hote hi seedha Home — board/language/class abhi select
    // karwana zaroori nahi. HomeScreen aur CoursesScreen already saare
    // available boards/exams "Discover" section me dikhate hain jahan se
    // student jab chahe browse/select kar sakta hai.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      // Keyboard layout ko squeeze na kare — screen fixed rehti hai.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ───────────────────────────
              SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.navy, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // ── Logo + tagline ────────────────────────
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/AppLogo.png',
                      width: w * 0.42,
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
                  ],
                ),
              ),

              const Spacer(),

              // ── Step badge + title + email ────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Step 2 of 2',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t.checkEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.sentCode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Row(
                            children: [
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.edit_outlined,
                                  size: 13, color: AppColors.primaryBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── OTP boxes ─────────────────────────────
              Center(
                child: Pinput(
                  length: 6,
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  autofocus: true,
                  defaultPinTheme: PinTheme(
                    width: 48,
                    height: 54,
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 48,
                    height: 54,
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                      Border.all(color: AppColors.primaryBlue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color:
                          AppColors.primaryBlue.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  onCompleted: (_) => _verifyOtp(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Timer / resend info ───────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _canResend ? t.didntReceive : 'OTP expires in  ',
                      style:
                      const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (!_canResend)
                      Text(
                        _timerText,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Verify & Login button ─────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 3,
                    shadowColor:
                    AppColors.primaryBlue.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.verifyLogin,
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

              // ── Resend OTP ────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _canResend ? _resendOtp : null,
                  child: Text(
                    t.resend,
                    style: TextStyle(
                      color: _canResend
                          ? AppColors.primaryBlue
                          : AppColors.primaryBlue.withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Security notice box ───────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF0FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_outlined,
                          color: AppColors.primaryBlue, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your security is our priority',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Never share your OTP with anyone. Damini+ will never ask for your OTP.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}