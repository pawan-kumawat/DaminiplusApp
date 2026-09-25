import 'package:shared_preferences/shared_preferences.dart';

class AppSharedPreferencesData {
  static const _kToken          = 'token';
  static const _kUserId         = 'userId';
  // Raw Mongo _id (distinct from _kUserId, which stores the
  // human-readable student code) — needed as the OneSignal
  // external_user_id so the backend can target push notifications at
  // this exact student (see main.dart's OneSignal.login call).
  static const _kMongoId        = 'mongoId';
  static const _kUserName       = 'userName';
  static const _kEmail          = 'email';
  static const _kIsLogin        = 'isLogin';
  static const _kRole           = 'role';
  static const _kIsNewUser      = 'isNewUser';
  static const _kLanguageId     = 'languageId';
  static const _kBoardId        = 'boardId';
  static const _kClassId        = 'classId';
  static const _kSubscriptionId = 'subscriptionId';
  static const _kSubExpiry      = 'subscriptionExpiry';
  static const _kExamId           = 'examId';
  static const _kExamName         = 'examName';
  static const _kExamLanguageId   = 'examLanguageId';
  static const _kExamSubExpiry    = 'examSubscriptionExpiry';
  static const _kOtherCourseId           = 'otherCourseId';
  static const _kOtherCourseName         = 'otherCourseName';
  static const _kOtherCourseLanguageId   = 'otherCourseLanguageId';
  static const _kOtherCourseSubExpiry    = 'otherCourseSubscriptionExpiry';
  static const _kAppLanguage    = 'appLanguage';
  static const _keyOnboarding   = 'onboarding_done';

  // ── Save login data ───────────────────────────────────────
  static Future<void> saveLoginData({
    required String token,
    required String userId,
    required String name,
    required String email,
    required bool   isNewUser,
    String?         languageId,
    String?         boardId,
    String?         classId,
    String?         mongoId,
    String          role = 'student',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken,    token);
    await prefs.setString(_kUserId,   userId);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kEmail,    email);
    await prefs.setBool(_kIsLogin,    true);
    await prefs.setString(_kRole,     role);
    await prefs.setBool(_kIsNewUser,  isNewUser);
    if (mongoId != null && mongoId.isNotEmpty) {
      await prefs.setString(_kMongoId, mongoId);
    }

