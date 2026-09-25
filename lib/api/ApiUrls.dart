

class ApiUrls {
  static const String baseUrl = "https://www.daminiplus.com/api/v1";

  // ── Auth ──────────────────────────────────────────────
  static const String sendOtp = "$baseUrl/app/auth/send-otp";
  static const String verifyOtp = "$baseUrl/app/auth/verify-otp";

  // ── App update (splash version check) ─────────────────
  static const String versionCheck = "$baseUrl/app/version-check";

  // ── Profile & Selection ───────────────────────────────
  static const String getProfile = "$baseUrl/app/me";
  static const String updateProfile = "$baseUrl/app/me"; // PUT
  static const String deleteAccount = "$baseUrl/app/me"; // DELETE
  static const String notificationPreferences = "$baseUrl/app/notification-preferences"; // GET/PUT
  static const String updateProfilePhoto = "$baseUrl/app/me/photo"; // POST (multipart)
  static const String getProfileStats = "$baseUrl/app/profile-stats";
  static const String getReferralInfo = "$baseUrl/app/referral-info";
  static const String getMyReferrals = "$baseUrl/app/my-referrals";

  // ── Notifications ──────────────────────────────────────
  static String getNotifications({String type = 'all'}) =>
      "$baseUrl/app/notifications?type=$type";
  static String markNotificationRead(String id) =>
      "$baseUrl/app/notifications/$id/read";
  static String deleteNotification(String id) =>
      "$baseUrl/app/notifications/$id";
  static const String selectBoardClass =
      "$baseUrl/app/select-board-class"; // PUT

  // ── Multiple boards/exams per account ─────────────────
  static const String getMyBoards = "$baseUrl/app/my-boards";
  static const String switchBoard = "$baseUrl/app/switch-board"; // PUT
  static const String getBoardsProgress = "$baseUrl/app/boards-progress";
  static const String getMyExams = "$baseUrl/app/my-exams";
  static const String switchExam = "$baseUrl/app/switch-exam"; // PUT
  static const String getExamsProgress = "$baseUrl/app/exams-progress";
  static String removeBoardEnrollment(String boardId, String classId) =>
      "$baseUrl/app/board-enrollment?boardId=$boardId&classId=$classId"; // DELETE
  static String removeExamEnrollment(String examId) =>
      "$baseUrl/app/exam-enrollment?examId=$examId"; // DELETE
  static String removeOtherCourseEnrollment(String otherCourseId) =>
      "$baseUrl/app/other-course-enrollment?otherCourseId=$otherCourseId"; // DELETE

  // ── Dropdowns ─────────────────────────────────────────
  static const String getLanguages = "$baseUrl/app/languages";
  static String getBoardLanguages(String boardId) =>
      "$baseUrl/app/languages?boardId=$boardId";
  static const String getBoards = "$baseUrl/app/boards";

  // classes: GET /app/classes?boardId=xxx&availablePlans=true
  static String getClasses(String boardId) =>
      "$baseUrl/app/classes?boardId=$boardId&availablePlans=true";

  // ── Learning Content ──────────────────────────────────
  static const String getDashboard = "$baseUrl/app/dashboard";
  static const String getRecentCourses = "$baseUrl/app/recent-courses";
  static const String getHomeSliders = "$baseUrl/app/home-sliders";

  // subjects: GET /app/subjects?languageId=xxx[&boardId=&classId=]
  // boardId/classId dene par us SPECIFIC enrolled board ke subjects
  // milte hain (active board se independent) — HomeScreen isse
  // multiple boards ke subjects ek saath dikhati hai.
  static String getSubjects(String languageId, {String? boardId, String? classId}) {
    var url = "$baseUrl/app/subjects?languageId=$languageId";
    if (boardId != null && boardId.isNotEmpty) url += "&boardId=$boardId";
    if (classId != null && classId.isNotEmpty) url += "&classId=$classId";
    return url;
  }

  // chapters: GET /app/chapters?subjectId=xxx&languageId=xxx
  static String getChapters(String subjectId, String languageId) =>
      "$baseUrl/app/chapters?subjectId=$subjectId&languageId=$languageId";

  // topics: GET /app/subjects/{subjectId}/topics?languageId=xxx
  static String getTopics(String subjectId, String languageId) =>
      "$baseUrl/app/subjects/$subjectId/topics?languageId=$languageId";

