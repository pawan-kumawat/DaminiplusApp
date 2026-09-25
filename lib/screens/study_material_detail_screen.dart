// ─────────────────────────────────────────────────────────────
// study_material_detail_screen.dart
// Ek subject ka Book/Notes/Model-Paper detail — cover, admin ne jo
// "About" likha hai, aur PDF(s). Sirf ek PDF ho to seedha "View PDF"
// button; multiple ho to admin ne jo title diya hai usi naam ki
// numbered list (5 se zyada ho to "View All" se expand hoti hai).
// Koi Download button jaanboojh kar nahi hai — sirf in-app view.
//
// Visual design reference screenshot ke mutabiq hai. Screenshot me
// jo extra cheezein thi (rating, downloads count, "Official Book"
// badge, chapters/topics/pages/questions stats, "updated on" date)
// unhe include NAHI kiya gaya hai kyunki backend data me wo fields
// exist hi nahi karte — sirf jo real data hai wahi dikhaya gaya hai.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../utils/format_utils.dart';
import '../widgets/book_cover.dart';
import 'pdf_viewer_screen.dart';

class StudyMaterialDetailScreen extends StatefulWidget {
  final String type; // book | notes | model_paper
  final String kind; // board | exam | otherCourse
  final String subjectId;
  final String boardId;
  final String classId;
  final String examId;
  final String otherCourseId;
  final String fallbackName;
  final String fallbackIconUrl;
  final String fallbackBoardName;
  final String fallbackClassName;

  const StudyMaterialDetailScreen({
    super.key,
    required this.type,
    required this.subjectId,
    required this.fallbackName,
    required this.fallbackIconUrl,
    this.kind = 'board',
    this.boardId = '',
    this.classId = '',
    this.examId = '',
    this.otherCourseId = '',
    this.fallbackBoardName = '',
    this.fallbackClassName = '',
  });

  @override
  State<StudyMaterialDetailScreen> createState() =>
      _StudyMaterialDetailScreenState();
}

