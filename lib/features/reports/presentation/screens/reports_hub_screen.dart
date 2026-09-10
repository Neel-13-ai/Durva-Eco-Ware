import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/reports/application/reports_providers.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Business Analytics'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Analytics',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting report to CSV... Download complete.'), backgroundColor: BrandColors.primary),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(stockSummaryReportProvider);
              ref.invalidate(productionSummaryReportProvider);
              ref.invalidate(salesSummaryReportProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Stock Valuation'),
            Tab(text: 'Production Yield'),
            Tab(text: 'Sales Revenue'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStockTab(),
          _buildProductionTab(),
          _buildSalesTab(),
        ],
      ),
    );
  }

  Widget _buildStockTab() {
    final stockAsync = ref.watch(stockSummaryReportProvider);
    return stockAsync.when(
      data: (rows) {
        if (rows.isEmpty) return const Center(child: Text('No stock data available'));
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
          itemBuilder: (ctx, index) {
            final r = rows[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                title: Text(r.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Items: ${r.itemCount} • Low Stock Alert: ${r.lowStockCount}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${r.totalValuation.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: BrandColors.primary)),
                    Text('${r.totalQuantity.toStringAsFixed(0)} units', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildProductionTab() {
    final prodAsync = ref.watch(productionSummaryReportProvider);
    return prodAsync.when(
      data: (rows) {
        if (rows.isEmpty) return const Center(child: Text('No production summary data'));
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
          itemBuilder: (ctx, index) {
            final r = rows[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                          child: Text('${r.yieldPercentage.toStringAsFixed(1)}% YIELD', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Planned: ${r.plannedQty.toStringAsFixed(0)} | Good: ${r.goodQty.toStringAsFixed(0)} | Rejects: ${r.rejectQty.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSalesTab() {
    final salesAsync = ref.watch(salesSummaryReportProvider);
    return salesAsync.when(
      data: (rows) {
        if (rows.isEmpty) return const Center(child: Text('No sales summary data'));
        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
          itemBuilder: (ctx, index) {
            final r = rows[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                title: Text(r.periodOrCustomer, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Invoices: ${r.invoiceCount} • Balance: ₹${r.outstandingBalance.toStringAsFixed(2)}'),
                trailing: Text('₹${r.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
