import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/auth_provider.dart';
import 'package:triade_app/screens/profile_screen.dart';
import 'package:triade_app/screens/login_screen.dart';
import 'package:triade_app/screens/change_password_screen.dart';
import 'package:triade_app/screens/edit_profile_screen.dart';
import 'package:triade_app/screens/follow_up_screen.dart';
import 'package:triade_app/widgets/onboarding/onboarding_overlay.dart';

/// Widget reutilizável para exibir o avatar do usuário com menu
class UserAvatarMenu extends StatelessWidget {
  final double radius;
  final Color? backgroundColor;
  final bool showBorder;
  final Color? borderColor;

  // Constantes de design - Dark Premium Theme
  static const Color _surfaceColor = Color(0xFF1C1C1E);
  static const Color _cardColor = Color(0xFF2C2C2E);
  static const Color _borderColor = Color(0xFF38383A);
  static const Color _accentGold = Color(0xFFFFD60A);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF8E8E93);
  static const Color _errorRed = Color(0xFFFF453A);

  const UserAvatarMenu({
    super.key,
    this.radius = 20,
    this.backgroundColor,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final initial = user?.personalName.isNotEmpty == true
            ? user!.personalName.substring(0, 1).toUpperCase()
            : 'U';

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          color: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _borderColor, width: 1),
          ),
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          child: Container(
            decoration: showBorder
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor ?? _accentGold,
                      width: 2,
                    ),
                  )
                : null,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
              child: authProvider.user?.hasPhoto == true
                  ? ClipOval(
                      child: Image.network(
                        authProvider.profilePhotoUrl ?? '',
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          initial,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: radius * 0.8,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: radius * 0.8,
                      ),
                    ),
            ),
          ),
          onSelected: (value) async {
            HapticFeedback.lightImpact();
            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                break;
              case 'edit_profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                break;
              case 'delegated_tasks':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FollowUpScreen()),
                );
                break;
              case 'tutorial':
                // Mostra o tutorial novamente (sem marcar como visto novamente)
                OnboardingOverlay.show(context, markAsCompleted: false);
                break;
              case 'change_password':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
                break;
              case 'logout':
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: _surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: _borderColor),
                    ),
                    title: const Text('Sair', style: TextStyle(color: _textPrimary)),
                    content: const Text(
                      'Deseja realmente sair da sua conta?',
                      style: TextStyle(color: _textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar', style: TextStyle(color: _textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _errorRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
                break;
            }
          },
          itemBuilder: (context) => [
            // Header do menu com info do usuário
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar pequeno com borda dourada
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_accentGold, Color(0xFFFFA500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: _cardColor,
                      child: authProvider.user?.hasPhoto == true
                          ? ClipOval(
                              child: Image.network(
                                authProvider.profilePhotoUrl ?? '',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  initial,
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              initial,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nome e username
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.personalName ?? 'Usuário',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user?.username ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            // Ver Perfil
            _buildMenuItem(
              value: 'profile',
              icon: Icons.person_outline_rounded,
              label: 'Ver Perfil',
            ),
            // Editar Perfil
            _buildMenuItem(
              value: 'edit_profile',
              icon: Icons.edit_outlined,
              label: 'Editar Perfil',
            ),
            // Tarefas Delegadas - destacado
            _buildMenuItem(
              value: 'delegated_tasks',
              icon: Icons.people_outline_rounded,
              label: 'Tarefas Delegadas',
              isHighlighted: true,
            ),
            // Alterar Senha
            _buildMenuItem(
              value: 'change_password',
              icon: Icons.lock_outline_rounded,
              label: 'Alterar Senha',
            ),
            // Tutorial
            _buildMenuItem(
              value: 'tutorial',
              icon: Icons.school_outlined,
              label: 'Tutorial',
            ),
            const PopupMenuDivider(height: 1),
            // Sair
            _buildMenuItem(
              value: 'logout',
              icon: Icons.logout_rounded,
              label: 'Sair',
              isDestructive: true,
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    bool isHighlighted = false,
    bool isDestructive = false,
  }) {
    Color iconColor = _textSecondary;
    Color textColor = _textPrimary;

    if (isHighlighted) {
      iconColor = _accentGold;
      textColor = _accentGold;
    } else if (isDestructive) {
      iconColor = _errorRed;
      textColor = _errorRed;
    }

    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
