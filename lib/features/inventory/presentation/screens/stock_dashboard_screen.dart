import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/inventory/data/models/stock_balance_dto.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';
import 'package:durvaeco/features/inventory/presentation/widgets/stock_adjustment_dialog.dart';

class StockDashboardScreen extends ConsumerStatefulWidget {
  const StockDashboardScreen({super.key});

  @override
  ConsumerState<StockDashboardScreen> createState() => _StockDashboardScreenState();
}

class _StockDashboardScreenState extends ConsumerState<StockDashboardScreen> {
  final _searchCtrl = TextEditingController();
  int? _selectedWarehouseId;
  String? _selectedProductType;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(stockFilterProvider.notifier).state = StockFilter(
      warehouseId: _selectedWarehouseId,
      productType: _selectedProductType,
      searchQuery: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(stockMetricsProvider);
    final balancesAsync = ref.watch(stockBalancesListProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Stock Movement Ledger',
            onPressed: () => context.push('/inventory/movements'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Inventory',
            onPressed: () {
              ref.invalidate(stockBalancesListProvider);
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => StockAdjustmentDialog.show(context),
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.tune, color: Colors.white),
        label: const Text('Stock Adjustment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Total Stock Value',
                    value: '₹${metrics.totalStockValue.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Raw Material Value',
                    value: '₹${metrics.totalRawMaterialValue.toStringAsFixed(0)}',
                    icon: Icons.layers,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Finished Goods',
                    value: '${metrics.totalFinishedGoodsUnits.toStringAsFixed(0)} Units',
                    icon: Icons.inventory_2,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _KpiMetricCard(
                    title: 'Low / Out Stock',
                    value: '${metrics.lowStockCount} Low / ${metrics.outOfStockCount} Out',
                    icon: Icons.warning_amber_rounded,
                    color: metrics.lowStockCount + metrics.outOfStockCount > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Search & Filter Controls
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search material, product code...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: warehousesAsync.when(
                          data: (warehouses) => DropdownButtonFormField<int?>(
                            isExpanded: true,
                            initialValue: _selectedWarehouseId,
                            decoration: const InputDecoration(
                              labelText: 'Warehouse',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Warehouses', overflow: TextOverflow.ellipsis)),
                              ...warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedWarehouseId = val);
                              _applyFilters();
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: _selectedProductType,
                          decoration: const InputDecoration(
                            labelText: 'Product Type',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All Types', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'RAW_MATERIAL', child: Text('Raw Material', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'FINISHED_GOOD', child: Text('Finished Good', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'PACKAGING', child: Text('Packaging', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedProductType = val);
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Balances List Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Stock Balances',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/inventory/movements'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Movements', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),

            // Balances List
            balancesAsync.when(
              data: (balances) {
                if (balances.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.xl),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
                          SizedBox(height: 8),
                          Text('No stock records match criteria', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: balances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                  itemBuilder: (ctx, index) {
                    final balance = balances[index];
                    return _StockBalanceCard(
                      balance: balance,
                      onAdjust: () {
                        StockAdjustmentDialog.show(
                          context,
                          initialProductId: balance.productId,
                          initialWarehouseId: balance.warehouseId,
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBalanceCard extends StatelessWidget {
  const _StockBalanceCard({
    required this.balance,
    required this.onAdjust,
  });

  final StockBalanceDto balance;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final isLow = balance.isLowStock;
    final isOut = balance.isOutOfStock;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: isOut ? Colors.red.shade300 : (isLow ? Colors.amber.shade400 : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.productName ?? 'Product #${balance.productId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Code: ${balance.productCode ?? "N/A"} • ${balance.warehouseName ?? "Warehouse"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isOut)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(Radii.sm)),
                    child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 9)),
                  )
                else if (isLow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(Radii.sm)),
                    child: const Text('LOW STOCK', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 9)),
                  ),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(
                      '${balance.quantity.toStringAsFixed(1)} ${balance.unitName ?? "Units"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avg Cost', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text('₹${balance.averageCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Valuation', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text('₹${balance.totalValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: BrandColors.primary)),
                  ],
                ),
                OutlinedButton(
                  onPressed: onAdjust,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 30),
                    foregroundColor: BrandColors.primary,
                  ),
                  child: const Text('Adjust', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
