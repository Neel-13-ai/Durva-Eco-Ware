import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';

class ManufacturingFlowScreen extends StatelessWidget {
  const ManufacturingFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const stages = [
      _FlowStage(
        stepNumber: '01',
        title: 'Raw Material Purchasing & Inward (GRN)',
        subtitle: 'Suppliers, Purchase Orders, Gate Receipts & Vendor Payouts',
        icon: Icons.shopping_bag_outlined,
        color: Color(0xFF00796B),
        route: '/purchases',
      ),
      _FlowStage(
        stepNumber: '02',
        title: 'Inventory Health & Raw Material Balances',
        subtitle: 'Warehouse Stock Balances, Stock Movements & Valuation',
        icon: Icons.warehouse_outlined,
        color: Color(0xFF1B5E20),
        route: '/inventory',
      ),
      _FlowStage(
        stepNumber: '03',
        title: 'Recipe Engineering & Bill of Materials (BOM)',
        subtitle: 'Formulations, Scrap Allowance % & Per-Unit Batch Costing',
        icon: Icons.science_outlined,
        color: Color(0xFF6A1B9A),
        route: '/bom',
      ),
      _FlowStage(
        stepNumber: '04',
        title: 'Production Floor Tracking & Execution',
        subtitle: 'Production Orders, Sequential Stage Tracking & Output Recording',
        icon: Icons.precision_manufacturing_outlined,
        color: Color(0xFF1565C0),
        route: '/production',
      ),
      _FlowStage(
        stepNumber: '05',
        title: 'Quality Gates, Scrap & Waste Recovery',
        subtitle: 'Defect Analysis, Financial Loss Accounting & Repulping',
        icon: Icons.delete_sweep_outlined,
        color: Color(0xFFC62828),
        route: '/waste',
      ),
      _FlowStage(
        stepNumber: '06',
        title: 'Sales Orders, Invoicing & Receivables',
        subtitle: 'Customer Accounts, Order Confirmations & Payment Receipts',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFF2E7D32),
        route: '/sales',
      ),
      _FlowStage(
        stepNumber: '07',
        title: 'Dispatch Logistics, Fleet & Outward Delivery',
        subtitle: 'Delivery Challans, Transporters, Vehicles & Customer Delivery',
        icon: Icons.local_shipping_outlined,
        color: Color(0xFFE65100),
        route: '/dispatch',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Manufacturing Flow'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final stage = stages[index];
          final isLast = index == stages.length - 1;

          return Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.md),
                  onTap: () => context.push(stage.route),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: stage.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Center(
                            child: Icon(stage.icon, color: stage.color, size: 24),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: stage.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'STAGE ${stage.stepNumber}',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stage.color),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(stage.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(stage.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Icon(Icons.arrow_downward, size: 20, color: Colors.grey.shade400),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FlowStage {
  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _FlowStage({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
