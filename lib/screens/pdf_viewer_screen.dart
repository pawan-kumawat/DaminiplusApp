import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../Helper/AppColors.dart';

/// Renders a PDF natively, in-app — no Google Docs Viewer or any other
/// external service, so nothing but our own content ever shows.
/// Downloads once to a temp file, then hands it to the platform's own
/// PDF engine (PDFKit on iOS, PdfRenderer on Android) via flutter_pdfview.
class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  const PdfViewerScreen({super.key, required this.title, required this.url});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    try {
      final response = await http.get(Uri.parse(widget.url)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw Exception('status ${response.statusCode}');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dp_${widget.url.hashCode.toRadixString(16)}.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      if (!mounted) return;
      setState(() {
        _localPath = file.path;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load this document. Please check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF525659),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 40),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => setState(() => _download()),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          : _localPath == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : PDFView(
                  filePath: _localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onRender: (pages) {
                    if (mounted) setState(() => _totalPages = pages ?? 0);
                  },
                  onPageChanged: (page, total) {
                    if (mounted) setState(() => _currentPage = page ?? 0);
                  },
                  onError: (error) {
                    if (mounted) setState(() => _error = 'Could not open this document.');
                  },
                ),
    );
  }
}
