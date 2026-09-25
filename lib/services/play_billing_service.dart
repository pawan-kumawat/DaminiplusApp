import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play Billing plumbing for the subscription plans — client
/// side only, NOT wired into any purchase screen yet.
///
/// Why it's not live: buying a real subscription through Play Billing
/// requires (1) products created in Google Play Console matching real
/// productIds, which needs a paid Play Console account + a published
/// (at least internal-track) app listing, and (2) server-side receipt
/// verification via the Android Publisher API (a Google Cloud service
/// account with access to the Play Console project), so a purchase
/// token can't just be trusted client-side — anyone could fabricate
/// one and grant themselves a free subscription otherwise. Neither
/// exists yet. Until both are in place, the app's existing purchase
/// flow (SubscriptionScreen/ExamSubscriptionScreen/
/// OtherCourseSubscriptionScreen → POST /app/purchases) stays as the
/// live path — it already carries the referral/coupon discount engine
/// and simply records a purchase directly, no payment gateway wired
/// in behind it either.
///
/// To go live: create matching products in Play Console for every
/// Subscription/ExamSubscription/OtherCourseSubscription plan (one
/// sensible productId scheme is `board_<subscriptionId>`,
/// `exam_<subscriptionId>`, `otherCourse_<subscriptionId>`), point a
/// purchase button at [buy], and change the purchase-update listener
/// below to call a new backend endpoint that verifies the purchase
/// token server-side (via googleapis' androidpublisher) before
/// creating the purchase record — never trust [PurchaseDetails]
/// alone.
class PlayBillingService {
  PlayBillingService._();
  static final PlayBillingService instance = PlayBillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Call once (e.g. from a settings/debug screen) to check whether
  /// the Play Store billing service is reachable on this device.
  Future<bool> initialize() async {
    _isAvailable = await _iap.isAvailable();
    return _isAvailable;
  }

  /// Looks up Play Console product listings for the given productIds.
  /// Returns empty/notFoundIds for anything not yet created in Play
  /// Console — expected to be everything until products are set up.
  Future<ProductDetailsResponse> queryProducts(Set<String> productIds) {
    return _iap.queryProductDetails(productIds);
  }

  /// Starts listening for purchase updates. [onUpdate] fires for every
  /// state change (pending/purchased/restored/error); the caller is
  /// responsible for calling [completePurchase] once it has been
  /// durably recorded (verified + saved backend-side), otherwise Play
  /// will keep redelivering it as "pending" on every app start.
  void listen(void Function(List<PurchaseDetails> purchases) onUpdate) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      onUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );
  }

  Future<void> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
