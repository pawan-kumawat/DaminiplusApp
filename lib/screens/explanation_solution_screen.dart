import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../widgets/explanation_video_player.dart';
import '../widgets/math_text.dart';

/// Dedicated "Solution" page — question for context up top, the admin's
/// recorded whiteboard explanation video below it.
class ExplanationSolutionScreen extends StatelessWidget {
  final String questionText;
  final String videoUrl;
  final String imageUrl;
  final String description;

  const ExplanationSolutionScreen({
    super.key,
    required this.questionText,
    this.videoUrl = '',
    this.imageUrl = '',
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: const Text(
          'Solution',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Ques: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                          fontSize: 13.5,
                        ),
                      ),
                      ...MathText.buildSpans(
                        questionText,
                        const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (videoUrl.isNotEmpty || imageUrl.isNotEmpty)
                _buildExplanationMedia(),
              if (description.isNotEmpty) ...[
                if (videoUrl.isNotEmpty || imageUrl.isNotEmpty)
                  const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MathText(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Whichever of video/image is available shows; if both are attached,
  // both show (video first, then image below it).
  Widget _buildExplanationMedia() {
    return Column(
      children: [
        if (videoUrl.isNotEmpty) ExplanationVideoPlayer(url: videoUrl),
        if (videoUrl.isNotEmpty && imageUrl.isNotEmpty)
          const SizedBox(height: 12),
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  _mediaPlaceholder('Could not load explanation image'),
            ),
          ),
      ],
    );
  }

  Widget _mediaPlaceholder(String text) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      ),
    );
  }
}
