import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/auth_provider.dart';
import 'package:triade_app/screens/profile_screen.dart';
import 'package:triade_app/screens/login_screen.dart';
import 'package:triade_app/screens/change_password_screen.dart';
import 'package:triade_app/screens/edit_profile_screen.dart';

/// Widget reutilizável para exibir o avatar do usuário com menu
class UserAvatarMenu extends StatelessWidget {
  final double radius;
  final Color? backgroundColor;
  final bool showBorder;
  final Color? borderColor;

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
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: showBorder
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor ?? const Color(0xFFFFD60A),
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
                    title: const Text('Sair'),
                    content: const Text('Deseja realmente sair da sua conta?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sair'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.personalName ?? 'Usuário',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '@${user?.username ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (user?.email != null)
                    Text(
                      user!.email!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Ver Perfil
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Ver Perfil'),
                ],
              ),
            ),
            // Editar Perfil
            const PopupMenuItem<String>(
              value: 'edit_profile',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Editar Perfil'),
                ],
              ),
            ),
            // Alterar Senha
            const PopupMenuItem<String>(
              value: 'change_password',
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Alterar Senha'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Sair
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Sair', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
