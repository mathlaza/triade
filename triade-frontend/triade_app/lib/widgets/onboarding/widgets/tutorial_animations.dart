import 'package:flutter/material.dart';
import 'dart:math' as math;

// =====================================================================
// CONSTANTES DE DESIGN - Premium Dark Theme
// =====================================================================
class TutorialColors {
  TutorialColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color card = Color(0xFF2C2C2E);
  static const Color border = Color(0xFF38383A);
  static const Color gold = Color(0xFFFFD60A);
  static const Color goldDark = Color(0xFFFFA500);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color highEnergy = Color(0xFFE53935);
  static const Color renewal = Color(0xFF43A047);
  static const Color lowEnergy = Color(0xFF757575);
  static const Color overlay = Color(0xCC000000);
}

// =====================================================================
// PULSING HIGHLIGHT - Efeito de pulsação para destacar elementos
// =====================================================================
class PulsingHighlight extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final bool showGlow;
  final double glowRadius;

  const PulsingHighlight({
    super.key,
    required this.child,
    this.color = TutorialColors.gold,
    this.minScale = 1.0,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1200),
    this.showGlow = true,
    this.glowRadius = 20,
  });

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: widget.showGlow
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: _glowAnimation.value),
                        blurRadius: widget.glowRadius,
                        spreadRadius: 4,
                      ),
                    ],
                  )
                : null,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// =====================================================================
// SPOTLIGHT PAINTER - Overlay com recorte circular/retangular
// =====================================================================
class SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;
  final double borderRadius;
  final Color overlayColor;
  final double spotlightPadding;

  SpotlightPainter({
    this.spotlightRect,
    this.borderRadius = 16,
    this.overlayColor = TutorialColors.overlay,
    this.spotlightPadding = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // Desenha o overlay escuro em toda a tela
    final fullScreen = Rect.fromLTWH(0, 0, size.width, size.height);
    
    if (spotlightRect != null) {
      // Expande o retângulo de spotlight com padding
      final expandedRect = Rect.fromLTRB(
        spotlightRect!.left - spotlightPadding,
        spotlightRect!.top - spotlightPadding,
        spotlightRect!.right + spotlightPadding,
        spotlightRect!.bottom + spotlightPadding,
      );

      // Cria o path com recorte
      final path = Path()
        ..addRect(fullScreen)
        ..addRRect(RRect.fromRectAndRadius(
          expandedRect,
          Radius.circular(borderRadius),
        ));
      path.fillType = PathFillType.evenOdd;

      canvas.drawPath(path, paint);

      // Desenha borda dourada ao redor do spotlight
      final borderPaint = Paint()
        ..color = TutorialColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          expandedRect,
          Radius.circular(borderRadius),
        ),
        borderPaint,
      );
    } else {
      canvas.drawRect(fullScreen, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return spotlightRect != oldDelegate.spotlightRect;
  }
}

// =====================================================================
// ANIMATED ARROW - Seta animada para indicar direção
// =====================================================================
class AnimatedArrow extends StatefulWidget {
  final AxisDirection direction;
  final Color color;
  final double size;

  const AnimatedArrow({
    super.key,
    this.direction = AxisDirection.down,
    this.color = TutorialColors.gold,
    this.size = 32,
  });

  @override
  State<AnimatedArrow> createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<AnimatedArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        double dx = 0, dy = 0;
        double rotation = 0;

        switch (widget.direction) {
          case AxisDirection.down:
            dy = _bounceAnimation.value;
            rotation = 0;
            break;
          case AxisDirection.up:
            dy = -_bounceAnimation.value;
            rotation = math.pi;
            break;
          case AxisDirection.right:
            dx = _bounceAnimation.value;
            rotation = -math.pi / 2;
            break;
          case AxisDirection.left:
            dx = -_bounceAnimation.value;
            rotation = math.pi / 2;
            break;
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotation,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
// TYPING TEXT - Texto com efeito de digitação
// =====================================================================
class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;

  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 30),
    this.onComplete,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayedText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    while (_charIndex < widget.text.length && mounted) {
      await Future.delayed(widget.charDuration);
      if (mounted) {
        setState(() {
          _charIndex++;
          _displayedText = widget.text.substring(0, _charIndex);
        });
      }
    }
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style ?? const TextStyle(
        color: TutorialColors.textPrimary,
        fontSize: 16,
      ),
    );
  }
}

// =====================================================================
// FADE SLIDE WIDGET - Widget com animação de fade + slide
// =====================================================================
class FadeSlideWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const FadeSlideWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.slideOffset = const Offset(0, 30),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideWidget> createState() => _FadeSlideWidgetState();
}

class _FadeSlideWidgetState extends State<FadeSlideWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// =====================================================================
// SHIMMER EFFECT - Efeito de brilho passando
// =====================================================================
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color shimmerColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.shimmerColor = TutorialColors.gold,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                widget.shimmerColor.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

// =====================================================================
// GRADIENT BORDER - Borda com gradiente animado
// =====================================================================
class GradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final List<Color> colors;
  final Duration duration;

  const GradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.borderRadius = 16,
    this.colors = const [TutorialColors.gold, TutorialColors.goldDark],
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<GradientBorder> createState() => _GradientBorderState();
}

class _GradientBorderState extends State<GradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              startAngle: _controller.value * 2 * math.pi,
              colors: [...widget.colors, widget.colors.first],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              decoration: BoxDecoration(
                color: TutorialColors.surface,
                borderRadius: BorderRadius.circular(
                  widget.borderRadius - widget.borderWidth,
                ),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
// FLOATING PARTICLES - Partículas flutuantes de fundo
// =====================================================================
class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color color;

  const FloatingParticles({
    super.key,
    this.particleCount = 15,
    this.color = TutorialColors.gold,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 4 + 2,
        speed: math.Random().nextDouble() * 0.3 + 0.1,
        opacity: math.Random().nextDouble() * 0.5 + 0.2,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) % 1.0;
      final x = particle.x + math.sin(progress * 2 * math.pi + particle.y * 10) * 0.02;

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
