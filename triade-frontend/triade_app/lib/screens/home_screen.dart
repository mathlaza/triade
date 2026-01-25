import 'package:flutter/material.dart';
import 'package:triade_app/screens/daily_view_screen.dart';
import 'package:triade_app/screens/weekly_planning_screen.dart';
import 'package:triade_app/screens/follow_up_screen.dart';
import 'package:triade_app/screens/dashboard_screen.dart';
import 'package:triade_app/config/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final GlobalKey<DailyViewScreenState> _dailyKey = GlobalKey();
  final GlobalKey<WeeklyPlanningScreenState> _weeklyKey = GlobalKey();
  final GlobalKey<FollowUpScreenState> _followUpKey = GlobalKey();
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();

  // ✅ PageStorageBucket para manter estado de scroll
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DailyViewScreen(key: _dailyKey),
            WeeklyPlanningScreen(key: _weeklyKey),
            FollowUpScreen(key: _followUpKey),
            DashboardScreen(key: _dashboardKey),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // ✅ Só recarrega se mudou de aba (evita recarregar ao clicar na mesma aba)
          if (index == _currentIndex) return;
          
          setState(() {
            _currentIndex = index;
          });

          // ✅ Recarregar dados apenas quando volta para a tela
          _notifyScreenVisible(index);
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

  // ✅ Método separado para notificar tela visível
  void _notifyScreenVisible(int index) {
    switch (index) {
      case 0:
        _dailyKey.currentState?.onBecameVisible();
        break;
      case 1:
        _weeklyKey.currentState?.onBecameVisible();
        break;
      case 2:
        _followUpKey.currentState?.onBecameVisible();
        break;
      case 3:
        _dashboardKey.currentState?.onBecameVisible();
        break;
    }
  }
}