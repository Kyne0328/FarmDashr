import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color borderColor;
  final String svgPath;
  final Color iconColor;
  final VoidCallback onTap;

  const RoleSelectionCard({
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.svgPath,
    required this.iconColor,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              svgPath,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101727),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF697282),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF495565)),
          onPressed: () {
            context.go('/');
            debugPrint("Back tapped");
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Choose Your Role',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF101727),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Select how you'd like to use Fresh Market",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF697282),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                RoleSelectionCard(
                  title: "I'm a Farmer",
                  subtitle: "Sell your produce and manage inventory",
                  borderColor: const Color(0xFFA4F3CF),
                  svgPath: 'assets/leaf_icon.svg',
                  iconColor: Colors.green,
                  onTap: () => context.push('/farmer-login'),
                ),

                const SizedBox(height: 16),

                RoleSelectionCard(
                  title: "I'm a Customer",
                  subtitle: "Browse and pre-order fresh local products",
                  borderColor: const Color(0xFFBDDAFF),
                  svgPath: 'assets/blue_basket_icon.svg',
                  iconColor: Colors.blue,
                  onTap: () => context.push('/customer-login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
