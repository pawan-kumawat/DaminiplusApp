import 'package:flutter/material.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../Helper/AppSharedPreferencesData.dart';
import '../screens/main_screen.dart';
import '../screens/course_subjects_screen.dart';

/// Shared by class_selection_screen.dart and the Home screen's direct
/// class tiles — both need the exact same select → persist → navigate
/// sequence, just reached via a different path (pick-then-confirm vs.
/// one direct tap).
Future<void> selectBoardClassAndEnter(
  BuildContext context, {
  required String boardId,
  required String boardName,
  required String classId,
  required String languageId,
}) async {
  final response = await APIService.putApiCaller(
    context: context,
    url: ApiUrls.selectBoardClass,
    body: {
      "boardId": boardId,
      "classId": classId,
      "languageId": languageId,
    },
  );

  if (response != "Error" && context.mounted) {
    await AppSharedPreferencesData.saveBoardClass(
      languageId: languageId,
      boardId: boardId,
      classId: classId,
    );
    if (!context.mounted) return;

    // See class_selection_screen.dart for why pushAndRemoveUntil is
    // never awaited here — its Future only resolves when MainScreen
    // itself gets popped, which would silently block the push below.
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
    navigator.push(
      MaterialPageRoute(
        builder: (_) => CourseSubjectsScreen(
          kind: 'board',
          courseTitle: boardName.isNotEmpty ? boardName : 'Subjects',
          boardId: boardId,
          classId: classId,
          languageId: languageId,
        ),
      ),
    );
  }
}
