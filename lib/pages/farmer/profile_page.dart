import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 16),

                    // Profile Card
                    _buildProfileCard(),
                    const SizedBox(height: 16),

                    // Stats Row
                    _buildStatsRow(),
                    const SizedBox(height: 16),

                    // Business Information Card
                    _buildBusinessInfoCard(),
                    const SizedBox(height: 16),

                    // Logout Button
                    _buildLogoutButton(context),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNavigationBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Profile',
      style: TextStyle(
        color: Color(0xFF101727),
        fontSize: 16,
        fontFamily: 'Arimo',
        fontWeight: FontWeight.w400,
        height: 1.50,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header with Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFD0FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 40, color: Color(0xFF009966)),
                ),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'you',
                      style: TextStyle(
                        color: Color(0xFF101727),
                        fontSize: 16,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'you@example.com',
                      style: TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 14,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Farmer Account Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Farmer Account',
                        style: TextStyle(
                          color: Color(0xFF007955),
                          fontSize: 12,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Edit Button
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to edit profile
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF697282),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contact Information
          _buildContactRow(Icons.phone_outlined, '(555) 123-4567'),
          const SizedBox(height: 8),
          _buildContactRow(Icons.email_outlined, 'you@example.com'),
          const SizedBox(height: 8),
          _buildContactRow(
            Icons.location_on_outlined,
            'Green Valley Farm, 123 Farm Road',
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF495565)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF495565),
            fontSize: 14,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.43,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            iconBackgroundColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF009966),
            label: 'Total Revenue',
            value: '\$24,850',
            change: '+12.5%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.shopping_bag_outlined,
            iconBackgroundColor: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            label: 'Products Sold',
            value: '1,247',
            change: '+8.3%',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required String label,
    required String value,
    required String change,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          // Label
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF697282),
              fontSize: 12,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 4),
          // Value
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF101727),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
          const SizedBox(height: 4),
          // Change
          Text(
            change,
            style: const TextStyle(
              color: Color(0xFF009966),
              fontSize: 12,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: Color(0xFF101727),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Business Information',
                    style: TextStyle(
                      color: Color(0xFF101727),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to edit business info
                },
                child: const Text(
                  'Edit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF009966),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Business Info Fields
          _buildInfoField('Farm Name', 'Green Valley Farm'),
          const SizedBox(height: 12),
          _buildInfoField('Business License', '#FRM-2024-001234'),
          const SizedBox(height: 12),
          _buildCertificationField(),
          const SizedBox(height: 12),
          _buildInfoField('Member Since', 'January 2024'),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF697282),
            fontSize: 14,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.43,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101727),
            fontSize: 14,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.43,
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Certification',
          style: TextStyle(
            color: Color(0xFF697282),
            fontSize: 14,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.43,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildCertificationBadge(
              'Organic Certified',
              const Color(0xFFD0FAE5),
              const Color(0xFF007955),
            ),
            const SizedBox(width: 8),
            _buildCertificationBadge(
              'Local Producer',
              const Color(0xFFDBEAFE),
              const Color(0xFF1347E5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCertificationBadge(
    String text,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Arimo',
          fontWeight: FontWeight.w400,
          height: 1.33,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement logout functionality
        context.go('/');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE7000B),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Logout',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: false,
            onTap: () {
              context.go('/farmer-home-page');
            },
          ),
          _buildNavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            isActive: false,
            onTap: () {
              context.go('/orders-page');
            },
          ),
          _buildNavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            isActive: false,
            onTap: () {
              context.go('/inventory-page');
            },
          ),
          _buildNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: true,
            onTap: () {
              // Already on profile page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFF009966) : const Color(0xFF697282);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
