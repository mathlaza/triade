import 'package:flutter/material.dart';
import 'package:triade_app/screens/daily_view_screen.dart';
import 'package:triade_app/screens/follow_up_screen.dart';
import 'package:triade_app/config/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Keys para acessar os estados dos widgets filhos
  final GlobalKey<DailyViewScreenState> _dailyKey = GlobalKey();
  final GlobalKey<FollowUpScreenState> _followUpKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DailyViewScreen(key: _dailyKey),
          FollowUpScreen(key: _followUpKey),
          const Center(child: Text('Dashboard em breve')), // Placeholder
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1 && _followUpKey.currentState != null) {
            _followUpKey.currentState!.onBecameVisible();
          }
        },
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Daily View',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Follow-up',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
