import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Navigator',
      theme: ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF6200EA),
  scaffoldBackgroundColor: const Color(0xFF0A0F2A),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF7C4DFF),
    secondary: Color(0xFFB47CFF),
    surface: Color(0xFF12163A),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F142E),
    elevation: 0,
    centerTitle: true,
  ),
),
      home: const CampusNavigationScreen(),
    );
  }
}

class CampusNavigationScreen extends StatefulWidget {
  const CampusNavigationScreen({super.key});

  @override
  State<CampusNavigationScreen> createState() => _CampusNavigationScreenState();
}

class _CampusNavigationScreenState extends State<CampusNavigationScreen> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(title: 'Навигация по кампусу', icon: Icons.map),
    NavigationItem(title: 'Выбор места для еды', icon: Icons.restaurant_menu),
    NavigationItem(title: 'Зоны питания', icon: Icons.food_bank),
    NavigationItem(title: 'Оценка заведения', icon: Icons.star_rate),
    NavigationItem(title: 'Маршрут покупки еды', icon: Icons.route),
    NavigationItem(title: 'Поиск места для учебы', icon: Icons.search),
  ];

  final List<Widget> _screens = const [
    EmptyScreen(),
    EmptyScreen(),
    EmptyScreen(),
    EmptyScreen(),
    EmptyScreen(),
    EmptyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_currentIndex].title),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildScrollableBottomNavBar(),
    );
  }

  Widget _buildScrollableBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F142E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildNavBarItem(
                  icon: item.icon,
                  title: item.title,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF7C4DFF).withOpacity(0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFB47CFF) : const Color(0xFF6A6A8B),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFFB47CFF) : const Color(0xFF9A9AB0),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0F2A),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;

  const NavigationItem({
    required this.title,
    required this.icon,
  });
}