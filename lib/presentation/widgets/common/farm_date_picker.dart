import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

/// bottom-sheet date picker using CupertinoPicker style.
class FarmDatePicker {
  FarmDatePicker._();

  /// Shows a bottom sheet date picker and returns the selected date.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    bool Function(DateTime)? selectableDayPredicate,
  }) async {
    DateTime selectedDate = initialDate;

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: selectableDayPredicate,
        onDateChanged: (date) => selectedDate = date,
        onConfirm: () => Navigator.pop(context, selectedDate),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

class _DatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool Function(DateTime)? selectableDayPredicate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.selectableDayPredicate,
    required this.onDateChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  bool _isDateSelectable(DateTime date) {
    if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) {
      return false;
    }
    if (widget.selectableDayPredicate != null) {
      return widget.selectableDayPredicate!(date);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text('Select Date', style: AppTextStyles.h4),
                  TextButton(
                    onPressed: () {
                      if (_isDateSelectable(_selectedDate)) {
                        widget.onDateChanged(_selectedDate);
                        widget.onConfirm();
                      }
                    },
                    child: Text(
                      'Confirm',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Date Picker
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: widget.firstDate,
                maximumDate: widget.lastDate,
                onDateTimeChanged: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
            ),
            // Warning if not selectable
            if (!_isDateSelectable(_selectedDate))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'This date is not available for pickup',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warningDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }
}
