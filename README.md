# 📚 Damini Plus App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-1.0.0%2B7-brightgreen.svg)](pubspec.yaml)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue)](https://flutter.dev)

**Damini Plus App** is a feature-rich, multi-pillar educational and practice app built with **Flutter**. Designed for students across various grade levels and competitive exams, Damini Plus provides interactive MCQ and theory practice, video explanations, digital rough work scratchpads, downloadable PDF notes, multi-language support, and built-in teacher explanation recording capabilities.

---

## 🌟 Key Features

### 🎓 1. Multi-Pillar Learning System
* **Board Education (Class 1 – 12):** Subject-wise, chapter-wise, and topic-wise structured learning for school boards (CBSE, State Boards).
* **Competitive Exams:** Targeted study material and practice tests for competitive exams (SSC GD, Railway, Police, State Exams, etc.).
* **Other Specialized Courses:** Skill-based and supplementary courses with customized syllabus structures.

### 📝 2. Interactive Practice & Quizzes
* **MCQ & Theory Support:** Practice multiple-choice questions with instant evaluation, or study theory/descriptive learning cards.
* **LaTeX & Math Expressions:** Beautiful rendering of complex mathematical formulas and physics equations using `flutter_math_fork`.
* **Smart Progress Tracking:** Automatic bookmarking and resume-position tracking per topic.

### 🎨 3. Digital Rough Work Board
* **Integrated Canvas:** Solves math and numerical problems directly on-screen with an interactive drawing canvas (`RoughWorkSolveScreen`).

### 🎥 4. Video Solutions & Teacher Recording Portal
* **Rich Explanations:** Step-by-step video solutions, diagrams, and detailed text explanations for questions.
* **Teacher Recording Portal:** Dedicated screen (`TeacherRecordScreen`) and webview tool (`assets/html/teacher-record.html`) allowing educators to record explanation videos per question and language.

### 📖 5. Digital Library & Study Materials
* **PDF Reader:** In-app PDF viewer (`flutter_pdfview`) for studying e-books, notes, model papers, and previous year question papers.

### 🌐 6. Multi-Lingual Support
* **Multi-Language UI & Content:** Dynamic language switching for app UI and question content (Hindi, English, and regional languages) using `flutter_localizations` and custom locale providers.

### 🔔 7. Push Notifications & Referral System
* **OneSignal Integration:** Real-time push notifications for updates, new tests, and announcements (`onesignal_flutter`).
* **Refer & Earn:** Built-in sharing tools (`share_plus`) to invite friends and earn rewards.

---

## 🛠 Tech Stack & Dependencies

* **Framework:** [Flutter](https://flutter.dev) & [Dart](https://dart.dev) (SDK `^3.12.0`)
* **State Management & DI:** `provider`
* **Local Storage:** `shared_preferences`
* **Networking & APIs:** `http`
* **Math Formatting:** `flutter_math_fork`
* **Media & Video:** `video_player`, `audioplayers`, `webview_flutter`
* **Document Viewer:** `flutter_pdfview`, `path_provider`
* **Push Notifications:** `onesignal_flutter`
* **Authentication & UI Elements:** `pinput`, `image_picker`, `permission_handler`
* **Sharing & Utility:** `share_plus`, `url_launcher`, `package_info_plus`

---

## 📂 Project Structure

```text
damini_plusapp/
├── android/                   # Android native project files & configurations
├── ios/                       # iOS native project files & configurations
├── assets/                    # App assets
│   ├── html/                  # Web tools (e.g., teacher-record.html)
│   ├── image/                 # App UI icons and illustrations
│   ├── images/                # App logos and branding assets
│   └── videos/                # Local instructional / demo media
├── lib/
│   ├── api/                   # API HTTP client & endpoints
│   │   ├── API.dart           # Core API service caller
│   │   ├── ApiUrls.dart       # API URL constants
│   │   └── Loader.dart        # Custom API loading indicators
│   ├── constant/              # Design system constants & colors
│   ├── helper/                # Helpers, SharedPreferences, localization & utilities
│   │   ├── AppLocalizations.dart
│   │   ├── AppSharedPreferencesData.dart
│   │   └── LocaleProvider.dart
│   ├── model/                 # Data models (Login, TestData, Subscriptions)
│   ├── screens/               # App screens & workflows
│   │   ├── home_screen.dart                   # Main dashboard
│   │   ├── courses_screen.dart                # Course categories
│   │   ├── chapters_screen.dart               # Board chapters
│   │   ├── topics_screen.dart                 # Board topics
│   │   ├── questions_screen.dart              # Board practice questions
│   │   ├── exam_questions_screen.dart         # Exam practice questions
│   │   ├── other_course_questions_screen.dart # Special course questions
│   │   ├── rough_work_solve_screen.dart       # Digital scratchpad canvas
│   │   ├── teacher_record_screen.dart         # Solution video recorder
│   │   ├── explanation_solution_screen.dart   # Question solution viewer
│   │   ├── library_screen.dart                # Books & PDF study materials
│   │   ├── pdf_viewer_screen.dart             # PDF document viewer
│   │   └── ...                                # Login, Settings, Profile screens
│   ├── services/              # Third-party services (Notifications, Billing)
│   ├── utils/                 # Utility functions & formatters
│   ├── widgets/               # Reusable UI widgets (MathText, Video Players, Cards)
│   └── main.dart              # App entry point
├── pubspec.yaml               # Dependencies, assets, and project config
└── README.md                  # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your developer machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.12.0`)
* [Dart SDK](https://dart.dev/get-dart)
* [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions
* Android SDK (Target API Level 34 / Minimum API Level 21)
* Xcode (for iOS builds - macOS required)

### Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/damini_plusapp.git
   cd damini_plusapp
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Launcher Icons (Optional):**
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Run the Application:**
   * Connect an Android/iOS device or launch an emulator.
   * Run the app in debug mode:
     ```bash
     flutter run
     ```

---

## 📦 Building for Production

### Android

* **Generate APK:**
  ```bash
  flutter build apk --release
  ```
  The generated APK will be available at `build/app/outputs/flutter-apk/app-release.apk`.

* **Generate App Bundle (AAB for Google Play):**
  ```bash
  flutter build appbundle --release
  ```
  The generated AAB will be available at `build/app/outputs/bundle/release/app-release.aab`.

### iOS

* **Build iOS App:**
  ```bash
  flutter build ios --release
  ```

---

## 📄 License & Credits

Designed & Developed for **Damini Plus App** team. All rights reserved.

---
*For support or inquiries, please contact the development team.*
