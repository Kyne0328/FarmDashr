import 'package:flutter/material.dart';
import 'package:farmdashr/data/models/product.dart';
import 'package:farmdashr/data/models/cart_item.dart';

class CustomerCartPage extends StatelessWidget {
  const CustomerCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded mock data for visualization
    final List<CartItem> mockItems = [
      CartItem(
        product: const Product(
          id: '1',
          farmerId: 'farmer_1',
          name: 'Organic Tomatoes',
          sku: 'VEG-001',
          currentStock: 45,
          minStock: 20,
          price: 4.99,
          sold: 23,
          revenue: 114.77,
          category: ProductCategory.vegetables,
          imageUrls: [], // Updated
        ),
        quantity: 1,
      ),
      CartItem(
        product: const Product(
          id: '2',
          farmerId: 'farmer_1',
          name: 'Fresh Strawberries',
          sku: 'FRU-002',
          currentStock: 12,
          minStock: 20,
          price: 6.50,
          sold: 31,
          revenue: 201.50,
          category: ProductCategory.fruits,
          imageUrls: [],
        ),
        quantity: 2,
      ),
      CartItem(
        product: const Product(
          id: '4',
          farmerId: 'farmer_2',
          name: 'Farm Fresh Eggs',
          sku: 'DAI-004',
          currentStock: 30,
          minStock: 15,
          price: 3.49,
          sold: 14,
          revenue: 48.86,
          category: ProductCategory.dairy,
          imageUrls: [],
        ),
        quantity: 1,
      ),
    ];

    // Calculate totals based on mock data
    final double subtotal = mockItems.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    const double serviceFee = 2.99;
    final double tax = subtotal * 0.08;
    final double total = subtotal + serviceFee + tax;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Your Cart',
          style: TextStyle(
            color: Color(0xFF101727),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              // debugPrint('Clear All tapped');
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xFFE7000B), fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _CartItemWidget(item: mockItems[index]);
            },
          ),
          const SizedBox(height: 24),
          _CartSummary(
            subtotal: subtotal,
            serviceFee: serviceFee,
            tax: tax,
            total: total,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // debugPrint('Checkout tapped');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155DFC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue to Pre-Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final CartItem item;

  const _CartItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    color: Color(0xFF101727),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.product.category.displayName,
                  style: const TextStyle(
                    color: Color(0xFF697282),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.formattedTotal,
                      style: const TextStyle(
                        color: Color(0xFF155CFB),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Quantity Display (Read-only for mockup)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double subtotal;
  final double serviceFee;
  final double tax;
  final double total;

  const _CartSummary({
    required this.subtotal,
    required this.serviceFee,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', amount: subtotal),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Service Fee', amount: serviceFee),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Tax (8%)', amount: tax),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _SummaryRow(label: 'Total', amount: total, isTotal: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? const Color(0xFF101727) : const Color(0xFF495565),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? const Color(0xFF155CFB) : const Color(0xFF101727),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
