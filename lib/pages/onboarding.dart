import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';

class FreshMarketOnboarding extends StatefulWidget {
  const FreshMarketOnboarding({super.key});

  @override
  State<FreshMarketOnboarding> createState() => _FreshMarketOnboardingState();
}

class _FreshMarketOnboardingState extends State<FreshMarketOnboarding> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _finishOnboarding() async {
    // Navigate to login
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              if (_currentPage < 2)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 72),

              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildPage(
                      imageAsset: 'assets/app_icon_foreground.png',
                      isAppIcon: true,
                      title: 'FarmDashR',
                      subtitle: 'Connecting local farmers with community',
                      description:
                          'Experience the freshest produce directly from your local farmers.',
                    ),
                    _buildPage(
                      imageAsset: 'assets/leaf_icon.svg',
                      title: 'Pre-order & Pickup',
                      subtitle: 'Sustainable & Convenient',
                      description:
                          'Browse inventory, place pre-orders, and pick up fresh produce at convenient local spots.',
                    ),
                    _buildPage(
                      imageAsset: 'assets/bell_icon.png',
                      iconData: Icons.notifications_active_outlined,
                      title: 'Stay Updated',
                      subtitle: 'Never miss an order',
                      description:
                          'Get real-time updates on your order status and pickup reminders.',
                    ),
                  ],
                ),
              ),

              // Bottom Section
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                child: Column(
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusS,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Main Action Buttons
                    // Main Action Buttons
                    if (_currentPage < 2)
                      SizedBox(
                        width: double.infinity,
                        child: FarmButton(
                          label: 'Next',
                          onPressed: _nextPage,
                          style: FarmButtonStyle.primary,
                          // Override to match the specific white-on-gradient design
                          backgroundColor: Colors.white,
                          textColor: AppColors.primary,
                          isFullWidth: true,
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FarmButton(
                              label: 'Enable Notifications',
                              onPressed: _requestNotifications,
                              style: FarmButtonStyle.outline,
                              // Override for white outline on gradient
                              borderColor: Colors.white,
                              textColor: Colors.white,
                              isFullWidth: true,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          SizedBox(
                            width: double.infinity,
                            child: FarmButton(
                              label: 'Get Started',
                              onPressed: _finishOnboarding,
                              style: FarmButtonStyle.primary,
                              backgroundColor: Colors.white,
                              textColor: AppColors.primary,
                              isFullWidth: true,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    String? imageAsset,
    IconData? iconData,
    bool isAppIcon = false,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isAppIcon
                  ? Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
                      child: Image.asset(imageAsset!, fit: BoxFit.contain),
                    )
                  : iconData != null
                  ? Icon(
                      iconData,
                      size: AppDimensions.iconXL,
                      color: AppColors.primary,
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingXXL),
                      child: SvgPicture.asset(
                        imageAsset!,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXL),

          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.gradientLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
