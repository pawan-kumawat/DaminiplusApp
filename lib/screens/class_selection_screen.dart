import 'dart:convert';
import 'package:flutter/material.dart';
import '../Helper/AppColors.dart';
import '../Helper/BoardClassSelection.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';

class ClassSelectionScreen extends StatefulWidget {
  final String languageId;
  final String boardId;
  final String boardName;

  const ClassSelectionScreen({
    super.key,
    required this.languageId,
    required this.boardId,
    this.boardName = '',
  });

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  List<Map<String, dynamic>> _classes = [];
  String? _selectedId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    final response = await APIService.getApiCaller(
      context: context,
      url: ApiUrls.getClasses(widget.boardId),
      showLoader: false,
    );
    if (response != "Error" && mounted) {
      final json = jsonDecode(response);
      final data = json['data'] as List<dynamic>? ?? [];
      setState(() {
        _classes = data
            .map<Map<String, dynamic>>(
              (e) => <String, dynamic>{
                '_id': e['_id']?.toString() ?? '',
                'name': e['name']?.toString() ?? '',
                'grade': _extractGrade(e),
                'imageUrl': e['imageUrl']?.toString(),
              },
            )
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _extractGrade(dynamic e) {
    if (e['grade'] != null) return e['grade'].toString();
    final name = e['name']?.toString() ?? '';
    final match = RegExp(r'\d+').firstMatch(name);
    return match?.group(0) ?? '';
  }

  Future<void> _selectBoardClass() async {
    if (_selectedId == null) return;
    // Ek account par multiple boards saath rehte hain (NCERT + RBSE
    // dono), aur ek hi board ke andar bhi multiple classes (e.g. CBSE
    // Class 9 + Class 10) — har (board, class) pair ki apni independent
    // enrollment/subscription hoti hai, isliye ek naya class select
    // karna doosri class ki subscription ko bilkul touch nahi karta.
    await selectBoardClassAndEnter(
      context,
      boardId: widget.boardId,
      boardName: widget.boardName,
      classId: _selectedId!,
      languageId: widget.languageId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = _classes.where((c) {
      final g = int.tryParse(c['grade'] as String? ?? '') ?? 0;
      return g >= 1 && g <= 5;
    }).toList();
    final middle = _classes.where((c) {
      final g = int.tryParse(c['grade'] as String? ?? '') ?? 0;
      return g >= 6 && g <= 8;
    }).toList();
    final high = _classes.where((c) {
      final g = int.tryParse(c['grade'] as String? ?? '') ?? 0;
      return g >= 9;
    }).toList();
    final ungrouped = _classes.where((c) {
      final g = int.tryParse(c['grade'] as String? ?? '');
      return g == null || g == 0;
    }).toList();

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Select Class',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the class you are currently studying in.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (ungrouped.isNotEmpty) ...[
                      _buildClassGrid(ungrouped),
                      const SizedBox(height: 32),
                    ],
                    if (primary.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'Primary School',
                        badge: 'Grades 1–5',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildClassGrid(primary),
                      const SizedBox(height: 32),
                    ],
                    if (middle.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'Middle School',
                        badge: 'Grades 6–8',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildClassGrid(middle),
                      const SizedBox(height: 32),
                    ],
                    if (high.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'High School',
                        badge: 'Grades 9–12',
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      _buildClassGrid(high),
                    ],
                    if (_classes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No classes available.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24.0),
        color: AppColors.backgroundColor,
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _selectedId == null ? null : _selectBoardClass,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String badge,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassGrid(List<Map<String, dynamic>> classes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: classes.length,
      itemBuilder: (_, i) {
        final cls = classes[i];
        final isSelected = _selectedId == (cls['_id'] as String?);
        final grade = cls['grade'] as String? ?? '';
        final label = grade.isNotEmpty ? grade : (cls['name'] as String? ?? '');
        final imageUrl = cls['imageUrl'] as String?;
        return GestureDetector(
          onTap: () => setState(() => _selectedId = cls['_id'] as String?),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 32, height: 32),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: label.length > 3 ? 14 : 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.navy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Class',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
