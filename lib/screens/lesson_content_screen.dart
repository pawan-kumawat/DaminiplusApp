import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import 'questions_screen.dart';

class LessonContentScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final String subjectId;
  final String subjectName;
  final String languageId;

  const LessonContentScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.subjectName,
    required this.languageId,
  });

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  bool _isLoading = true;

  String _title = '';
  String _imageUrl = '';
  String _content = '';
  String _funFact = '';
  String _audioUrl = '';
  double _progress = 0.0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _title = widget.topicName;
    _fetchTopicDetail();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  // ── Pehle non-null/non-empty key utha lo ───────────────
  dynamic _pick(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v != null && v.toString().trim().isNotEmpty) return v;
    }
    return null;
  }

  Future<void> _fetchTopicDetail() async {
    setState(() => _isLoading = true);

    final response = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.getTopicDetail(widget.topicId),
      showLoader: false,
    );

    if (response != "Error" && mounted) {
      try {
        final json = jsonDecode(response);
        final data = json['data'] as Map<String, dynamic>? ?? {};

        final pickedProgress = data['progress'] ?? data['progressPercent'];
        double progressVal = 0.0;
        if (pickedProgress != null) {
          final d = double.tryParse(pickedProgress.toString()) ?? 0;
          progressVal = d > 1 ? d / 100 : d;
        }

        setState(() {
          _title =
              _pick(data, ['name', 'title'])?.toString() ?? widget.topicName;
          _imageUrl =
              _pick(data, ['imageUrl', 'image', 'thumbnail', 'coverImage'])
                  ?.toString() ??
                  '';
          _content =
              _pick(data, [
                'content',
                'description',
                'body',
                'lessonContent',
                'text',
              ])?.toString() ??
                  '';
          _funFact =
              _pick(data, ['funFact', 'fact', 'didYouKnow'])?.toString() ??
                  '';
          _audioUrl =
              _pick(data, ['audioUrl', 'audio', 'audioFile'])?.toString() ??
                  '';
          _progress = progressVal;
        });
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  Future<void> _togglePlay() async {
    if (_audioUrl.isEmpty) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else if (_position == Duration.zero) {
      await _audioPlayer.play(UrlSource(_audioUrl));
    } else {
      await _audioPlayer.resume();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _goNext() async {
    // Resume point save — best effort, fail silently agar error aaye
    await APIService.putApiCaller(
      context: context,
      url: ApiUrls.updateResume,
      body: {"subjectId": widget.subjectId, "topicId": widget.topicId},
      showLoader: false,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionsScreen(
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          topicId: widget.topicId,
          topicName: _title,
          languageId: widget.languageId,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Current Lesson',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lesson Progress',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${(_progress * 100).round()}% Complete',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Image (sirf tab dikhao jab imageUrl ho) ──
              if (_imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const SizedBox.shrink(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _imagePlaceholder(loading: true);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text(
                _title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),

              // ── Audio player ───────────────────
              if (_audioUrl.isNotEmpty) _buildAudioPlayer(),
              if (_audioUrl.isNotEmpty) const SizedBox(height: 20),

              // ── Body content ───────────────────
              if (_content.isNotEmpty)
                _buildRichContent(_content)
              else
                const Text(
                  'Lesson content will appear here.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),

              // ── Fun fact ───────────────────────
              if (_funFact.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(
                        color: Colors.orange.shade700,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FUN FACT',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _funFact,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Prev / Next ────────────────────
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: AppColors.navy,
                        ),
                        label: const Text(
                          'Previous',
                          style: TextStyle(color: AppColors.navy),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _goNext,
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Next',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder({bool loading = false}) {
    return Container(
      width: double.infinity,
      height: 200,
      color: AppColors.primaryBlue.withOpacity(0.08),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : const Icon(
          Icons.image_outlined,
          size: 40,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    double progress = 0;
    if (_duration.inMilliseconds > 0) {
      progress = (_position.inMilliseconds / _duration.inMilliseconds).clamp(
        0.0,
        1.0,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listen to Lesson',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _duration.inMilliseconds > 0 ? _fmt(_duration) : '--:--',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── **bold** ko blue-bold highlight karke render karo ──
  Widget _buildRichContent(String text) {
    final paragraphs = text.split('\n').where((p) => p.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        final spans = <TextSpan>[];
        final regex = RegExp(r'\*\*(.*?)\*\*');
        int last = 0;
        for (final m in regex.allMatches(para)) {
          if (m.start > last) {
            spans.add(TextSpan(text: para.substring(last, m.start)));
          }
          spans.add(
            TextSpan(
              text: m.group(1),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          last = m.end;
        }
        if (last < para.length) {
          spans.add(TextSpan(text: para.substring(last)));
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                height: 1.5,
              ),
              children: spans,
            ),
          ),
        );
      }).toList(),
    );
  }
}