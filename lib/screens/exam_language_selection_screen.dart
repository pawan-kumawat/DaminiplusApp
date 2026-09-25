import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppLocalizations.dart';
import '../Helper/AppSharedPreferencesData.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';
import '../widgets/language_illustration.dart';
import 'coming_soon_screen.dart';
import 'main_screen.dart';
import 'course_subjects_screen.dart';

class ExamLanguageSelectionScreen extends StatefulWidget {
  final String examId;
  final String examName;

  const ExamLanguageSelectionScreen({
    super.key,
    required this.examId,
    this.examName = '',
  });

  @override
  State<ExamLanguageSelectionScreen> createState() =>
      _ExamLanguageSelectionScreenState();
}

class _ExamLanguageSelectionScreenState
    extends State<ExamLanguageSelectionScreen> {
  List<Map<String, dynamic>> _languages = [];
  String? _selectedId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    setState(() => _isLoading = true);
    final response = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.getExamLanguages(widget.examId),
      showLoader: false,
    );

    if (response != "Error" && mounted) {
      final json = jsonDecode(response);
      final data = json['data'] as List<dynamic>? ?? [];
      setState(() {
        _languages = data
            .map(
              (e) => {
                '_id': e['_id']?.toString() ?? '',
                'name': e['name']?.toString() ?? '',
                'nativeName':
                    e['nativeName']?.toString() ?? e['name']?.toString() ?? '',
                'icon': e['icon']?.toString() ?? 'A',
              },
            )
            .toList();
        if (_languages.isNotEmpty) _selectedId = _languages.first['_id'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectExam() async {
    if (_selectedId == null) return;

    final response = await APIService.putApiCaller(
      context: context,
      url: ApiUrls.selectExam,
      body: {
        "examId": widget.examId,
        "languageId": _selectedId,
      },
    );

    if (response != "Error" && mounted) {
      final json = jsonDecode(response);
      final hasPlans = json['data']?['hasPlans'] == true;

      await AppSharedPreferencesData.saveExam(
        examId: widget.examId,
        examName: widget.examName,
        examLanguageId: _selectedId!,
      );
      if (!mounted) return;

      if (!hasPlans) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ComingSoonScreen(courseName: widget.examName),
          ),
          (route) => false,
        );
      } else {
        // Selection ke baad seedha padhai shuru honi chahiye — Home
        // par nahi bhejte (pehle yahan se sirf MainScreen khulta tha
        // aur student ko khud Home ke subject-grid me apna exam
        // dhoondhna padta tha). MainScreen stack ke base par rehta
        // hai (back button se Home aa sake), subjects list uske upar
        // push hoti hai. `navigator` pehle hi capture kar liya kyunki
        // baad me widget/context dispose ho jaata hai. IMPORTANT:
        // pushAndRemoveUntil ka Future sirf tab complete hota hai jab
        // MainScreen khud pop ho (practically kabhi nahi) — isliye
        // AWAIT nahi karte, varna neeche wala push kabhi chalta hi
        // nahi tha (yahi bug tha jisme kabhi kabhi seedha Home dikhta
        // tha, aur agar student phir kisi purani exam ki cached screen
        // par jaata tha to galat exam ke subjects bhi dikh jaate the).
        final navigator = Navigator.of(context);
        final examId = widget.examId;
        final examName = widget.examName;
        final examLanguageId = _selectedId!;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
        navigator.push(
          MaterialPageRoute(
            builder: (_) => CourseSubjectsScreen(
              kind: 'exam',
              courseTitle: examName.isNotEmpty ? examName : 'Subjects',
              examId: examId,
              languageId: examLanguageId,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.selectLanguage,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.selectLanguageSub,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const LanguageIllustration(size: 100),
                ],
              ),
              const SizedBox(height: 32),

              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _languages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final l = _languages[i];
                      return _buildLanguageOption(
                        id: l['_id'],
                        name: l['name'],
                        nativeName: l['nativeName'],
                        icon: l['icon'],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),
              _buildInfoBox(),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _selectedId == null ? null : _selectExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 4,
                      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.continueBtn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                      ],
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

  Widget _buildLanguageOption({
    required String id,
    required String name,
    required String nativeName,
    required String icon,
  }) {
    final isSelected = _selectedId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = id),
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
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      if (name.toLowerCase() == 'english') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                        ),
                      ],
                    ],
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
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
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

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.public_rounded, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn in Your Language',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                SizedBox(height: 3),
                Text(
                  'We provide high quality study material, explanations & support in your preferred language.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
