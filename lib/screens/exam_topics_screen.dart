import 'package:flutter/material.dart';
import '../Helper/AdHelper.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../widgets/progress_ring.dart';
import 'exam_questions_screen.dart';
import 'exam_subscription_screen.dart';

class ExamTopicsScreen extends StatelessWidget {
  final String examId;
  final String examName;
  final String examSubjectId;
  final String examSubjectName;
  final String chapterName;
  final int chapterIndex;
  final List<Map<String, dynamic>> topics;

  const ExamTopicsScreen({
    super.key,
    required this.examId,
    required this.examName,
    required this.examSubjectId,
    required this.examSubjectName,
    required this.chapterName,
    this.chapterIndex = 1,
    required this.topics,
  });

  int _completedQuestions() => topics.fold<int>(
    0,
    (sum, t) => sum + (t['completedQuestions'] as int? ?? 0),
  );
  int _totalQuestions() =>
      topics.fold<int>(0, (sum, t) => sum + (t['totalQuestions'] as int? ?? 0));

  @override
  Widget build(BuildContext context) {
    final completed = _completedQuestions();
    final total = _totalQuestions();
    final overallPct = total > 0 ? (completed / total) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.navy),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: topics.isEmpty
            ? Center(
                child: Text(
                  AppLocalizations.of(context).text('No topics yet.'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  // ── Chapter header card ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$chapterIndex',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                chapterName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (total > 0)
                              ProgressRing(
                                percent: overallPct,
                                size: 48,
                                color: Colors.white,
                                trackColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                          ],
                        ),
                        if (total > 0) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (overallPct / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.25,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress: ${overallPct.round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$completed / $total questions solved',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── All Topics ────────────────────────────
                  Text(
                    AppLocalizations.of(context).text('All Topics'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(topics.length, (i) {
                    final tp = topics[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTopicCard(
                        context: context,
                        index: i + 1,
                        name: tp['name']?.toString() ?? 'Topic',
                        topicId: tp['_id']?.toString() ?? '',
                        isLocked: tp['isLocked'] == true,
                        lockedReason: tp['lockedReason']?.toString() ?? '',
                        completed: tp['completedQuestions'] as int? ?? 0,
                        total: tp['totalQuestions'] as int? ?? 0,
                      ),
                    );
                  }),

                  const SizedBox(height: 6),
                  // ── Tips box ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).text('Tip'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Finish each topic to sharpen your understanding — completing a topic unlocks the next one.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.9,
                                  ),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Chapter summary ───────────────────────
                  Text(
                    '$chapterName Summary',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryTile(
                          context: context,
                          icon: Icons.menu_book_rounded,
                          label: 'Topics',
                          value: '${topics.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryTile(
                          context: context,
                          icon: Icons.quiz_outlined,
                          label: 'Questions',
                          value: '$total',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryTile(
                          context: context,
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Solved',
                          value: '$completed',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryTile(
                          context: context,
                          icon: Icons.trending_up_rounded,
                          label: 'Progress',
                          value: '${overallPct.round()}%',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summaryTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            AppLocalizations.of(context).text(label),
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard({
    required BuildContext context,
    required int index,
    required String name,
    required String topicId,
    required bool isLocked,
    required String lockedReason,
    required int completed,
    required int total,
  }) {
    final isComplete = total > 0 && completed >= total;
    final pct = total > 0 ? (completed / total) * 100 : 0.0;

    return GestureDetector(
      onTap: topicId.isEmpty
          ? null
          : () {
              if (isLocked) {
                _openSubscription(context, lockedReason);
                return;
              }
              AdHelper.showRewardedAd(
                onComplete: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExamQuestionsScreen(
                        examId: examId,
                        examName: examName,
                        examSubjectId: examSubjectId,
                        examSubjectName: examSubjectName,
                        topicId: topicId,
                        topicName: name,
                      ),
                    ),
                  );
                },
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isLocked
              ? Border.all(color: Colors.orange.withValues(alpha: 0.28))
              : Border.all(color: Colors.grey.shade100),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isLocked ? Colors.orange : AppColors.primaryBlue)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$chapterIndex.$index',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? Colors.orange.shade700
                        : AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      '$total Questions',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLocked)
              _statusBadge(
                context: context,
                icon: Icons.lock_rounded,
                label: 'Locked',
                color: Colors.orange,
                fraction: total > 0 ? '0/$total' : null,
              )
            else if (isComplete)
              _statusBadge(
                context: context,
                icon: Icons.check_circle_rounded,
                label: 'Complete',
                color: Colors.green,
                fraction: '$completed/$total',
              )
            else if (total > 0)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProgressRing(percent: pct, size: 36, strokeWidth: 3),
                  const SizedBox(height: 2),
                  Text(
                    '$completed/$total',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    String? fraction,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).text(label),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (fraction != null) ...[
          const SizedBox(height: 3),
          Text(
            fraction,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  void _openSubscription(BuildContext context, String reason) {
    if (reason.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(reason)));
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExamSubscriptionScreen(examId: examId, examName: examName),
      ),
    );
  }
}
