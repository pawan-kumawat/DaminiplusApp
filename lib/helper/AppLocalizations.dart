// ─────────────────────────────────────────────────────────────
// AppLocalizations.dart
// Full EN + HI translations for the entire app.
// Usage:
//   final t = AppLocalizations.of(context);
//   t.welcome   →  'Welcome to Damini+' / 'Damini+ में आपका स्वागत है'
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Supported locales ────────────────────────────────────────
const Locale kLocaleEn = Locale('en');
const Locale kLocaleHi = Locale('hi');

// Shared labels used across screens that are still backed by API content.
// Keeping these here prevents each screen from maintaining its own Hindi map.
const Map<String, String> _commonHindi = {
  'Home': 'होम',
  'Other Courses': 'अन्य कोर्स',
  'My Course': 'मेरा कोर्स',
  'Library': 'लाइब्रेरी',
  'Profile': 'प्रोफ़ाइल',
  'Teacher': 'शिक्षक',
  'Student': 'छात्र',
  'Class': 'कक्षा',
  'Stream': 'स्ट्रीम',
  'Medium': 'माध्यम',
  'Competitive Exam': 'प्रतियोगी परीक्षा',
  'Not Selected': 'चयनित नहीं',
  'Academic Details': 'शैक्षणिक विवरण',
  'Overall Study Progress': 'कुल अध्ययन प्रगति',
  'Recently Studied': 'हाल में पढ़ा',
  'Subject Progress': 'विषय प्रगति',
  'Topic Progress Overview': 'टॉपिक प्रगति विवरण',
  'Total Topics': 'कुल टॉपिक',
  'Completed': 'पूर्ण',
  'Remaining': 'बाकी',
  'Subjects Enrolled': 'नामांकित विषय',
  'Topics Completed': 'पूर्ण टॉपिक',
  'Questions Solved': 'हल किए प्रश्न',
  'Overall Progress': 'कुल प्रगति',
  'Study Streak': 'स्टडी स्ट्रीक',
  'Settings': 'सेटिंग्स',
  'My Courses': 'मेरे कोर्स',
  'Add Another Board / Exam / Course': 'दूसरा बोर्ड / परीक्षा / कोर्स जोड़ें',
  'Preferences': 'प्राथमिकताएं',
  'Language': 'भाषा',
  'Study Reminder': 'पढ़ाई का रिमाइंडर',
  'Test & Exam Alerts': 'टेस्ट और परीक्षा अलर्ट',
  'New Course Updates': 'नए कोर्स अपडेट',
  'Offers & Announcements': 'ऑफ़र और घोषणाएं',
  'Coupons, referral updates and other news':
      'कूपन, रेफरल अपडेट और अन्य समाचार',
  'Notifications': 'सूचनाएं',
  'View all your notifications': 'अपनी सभी सूचनाएं देखें',
  'Rewards': 'रिवॉर्ड',
  'Refer & Earn': 'रेफर करें और कमाएं',
  'Invite friends, get rewarded': 'दोस्तों को आमंत्रित करें और रिवॉर्ड पाएं',
  'Support': 'सहायता',
  'Help': 'मदद',
  'Legal': 'कानूनी जानकारी',
  'Privacy Policy': 'गोपनीयता नीति',
  'Terms & Conditions': 'नियम और शर्तें',
  'Account': 'खाता',
  'Delete Account': 'खाता हटाएं',
  'Logout': 'लॉगआउट',
  'Cancel': 'रद्द करें',
  'Remove': 'हटाएं',
  'Save': 'सेव करें',
  'Previous': 'पिछला',
  'Next': 'अगला',
  'Finish': 'समाप्त करें',
  'Board': 'बोर्ड',
  'Solution': 'समाधान',
  'Answer': 'उत्तर',
  'Choose the correct answer': 'सही उत्तर चुनें',
  'Question': 'प्रश्न',
  'Questions': 'प्रश्न',
  'Chapters': 'अध्याय',
  'Topics': 'टॉपिक',
  'All Chapters': 'सभी अध्याय',
  'All Topics': 'सभी टॉपिक',
  'Progress': 'प्रगति',
  'Solved': 'हल किए',
  'Complete': 'पूर्ण',
  'Locked': 'लॉक',
  'Tip': 'सुझाव',
  'Continue': 'जारी रखें',
  'Start Learning': 'पढ़ना शुरू करें',
  'Select Class': 'कक्षा चुनें',
  'Competitive Exams': 'प्रतियोगी परीक्षाएं',
  'Books & More': 'किताबें और अन्य सामग्री',
  'Books': 'किताबें',
  'Notes': 'नोट्स',
  'Previous Papers': 'पिछले प्रश्नपत्र',
  'Practice Set': 'अभ्यास सेट',
  'Current Affairs': 'करेंट अफेयर्स',
  'Continue Learning': 'पढ़ाई जारी रखें',
  'Recommended Courses': 'सुझाए गए कोर्स',
  'Recently Added Courses': 'हाल में जोड़े गए कोर्स',
  'View All': 'सभी देखें',
  'Show Less': 'कम दिखाएं',
  'Study. Learn. Succeed.': 'पढ़ें। सीखें। सफल हों।',
  'Keep The Streak Going!': 'अपनी पढ़ाई जारी रखें!',
  'Explore More Courses': 'और कोर्स देखें',
  'Browse Courses': 'कोर्स देखें',
  'Pick a board or competitive exam to get started.':
      'शुरू करने के लिए बोर्ड या प्रतियोगी परीक्षा चुनें।',
  'No subjects available yet.': 'अभी कोई विषय उपलब्ध नहीं है।',
  'No topics yet.': 'अभी कोई टॉपिक उपलब्ध नहीं है।',
  'No boards available yet.': 'अभी कोई बोर्ड उपलब्ध नहीं है।',
  'No competitive exams available yet.':
      'अभी कोई प्रतियोगी परीक्षा उपलब्ध नहीं है।',
  'Record Explanation': 'व्याख्या रिकॉर्ड करें',
  'Search books, model papers, notes...':
      'किताबें, मॉडल पेपर और नोट्स खोजें...',
  'Search across Books, Model Papers and Notes.':
      'किताबों, मॉडल पेपर और नोट्स में खोजें।',
  'Browse Other Courses': 'अन्य कोर्स देखें',
  'All': 'सभी',
  'Model Paper': 'मॉडल पेपर',
  'Explore by Category': 'श्रेणी के अनुसार देखें',
  'Select Board / Exam': 'बोर्ड / परीक्षा चुनें',
  'Recent Added': 'हाल में जोड़ी गई सामग्री',
  'All study materials in one place': 'सारी अध्ययन सामग्री एक ही जगह',
  'New': 'नया',
};

