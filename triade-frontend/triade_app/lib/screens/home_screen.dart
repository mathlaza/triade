import 'package:flutter/material.dart';
import 'package:triade_app/screens/daily_view_screen.dart';
import 'package:triade_app/screens/weekly_planning_screen.dart';
import 'package:triade_app/screens/dashboard_screen.dart';
import 'package:triade_app/services/onboarding_service.dart';
import 'package:triade_app/widgets/onboarding/onboarding_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final GlobalKey<DailyViewScreenState> _dailyKey = GlobalKey();
  final GlobalKey<WeeklyPlanningScreenState> _weeklyKey = GlobalKey();
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();

  // ✅ PageStorageBucket para manter estado de scroll
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    // ✅ Verificar se deve mostrar tutorial no primeiro login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();
    });
  }

  /// Verifica se é a primeira vez do usuário e mostra o tutorial
  Future<void> _checkFirstTimeUser() async {
    final shouldShow = await OnboardingService.shouldShowTutorialOnLogin();
    if (shouldShow && mounted) {
      // Pequeno delay para garantir que a tela está carregada
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        OnboardingOverlay.show(context);
      }
    }
  }

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
            DashboardScreen(key: _dashboardKey),
          ],
        ),
      ),
      bottomNavigationBar: _buildPremiumNavigationBar(),
    );
  }

  Widget _buildPremiumNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF38383A).withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.today_outlined,
                activeIcon: Icons.today_rounded,
                label: 'Daily',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.view_week_outlined,
                activeIcon: Icons.view_week_rounded,
                label: 'Semanal',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: 'Dashboard',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (index == _currentIndex) return;
        
        setState(() {
          _currentIndex = index;
        });
        _notifyScreenVisible(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFD60A),
                    Color(0xFFFFA500),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF000000)
                  : const Color(0xFF8E8E93),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ],
        ),
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
        _dashboardKey.currentState?.onBecameVisible();
        break;
    }
  }
}