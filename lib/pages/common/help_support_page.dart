import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
              Text('General FAQs', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _buildFaqItem(
                'What is FarmDashr?',
                'FarmDashr is a platform that connects local farmers directly with consumers, ensuring fresh produce and fair prices.',
              ),
              _buildFaqItem(
                'Is FarmDashr free?',
                'Yes, our platform is currently free for both customers and farmers to help support local agriculture.',
              ),
              const SizedBox(height: 24),
              Text('Customer FAQs', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _buildFaqItem(
                'How do I place an order?',
                'Browse through local farmers, select the products you want, add them to your cart, and proceed to checkout.',
              ),
              _buildFaqItem(
                'How do I track my order?',
                'You can monitor your order\'s progress in the "Orders" tab. Statuses include: Pending (waiting for farmer), Preparing (farmer is harvesting/packing), Ready (prepared and waiting for you), and Completed.',
              ),
              _buildFaqItem(
                'Can I cancel an order?',
                'You can cancel an order as long as it is still in "Pending" status. Once a farmer marks an order as "Ready", it is considered committed to protect our farmers from wasted produce.',
              ),
              _buildFaqItem(
                'What happens if I miss my pickup?',
                'Our farmers prepare fresh goods specifically for your order. If you can\'t make it, please try to contact the farmer through their business details. Repeated "no-shows" may result in account restrictions.',
              ),
              _buildFaqItem(
                'How do I pay for my items?',
                'Payments are handled directly between you and the farmer at the time of pickup, or according to their specified payment methods.',
              ),
              const SizedBox(height: 24),
              Text('Farmer FAQs', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _buildFaqItem(
                'How do I start selling?',
                'Switch to a Farmer profile in your settings, complete the onboarding process, and start listing your inventory.',
              ),
              _buildFaqItem(
                'How do I manage my farm info?',
                'Go to Profile > Farmer Settings > Business Info to update your farm\'s name, description, and pickup locations.',
              ),
              _buildFaqItem(
                'What if a customer doesn\'t show up?',
                'If a customer misses their pickup, the order remains in your list. We are working on features to help you flag no-shows and protect your hard work.',
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
                      'assets/app_icon_foreground.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.eco,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version ?? '1.0.0';
                        return Text(
                          'FarmDashr v$version',
                          style: AppTextStyles.body2Secondary,
                        );
                      },
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
                    'Source code, and documentation',
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