// ── Strings map ───────────────────────────────────────────────
const Map<String, Map<String, String>> _strings = {
  'en': {
    // ── App Language Selection ─────────────────────────────
    'chooseAppLanguage': 'Choose App Language',
    'chooseAppLanguageSub': 'Select the language you want to use for this app.',
    'english': 'English',
    'hindi': 'Hindi',
    'nativeHindi': 'हिंदी',
    'nativeEnglish': 'English',
    'continueBtn': 'Continue',

    // ── Login ──────────────────────────────────────────────
    'welcome': 'Welcome to Damini+',
    'emailAddress': 'Email Address',
    'emailHint': 'student@example.com',
    'sendOtp': 'Send OTP',
    'termsText':
        'By continuing, you agree to our Terms of Service and Privacy Policy.',
    'enterEmail': 'Please enter your email',
    'validEmail': 'Please enter a valid email',

    // ── OTP ───────────────────────────────────────────────
    'checkEmail': 'Check your email',
    'sentCode': 'We sent a 6-digit code to',
    'verifyLogin': 'Verify & Login',
    'resendOtpIn': 'Resend OTP in',
    'didntReceive': "Didn't receive OTP? ",
    'resend': 'Resend',
    'enterCompleteOtp': 'Please enter complete OTP',

    // ── Language Selection (study language) ────────────────
    'selectLanguage': 'Choose Your Study Language',
    'selectLanguageSub':
        'Select the language you are most comfortable learning in.',

    // ── Board Selection ───────────────────────────────────
    'selectBoard': 'Select Board',
    'selectBoardSub': 'Choose your education board to get the right syllabus.',
    'noBoardsAvailable': 'No boards available',

    // ── Class Selection ───────────────────────────────────
    'selectClass': 'Select Class',
    'selectClassSub': 'Choose the class you are currently studying in.',
    'primarySchool': 'Primary School',
    'grades15': 'Grades 1–5',
    'middleSchool': 'Middle School',
    'grades68': 'Grades 6–8',
    'highSchool': 'High School',
    'grades912': 'Grades 9–12',
    'noClassesAvailable': 'No classes available.',
    'classLabel': 'Class',

    // ── Home ──────────────────────────────────────────────
    'whatToStudy': 'What do you want to study?',
    'resumeLearning': 'Resume Learning',
    'continueWhereLeft': 'Continue where you left off',
    'student': 'Student',
    'board': 'Board',
    'id': 'ID',

    // ── Chapters ──────────────────────────────────────────
    'chooseChapter': 'Choose a chapter to start learning.',
    'noChapters': 'No chapters available yet.',
    'lessons': 'lessons',

    // ── Topics ────────────────────────────────────────────
    'noLessons': 'No lessons in this chapter yet.',

    // ── Profile ───────────────────────────────────────────
    'completed': 'COMPLETED',
    'topics': 'Topics',
    'average': 'AVERAGE',
    'score': 'Score',

    // ── Settings ──────────────────────────────────────────
    'settings': 'Settings',
    'appLanguage': 'App Language',
    'appLanguageSub': 'Change display language',
    'currentSubscription': 'Current Subscription',
    'noActiveSubscription': 'No active subscription',
    'loading': 'Loading...',
    'validTill': 'Valid till',
    'supportPrivacy': 'Support & Privacy',
    'faq': 'FAQ',
    'helpSupport': 'Help & Support',
    'privacyPolicy': 'Privacy Policy',
    'terms': 'Terms & Conditions',
    'deleteAccount': 'Delete Account',
    'referAndEarn': 'Refer & Earn',
    'logout': 'Logout',
    'logoutConfirm': 'Are you sure you want to logout?',
    'cancel': 'Cancel',
    'version': 'Damini+ version 1.1',

    // ── Subscription ──────────────────────────────────────
    'choosePlan': 'Choose Your Plan',
    'unlockFull': 'Unlock full access to all subjects and chapters.',
    'buyNow': 'Buy Now',
    'alreadySubscribed': 'Already subscribed? ',
    'refresh': 'Refresh',
    'noPlans': 'No plans available.',
    'perYear': 'per year',
    'perMonth': 'per month',
    'perDay': 'per day',

    // ── General ───────────────────────────────────────────
    'back': 'Back',
    'of': 'of',
  },

  'hi': {
    // ── App Language Selection ─────────────────────────────
    'chooseAppLanguage': 'ऐप की भाषा चुनें',
    'chooseAppLanguageSub':
        'वह भाषा चुनें जो आप इस ऐप में उपयोग करना चाहते हैं।',
    'english': 'English',
    'hindi': 'हिंदी',
    'nativeHindi': 'हिंदी',
    'nativeEnglish': 'English',
    'continueBtn': 'आगे बढ़ें',

    // ── Login ──────────────────────────────────────────────
    'welcome': 'Damini+ में आपका स्वागत है',
    'emailAddress': 'ईमेल पता',
    'emailHint': 'student@example.com',
    'sendOtp': 'OTP भेजें',
    'termsText':
        'आगे बढ़ने पर, आप हमारी सेवा की शर्तें और गोपनीयता नीति से सहमत होते हैं।',
    'enterEmail': 'कृपया अपना ईमेल दर्ज करें',
    'validEmail': 'कृपया एक वैध ईमेल दर्ज करें',

    // ── OTP ───────────────────────────────────────────────
    'checkEmail': 'अपना ईमेल जांचें',
    'sentCode': 'हमने 6 अंकों का कोड भेजा है',
    'verifyLogin': 'सत्यापित करें और लॉगिन करें',
    'resendOtpIn': 'OTP दोबारा भेजें',
    'didntReceive': 'OTP नहीं मिला? ',
    'resend': 'दोबारा भेजें',
    'enterCompleteOtp': 'कृपया पूरा OTP दर्ज करें',

    // ── Language Selection (study language) ────────────────
    'selectLanguage': 'अपनी अध्ययन भाषा चुनें',
    'selectLanguageSub': 'वह भाषा चुनें जिसमें आप सबसे सहज हैं।',

    // ── Board Selection ───────────────────────────────────
    'selectBoard': 'बोर्ड चुनें',
    'selectBoardSub': 'सही पाठ्यक्रम पाने के लिए अपना शिक्षा बोर्ड चुनें।',
    'noBoardsAvailable': 'कोई बोर्ड उपलब्ध नहीं है',

    // ── Class Selection ───────────────────────────────────
    'selectClass': 'कक्षा चुनें',
    'selectClassSub': 'वह कक्षा चुनें जिसमें आप अभी पढ़ रहे हैं।',
    'primarySchool': 'प्राथमिक विद्यालय',
    'grades15': 'कक्षा 1–5',
    'middleSchool': 'माध्यमिक विद्यालय',
    'grades68': 'कक्षा 6–8',
    'highSchool': 'उच्च विद्यालय',
    'grades912': 'कक्षा 9–12',
    'noClassesAvailable': 'कोई कक्षा उपलब्ध नहीं है।',
    'classLabel': 'कक्षा',

    // ── Home ──────────────────────────────────────────────
    'whatToStudy': 'आप क्या पढ़ना चाहते हैं?',
    'resumeLearning': 'पढ़ाई जारी रखें',
    'continueWhereLeft': 'जहाँ छोड़ा था वहाँ से शुरू करें',
    'student': 'छात्र',
    'board': 'बोर्ड',
    'id': 'आईडी',

    // ── Chapters ──────────────────────────────────────────
    'chooseChapter': 'सीखने के लिए एक अध्याय चुनें।',
    'noChapters': 'अभी कोई अध्याय उपलब्ध नहीं है।',
    'lessons': 'पाठ',

    // ── Topics ────────────────────────────────────────────
    'noLessons': 'इस अध्याय में अभी कोई पाठ नहीं है।',

    // ── Profile ───────────────────────────────────────────
    'completed': 'पूर्ण',
    'topics': 'विषय',
    'average': 'औसत',
    'score': 'अंक',

    // ── Settings ──────────────────────────────────────────
    'settings': 'सेटिंग्स',
    'appLanguage': 'ऐप भाषा',
    'appLanguageSub': 'प्रदर्शन भाषा बदलें',
    'currentSubscription': 'वर्तमान सदस्यता',
    'noActiveSubscription': 'कोई सक्रिय सदस्यता नहीं',
    'loading': 'लोड हो रहा है...',
    'validTill': 'वैध तक',
    'supportPrivacy': 'सहायता और गोपनीयता',
    'faq': 'अक्सर पूछे जाने वाले प्रश्न',
    'helpSupport': 'मदद और सहायता',
    'privacyPolicy': 'गोपनीयता नीति',
    'terms': 'नियम और शर्तें',
    'deleteAccount': 'खाता हटाएं',
    'referAndEarn': 'रेफर करें और कमाएं',
    'logout': 'लॉगआउट',
    'logoutConfirm': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
    'cancel': 'रद्द करें',
    'version': 'Damini+ संस्करण 1.1',

    // ── Subscription ──────────────────────────────────────
    'choosePlan': 'अपना प्लान चुनें',
    'unlockFull': 'सभी विषयों और अध्यायों तक पूरी पहुँच अनलॉक करें।',
    'buyNow': 'अभी खरीदें',
    'alreadySubscribed': 'पहले से सदस्य हैं? ',
    'refresh': 'रीफ्रेश करें',
    'noPlans': 'कोई प्लान उपलब्ध नहीं है।',
    'perYear': 'प्रति वर्ष',
    'perMonth': 'प्रति माह',
    'perDay': 'प्रति दिन',

    // ── General ───────────────────────────────────────────
    'back': 'वापस',
    'of': 'में से',
  },
};

