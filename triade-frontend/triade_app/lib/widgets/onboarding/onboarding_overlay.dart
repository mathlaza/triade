import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import 'widgets/tutorial_animations.dart';
import 'pages/welcome_page.dart';
import 'pages/create_task_page.dart';
import 'pages/delegate_task_page.dart';
import 'pages/daily_view_page.dart';
import 'pages/weekly_view_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/completion_page.dart';

/// Widget principal do tutorial onboarding
/// Exibe um overlay de tela cheia com navegação entre páginas do tutorial
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final bool showSkip;

  const OnboardingOverlay({
    super.key,
    required this.onComplete,
    this.showSkip = true,
  });

  /// Mostra o tutorial como overlay sobre o conteúdo atual
  static Future<void> show(BuildContext context, {bool markAsCompleted = true}) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return OnboardingOverlay(
            onComplete: () async {
              if (markAsCompleted) {
                await OnboardingService.markTutorialAsCompleted();
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  // Lista de páginas do tutorial
  final List<Widget> _pages = const [
    WelcomePage(),
    CreateTaskPage(),
    DelegateTaskPage(),
    DailyViewPage(),
    WeeklyViewPage(),
    DashboardPage(),
    CompletionPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeTutorial();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipTutorial() {
    _showSkipConfirmation();
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TutorialColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: TutorialColors.border),
        ),
        title: const Text(
          'Pular Tutorial?',
          style: TextStyle(
            color: TutorialColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Você pode acessar o tutorial novamente pelo menu do seu avatar.',
          style: TextStyle(
            color: TutorialColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Continuar',
              style: TextStyle(color: TutorialColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeTutorial();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TutorialColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Pular',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _completeTutorial() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background com partículas flutuantes
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFF000000),
                    Color(0xFF050505),
                  ],
                ),
              ),
              child: const FloatingParticles(
                particleCount: 20,
                color: TutorialColors.gold,
              ),
            ),
          ),

          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                // Header com skip e indicador de página
                _buildHeader(),

                // PageView com as páginas do tutorial
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: _pages,
                  ),
                ),

                // Footer com navegação
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Skip
          if (widget.showSkip && _currentPage < _pages.length - 1)
            GestureDetector(
              onTap: _skipTutorial,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: TutorialColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: TutorialColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'Pular',
                  style: TextStyle(
                    color: TutorialColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 60),

          // Indicador de página
          _buildPageIndicator(),

          // Espaço para balancear
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TutorialColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TutorialColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_currentPage + 1}',
            style: const TextStyle(
              color: TutorialColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' / ${_pages.length}',
            style: const TextStyle(
              color: TutorialColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isLastPage = _currentPage == _pages.length - 1;
    final isFirstPage = _currentPage == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicadores de página (dots)
          _buildPageDots(),
          const SizedBox(height: 24),

          // Botões de navegação
          Row(
            children: [
              // Botão Voltar
              if (!isFirstPage)
                Expanded(
                  child: GestureDetector(
                    onTap: _previousPage,
                    child: Container(
                      height: 56,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: TutorialColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: TutorialColors.border,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: TutorialColors.textSecondary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Voltar',
                            style: TextStyle(
                              color: TutorialColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Botão Próximo/Começar
              Expanded(
                flex: isFirstPage ? 1 : 1,
                child: GestureDetector(
                  onTapDown: (_) => _buttonAnimationController.forward(),
                  onTapUp: (_) {
                    _buttonAnimationController.reverse();
                    _nextPage();
                  },
                  onTapCancel: () => _buttonAnimationController.reverse(),
                  child: AnimatedBuilder(
                    animation: _buttonScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonScaleAnimation.value,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                TutorialColors.gold,
                                TutorialColors.goldDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: TutorialColors.gold.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? 'Começar' : 'Próximo',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        final isPast = index < _currentPage;

        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? TutorialColors.gold
                  : isPast
                      ? TutorialColors.gold.withValues(alpha: 0.5)
                      : TutorialColors.border,
            ),
          ),
        );
      }),
    );
  }
}
