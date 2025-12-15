import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

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
                    // Header Section
                    _buildHeader(context),
                    const SizedBox(height: 16),

                    // Low Stock Alert
                    _buildLowStockAlert(),
                    const SizedBox(height: 16),

                    // Stats Grid
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // Product List
                    _buildProductList(),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Inventory',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 16,
            fontFamily: 'Arimo',
            fontWeight: FontWeight.w400,
            height: 1.50,
          ),
        ),
        GestureDetector(
          onTap: () {
            // TODO: Navigate to add product page
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF009966),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Add Product',
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
        ),
      ],
    );
  }

  Widget _buildLowStockAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6A7), width: 1.14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Color(0xFFF44900),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    color: Color(0xFF7E2A0B),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '2 products below minimum stock level',
                  style: TextStyle(
                    color: Color(0xFFC93400),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.inventory_2_outlined,
                title: 'Total Products',
                value: '4',
                isWarning: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.warning_amber_rounded,
                title: 'Low Stock',
                value: '2',
                isWarning: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                title: 'Total Revenue',
                value: '\$628.27',
                isWarning: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.shopping_cart_outlined,
                title: 'Items Sold',
                value: '86',
                isWarning: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isWarning,
  }) {
    final backgroundColor = isWarning ? const Color(0xFFFFF7ED) : Colors.white;
    final borderColor = isWarning
        ? const Color(0xFFFFD6A7)
        : const Color(0xFFE5E7EB);
    final titleColor = isWarning
        ? const Color(0xFFF44900)
        : const Color(0xFF495565);
    final valueColor = isWarning
        ? const Color(0xFF7E2A0B)
        : const Color(0xFF101727);
    final iconColor = isWarning
        ? const Color(0xFFF44900)
        : const Color(0xFF495565);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    // Sample product data
    final products = [
      ProductData(
        name: 'Organic Tomatoes',
        sku: 'VEG-001',
        currentStock: 45,
        minStock: 20,
        price: 4.99,
        sold: 23,
        revenue: 114.77,
        isLowStock: false,
      ),
      ProductData(
        name: 'Fresh Strawberries',
        sku: 'FRU-002',
        currentStock: 12,
        minStock: 20,
        price: 6.50,
        sold: 31,
        revenue: 201.50,
        isLowStock: true,
      ),
      ProductData(
        name: 'Sourdough Bread',
        sku: 'BAK-003',
        currentStock: 8,
        minStock: 15,
        price: 5.99,
        sold: 18,
        revenue: 107.82,
        isLowStock: true,
      ),
      ProductData(
        name: 'Farm Fresh Eggs',
        sku: 'DAI-004',
        currentStock: 30,
        minStock: 15,
        price: 3.49,
        sold: 14,
        revenue: 48.86,
        isLowStock: false,
      ),
    ];

    return Column(
      children: products
          .map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProductCard(product),
            ),
          )
          .toList(),
    );
  }

  Widget _buildProductCard(ProductData product) {
    final backgroundColor = product.isLowStock
        ? const Color(0xFFFFF7ED)
        : Colors.white;
    final borderColor = product.isLowStock
        ? const Color(0xFFFFD6A7)
        : const Color(0xFFE5E7EB);
    final stockColor = product.isLowStock
        ? const Color(0xFFF44900)
        : const Color(0xFF101727);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            color: const Color(0xFF101727),
                            fontSize: product.isLowStock ? 16 : 18,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                        if (product.isLowStock) ...[
                          const SizedBox(width: 8),
                          _buildLowStockBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product.sku}',
                      style: const TextStyle(
                        color: Color(0xFF697282),
                        fontSize: 14,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              ),
              _buildMoreOptionsButton(),
            ],
          ),
          const SizedBox(height: 12),

          // Product Stats Row
          Row(
            children: [
              Expanded(
                child: _buildProductStat(
                  label: 'Stock',
                  value: '${product.currentStock} / ${product.minStock}',
                  valueColor: stockColor,
                ),
              ),
              Expanded(
                child: _buildProductStat(
                  label: 'Price',
                  value: '\$${product.price.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF101727),
                ),
              ),
              Expanded(
                child: _buildProductStat(
                  label: 'Sold',
                  value: '${product.sold}',
                  valueColor: const Color(0xFF101727),
                  showTrendIcon: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Revenue Section
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1.14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue',
                  style: TextStyle(
                    color: Color(0xFF495565),
                    fontSize: 14,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                  ),
                ),
                Text(
                  '\$${product.revenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF009966),
                    fontSize: 16,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6900),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Low',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Arimo',
          fontWeight: FontWeight.w400,
          height: 1.33,
        ),
      ),
    );
  }

  Widget _buildMoreOptionsButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Show product options menu
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.more_vert, size: 16, color: Color(0xFF697282)),
      ),
    );
  }

  Widget _buildProductStat({
    required String label,
    required String value,
    required Color valueColor,
    bool showTrendIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontFamily: 'Arimo',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
            ),
            if (showTrendIcon) ...[
              const SizedBox(width: 4),
              const Icon(Icons.trending_up, size: 12, color: Color(0xFF009966)),
            ],
          ],
        ),
      ],
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
            isActive: true,
            onTap: () {
              // Already on inventory page
            },
          ),
          _buildNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: false,
            onTap: () {
              context.go('/profile-page');
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

/// Data model for product information
class ProductData {
  final String name;
  final String sku;
  final int currentStock;
  final int minStock;
  final double price;
  final int sold;
  final double revenue;
  final bool isLowStock;

  const ProductData({
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.minStock,
    required this.price,
    required this.sold,
    required this.revenue,
    required this.isLowStock,
  });
}