class _StudyMaterialDetailScreenState
    extends State<StudyMaterialDetailScreen> {
  static const int _collapsedLimit = 5;

  bool _isLoading = true;
  bool _showAllFiles = false;
  bool _isSaved = false;
  String _name = '';
  String _iconUrl = '';
  String _about = '';
  List<Map<String, dynamic>> _items = [];

  static const Map<String, String> _dataKeyByType = {
    'book': 'books',
    'model_paper': 'modelPapers',
    'practice_set': 'practiceSets',
    'current_affairs': 'currentAffairs',
  };

  static const Map<String, String> _appBarTitleByType = {
    'book': 'Book Details',
    'model_paper': 'Paper Details',
    'practice_set': 'Practice Set Details',
    'current_affairs': 'Current Affairs Details',
  };

  static const Map<String, String> _aboutTitleByType = {
    'book': 'About This Book',
    'model_paper': 'About This Paper',
    'practice_set': 'About This Practice Set',
    'current_affairs': 'About This',
  };

  static const Map<String, String> _filesTitleByType = {
    'book': 'Files in this Book',
    'model_paper': 'Files in this Paper',
    'practice_set': 'Files in this Practice Set',
    'current_affairs': 'Files in this Section',
  };

  @override
  void initState() {
    super.initState();
    _name = widget.fallbackName;
    _iconUrl = widget.fallbackIconUrl;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final url = widget.kind == 'exam'
        ? ApiUrls.getExamSubjectResources(widget.subjectId, examId: widget.examId)
        : widget.kind == 'otherCourse'
            ? ApiUrls.getOtherCourseSubjectResources(widget.subjectId, otherCourseId: widget.otherCourseId)
            : ApiUrls.getSubjectResources(
                widget.subjectId,
                boardId: widget.boardId,
                classId: widget.classId,
              );
    final result = await APIService.getApiCaller(
      context: context,
      url: url,
      showLoader: false,
    );
    if (!mounted) return;

    if (result != "Error") {
      try {
        final json = jsonDecode(result);
        final data = json['data'] as Map<String, dynamic>? ?? {};
        final subject = data['subject'] as Map<String, dynamic>? ?? {};
        final key = _dataKeyByType[widget.type] ?? 'books';
        final rawItems = data[key] as List<dynamic>? ?? [];
        setState(() {
          _name = subject['name']?.toString() ?? widget.fallbackName;
          _iconUrl = subject['iconUrl']?.toString() ?? widget.fallbackIconUrl;
          _about = subject['about']?.toString() ?? '';
          _items = rawItems
              .map<Map<String, dynamic>>(
                (e) => {
              '_id': e['_id']?.toString() ?? '',
              'title': e['title']?.toString() ?? 'Untitled',
              'fileUrl': e['fileUrl']?.toString() ?? '',
              'imageUrl': e['imageUrl']?.toString() ?? '',
              'fileSize': e['fileSize'] is int
                  ? e['fileSize']
                  : int.tryParse(e['fileSize']?.toString() ?? '') ?? 0,
            },
          )
              .where((e) => (e['fileUrl'] as String).isNotEmpty)
              .toList();
          _isLoading = false;
        });
        return;
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  void _openPdf(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(title: title, url: url),
      ),
    );
  }

  void _onShare() {
    if (_items.isEmpty) return;

    final buffer = StringBuffer();
    final headerParts = [
      widget.fallbackBoardName,
      widget.fallbackClassName,
    ].where((s) => s.isNotEmpty).join(' · ');

    if (_items.length == 1) {
      // Sirf ek hi PDF hai — seedha uska title + link.
      buffer.writeln(_items[0]['title'] as String);
      if (headerParts.isNotEmpty) buffer.writeln(headerParts);
      buffer.writeln();
      buffer.write(_items[0]['fileUrl'] as String);
    } else {
      // Multiple PDFs — subject name + har ek ka title + link.
      buffer.writeln(_name);
      if (headerParts.isNotEmpty) buffer.writeln(headerParts);
      buffer.writeln();
      for (var i = 0; i < _items.length; i++) {
        buffer.writeln('${i + 1}. ${_items[i]['title']}');
        buffer.writeln(_items[i]['fileUrl'] as String);
        if (i != _items.length - 1) buffer.writeln();
      }
    }

    Share.share(buffer.toString(), subject: _name);
  }

  @override
  Widget build(BuildContext context) {
    final boardName = widget.fallbackBoardName;
    final className = widget.fallbackClassName;
    final appBarTitle = _appBarTitleByType[widget.type] ?? 'Details';
    final aboutTitle = _aboutTitleByType[widget.type] ?? 'About';
    final filesTitle = _filesTitleByType[widget.type] ?? 'Files';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
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
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              color: _isSaved ? Colors.redAccent : AppColors.navy,
            ),
            onPressed: () => setState(() => _isSaved = !_isSaved),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.navy),
            onPressed: _onShare,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    height: 150,
                    child: BookCover(
                      title: _name,
                      subtitle: className,
                      badge: boardName,
                      imageUrl: _iconUrl,
                      borderRadius: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        if (boardName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            boardName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (className.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            className,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildPill('PDF'),
                            _buildPill(
                              _items.length == 1
                                  ? '1 file'
                                  : '${_items.length} files',
                            ),
                          ],
                        ),
                        if (_items.length == 1 &&
                            (_items[0]['fileSize'] as int) > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${appBarTitle.replaceAll(' Details', '')} PDF · '
                                '${formatFileSize(_items[0]['fileSize'] as int)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (_about.trim().isNotEmpty) ...[
                Text(
                  aboutTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _about,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_items.isNotEmpty) ...[
                Text(
                  '$filesTitle (${_items.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilesList(),
              ],
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Nothing uploaded here yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Jab admin ne is PDF ke liye koi cover image upload nahi ki ho.
  Widget _fileNumberBadge(int index) {
    return Container(
      width: 56,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    final visible =
    _showAllFiles ? _items : _items.take(_collapsedLimit).toList();
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final item = visible[i];
            final fileSize = item['fileSize'] as int;
            final imageUrl = item['imageUrl'] as String;
            return GestureDetector(
              onTap: () => _openPdf(
                item['title'] as String,
                item['fileUrl'] as String,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 56,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fileNumberBadge(i),
                            )
                          : _fileNumberBadge(i),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          if (fileSize > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              formatFileSize(fileSize),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_items.length > _collapsedLimit) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showAllFiles = !_showAllFiles),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _showAllFiles
                    ? 'Show Less'
                    : 'View All (${_items.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}