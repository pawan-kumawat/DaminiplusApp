import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static const String appId = 'ca-app-pub-1986575037466466~1231816416';
  static const String rewardedAdUnitId =
      'ca-app-pub-1986575037466466/9377145145';

  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

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

  /// Show Rewarded Ad and then invoke completion callback
  static void showRewardedAd({required VoidCallback onComplete}) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      onComplete();
      return;
    }

    bool hasHandledCallback = false;

    void finish() {
      if (!hasHandledCallback) {
        hasHandledCallback = true;
        _rewardedAd = null;
        loadRewardedAd();
        onComplete();
      }
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        finish();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint("User earned reward: ${reward.amount} ${reward.type}");
      },
    );
  }
}
