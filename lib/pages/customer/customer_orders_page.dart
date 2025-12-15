import 'package:flutter/material.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(active: true),
                  _buildOrdersList(active: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF101727),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TabBar(
              controller: _tabController,
              padding: EdgeInsets.zero,
              indicator: BoxDecoration(
                color: const Color(0xFF1347E5),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF4B5563),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList({required bool active}) {
    if (active) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          OrderCard(
            orderId: 'ORD-001',
            date: '2025-11-28 10:00 AM',
            status: 'Confirmed',
            statusColor: Color(0xFFDBEAFE),
            statusTextColor: Color(0xFF1347E5),
            itemsCount: 5,
            total: 45.50,
            vendorName: 'Downtown Market',
          ),
          SizedBox(height: 12),
          OrderCard(
            orderId: 'ORD-002',
            date: '2025-11-25 2:00 PM',
            status: 'Ready for Pickup',
            statusColor: Color(0xFFD0FAE5),
            statusTextColor: Color(0xFF007955),
            itemsCount: 3,
            total: 28.00,
            vendorName: 'Northside Farmers Market',
          ),
        ],
      );
    } else {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          OrderCard(
            orderId: 'ORD-000',
            date: '2025-10-15 4:30 PM',
            status: 'Completed',
            statusColor: Color(0xFFF3F4F6),
            statusTextColor: Color(0xFF6B7280),
            itemsCount: 8,
            total: 89.20,
            vendorName: 'Sunny Side Farms',
          ),
        ],
      );
    }
  }
}

class OrderCard extends StatelessWidget {
  final String orderId;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusTextColor;
  final int itemsCount;
  final double total;
  final String vendorName;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
    required this.itemsCount,
    required this.total,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101727),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemsCount items',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          Row(
            children: [
              const Icon(Icons.store, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vendorName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1347E5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
