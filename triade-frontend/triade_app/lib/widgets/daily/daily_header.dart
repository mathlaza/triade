import 'package:flutter/material.dart';
import 'package:triade_app/widgets/user_avatar_menu.dart';

/// Header do Daily View com logo e avatar
/// EXTRAÍDO SEM ALTERAÇÕES do daily_view_screen.dart
class DailyHeader extends StatelessWidget {
  const DailyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF38383A).withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: const Row(
        children: [
          // Espaço vazio à esquerda (mesmo tamanho do ícone direito)
          SizedBox(
              width: 42), // 8 padding + 18 icon + 8 padding + 8 extra
          // Centro expandido
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SizedBox(width: 10),
                Text(
                  'Daily View',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFFFD60A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Avatar do usuário à direita
          UserAvatarMenu(
            radius: 20,
            backgroundColor: Color(0xFF2C2C2E),
            showBorder: true,
            borderColor: Color(0xFFFFD60A),
          ),
        ],
      ),
    );
  }
}
