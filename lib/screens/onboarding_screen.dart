import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../Helper/AppColors.dart';
import '../Helper/AppSharedPreferencesData.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 3 client images — place them in assets/image/
  // and declare in pubspec.yaml under flutter > assets
  static const List<String> _images = [
    'assets/image/-1 final.png',
    'assets/image/-2 final.png',
    'assets/image/-4 final.png',
  ];

  // Har image ke top aur bottom edge ka dominant color yaha cache
  // hota hai (runtime pe pixel-read se nikala jaata hai, koi guess nahi).
  final Map<String, Color> _bottomColorCache = {};

  void _onColorsDetected(String assetPath, Color top, Color bottom) {
    setState(() {
      _bottomColorCache[assetPath] = bottom;
    });
  }

  void _next() {
    if (_currentPage < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Onboarding khatam — DIRECT LoginScreen pe jao ──────────
  // (Language selection screen hata di gayi hai; app by default
  // English mein chalti hai. Language baad mein Settings se
  // change ho sakti hai agar wo screen fromSettings ke saath
  // kholi jaaye.)
  Future<void> _finish() async {
    // ← Ye flag ab hamesha ke liye set ho jaata hai. Logout() bhi ise
    // retain karta hai (clear nahi karta), isliye user chahe kitni
    // baar bhi login/logout kare, onboarding sirf EK baar hi dikhegi.
    await AppSharedPreferencesData.setOnboardingDone();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _images.length - 1;
    final isFirst = _currentPage == 0;
    final currentBottomColor =
        _bottomColorCache[_images[_currentPage]] ?? AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full-screen swipeable images ──────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _images.length,
            itemBuilder: (_, i) => _OnboardingImagePage(
              assetPath: _images[i],
              onColorsDetected: (top, bottom) =>
                  _onColorsDetected(_images[i], top, bottom),
            ),
          ),

          // ── Skip button (top-right) ───────────────────
          if (!isLast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: GestureDetector(
                onTap: _finish,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

          if (!isFirst)
            Positioned(
              left: 24,
              bottom: MediaQuery.of(context).padding.bottom + 28,
              child: _CircleNavButton(
                icon: Icons.arrow_back_rounded,
                onTap: _back,
                isPrimary: false,
                bgColor: currentBottomColor,
              ),
            ),

          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 28,
            child: isLast
                ? _PillNavButton(
              label: 'शुरू करें',
              onTap: _finish,
              bgColor: currentBottomColor,
            )
                : _CircleNavButton(
              icon: Icons.arrow_forward_rounded,
              onTap: _next,
              isPrimary: true,
              bgColor: currentBottomColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingImagePage extends StatefulWidget {
  final String assetPath;
  final void Function(Color top, Color bottom) onColorsDetected;

  const _OnboardingImagePage({
    required this.assetPath,
    required this.onColorsDetected,
  });

  @override
  State<_OnboardingImagePage> createState() => _OnboardingImagePageState();
}

class _OnboardingImagePageState extends State<_OnboardingImagePage> {
  Color? _topColor;
  Color? _bottomColor;

  @override
  void initState() {
    super.initState();
    _detectEdgeColors();
  }

  Future<void> _detectEdgeColors() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final width = image.width;
      final height = image.height;

      Color dominantColor(int startY, int endY) {
        final Map<int, int> freq = {};
        final Map<int, List<int>> sums = {};

        for (int y = startY; y < endY; y++) {
          for (int x = 0; x < width; x += 2) {
            final pixelIndex = (y * width + x) * 4;
            if (pixelIndex + 3 >= byteData.lengthInBytes) continue;
            final r = byteData.getUint8(pixelIndex);
            final g = byteData.getUint8(pixelIndex + 1);
            final b = byteData.getUint8(pixelIndex + 2);

            const bucket = 12;
            final key = ((r ~/ bucket) << 16) |
            ((g ~/ bucket) << 8) |
            (b ~/ bucket);

            freq[key] = (freq[key] ?? 0) + 1;
            final s = sums.putIfAbsent(key, () => [0, 0, 0, 0]);
            s[0] += r;
            s[1] += g;
            s[2] += b;
            s[3] += 1;
          }
        }

        if (freq.isEmpty) return Colors.white;

        final winningKey =
            freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        final s = sums[winningKey]!;
        return Color.fromARGB(
          255,
          (s[0] / s[3]).round(),
          (s[1] / s[3]).round(),
          (s[2] / s[3]).round(),
        );
      }

      final topSampleEnd = 40.clamp(0, height);
      final bottomSampleStart = (height - 40).clamp(0, height);

      final topEdge = dominantColor(0, topSampleEnd);
      final bottomEdge = dominantColor(bottomSampleStart, height);

      if (mounted) {
        setState(() {
          _topColor = topEdge;
          _bottomColor = bottomEdge;
        });
        widget.onColorsDetected(topEdge, bottomEdge);
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = _topColor ?? Colors.white;
    final bottom = _bottomColor ?? AppColors.primaryBlue;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: Center(
        child: Image.asset(
          widget.assetPath,
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}

class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color bgColor;

  const _CircleNavButton({
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? bgColor : Colors.white,
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? bgColor : Colors.black).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : bgColor,
          size: 26,
        ),
      ),
    );
  }
}

class _PillNavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color bgColor;

  const _PillNavButton({
    required this.label,
    required this.onTap,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}