// ── Delegate ─────────────────────────────────────────────────
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_) => false;
}

// ── Main class ───────────────────────────────────────────────
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(kLocaleEn);
  }

  String _t(String key) {
    final langMap = _strings[locale.languageCode] ?? _strings['en']!;
    return langMap[key] ?? _strings['en']![key] ?? key;
  }

  /// Translates shared UI copy while leaving server supplied names untouched.
  String text(String english) => locale.languageCode == 'hi'
      ? (_commonHindi[english] ?? english)
      : english;

  // ── Expose every key as a getter ──────────────────────────
  String get chooseAppLanguage => _t('chooseAppLanguage');
  String get chooseAppLanguageSub => _t('chooseAppLanguageSub');
  String get english => _t('english');
  String get hindi => _t('hindi');
  String get nativeHindi => _t('nativeHindi');
  String get nativeEnglish => _t('nativeEnglish');
  String get continueBtn => _t('continueBtn');

  String get welcome => _t('welcome');
  String get emailAddress => _t('emailAddress');
  String get emailHint => _t('emailHint');
  String get sendOtp => _t('sendOtp');
  String get termsText => _t('termsText');
  String get enterEmail => _t('enterEmail');
  String get validEmail => _t('validEmail');

  String get checkEmail => _t('checkEmail');
  String get sentCode => _t('sentCode');
  String get verifyLogin => _t('verifyLogin');
  String get resendOtpIn => _t('resendOtpIn');
  String get didntReceive => _t('didntReceive');
  String get resend => _t('resend');
  String get enterCompleteOtp => _t('enterCompleteOtp');

  String get selectLanguage => _t('selectLanguage');
  String get selectLanguageSub => _t('selectLanguageSub');

  String get selectBoard => _t('selectBoard');
  String get selectBoardSub => _t('selectBoardSub');
  String get noBoardsAvailable => _t('noBoardsAvailable');

  String get selectClass => _t('selectClass');
  String get selectClassSub => _t('selectClassSub');
  String get primarySchool => _t('primarySchool');
  String get grades15 => _t('grades15');
  String get middleSchool => _t('middleSchool');
  String get grades68 => _t('grades68');
  String get highSchool => _t('highSchool');
  String get grades912 => _t('grades912');
  String get noClassesAvailable => _t('noClassesAvailable');
  String get classLabel => _t('classLabel');

  String get whatToStudy => _t('whatToStudy');
  String get resumeLearning => _t('resumeLearning');
  String get continueWhereLeft => _t('continueWhereLeft');
  String get student => _t('student');
  String get board => _t('board');
  String get id => _t('id');

  String get chooseChapter => _t('chooseChapter');
  String get noChapters => _t('noChapters');
  String get lessons => _t('lessons');

  String get noLessons => _t('noLessons');

  String get completed => _t('completed');
  String get topics => _t('topics');
  String get average => _t('average');
  String get score => _t('score');

  String get settings => _t('settings');
  String get appLanguage => _t('appLanguage');
  String get appLanguageSub => _t('appLanguageSub');
  String get currentSubscription => _t('currentSubscription');
  String get noActiveSubscription => _t('noActiveSubscription');
  String get loading => _t('loading');
  String get validTill => _t('validTill');
  String get supportPrivacy => _t('supportPrivacy');
  String get faq => _t('faq');
  String get helpSupport => _t('helpSupport');
  String get privacyPolicy => _t('privacyPolicy');
  String get terms => _t('terms');
  String get deleteAccount => _t('deleteAccount');
  String get logout => _t('logout');
  String get logoutConfirm => _t('logoutConfirm');
  String get cancel => _t('cancel');
  String get version => _t('version');

  String get choosePlan => _t('choosePlan');
  String get unlockFull => _t('unlockFull');
  String get buyNow => _t('buyNow');
  String get alreadySubscribed => _t('alreadySubscribed');
  String get refresh => _t('refresh');
  String get noPlans => _t('noPlans');
  String get perYear => _t('perYear');
  String get perMonth => _t('perMonth');
  String get perDay => _t('perDay');

  String get referAndEarn => _t('referAndEarn');
  String get back => _t('back');
  String get ofLabel => _t('of');
}