  // Books / Notes / Previous Papers home tiles — library listing of
  // every subject (across all of the student's subscribed boards)
  // that has at least one PDF of this type. type: book | notes | model_paper
  static String getStudyMaterial(String type) =>
      "$baseUrl/app/study-material?type=$type";

  // Flat, cross-pillar "recently added" file feed (board + exam +
  // other-course), newest first — real title/fileSize/date, no fabricated
  // stats. Powers the Library home's "Recent Added" list.
  static String getRecentStudyMaterial({int limit = 20}) =>
      "$baseUrl/app/study-material/recent?limit=$limit";

  // subject study material: GET /app/subjects/{subjectId}/resources
  // boardId/classId zaroori hain kyunki study-material library screen
  // student ke MULTIPLE boards ke subjects ek saath list karti hai,
  // "currently active" board tak limited nahi.
  static String getSubjectResources(
    String subjectId, {
    required String boardId,
    required String classId,
  }) =>
      "$baseUrl/app/subjects/$subjectId/resources?boardId=$boardId&classId=$classId";

  // exam subject study material: GET /app/exam-subjects/{examSubjectId}/resources
  static String getExamSubjectResources(
    String examSubjectId, {
    required String examId,
  }) =>
      "$baseUrl/app/exam-subjects/$examSubjectId/resources?examId=$examId";

  // topic detail
  static String getTopicDetail(String topicId) =>
      "$baseUrl/app/topics/$topicId";

  static String completeTopic(String topicId) =>
      "$baseUrl/app/topics/$topicId/complete";

  // questions
  static String getQuestions(
    String subjectId,
    String topicId,
    String languageId, {
    int page = 1,
    int limit = 20,
  }) =>
      "$baseUrl/app/questions?subjectId=$subjectId&topicId=$topicId&languageId=$languageId&page=$page&limit=$limit";

  // ── Answer Submission ─────────────────────────────────
  static String submitAnswer(String questionId) =>
      "$baseUrl/app/questions/$questionId/submit";
  static const String getSubmissions = "$baseUrl/app/submissions";

  static String getSubmissionsByTopic(String subjectId, String topicId) =>
      "$baseUrl/app/submissions?subjectId=$subjectId&topicId=$topicId";

  // ── Progress / Results / Resume ───────────────────────
  static const String getProgress = "$baseUrl/app/progress";
  static const String getResults = "$baseUrl/app/results";
  static const String getResume = "$baseUrl/app/resume";
  static const String updateResume = "$baseUrl/app/resume"; // PUT

  // ── Subscription ──────────────────────────────────────
  // Live discount preview (auto referral % + optional coupon) before
  // checkout — kind: 'board' | 'exam' | 'otherCourse'.
  static const String getPurchaseQuote = "$baseUrl/app/purchase-quote";
  static String getSubscriptions(String boardId, String classId) =>
      "$baseUrl/app/subscriptions?boardId=$boardId&classId=$classId";
  static const String purchaseSubscription = "$baseUrl/app/purchases";
  static const String getMyPurchases = "$baseUrl/app/purchases";
  static const String getAllSubscriptions = "$baseUrl/app/all-subscriptions";
  static const String getMyExamPurchases = "$baseUrl/app/exam-purchases";
  static const String getMyOtherCoursePurchases = "$baseUrl/app/other-course-purchases";

  // ── Combined course list (boards + exams) ──────────────
  static const String getCourses = "$baseUrl/app/courses";

  // ── Competitive Exam ───────────────────────────────────
  static const String getExams = "$baseUrl/app/exams";
  static String getExamLanguages(String examId) =>
      "$baseUrl/app/exam-languages?examId=$examId";
  static const String selectExam = "$baseUrl/app/select-exam"; // PUT

  // exam subjects: GET /app/exam-subjects?languageId=xxx[&examId=]
  static String getExamSubjects(String languageId, {String? examId}) {
    var url = "$baseUrl/app/exam-subjects?languageId=$languageId";
    if (examId != null && examId.isNotEmpty) url += "&examId=$examId";
    return url;
  }

  // exam chapters: GET /app/exam-chapters?examSubjectId=xxx
  static String getExamChapters(String examSubjectId) =>
      "$baseUrl/app/exam-chapters?examSubjectId=$examSubjectId";

  // exam topics: GET /app/exam-subjects/{examSubjectId}/topics
  static String getExamSubjectTopics(String examSubjectId) =>
      "$baseUrl/app/exam-subjects/$examSubjectId/topics";

  // exam topics by chapter: GET /app/exam-topics?examChapterId=xxx
  static String getExamTopicsByChapter(String examChapterId) =>
      "$baseUrl/app/exam-topics?examChapterId=$examChapterId";

