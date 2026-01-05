import 'dart:async';
import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/services/haptic_service.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _promos = [
    {
      'color': const Color(0xFFE8F5E9), // Light Green
      'image': 'assets/images/promo_1.png', // Placeholder
      'icon': Icons.storefront_outlined,
      'title': 'Browse Experience',
      'subtitle': 'Explore our wide range of fresh produce.',
      'action': 'Start Shopping',
      'route': '/customer-browse',
    },
    {
      'color': const Color(0xFFFFF3E0), // Light Orange
      'image': 'assets/images/promo_2.png',
      'icon': Icons.people_outline,
      'title': 'Meet Our Farmers',
      'subtitle': 'Connect directly with your community growers.',
      'action': 'View Vendors',
      'route': '/customer-browse?tab=vendors',
    },
    {
      'color': const Color(0xFFE3F2FD), // Light Blue
      'image': 'assets/images/promo_3.png',
      'icon': Icons.shopping_cart_outlined,
      'title': 'Ready to Order?',
      'subtitle': 'Check out your fresh finds now.',
      'action': 'Go to Cart',
      'route': '/customer-cart',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _promos.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXS,
                ),
                child: _buildPromoCard(promo),
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        if (promo['route'] != null) {
          context.push(promo['route']);
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        decoration: BoxDecoration(
          color: promo['color'],
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background generic texture or icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                promo['icon'],
                size: 150,
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FEATURED',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        Text(
                          promo['title'],
                          style: AppTextStyles.h2.copyWith(fontSize: 20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          promo['subtitle'],
                          style: AppTextStyles.body2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                promo['action'],
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_promos.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
