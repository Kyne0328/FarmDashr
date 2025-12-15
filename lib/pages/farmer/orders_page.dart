import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _showCurrentOrders = true;

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
                    const SizedBox(height: 24),

                    // Stats Cards Row
                    _buildStatsRow(),
                    const SizedBox(height: 24),

                    // Tab Buttons
                    _buildTabButtons(),
                    const SizedBox(height: 16),

                    // Order Cards List
                    _buildOrdersList(),
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
      'Orders',
      style: TextStyle(
        color: Color(0xFF101727),
        fontSize: 16,
        fontFamily: 'Arimo',
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Pending',
            value: '1',
            backgroundColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFFD6A7),
            textColor: const Color(0xFFF44900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Ready',
            value: '1',
            backgroundColor: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA4F3CF),
            textColor: const Color(0xFF009966),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Today',
            value: '3',
            backgroundColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBDDAFF),
            textColor: const Color(0xFF155CFB),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildTabButton(
            label: 'Current (3)',
            isActive: _showCurrentOrders,
            onTap: () => setState(() => _showCurrentOrders = true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTabButton(
            label: 'History (3)',
            isActive: !_showCurrentOrders,
            onTap: () => setState(() => _showCurrentOrders = false),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF009966) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1.14),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF495565),
              fontSize: 16,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    // Sample data
    final currentOrders = [
      OrderData(
        orderId: 'ORD-001',
        customerName: 'Sarah Johnson',
        status: OrderStatus.newOrder,
        dateTime: '2025-11-28 at 10:00 AM',
        location: 'Downtown Market',
        itemCount: 3,
        amount: '\$32.48',
      ),
      OrderData(
        orderId: 'ORD-002',
        customerName: 'Mike Chen',
        status: OrderStatus.preparing,
        dateTime: '2025-11-28 at 2:00 PM',
        location: 'Northside Farmers Market',
        itemCount: 3,
        amount: '\$31.50',
      ),
      OrderData(
        orderId: 'ORD-003',
        customerName: 'Emily Davis',
        status: OrderStatus.ready,
        dateTime: '2025-11-28 at 11:00 AM',
        location: 'Downtown Market',
        itemCount: 2,
        amount: '\$19.50',
      ),
    ];

    return Column(
      children: currentOrders.map((order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOrderCard(order),
        );
      }).toList(),
    );
  }

  Widget _buildOrderCard(OrderData order) {
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
          // Header Row: Order ID, Customer Name, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderId,
                    style: const TextStyle(
                      color: Color(0xFF101727),
                      fontSize: 16,
                      fontFamily: 'Arimo',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customerName,
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
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 12),

          // Date/Time Row
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: const Color(0xFF495565),
              ),
              const SizedBox(width: 8),
              Text(
                order.dateTime,
                style: const TextStyle(
                  color: Color(0xFF495565),
                  fontSize: 14,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location Row
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: const Color(0xFF495565),
              ),
              const SizedBox(width: 8),
              Text(
                order.location,
                style: const TextStyle(
                  color: Color(0xFF495565),
                  fontSize: 14,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Footer Row: Item Count and Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.itemCount} items',
                style: const TextStyle(
                  color: Color(0xFF495565),
                  fontSize: 14,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
              ),
              Text(
                order.amount,
                style: const TextStyle(
                  color: Color(0xFF009966),
                  fontSize: 16,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.newOrder:
        backgroundColor = const Color(0xFFFFEDD4);
        borderColor = const Color(0xFFFFD6A7);
        textColor = const Color(0xFFC93400);
        label = 'New Order';
        icon = Icons.fiber_new_outlined;
        break;
      case OrderStatus.preparing:
        backgroundColor = const Color(0xFFDBEAFE);
        borderColor = const Color(0xFFBDDAFF);
        textColor = const Color(0xFF1347E5);
        label = 'Preparing';
        icon = Icons.hourglass_empty;
        break;
      case OrderStatus.ready:
        backgroundColor = const Color(0xFFD0FAE5);
        borderColor = const Color(0xFFA4F3CF);
        textColor = const Color(0xFF007955);
        label = 'Ready';
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 1.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
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
            isActive: true,
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
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}

// Order Status Enum
enum OrderStatus { newOrder, preparing, ready }

// Order Data Model
class OrderData {
  final String orderId;
  final String customerName;
  final OrderStatus status;
  final String dateTime;
  final String location;
  final int itemCount;
  final String amount;

  OrderData({
    required this.orderId,
    required this.customerName,
    required this.status,
    required this.dateTime,
    required this.location,
    required this.itemCount,
    required this.amount,
  });
}
