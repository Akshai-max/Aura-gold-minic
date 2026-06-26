import 'package:flutter/material.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/features/user_dashboard/domain/metal_history.dart';

class MetalHistoryRangeSelector extends StatelessWidget {
  final MetalHistoryRange selected;
  final ValueChanged<MetalHistoryRange> onChanged;
  final Color selectedColor;

  const MetalHistoryRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.selectedColor = AppTheme.primaryGold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MetalHistoryRange.selectable.map((range) {
        final isSelected = range == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TextButton(
              onPressed: () => onChanged(range),
              style: TextButton.styleFrom(
                backgroundColor: isSelected
                    ? selectedColor.withValues(alpha: 0.2)
                    : null,
                foregroundColor: isSelected ? selectedColor : null,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
              child: Text(
                range.apiValue,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
