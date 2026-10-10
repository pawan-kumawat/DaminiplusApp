import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static const String appId = 'ca-app-pub-1986575037466466~1231816416';
  static const String rewardedAdUnitId =
      'ca-app-pub-1986575037466466/9377145145';

  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;
  static bool _isShowing = false;

  /// Initialize Mobile Ads SDK and preload initial rewarded ad
  static Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      loadRewardedAd();
    } catch (e) {
      debugPrint("AdMob Init Error: $e");
    }
  }

  /// Load Rewarded Ad in background
  static void loadRewardedAd() {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint("RewardedAd loaded successfully.");
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint("RewardedAd failed to load: ${error.message}");
        },
      ),
    );
  }

  /// Show Rewarded Ad and invoke completion callback ONLY if user earns the reward
  static void showRewardedAd({
    required VoidCallback onComplete,
    required BuildContext context,
  }) {
    if (_isShowing) return;

    // 1. If ad is loaded, present it directly
    if (_rewardedAd != null) {
      final adToShow = _rewardedAd!;
      _rewardedAd = null;
      _presentAd(ad: adToShow, onComplete: onComplete, context: context);
      return;
    }

    if (!context.mounted) return;
    _isShowing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Loading ad...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _waitForAd(context: context, onComplete: onComplete);
  }

  static Future<void> _waitForAd({
    required BuildContext context,
    required VoidCallback onComplete,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (context.mounted && _rewardedAd == null && DateTime.now().isBefore(deadline)) {
      if (!_isLoading) loadRewardedAd();
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!context.mounted) {
      _isShowing = false;
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    final ad = _rewardedAd;
    _rewardedAd = null;
    if (ad == null) {
      _isShowing = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The ad could not be loaded. Please try again.')),
      );
      return;
    }
    _presentAd(ad: ad, onComplete: onComplete, context: context);
  }

  static void _presentAd({
    required RewardedAd ad,
    required VoidCallback onComplete,
    required BuildContext context,
  }) {
    _isShowing = true;
    bool isRewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        loadRewardedAd(); // Preload next ad

        if (isRewardEarned) {
          onComplete();
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please watch the full ad to unlock this content.',
                ),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        loadRewardedAd();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The ad could not be shown. Please try again.')),
          );
        }
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint("User earned reward: ${reward.amount} ${reward.type}");
        isRewardEarned = true;
      },
    );
  }
}