  static String getExamTopicDetail(String topicId) =>
      "$baseUrl/app/exam-topics/$topicId";

  static String completeExamTopic(String topicId) =>
      "$baseUrl/app/exam-topics/$topicId/complete";

  static const String getExamProgress = "$baseUrl/app/exam-progress";

  // exam questions
  static String getExamQuestions(
    String examSubjectId,
    String examTopicId, {
    int page = 1,
    int limit = 20,
  }) =>
      "$baseUrl/app/exam-questions?examSubjectId=$examSubjectId&examTopicId=$examTopicId&page=$page&limit=$limit";

  static String submitExamAnswer(String questionId) =>
      "$baseUrl/app/exam-questions/$questionId/submit";

  // ── Exam Subscription ──────────────────────────────────
  static String getExamSubscriptions(String examId) =>
      "$baseUrl/app/exam-subscriptions?examId=$examId";
  static const String purchaseExamSubscription = "$baseUrl/app/exam-purchases";

  // ── Other Courses — same shape as Competitive Exam, a
  // separate parallel content pillar. ─────────────────────
  static const String getOtherCourses = "$baseUrl/app/other-courses";
  static String getOtherCourseLanguages(String otherCourseId) =>
      "$baseUrl/app/other-course-languages?otherCourseId=$otherCourseId";
  static const String selectOtherCourse = "$baseUrl/app/select-other-course"; // PUT

  static const String getMyOtherCourses = "$baseUrl/app/my-other-courses";
  static const String switchOtherCourse = "$baseUrl/app/switch-other-course"; // PUT
  static const String getOtherCoursesProgress = "$baseUrl/app/other-courses-progress";

  // other-course subjects: GET /app/other-course-subjects?languageId=xxx[&otherCourseId=]
  static String getOtherCourseSubjects(String languageId, {String? otherCourseId}) {
    var url = "$baseUrl/app/other-course-subjects?languageId=$languageId";
    if (otherCourseId != null && otherCourseId.isNotEmpty) url += "&otherCourseId=$otherCourseId";
    return url;
  }

  // pre-purchase subject preview (no enrollment needed): GET /app/other-course-subjects-preview?otherCourseId=xxx
  static String getOtherCourseSubjectsPreview(String otherCourseId) =>
      "$baseUrl/app/other-course-subjects-preview?otherCourseId=$otherCourseId";

  // other-course chapters: GET /app/other-course-chapters?otherCourseSubjectId=xxx
  static String getOtherCourseChapters(String otherCourseSubjectId) =>
      "$baseUrl/app/other-course-chapters?otherCourseSubjectId=$otherCourseSubjectId";

  // other-course topics: GET /app/other-course-subjects/{otherCourseSubjectId}/topics
  static String getOtherCourseSubjectTopics(String otherCourseSubjectId) =>
      "$baseUrl/app/other-course-subjects/$otherCourseSubjectId/topics";

  // other-course subject study material: GET /app/other-course-subjects/{otherCourseSubjectId}/resources
  static String getOtherCourseSubjectResources(
    String otherCourseSubjectId, {
    required String otherCourseId,
  }) =>
      "$baseUrl/app/other-course-subjects/$otherCourseSubjectId/resources?otherCourseId=$otherCourseId";

  static String getOtherCourseTopicDetail(String topicId) =>
      "$baseUrl/app/other-course-topics/$topicId";

  static String completeOtherCourseTopic(String topicId) =>
      "$baseUrl/app/other-course-topics/$topicId/complete";

  static const String getOtherCourseProgress = "$baseUrl/app/other-course-progress";

  // other-course questions
  static String getOtherCourseQuestions(
    String otherCourseSubjectId,
    String otherCourseTopicId, {
    int page = 1,
    int limit = 20,
  }) =>
      "$baseUrl/app/other-course-questions?otherCourseSubjectId=$otherCourseSubjectId&otherCourseTopicId=$otherCourseTopicId&page=$page&limit=$limit";

  static String submitOtherCourseAnswer(String questionId) =>
      "$baseUrl/app/other-course-questions/$questionId/submit";

  // ── Other Course Subscription ──────────────────────────
  static String getOtherCourseSubscriptions(String otherCourseId) =>
      "$baseUrl/app/other-course-subscriptions?otherCourseId=$otherCourseId";
  static const String purchaseOtherCourseSubscription = "$baseUrl/app/other-course-purchases";

}
