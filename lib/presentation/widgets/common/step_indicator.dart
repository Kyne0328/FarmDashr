import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';

/// A premium, responsive step indicator widget to guide users through multi-step flows.
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final Color activeColor;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.activeColor = AppColors.primary,
  }) : assert(
         stepLabels.length == totalSteps,
         'stepLabels length must match totalSteps',
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                // Step circle
                final stepIndex = index ~/ 2;
                final isActive = stepIndex <= currentStep;
                final isCurrent = stepIndex == currentStep;

                return _buildStepCircle(stepIndex + 1, isActive, isCurrent);
              } else {
                // Progress line
                final lineIndex = index ~/ 2;
                final isCompleted = lineIndex < currentStep;

                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? activeColor : AppColors.border,
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stepLabels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final isActive = index <= currentStep;
              final isCurrent = index == currentStep;

              return Expanded(
                child: Text(
                  label,
                  textAlign: index == 0
                      ? TextAlign.left
                      : index == totalSteps - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  style: AppTextStyles.cardCaption.copyWith(
                    color: isCurrent
                        ? activeColor
                        : isActive
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, bool isActive, bool isCurrent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCurrent
            ? activeColor
            : isActive
            ? activeColor.withValues(alpha: 0.1)
            : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent || isActive ? activeColor : AppColors.border,
          width: 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isActive && !isCurrent
            ? Icon(Icons.check, size: 16, color: activeColor)
            : Text(
                '$stepNumber',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isCurrent ? Colors.white : AppColors.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
