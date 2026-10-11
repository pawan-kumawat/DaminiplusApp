import 'package:flutter/material.dart';
import '../main.dart' show ipadView;

/// Helper class to handle iPad/Tablet responsive design layout & grid calculations.
class TabletHelper {
  /// Check if iPad/Tablet view is enabled
  static bool isTablet(BuildContext context) {
    if (!ipadView) return false;
    return true;
  }

  /// Get responsive grid cross-axis count for GridViews across all screens
  static int getGridCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int largeTablet = 4,
  }) {
    if (!ipadView) return mobile;
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return largeTablet;
    return tablet;
  }

  /// Get max content width for iPad/Tablet layout
  static double getMaxWidth(BuildContext context) {
    return 850.0;
  }
}

/// A wrapper widget that transforms and constrains ALL screens across the app
/// into a clean, adaptable iPad/Tablet layout when ipadView is enabled.
class TabletLayoutWrapper extends StatelessWidget {
  final Widget? child;

  const TabletLayoutWrapper({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    if (!ipadView) return child!;

    final mediaQuery = MediaQuery.of(context);
    final realWidth = mediaQuery.size.width;
    final realHeight = mediaQuery.size.height;

    const double targetTabletWidth = 850.0;

    // Case 1: Wide screen (iPad / Tablet / Web / Desktop, realWidth >= 600)
    if (realWidth >= 600) {
      return Container(
        color: const Color(0xFF0F172A), // Premium dark slate tablet canvas
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: targetTabletWidth),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  spreadRadius: 6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRect(
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(
                    realWidth > targetTabletWidth ? targetTabletWidth : realWidth,
                    realHeight,
                  ),
                ),
                child: child!,
              ),
            ),
          ),
        ),
      );
    }

    // Case 2: Mobile device (realWidth < 600) but ipadView = true
    // Simulate iPad view on mobile device by scaling 768px iPad layout into phone screen
    const double simulatedTabletWidth = 768.0; // iPad mini width
    final double scaleFactor = realWidth / simulatedTabletWidth;

    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: simulatedTabletWidth,
            height: realHeight / scaleFactor,
            child: MediaQuery(
              data: mediaQuery.copyWith(
                size: Size(simulatedTabletWidth, realHeight / scaleFactor),
                devicePixelRatio: mediaQuery.devicePixelRatio * scaleFactor,
              ),
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}
