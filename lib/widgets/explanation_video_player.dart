import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../Helper/AppColors.dart';

/// Plays a question's admin-recorded whiteboard "Explanation" video.
class ExplanationVideoPlayer extends StatefulWidget {
  final String url;
  const ExplanationVideoPlayer({super.key, required this.url});

  @override
  State<ExplanationVideoPlayer> createState() => _ExplanationVideoPlayerState();
}

class _ExplanationVideoPlayerState extends State<ExplanationVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init({int attempt = 1}) async {
    if (mounted) setState(() => _failed = false);
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      controller.dispose();
      if (!mounted) return;
      // Mobile networks hiccup often enough that a single failed load
      // shouldn't be final — a couple of quick automatic retries clear
      // most of them before the user ever sees an error state.
      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
        if (mounted) return _init(attempt: attempt + 1);
      }
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    final controller = _controller;
    if (controller == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenExplanationPlayer(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return GestureDetector(
        onTap: () => _init(),
        child: _placeholder(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              SizedBox(height: 6),
              Text(
                'Could not load explanation video — tap to retry',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _placeholder(
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: _VideoSurface(
          controller: controller,
          onFullscreenTap: _openFullscreen,
          fullscreenIcon: Icons.fullscreen_rounded,
        ),
      ),
    );
  }

  Widget _placeholder({required Widget child}) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Full-screen playback follows the recorded video's own orientation and
/// reuses the SAME controller
/// (not a new one) so position/playback state carries over seamlessly
/// and popping back doesn't restart the video.
class _FullscreenExplanationPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const _FullscreenExplanationPlayer({required this.controller});

  @override
  State<_FullscreenExplanationPlayer> createState() =>
      _FullscreenExplanationPlayerState();
}

class _FullscreenExplanationPlayerState
    extends State<_FullscreenExplanationPlayer> {
  @override
  void initState() {
    super.initState();
    final isLandscape = widget.controller.value.aspectRatio >= 1;
    SystemChrome.setPreferredOrientations(
      isLandscape
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio == 0
                ? 16 / 9
                : widget.controller.value.aspectRatio,
            child: _VideoSurface(
              controller: widget.controller,
              onFullscreenTap: () => Navigator.of(context).pop(),
              fullscreenIcon: Icons.fullscreen_exit_rounded,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared video + tap-to-play/pause overlay + scrub bar + fullscreen
/// toggle, used both inline (in the question card) and in the fullscreen
/// route — kept in one place so the two stay visually/behaviorally in sync.
class _VideoSurface extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onFullscreenTap;
  final IconData fullscreenIcon;

  const _VideoSurface({
    required this.controller,
    required this.onFullscreenTap,
    required this.fullscreenIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(controller),
        _PlayPauseOverlay(controller: controller),
        Positioned(
          left: 8,
          right: 40,
          bottom: 6,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.primaryBlue,
              bufferedColor: Colors.white38,
              backgroundColor: Colors.white24,
            ),
          ),
        ),
        Positioned(
          right: 6,
          bottom: 2,
          child: GestureDetector(
            onTap: onFullscreenTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(fullscreenIcon, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayPauseOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  const _PlayPauseOverlay({required this.controller});

  @override
  State<_PlayPauseOverlay> createState() => _PlayPauseOverlayState();
}

class _PlayPauseOverlayState extends State<_PlayPauseOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.controller.value.isPlaying;
    return GestureDetector(
      onTap: () =>
          playing ? widget.controller.pause() : widget.controller.play(),
      child: AnimatedOpacity(
        opacity: playing ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: Colors.black26,
          child: const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
        ),
      ),
    );
  }
}
