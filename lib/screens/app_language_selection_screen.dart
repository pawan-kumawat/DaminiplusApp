// ─────────────────────────────────────────────────────────────
// app_language_selection_screen.dart
// Shown ONCE before the login screen when no app language is saved.
// Also reachable from Settings to change the app language.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../Helper/LocaleProvider.dart';

class AppLanguageSelectionScreen extends StatefulWidget {
  /// If true, shows a back button and pops instead of pushing LoginScreen.
  final bool fromSettings;

  const AppLanguageSelectionScreen({super.key, this.fromSettings = false});

  @override
  State<AppLanguageSelectionScreen> createState() =>
      _AppLanguageSelectionScreenState();
}

class _AppLanguageSelectionScreenState
    extends State<AppLanguageSelectionScreen> {
  String _selectedCode = 'en';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    _selectedCode = provider.locale.languageCode;
  }

  Future<void> _saveLanguage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    final locale = _selectedCode == 'hi' ? kLocaleHi : kLocaleEn;
    await provider.setLocale(locale);

    if (!mounted) return;

    if (widget.fromSettings) {
      Navigator.pop(context);
    } else {
      // Push LoginScreen — imported lazily to avoid circular deps
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use raw strings here because the locale may not be set yet,
    // so we read from both languages ourselves.
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: widget.fromSettings
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
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
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Title — bilingual so user always understands
              const Text(
                'Choose App Language\nऐप की भाषा चुनें',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select the language you want to use for this app.\nवह भाषा चुनें जो आप इस ऐप में उपयोग करना चाहते हैं।',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),

              // English option
              _buildOption(
                code: 'en',
                icon: 'A',
                name: 'English',
                nativeName: 'English',
              ),
              const SizedBox(height: 16),

              // Hindi option
              _buildOption(
                code: 'hi',
                icon: 'अ',
                name: 'हिंदी',
                nativeName: 'Hindi',
              ),

              const Spacer(),

              // Continue button
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveLanguage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 4,
                      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _selectedCode == 'hi' ? 'सेव करें' : 'Save',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String code,
    required String icon,
    required String name,
    required String nativeName,
  }) {
    final isSelected = _selectedCode == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedCode = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  nativeName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
