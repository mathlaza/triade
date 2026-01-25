import 'package:flutter/material.dart';
import 'package:triade_app/config/constants.dart';

// Premium Dark Theme Colors
const _kSurfaceColor = Color(0xFF1C1C1E);
const _kCardColor = Color(0xFF2C2C2E);
const _kBorderColor = Color(0xFF38383A);
const _kGoldAccent = Color(0xFFFFD60A);
const _kTextSecondary = Color(0xFF8E8E93);

/// Barra de filtros por contexto
class ContextFiltersBar extends StatelessWidget {
  final String? selectedContext;
  final ValueChanged<String?> onContextSelected;

  const ContextFiltersBar({
    super.key,
    required this.selectedContext,
    required this.onContextSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allContexts = ContextColors.colors.keys.toList();
    
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: _kSurfaceColor,
        border: Border(
          bottom: BorderSide(color: _kBorderColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allContexts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAllContextChip();
          }
          final contextTag = allContexts[index - 1];
          return _buildContextChip(contextTag);
        },
      ),
    );
  }

  Widget _buildAllContextChip() {
    final isSelected = selectedContext == null;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => onContextSelected(null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _kGoldAccent : _kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _kGoldAccent : _kBorderColor,
            ),
          ),
          child: Text(
            'Todos',
            style: TextStyle(
              color: isSelected ? Colors.black : _kTextSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextChip(String contextTag) {
    final isSelected = selectedContext == contextTag;
    final color = ContextColors.getColor(contextTag);
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => onContextSelected(isSelected ? null : contextTag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : _kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : _kBorderColor,
            ),
          ),
          child: Text(
            contextTag,
            style: TextStyle(
              color: isSelected ? color : _kTextSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
