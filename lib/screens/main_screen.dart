import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Helper/AppColors.dart';
import '../Helper/AppAlert.dart';
import '../Helper/AppLocalizations.dart';
import 'home_screen.dart';
import 'other_courses_list_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'library_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _switchTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  List<Widget> get _screens => [
    HomeScreen(onNavigateTab: _switchTab),
    OtherCoursesListScreen(onNavigateTab: _switchTab),
    ProfileScreen(onNavigateTab: _switchTab),
    LibraryScreen(onNavigateTab: _switchTab),
    SettingsScreen(onNavigateTab: _switchTab),
  ];

  static const List<_NavItemData> _navItems = [
    _NavItemData(Icons.home_outlined, Icons.home, 'Home'),
    _NavItemData(Icons.school_outlined, Icons.school, 'Other Courses'),
    _NavItemData(
      Icons.play_circle_fill_outlined,
      Icons.play_circle_fill,
      'My Course',
    ),
    _NavItemData(Icons.menu_book_outlined, Icons.menu_book, 'Library'),
    _NavItemData(Icons.person_2_outlined, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          ShowAlert.showAlertWith2Buttons(
            context,
            "क्या आप ऐप बंद करना चाहते हैं?",
            "No",
            () => Navigator.of(context).pop(),
            "Yes",
            () => SystemNavigator.pop(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: _BottomNavBar(
          items: _navItems,
          selectedIndex: _selectedIndex,
          onTap: _switchTab,
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData(this.icon, this.activeIcon, this.label);
}

class _BottomNavBar extends StatelessWidget {
  final List<_NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _NavItem(
                  data: items[index],
                  isSelected: selectedIndex == index,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: isSelected ? 1.12 : 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Icon(
                isSelected ? data.activeIcon : data.icon,
                color: isSelected
                    ? AppColors.primaryBlue
                    : const Color(0xFF9AA1AC),
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryBlue
                    : const Color(0xFF9AA1AC),
              ),
              child: Text(AppLocalizations.of(context).text(data.label)),
            ),
          ],
        ),
      ),
    );
  }
}
