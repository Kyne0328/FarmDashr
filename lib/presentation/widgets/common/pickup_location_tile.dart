import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';

class PickupLocationTile extends StatelessWidget {
  final PickupLocation location;
  final bool isSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool?>? onSelectionChanged;
  final bool isSelectionMode;

  const PickupLocationTile({
    super.key,
    required this.location,
    this.isSelected = false,
    this.onEdit,
    this.onDelete,
    this.onSelectionChanged,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: isSelectionMode && isSelected
            ? AppColors.farmerPrimaryLight.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isSelectionMode && isSelected
              ? AppColors.farmerPrimary
              : AppColors.border,
          width: isSelectionMode && isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isSelectionMode && onSelectionChanged != null
            ? () => onSelectionChanged!(!isSelected)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelectionMode) ...[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onSelectionChanged,
                      activeColor: AppColors.farmerPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                ],
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.farmerPrimaryLight.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.farmerPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location.address,
                        style: AppTextStyles.body2Secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isSelectionMode) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  if (onEdit != null)
                    _buildIconButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.textSecondary,
                      onPressed: onEdit!,
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    _buildIconButton(
                      icon: Icons.delete_outline,
                      color: AppColors.error,
                      onPressed: onDelete!,
                    ),
                  ],
                ],
              ],
            ),
            if (location.notes.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        location.notes,
                        style: AppTextStyles.caption.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (location.availableWindows.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingM),
              if (!isSelectionMode && location.notes.isNotEmpty)
                const Divider(height: 1), // Separator if notes exist
              if (isSelectionMode || location.notes.isEmpty)
                // Use a different spacing/visual if notes are present/absent
                const SizedBox(height: 0)
              else
                const SizedBox(height: AppDimensions.spacingM),

              if (isSelectionMode) const SizedBox(height: 4),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _groupWindows(location.availableWindows).map((text) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.farmerPrimaryLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.farmerPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          text,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.farmerPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  List<String> _groupWindows(List<PickupWindow> windows) {
    if (windows.isEmpty) return [];

    // Sort by dayOfWeek
    final sortedWindows = List<PickupWindow>.from(windows)
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    final results = <String>[];
    if (sortedWindows.isEmpty) return results;

    var startDay = sortedWindows[0].dayOfWeek;
    var lastDay = startDay;
    var currentTimeRange = sortedWindows[0].formattedTimeRange;

    for (var i = 1; i < sortedWindows.length; i++) {
      final w = sortedWindows[i];
      if (w.dayOfWeek == lastDay + 1 &&
          w.formattedTimeRange == currentTimeRange) {
        lastDay = w.dayOfWeek;
      } else {
        results.add('${_formatDayRange(startDay, lastDay)}: $currentTimeRange');
        startDay = w.dayOfWeek;
        lastDay = startDay;
        currentTimeRange = w.formattedTimeRange;
      }
    }
    results.add('${_formatDayRange(startDay, lastDay)}: $currentTimeRange');

    return results;
  }

  String _formatDayRange(int start, int end) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (start == end) return days[start - 1];
    if (end == start + 1) return '${days[start - 1]}, ${days[end - 1]}';
    return '${days[start - 1]} - ${days[end - 1]}';
  }
}
