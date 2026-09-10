import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';

class MasterEntryHubScreen extends StatelessWidget {
  const MasterEntryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Entry Setup'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    color: BrandColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: Spacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Core Master Configuration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Define products, raw materials, categories, units & storage locations',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            const Text(
              'Master Catalogs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Spacing.md,
              crossAxisSpacing: Spacing.md,
              childAspectRatio: 1.15,
              children: [
                _MasterHubCard(
                  title: 'Finished Goods',
                  subtitle: 'Plates & products',
                  icon: Icons.dinner_dining_outlined,
                  color: const Color(0xFF2E7D32),
                  onTap: () => context.push('/masters/products?type=FINISHED_GOOD'),
                ),
                _MasterHubCard(
                  title: 'Raw Materials',
                  subtitle: 'Pulp, leaves & coils',
                  icon: Icons.layers_outlined,
                  color: const Color(0xFF00796B),
                  onTap: () => context.push('/masters/products?type=RAW_MATERIAL'),
                ),
                _MasterHubCard(
                  title: 'Categories',
                  subtitle: 'Item classifications',
                  icon: Icons.category_outlined,
                  color: const Color(0xFF1565C0),
                  onTap: () => context.push('/masters/categories'),
                ),
                _MasterHubCard(
                  title: 'Units of Measure',
                  subtitle: 'Pcs, Kg, Bundle, Roll',
                  icon: Icons.straighten_outlined,
                  color: const Color(0xFFE65100),
                  onTap: () => context.push('/masters/units'),
                ),
                _MasterHubCard(
                  title: 'Warehouses',
                  subtitle: 'Godowns & stock locations',
                  icon: Icons.warehouse_outlined,
                  color: const Color(0xFF4527A0),
                  onTap: () => context.push('/masters/warehouses'),
                ),
                _MasterHubCard(
                  title: 'Document Sequences',
                  subtitle: 'PO, SO & GRN numbering',
                  icon: Icons.format_list_numbered_outlined,
                  color: const Color(0xFF4E342E),
                  onTap: () => context.push('/masters/sequences'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterHubCard extends StatelessWidget {
  const _MasterHubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
