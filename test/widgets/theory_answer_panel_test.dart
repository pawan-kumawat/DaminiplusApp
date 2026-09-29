import 'package:damini_plusapp/api/ApiUrls.dart';
import 'package:damini_plusapp/widgets/math_text.dart';
import 'package:damini_plusapp/widgets/theory_answer_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> showAnswer(
    WidgetTester tester, {
    String text = '',
    String imageUrl = '',
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TheoryAnswerPanel(
              answerText: text,
              answerImageUrl: imageUrl,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('existing text-only answers keep their math renderer', (
    tester,
  ) async {
    await showAnswer(tester, text: r'The result is $x^2$.');

    expect(find.text('Answer'), findsOneWidget);
    expect(
      tester.widget<MathText>(find.byType(MathText)).text,
      r'The result is $x^2$.',
    );
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image-only answers display the uploaded answer image', (
    tester,
  ) async {
    await showAnswer(
      tester,
      imageUrl: 'https://example.test/uploads/answer-only.png',
    );

    expect(find.text('Answer'), findsOneWidget);
    expect(find.byType(MathText), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'https://example.test/uploads/answer-only.png',
    );
    expect(image.fit, BoxFit.contain);
    expect(tester.takeException(), isNull);
  });

  testWidgets('answers can display text and an image together', (tester) async {
    await showAnswer(
      tester,
      text: 'Follow the solution shown below.',
      imageUrl: 'https://example.test/uploads/worked-solution.png',
    );

    expect(find.byType(MathText), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.widget<MathText>(find.byType(MathText)).text,
      'Follow the solution shown below.',
    );
    expect(
      tester.getTopLeft(find.byType(Image)).dy,
      greaterThan(tester.getBottomLeft(find.byType(MathText)).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a video solution takes priority over text and answer image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TheoryAnswerPanel(
            answerText: 'Fallback text must be hidden.',
            answerImageUrl: 'https://example.test/uploads/fallback.png',
            videoSolutionUrl: 'https://example.test/uploads/solution.webm',
            videoSolution: SizedBox(key: ValueKey('video-solution')),
          ),
        ),
      ),
    );

    expect(find.text('Video Solution'), findsOneWidget);
    expect(find.byKey(const ValueKey('video-solution')), findsOneWidget);
    expect(find.byType(MathText), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('relative uploads load from the backend host, not the API path', (
    tester,
  ) async {
    await showAnswer(tester, imageUrl: '/uploads/question-images/answer.png');

    final image = tester.widget<Image>(find.byType(Image));
    final imageUri = Uri.parse((image.image as NetworkImage).url);
    expect(imageUri.origin, Uri.parse(ApiUrls.baseUrl).origin);
    expect(imageUri.path, '/uploads/question-images/answer.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed image loading preserves the answer text', (tester) async {
    // Widget tests return HTTP 400 for network images. The fallback must handle
    // that error without losing the rest of the answer or throwing in the UI.
    await showAnswer(
      tester,
      text: 'This answer must remain readable.',
      imageUrl: 'https://example.test/uploads/missing.png',
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load answer image'), findsOneWidget);
    expect(
      tester.widget<MathText>(find.byType(MathText)).text,
      'This answer must remain readable.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed image-only answers show an error instead of a blank', (
    tester,
  ) async {
    await showAnswer(
      tester,
      imageUrl: 'https://example.test/uploads/missing-answer-only.png',
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load answer image'), findsOneWidget);
    expect(find.byType(MathText), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
