import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/auth/application/auth_providers.dart';

class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More & Hub'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User & System Status Card
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BrandColors.primary, BrandColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Radii.md),
                boxShadow: [
                  BoxShadow(
                    color: BrandColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Super Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Role: ${user?.roles.isNotEmpty == true ? user!.roles.first : 'Administrator'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF69F0AE), size: 10),
                            SizedBox(width: 4),
                            Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bagasse Eco-Ware ERP v1.0.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Connected: api-dev', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Section 1: Master Entry Hub
            _buildSectionHeader(
              title: 'Master Entry Setup',
              icon: Icons.dataset_outlined,
              color: const Color(0xFF1B5E20),
            ),
            const SizedBox(height: Spacing.xs),
            _buildMenuGroup(const [
              _MenuItem(
                icon: Icons.inventory_2_outlined,
                title: 'Products & Raw Materials',
                subtitle: 'Manage catalog, specs, types & HSN codes',
                route: '/masters/products',
                color: BrandColors.primary,
              ),
              _MenuItem(
                icon: Icons.category_outlined,
                title: 'Item Categories',
                subtitle: 'Classifications & product groupings',
                route: '/masters/categories',
                color: Color(0xFF2E7D32),
              ),
              _MenuItem(
                icon: Icons.straighten_outlined,
                title: 'Units of Measure (UOM)',
                subtitle: 'Metric units, conversions & decimals',
                route: '/masters/units',
                color: Color(0xFF00796B),
              ),
              _MenuItem(
                icon: Icons.warehouse_outlined,
                title: 'Warehouses & Locations',
                subtitle: 'Raw material, WIP & finished goods storage',
                route: '/masters/warehouses',
                color: Color(0xFF00838F),
              ),
              _MenuItem(
                icon: Icons.format_list_numbered_outlined,
                title: 'Document Sequences',
                subtitle: 'Prefixes & auto-numbering formulas',
                route: '/masters/sequences',
                color: Color(0xFF455A64),
              ),
            ]),
            const SizedBox(height: Spacing.lg),

            // Section 2: Partner Masters & Fleet
            _buildSectionHeader(
              title: 'Partners & Logistics',
              icon: Icons.handshake_outlined,
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(height: Spacing.xs),
            _buildMenuGroup(const [
              _MenuItem(
                icon: Icons.storefront_outlined,
                title: 'Suppliers & Vendors',
                subtitle: 'Raw material vendors, GSTIN & payment terms',
                route: '/partners/suppliers',
                color: Color(0xFF1565C0),
              ),
              _MenuItem(
                icon: Icons.people_outline,
                title: 'Customers & Buyers',
                subtitle: 'Buyer accounts, credit limits & delivery terms',
                route: '/partners/customers',
                color: Color(0xFF0277BD),
              ),
              _MenuItem(
                icon: Icons.local_shipping_outlined,
                title: 'Transporters & Logistics',
                subtitle: 'Freight partners & carrier details',
                route: '/partners/transporters',
                color: Color(0xFF00838F),
              ),
              _MenuItem(
                icon: Icons.fire_truck_outlined,
                title: 'Fleet & Vehicles',
                subtitle: 'Trucks, vehicle types & driver allocations',
                route: '/partners/vehicles',
                color: Color(0xFF00695C),
              ),
              _MenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payment Methods',
                subtitle: 'Bank transfer, UPI, cash & cheque channels',
                route: '/partners/payment-methods',
                color: Color(0xFF2E7D32),
              ),
            ]),
            const SizedBox(height: Spacing.lg),

            // Section 3: Sales & Outward Logistics
            _buildSectionHeader(
              title: 'Sales & Outward Logistics',
              icon: Icons.point_of_sale_outlined,
              color: const Color(0xFFE65100),
            ),
            const SizedBox(height: Spacing.xs),
            _buildMenuGroup(const [
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Sales Orders & Invoicing',
                subtitle: 'Customer orders, invoices & payments',
                route: '/sales',
                color: Color(0xFF2E7D32),
              ),
              _MenuItem(
                icon: Icons.local_shipping_outlined,
                title: 'Dispatch Logistics & Challans',
                subtitle: 'Delivery challans & outward tracking',
                route: '/dispatch',
                color: Color(0xFFE65100),
              ),
              _MenuItem(
                icon: Icons.pending_actions_outlined,
                title: 'Pending Dispatch Queue',
                subtitle: 'Orders awaiting truck assignment',
                route: '/dispatch/pending',
                color: Color(0xFFEF6C00),
              ),
            ]),
            const SizedBox(height: Spacing.lg),

            // Section 4: Production & Quality
            _buildSectionHeader(
              title: 'Production, BOM & Waste',
              icon: Icons.precision_manufacturing_outlined,
              color: const Color(0xFF6A1B9A),
            ),
            const SizedBox(height: Spacing.xs),
            _buildMenuGroup([
              const _MenuItem(
                icon: Icons.science_outlined,
                title: 'Bill of Materials (BOM)',
                subtitle: 'Product formulas, input ratios & unit costing',
                route: '/bom',
                color: Color(0xFF6A1B9A),
              ),
              _MenuItem(
                icon: Icons.delete_sweep_outlined,
                title: 'Waste & Scrap Tracking',
                subtitle: 'Defect logging, loss costs & repulping',
                route: '/waste',
                color: Colors.red.shade700,
              ),
              _MenuItem(
                icon: Icons.rule_folder_outlined,
                title: 'Waste Reason Codes',
                subtitle: 'Standardized defect categories',
                route: '/waste/reasons',
                color: Colors.red.shade900,
              ),
              const _MenuItem(
                icon: Icons.account_tree_outlined,
                title: 'Manufacturing Flow Storyboard',
                subtitle: 'Full 8-stage visual pipeline',
                route: '/manufacturing-flow',
                color: Color(0xFF2E7D32),
              ),
            ]),
            const SizedBox(height: Spacing.lg),

            // Section 5: Finance & Analytics
            _buildSectionHeader(
              title: 'Finance & Analytics',
              icon: Icons.analytics_outlined,
              color: const Color(0xFF4527A0),
            ),
            const SizedBox(height: Spacing.xs),
            _buildMenuGroup(const [
              _MenuItem(
                icon: Icons.receipt_outlined,
                title: 'Expense Management',
                subtitle: 'Operating expenses, utilities & vouchers',
                route: '/expenses',
                color: Color(0xFF673AB7),
              ),
              _MenuItem(
                icon: Icons.category_outlined,
                title: 'Expense Categories',
                subtitle: 'Cost centre classifications',
                route: '/expenses/categories',
                color: Color(0xFF512DA8),
              ),
              _MenuItem(
                icon: Icons.bar_chart_outlined,
                title: 'Reports & BI Analytics',
                subtitle: 'Production yield, sales & financial reports',
                route: '/reports',
                color: Color(0xFF1565C0),
              ),
              _MenuItem(
                icon: Icons.notifications_active_outlined,
                title: 'Notification Center',
                subtitle: 'System alerts, low stock & order updates',
                route: '/notifications',
                color: Color(0xFF00796B),
              ),
            ]),
            const SizedBox(height: Spacing.xl),

            // Section 6: Logout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out of Durva Eco Ware',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  backgroundColor: const Color(0xFFFFEBEE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Sign Out'),
                      content: const Text('Are you sure you want to sign out of the system?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ref.read(authControllerProvider.notifier).logout();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
            onTap: () => context.push(item.route),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}
