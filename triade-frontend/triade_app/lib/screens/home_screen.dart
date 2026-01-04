import 'package:flutter/material.dart';
import 'package:triade_app/screens/daily_view_screen.dart';
import 'package:triade_app/screens/weekly_planning_screen.dart';
import 'package:triade_app/screens/follow_up_screen.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/screens/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Keys para acessar os estados dos widgets filhos
  final GlobalKey<DailyViewScreenState> _dailyKey = GlobalKey();
  final GlobalKey<WeeklyPlanningScreenState> _weeklyKey = GlobalKey();
  final GlobalKey<FollowUpScreenState> _followUpKey = GlobalKey();
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DailyViewScreen(key: _dailyKey),
          WeeklyPlanningScreen(key: _weeklyKey),
          FollowUpScreen(key: _followUpKey),
          DashboardScreen(key: _dashboardKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex == 1 &&
              index != 1 &&
              _weeklyKey.currentState != null) {
            _weeklyKey.currentState!.onBecameInvisible();
          }
          setState(() {
            _currentIndex = index;
          });

          // ✅ Recarregar dados quando volta pra cada tela
          if (index == 0 && _dailyKey.currentState != null) {
            _dailyKey.currentState!.onBecameVisible();
          } else if (index == 1 && _weeklyKey.currentState != null) {
            _weeklyKey.currentState!.onBecameVisible();
          } else if (index == 2 && _followUpKey.currentState != null) {
            _followUpKey.currentState!.onBecameVisible();
          } else if (index == 3 && _dashboardKey.currentState != null) {
            _dashboardKey.currentState!.onBecameVisible();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Daily',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_week),
            label: 'Semanal',
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
