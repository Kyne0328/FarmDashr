import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';

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
              // Skip button (only on first two pages)
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
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 72), // Maintain spacing
              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    // Page 1: Welcome
                    _buildPage(
                      imageAsset: 'assets/app_icon_foreground.png',
                      isAppIcon: true,
                      title: 'Fresh Market',
                      subtitle: 'Connecting local farmers with community',
                      description:
                          'Experience the freshest produce directly from your local farmers.',
                    ),

                    // Page 2: Values (Pre-order & Pickup)
                    _buildPage(
                      imageAsset: 'assets/leaf_icon.svg',
                      title: 'Pre-order & Pickup',
                      subtitle: 'Sustainable & Convenient',
                      description:
                          'Browse inventory, place pre-orders, and pick up fresh produce at convenient local spots.',
                    ),

                    // Page 3: Notifications
                    _buildPage(
                      imageAsset:
                          'assets/bell_icon.png', // Fallback or use Icon
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
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Main Action Button
                    if (_currentPage < 2)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusL,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Enable Notifications Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _requestNotifications,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusL,
                                  ),
                                ),
                              ),
                              child: const Text('Enable Notifications'),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          // Get Started Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _finishOnboarding,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusL,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
          // Image/Icon Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: isAppIcon
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Image.asset(imageAsset!, fit: BoxFit.contain),
                    )
                  : iconData != null
                  ? Icon(iconData, size: 48, color: AppColors.primary)
                  : Padding(
                      padding: const EdgeInsets.all(32),
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

          // Text Content
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gradientLight,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
