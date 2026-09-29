import 'package:flutter/material.dart';

import '../api/ApiUrls.dart';
import '../helper/AppColors.dart';
import '../helper/AppLocalizations.dart';
import 'explanation_video_player.dart';
import 'math_text.dart';

/// Displays the reading answer for board, exam and other-course questions.
class TheoryAnswerPanel extends StatelessWidget {
  final String answerText;
  final String answerImageUrl;
  final String videoSolutionUrl;

  /// Only used by tests. Production builds this from [videoSolutionUrl].
  final Widget? videoSolution;

  const TheoryAnswerPanel({
    super.key,
    required this.answerText,
    this.answerImageUrl = '',
    this.videoSolutionUrl = '',
    this.videoSolution,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = answerText.trim().isNotEmpty;
    final rawImageUrl = answerImageUrl.trim();
    final hasVideo =
        videoSolutionUrl.trim().isNotEmpty || videoSolution != null;
    // Admin uploads return /uploads/... paths, while older/external images can
    // already contain a complete URL. Resolve both against the API's origin.
    final imageUrl = rawImageUrl.isEmpty
        ? ''
        : Uri.parse(
            ApiUrls.baseUrl,
          ).resolve('/').resolve(rawImageUrl).toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasVideo
                ? 'Video Solution'
                : AppLocalizations.of(context).text('Answer'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 12),
          // A recorded solution is the definitive answer. Do not place a
          // second text/image answer below it, where it can contradict the
          // teacher's explanation. When no video exists, use text and/or the
          // admin-uploaded answer photo as the fallback.
          if (hasVideo)
            videoSolution ?? ExplanationVideoPlayer(url: videoSolutionUrl)
          else if (hasText)
            MathText(
              answerText,
              style: const TextStyle(
                fontSize: 16.5,
                color: AppColors.navy,
                height: 1.6,
              ),
            ),
          if (!hasVideo && imageUrl.isNotEmpty) ...[
            if (hasText) const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                semanticLabel: AppLocalizations.of(context).text('Answer'),
                errorBuilder: (_, __, ___) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).text('Unable to load answer image'),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
