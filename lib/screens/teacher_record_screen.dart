import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show DeviceOrientation, SystemChrome, rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../API/ApiUrls.dart';
import '../Helper/AppSharedPreferencesData.dart';

/// Opens frontend/teacher-record.html (same canvas/record/preview/upload
/// tool the admin panel uses, adapted for a WebView — see that file for
/// the full mechanics) against one question+language. Pops the saved
/// video's URL once recording completes so the caller can update that
/// question's local state directly (button disappears without a
/// refetch); pops null if closed without saving.
class TeacherRecordScreen extends StatefulWidget {
  final String questionId;
  final String languageId;
  final String pillar; // 'board' | 'exam' | 'otherCourse'
  final String questionTitle;
  final String questionImageUrl;

  const TeacherRecordScreen({
    super.key,
    required this.questionId,
    required this.languageId,
    required this.pillar,
    this.questionTitle = '',
    this.questionImageUrl = '',
  });

  @override
  State<TeacherRecordScreen> createState() => _TeacherRecordScreenState();
}

class _TeacherRecordScreenState extends State<TeacherRecordScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _initError = false;
  bool _micPermanentlyDenied = false;

  Future<void> _setBoardOrientation(String orientation) async {
    await SystemChrome.setPreferredOrientations(
      orientation == 'landscape'
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
  }

  Future<void> _closeWithResult(Object? result) async {
    await _setBoardOrientation('portrait');
    if (mounted) Navigator.pop(context, result);
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await AppSharedPreferencesData.getToken();
    if (token.isEmpty) {
      if (!mounted) return;
      setState(() => _initError = true);
      return;
    }

    // Ask for the OS mic permission up front, before the page ever loads
    // — leaving this only to the WebView's onPermissionRequest doesn't
    // reliably surface the system dialog on Android, which is why
    // recording silently failed with no prompt at all. Once this is
    // settled, onPermissionRequest below just mirrors it to the page.
    final micStatus = await Permission.microphone.request();
    if (!mounted) return;
    if (micStatus.isPermanentlyDenied) {
      setState(() => _micPermanentlyDenied = true);
      return;
    }

    // The Digital Board ships inside the app. Inject only this recording's
    // API/auth context before loading it, so board behavior does not depend
    // on a separately deployed admin HTML page.
    final origin = ApiUrls.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    var boardHtml = await rootBundle.loadString(
      'assets/html/teacher-record.html',
    );
    boardHtml = boardHtml
        .replaceFirst('__API_BASE__', jsonEncode(ApiUrls.baseUrl))
        .replaceFirst('__TOKEN__', jsonEncode(token))
        .replaceFirst('__QUESTION_ID__', jsonEncode(widget.questionId))
        .replaceFirst('__LANGUAGE_ID__', jsonEncode(widget.languageId))
        .replaceFirst('__PILLAR__', jsonEncode(widget.pillar))
        .replaceFirst('__QUESTION_TITLE__', jsonEncode(widget.questionTitle))
        .replaceFirst(
          '__QUESTION_IMAGE_URL__',
          jsonEncode(widget.questionImageUrl),
        );

    final controller =
        WebViewController(
            // Web content calling getUserMedia({audio:true}) for the narration
            // track lands here — the OS-level permission was already settled
            // above, so this just mirrors that decision to the page.
            onPermissionRequest: (WebViewPermissionRequest request) async {
              final status = await Permission.microphone.status;
              if (status.isGranted) {
                request.grant();
              } else {
                request.deny();
              }
            },
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'TeacherRecorder',
            onMessageReceived: _onMessage,
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (mounted) setState(() => _isLoading = true);
              },
              onPageFinished: (_) {
                if (mounted) setState(() => _isLoading = false);
              },
            ),
          );

    await controller.loadHtmlString(boardHtml, baseUrl: origin);
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _onMessage(JavaScriptMessage message) {
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = data['type'] as String?;
    if (type == 'saved') {
      _closeWithResult(data['url']?.toString() ?? '');
    } else if (type == 'close') {
      _closeWithResult(null);
    } else if (type == 'orientation') {
      _setBoardOrientation(data['orientation']?.toString() ?? 'portrait');
    } else if (type == 'error' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']?.toString() ?? 'Something went wrong'),
        ),
      );
    }
  }

  // System back defers to the page's own Close button — it already
  // handles "recording in progress" / "unsaved draft" confirmations
  // before it ever tells Flutter to pop (see teacher-record.html).
  Future<void> _requestClose() async {
    if (_controller == null) {
      await _closeWithResult(null);
      return;
    }
    await _controller!.runJavaScript(
      "document.getElementById('closeBtn') && document.getElementById('closeBtn').click();",
    );
  }

  @override
  void dispose() {
    _setBoardOrientation('portrait');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _requestClose();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: _initError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Couldn't start recording — please log in again.",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Go back'),
                        ),
                      ],
                    ),
                  ),
                )
              : _micPermanentlyDenied
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mic_off_rounded,
                          color: Colors.white70,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Microphone access is blocked for this app. Enable it in Settings to record explanation videos.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => openAppSettings(),
                          child: const Text('Open Settings'),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text(
                            'Go back',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller!),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
        ),
      ),
    );
  }
}