    if (languageId != null && languageId.isNotEmpty) {
      await prefs.setString(_kLanguageId, languageId);
    }
    // ← Agar server ne boardId/classId bhi diya to seedha save karo
    if (boardId != null && boardId.isNotEmpty) {
      await prefs.setString(_kBoardId, boardId);
    }
    if (classId != null && classId.isNotEmpty) {
      await prefs.setString(_kClassId, classId);
    }
  }

  // ── Save board + class selection ──────────────────────────
  static Future<void> saveBoardClass({
    required String languageId,
    required String boardId,
    required String classId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageId, languageId);
    await prefs.setString(_kBoardId,    boardId);
    await prefs.setString(_kClassId,    classId);
    await prefs.setBool(_kIsNewUser,    false);   // ← board select hone ke baad isNewUser false
  }

  // ── Save subscription ─────────────────────────────────────
  static Future<void> saveSubscription({
    required String subscriptionId,
    String?         expiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSubscriptionId, subscriptionId);
    if (expiry != null && expiry.isNotEmpty) {
      await prefs.setString(_kSubExpiry, expiry);
    }
  }

  // ── Save exam selection ───────────────────────────────────
  static Future<void> saveExam({
    required String examId,
    String?         examName,
    String?         examLanguageId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kExamId, examId);
    if (examName != null && examName.isNotEmpty) {
      await prefs.setString(_kExamName, examName);
    }
    if (examLanguageId != null && examLanguageId.isNotEmpty) {
      await prefs.setString(_kExamLanguageId, examLanguageId);
    }
    await prefs.setBool(_kIsNewUser, false);   // ← exam select hone ke baad bhi isNewUser false
  }

  static Future<String> getExamId()         async => (await _p()).getString(_kExamId)         ?? '';
  static Future<String> getExamName()       async => (await _p()).getString(_kExamName)       ?? '';
  static Future<String> getExamLanguageId() async => (await _p()).getString(_kExamLanguageId) ?? '';
  static Future<String> getExamSubExpiry()  async => (await _p()).getString(_kExamSubExpiry)  ?? '';

  // ── Save other-course selection ────────────────────────────
  static Future<void> saveOtherCourse({
    required String otherCourseId,
    String?         otherCourseName,
    String?         otherCourseLanguageId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOtherCourseId, otherCourseId);
    if (otherCourseName != null && otherCourseName.isNotEmpty) {
      await prefs.setString(_kOtherCourseName, otherCourseName);
    }
    if (otherCourseLanguageId != null && otherCourseLanguageId.isNotEmpty) {
      await prefs.setString(_kOtherCourseLanguageId, otherCourseLanguageId);
    }
    await prefs.setBool(_kIsNewUser, false);   // ← other-course select hone ke baad bhi isNewUser false
  }

  static Future<String> getOtherCourseId()         async => (await _p()).getString(_kOtherCourseId)         ?? '';
  static Future<String> getOtherCourseName()       async => (await _p()).getString(_kOtherCourseName)       ?? '';
  static Future<String> getOtherCourseLanguageId() async => (await _p()).getString(_kOtherCourseLanguageId) ?? '';
  static Future<String> getOtherCourseSubExpiry()  async => (await _p()).getString(_kOtherCourseSubExpiry)  ?? '';

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, true);
  }

  static Future<bool> getOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarding) ?? false;
  }

  static Future<void> saveAppLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppLanguage, langCode);
  }

  static Future<String> getAppLanguage() async =>
      (await _p()).getString(_kAppLanguage) ?? '';

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, role);
  }

  // ── Getters ───────────────────────────────────────────────
  static Future<String> getToken()          async => (await _p()).getString(_kToken)          ?? '';
  static Future<String> getUserId()         async => (await _p()).getString(_kUserId)         ?? '';
  static Future<String> getMongoId()        async => (await _p()).getString(_kMongoId)        ?? '';
  static Future<String> getUserName()       async => (await _p()).getString(_kUserName)       ?? '';
  static Future<String> getEmail()          async => (await _p()).getString(_kEmail)          ?? '';
  static Future<bool>   getIsLogin()        async => (await _p()).getBool(_kIsLogin)          ?? false;
  static Future<String> getRole()           async => (await _p()).getString(_kRole)           ?? 'student';
  static Future<bool>   getIsTeacher()      async {
    final r = (await getRole()).trim().toLowerCase();
    return r == 'teacher' || r == 'admin';
  }
  static Future<String> getLanguageId()     async => (await _p()).getString(_kLanguageId)     ?? '';
  static Future<String> getBoardId()        async => (await _p()).getString(_kBoardId)        ?? '';
  static Future<String> getClassId()        async => (await _p()).getString(_kClassId)        ?? '';
  static Future<String> getSubscriptionId() async => (await _p()).getString(_kSubscriptionId) ?? '';
  static Future<String> getSubExpiry()      async => (await _p()).getString(_kSubExpiry)      ?? '';

  // ── isNewUser — boardId ya examId check se determine karo ──
  // Default true mat rakhna — boardId/examId se check karo
  static Future<bool> getIsNewUser() async {
    final prefs = await _p();
    // Agar explicitly false save hai to false
    final saved = prefs.getBool(_kIsNewUser);
    if (saved == false) return false;
    // Agar boardId ya examId set hai to new user nahi hai
    // (student board aur exam dono ya inme se ek select kar sakta hai)
    final boardId = prefs.getString(_kBoardId) ?? '';
    if (boardId.isNotEmpty) return false;
    final examId = prefs.getString(_kExamId) ?? '';
    if (examId.isNotEmpty) return false;
    final otherCourseId = prefs.getString(_kOtherCourseId) ?? '';
    if (otherCourseId.isNotEmpty) return false;
    // Otherwise true (genuinely new user)
    return true;
  }

  // ── Logout — sab clear (app language + onboarding retain) ─
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final lang        = prefs.getString(_kAppLanguage);
    final onboarding  = prefs.getBool(_keyOnboarding);
    await prefs.clear();
    if (lang != null && lang.isNotEmpty) {
      await prefs.setString(_kAppLanguage, lang);
    }
    if (onboarding == true) {
      await prefs.setBool(_keyOnboarding, true);
    }
  }

  static Future<SharedPreferences> _p() => SharedPreferences.getInstance();
}