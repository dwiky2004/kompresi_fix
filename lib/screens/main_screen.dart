import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';
import '../core/theme/theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 800 ? 800 : double.infinity,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                activeIcon: Icon(Icons.info),
                label: 'Tentang',
              ),
            ],
          ),
        );
      },
    );
  }
}
