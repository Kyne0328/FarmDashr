import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

/// bottom-sheet time picker using CupertinoPicker style.
class FarmTimePicker {
  FarmTimePicker._();

  /// Shows a bottom sheet time picker and returns the selected time.
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    // Convert TimeOfDay to DateTime for CupertinoDatePicker
    final now = DateTime.now();
    DateTime selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TimePickerSheet(
        initialDateTime: selectedDateTime,
        onTimeChanged: (dateTime) => selectedDateTime = dateTime,
        onConfirm: () => Navigator.pop(
          context,
          TimeOfDay(
            hour: selectedDateTime.hour,
            minute: selectedDateTime.minute,
          ),
        ),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onTimeChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _TimePickerSheet({
    required this.initialDateTime,
    required this.onTimeChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
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
                  Text('Select Time', style: AppTextStyles.h4),
                  TextButton(
                    onPressed: () {
                      widget.onTimeChanged(_selectedDateTime);
                      widget.onConfirm();
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
            // Time Picker
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedDateTime,
                use24hFormat: false,
                onDateTimeChanged: (dateTime) {
                  setState(() => _selectedDateTime = dateTime);
                },
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }
}
