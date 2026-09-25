import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import 'board_selection_screen.dart';
import 'exam_selection_screen.dart';

class SelectCourseTypeScreen extends StatelessWidget {
  const SelectCourseTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'What are you\npreparing for?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how you want to start learning.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              _buildCourseTypeCard(
                context: context,
                icon: Icons.school_rounded,
                title: 'Select Board',
                subtitle: 'School boards like CBSE, ICSE and more.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BoardSelectionScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildCourseTypeCard(
                context: context,
                icon: Icons.emoji_events_rounded,
                title: 'Select Competitive Exam',
                subtitle: 'SSC, banking, railways and other exams.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExamSelectionScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
