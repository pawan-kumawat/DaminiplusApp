// ─────────────────────────────────────────────────────────────
// AppAlert.dart  — modern redesign (drop-in replacement)
//
// Public API bilkul same hai, kahin aur koi change nahi karna:
//   ShowAlert.showAlert(context, "msg");
//   ShowAlert.showAlertWithAction(context, "msg", () { ... });
//   ShowAlert.showAlertWith2Buttons(context, "msg",
//       "Yes", () { ... }, "No", () { ... });
//
// Behavior bhi same rakha hai:
//   • showAlert            → OK khud pop karta hai
//   • showAlertWithAction  → OK sirf action chalata hai (pop NahI karta,
//                            action ke andar aap khud pop karte ho —
//                            purane code jaisa hi)
//   • showAlertWith2Buttons→ dono buttons sirf apna action chalate hain
//
// Naya look:
//   • 75% kaala overlay hata diya — ab subtle blur + 8% light tint
//   • White rounded card, icon circle, clean typography
//   • Smooth scale + fade + blur entry animation
// ─────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'AppColors.dart';

class ShowAlert {
  // Parallel API calls (e.g. a screen's Future.wait over several
  // endpoints) that all fail at once — no internet, server down —
  // used to each independently pop their own dialog, stacking many
  // copies on screen (tap OK and the next one is already waiting
  // underneath). Only one alert is allowed on screen at a time now;
  // anything else fires while it's up is simply dropped.
  static bool _isShowing = false;

  // ── Simple alert — OK pops itself ──────────────────────────
  static showAlert(BuildContext globalContext, String alertMessageText) {
    _show(
      globalContext,
      message: alertMessageText,
      // Tap-outside se dismiss allowed (koi action pending nahi hai)
      dismissible: true,
      buttons: [
        _AlertButtonSpec(
          text: 'OK',
          isPrimary: true,
          onTap: (ctx) => Navigator.of(ctx).pop(),
        ),
      ],
    );
  }

  // ── Alert with action — OK runs the action (no auto-pop, ───
  //    same as before: action khud pop karta hai)
  static showAlertWithAction(
      BuildContext globalContext, String alertMessageText, okButtonAction) {
    _show(
      globalContext,
      message: alertMessageText,
      // Action pending hai — bahar tap se band nahi hona chahiye
      dismissible: false,
      buttons: [
        _AlertButtonSpec(
          text: 'OK',
          isPrimary: true,
          onTap: (_) => okButtonAction(),
        ),
      ],
    );
  }

  // ── Two-button alert — both run their own actions ──────────
  static showAlertWith2Buttons(
      BuildContext globalContext,
      String alertMessageText,
      String button1Text,
      button1Action,
      String button2Text,
      button2Action) {
    _show(
      globalContext,
      message: alertMessageText,
      dismissible: false,
      buttons: [
        _AlertButtonSpec(
          text: button1Text,
          isPrimary: false,
          onTap: (_) => button1Action(),
        ),
        _AlertButtonSpec(
          text: button2Text,
          isPrimary: true,
          onTap: (_) => button2Action(),
        ),
      ],
    );
  }

  // ── Core presenter ─────────────────────────────────────────
  static void _show(
      BuildContext context, {
        required String message,
        required bool dismissible,
        required List<_AlertButtonSpec> buttons,
      }) {
    if (_isShowing) return;
    if (!context.mounted) return;
    _isShowing = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'alert',
      // Purana 75% black hata diya — ab bahut halka tint,
      // asli dimming neeche wale blur se aati hai.
      barrierColor: Colors.black.withOpacity(0.08),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved =
        CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * anim.value,
            sigmaY: 6 * anim.value,
          ),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
              child: _AlertCard(message: message, buttons: buttons),
            ),
          ),
        );
      },
    ).then((_) => _isShowing = false);
  }
}

// ── Button spec ───────────────────────────────────────────────
class _AlertButtonSpec {
  final String text;
  final bool isPrimary;
  final void Function(BuildContext) onTap;

  const _AlertButtonSpec({
    required this.text,
    required this.isPrimary,
    required this.onTap,
  });
}

// ── The popup card ────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final String message;
  final List<_AlertButtonSpec> buttons;

  const _AlertCard({required this.message, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon in soft tinted circle ─────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_rounded,
                    color: AppColors.primaryBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Message ────────────────────────────
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // ── Buttons ────────────────────────────
                Row(
                  children: [
                    for (int i = 0; i < buttons.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: _buildButton(context, buttons[i])),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, _AlertButtonSpec spec) {
    if (spec.isPrimary) {
      return SizedBox(
        height: 46,
        child: ElevatedButton(
          onPressed: () => spec.onTap(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(23),
            ),
          ),
          child: Text(
            spec.text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    // Secondary — outlined style
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: () => spec.onTap(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
        ),
        child: Text(
          spec.text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}