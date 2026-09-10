import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';
import 'package:durvaeco/features/home/application/dashboard_metrics_provider.dart';
import 'package:durvaeco/features/notifications/application/notification_providers.dart';
import 'package:durvaeco/features/production/application/providers/production_providers.dart';
import 'package:durvaeco/features/production/data/models/production_order_dto.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final productionOrdersAsync = ref.watch(productionOrdersListProvider);

    final user = auth.user;
    final userName = user?.displayName ?? 'Super Admin';
    final userInitials = userName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase();
    final roleName = (user?.roles.isNotEmpty == true) ? user!.roles.join(', ') : 'Plant Manager • Administrator';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1B5E20),
          onRefresh: () async {
            ref.invalidate(dashboardMetricsProvider);
            ref.invalidate(productionOrdersListProvider);
            ref.invalidate(unreadNotificationCountProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top App Header (Brand Logo + Notifications)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Color(0xFF2E7D32),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Durva Eco Ware',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B4332),
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Sustainable Today, Greener Tomorrow',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF52796F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: const Color(0xFFE53935),
                        label: Text(
                          unreadCount.toString(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        child: const Icon(
                          Icons.notifications_none_outlined,
                          color: Color(0xFF2D3748),
                          size: 26,
                        ),
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. User Greeting Section (Real User Profile)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF2D6A4F),
                      child: Text(
                        userInitials.isEmpty ? 'SA' : userInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Morning,',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A202C),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            roleName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 3. Hero Sustainability Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA5D6A7).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From Nature\nto a Better Tomorrow',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B4332),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Eco-friendly bagasse tableware manufacturing system.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2D6A4F),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D6A4F),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF81C784),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF81C784),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2, color: Color(0xFF40916C), size: 36),
                              SizedBox(height: 4),
                              Text(
                                'Bagasse Tableware',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. Live Overview Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    Text(
                      'Real-time metrics',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Live Overview Grid Cards (Bound Directly to Real API Metrics)
                metricsAsync.when(
                  data: (metrics) => Column(
                    children: [
                      // 2-Column Grid (Row 1)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.inventory_2_outlined,
                              iconBg: const Color(0xFFE8F5E9),
                              iconColor: const Color(0xFF2E7D32),
                              value: _formatCurrency(metrics.totalStockValuation),
                              label: 'Stock Valuation',
                              showChevron: true,
                              onTap: () => context.push('/inventory'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.warning_amber_rounded,
                              iconBg: const Color(0xFFFFEBEE),
                              iconColor: const Color(0xFFE53935),
                              value: metrics.lowStockCount.toString(),
                              label: 'Low Stock Items',
                              valueColor: metrics.lowStockCount > 0 ? const Color(0xFFE53935) : const Color(0xFF1A202C),
                              showChevron: true,
                              onTap: () => context.push('/inventory'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 2-Column Grid (Row 2)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.precision_manufacturing_outlined,
                              iconBg: const Color(0xFFE8F5E9),
                              iconColor: const Color(0xFF2E7D32),
                              value: metrics.activeProductionOrders.toString(),
                              label: 'Active Production\nOrders',
                              valueColor: const Color(0xFF2D6A4F),
                              onTap: () => context.push('/production'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.shopping_cart_outlined,
                              iconBg: const Color(0xFFFFEBEE),
                              iconColor: const Color(0xFFE53935),
                              value: metrics.pendingPurchases.toString(),
                              label: 'Pending Purchases',
                              valueColor: metrics.pendingPurchases > 0 ? const Color(0xFFE53935) : const Color(0xFF1A202C),
                              onTap: () => context.push('/purchases'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 2-Column Grid (Row 3)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.bar_chart_outlined,
                              iconBg: const Color(0xFFE8F5E9),
                              iconColor: const Color(0xFF2E7D32),
                              value: _formatCurrency(metrics.totalSalesRevenue),
                              label: 'Sales Revenue',
                              showChevron: true,
                              onTap: () => context.push('/sales'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.local_shipping_outlined,
                              iconBg: const Color(0xFFFFEBEE),
                              iconColor: const Color(0xFFE53935),
                              value: metrics.pendingDispatches.toString(),
                              label: 'Pending Dispatches',
                              valueColor: metrics.pendingDispatches > 0 ? const Color(0xFFE53935) : const Color(0xFF1A202C),
                              onTap: () => context.push('/dispatch'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Full Width Row (Unread Notifications)
                      _buildFullWidthMetricCard(
                        icon: Icons.notifications_none_outlined,
                        iconBg: const Color(0xFFFFEBEE),
                        iconColor: const Color(0xFFE53935),
                        value: unreadCount.toString(),
                        label: 'Unread Notifications',
                        valueColor: unreadCount > 0 ? const Color(0xFFE53935) : const Color(0xFF1A202C),
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Unable to load live metrics: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Quick Actions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/more'),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.shopping_cart_outlined,
                        label: 'New\nPurchase Order',
                        onTap: () => context.push('/purchases/new'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.precision_manufacturing_outlined,
                        label: 'New\nProduction Run',
                        onTap: () => context.push('/production/new'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.description_outlined,
                        label: 'New\nSales Order',
                        onTap: () => context.push('/sales/new'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.inventory_2_outlined,
                        label: 'View\nStock Health',
                        onTap: () => context.push('/inventory'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 7. Green Sustainability Slogan Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA5D6A7).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Build today. For a cleaner tomorrow.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            Text(
                              'Sustainable manufacturing. Lasting impact.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF52796F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 8. Active Production Runs Section (Bound to Real API Orders)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Production Runs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/production'),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Real Active Production Orders from Backend
                productionOrdersAsync.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.precision_manufacturing_outlined, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'No Active Production Runs',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a manufacturing order to track stage progress & QC.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/production/new'),
                              icon: const Icon(Icons.add, size: 16, color: Color(0xFF2E7D32)),
                              label: const Text('Start Production Run', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2E7D32))),
                            ),
                          ],
                        ),
                      );
                    }

                    final activeOrder = orders.firstWhere(
                      (o) => o.status == ProductionStatus.inProgress || o.status == ProductionStatus.draft,
                      orElse: () => orders.first,
                    );

                    final goodQty = activeOrder.totalGoodOutput;
                    final plannedQty = activeOrder.plannedQty > 0 ? activeOrder.plannedQty : 1.0;
                    final rejectedQty = activeOrder.outputs.fold(0.0, (sum, o) => sum + o.rejectQty);
                    final progress = (goodQty / plannedQty).clamp(0.0, 1.0);
                    final progressPct = (progress * 100).toInt();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => context.push('/production/${activeOrder.id}/track'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  activeOrder.productionNumber,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: activeOrder.status == ProductionStatus.inProgress
                                        ? const Color(0xFFE3F2FD)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    activeOrder.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: activeOrder.status == ProductionStatus.inProgress
                                          ? const Color(0xFF1976D2)
                                          : const Color(0xFFE65100),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              activeOrder.finishedProductName ?? 'Finished Product',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            if (activeOrder.finishedProductCode != null)
                              Text(
                                activeOrder.finishedProductCode!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Progress Bar with Percentage
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFEDF2F7),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$progressPct%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 3-Column Stats (Good Qty, Rejected, Planned)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      NumberFormat('#,##0').format(goodQty),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A202C),
                                      ),
                                    ),
                                    const Text('Good Qty', style: TextStyle(fontSize: 10.5, color: Color(0xFF718096))),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      NumberFormat('#,##0').format(rejectedQty),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A202C),
                                      ),
                                    ),
                                    const Text('Rejected', style: TextStyle(fontSize: 10.5, color: Color(0xFF718096))),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      NumberFormat('#,##0').format(activeOrder.plannedQty),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A202C),
                                      ),
                                    ),
                                    const Text('Planned', style: TextStyle(fontSize: 10.5, color: Color(0xFF718096))),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Color(0xFFEDF2F7)),

                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF718096)),
                                const SizedBox(width: 6),
                                Text(
                                  'Started ${DateFormat('d MMM yyyy, hh:mm a').format(activeOrder.productionDate)}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    Color valueColor = const Color(0xFF1A202C),
    bool showChevron = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF718096),
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showChevron)
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E0)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    Color valueColor = const Color(0xFF1A202C),
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E0)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
