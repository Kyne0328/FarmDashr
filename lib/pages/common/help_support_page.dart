import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://github.com/Kyne0328/FarmDashr');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frequently Asked Questions', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              _buildFaqItem(
                'How do I track my order?',
                'Go to the "Orders" tab to view the status of your current and past orders.',
              ),
              _buildFaqItem(
                'Can I cancel an order?',
                'You can cancel an order as long as it hasn\'t been packed or shipped by the farmer.',
              ),
              _buildFaqItem(
                'How do I become a farmer?',
                'Go to your profile and tap on "Switch to Farmer" to start the onboarding process.',
              ),
              _buildFaqItem(
                'Is payment secure?',
                'Yes, we use secure payment processing to ensure your data is safe.',
              ),
              const SizedBox(height: 32),
              Text('Contact Us', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              _buildGitHubCard(),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/app_icon.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.eco,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FarmDashr v1.0.0',
                      style: AppTextStyles.body2Secondary,
                    ),
                    const SizedBox(height: 4),
                    Text('© 2026 FarmDashr', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGitHubCard() {
    return InkWell(
      onTap: _launchUrl,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.code, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Project on GitHub',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Source code, issues, and documentation',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
