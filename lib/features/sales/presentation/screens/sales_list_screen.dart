import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/presentation/screens/customer_payment_form_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_detail_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_form_screen.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  String _filter = 'ALL'; // ALL, PENDING, PAID, OVERDUE
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Invoicing'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(salesListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SalesFormScreen()),
          );
        },
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: salesAsync.when(
        data: (allSales) {
          final filtered = allSales.where((s) {
            final matchesSearch = _search.isEmpty ||
                s.invoiceNumber.toLowerCase().contains(_search.toLowerCase()) ||
                (s.customerName?.toLowerCase().contains(_search.toLowerCase()) ?? false);

            if (!matchesSearch) return false;

            if (_filter == 'PENDING') return s.paymentStatus == 'PENDING' || s.paymentStatus == 'PARTIALLY_PAID';
            if (_filter == 'PAID') return s.paymentStatus == 'PAID';
            if (_filter == 'OVERDUE') return s.isOverdue;
            return true;
          }).toList();

          final totalInvoiced = allSales.fold(0.0, (sum, s) => sum + s.totalAmount);
          final totalCollected = allSales.fold(0.0, (sum, s) => sum + s.paidAmount);
          final totalReceivable = allSales.fold(0.0, (sum, s) => sum + s.outstandingBalance);

          return Column(
            children: [
              // Summary Metrics Banner
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Row(
                  children: [
                    _buildMetric('Total Invoiced', '₹${totalInvoiced.toStringAsFixed(0)}', const Color(0xFF1976D2)),
                    _buildMetric('Collected', '₹${totalCollected.toStringAsFixed(0)}', const Color(0xFF2E7D32)),
                    _buildMetric('Receivables', '₹${totalReceivable.toStringAsFixed(0)}', const Color(0xFFE65100)),
                  ],
                ),
              ),

              // Filter Tabs & Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search invoice # or customer...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                    const SizedBox(height: Spacing.xs),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All Invoices'),
                          _buildFilterChip('PENDING', 'Pending Payment'),
                          _buildFilterChip('PAID', 'Fully Paid'),
                          _buildFilterChip('OVERDUE', 'Overdue'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List of Invoices
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No sales invoices matching filter.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                        itemBuilder: (ctx, index) {
                          final sale = filtered[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.md),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(Radii.md),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => SalesDetailScreen(saleId: sale.id)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(Spacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          sale.invoiceNumber,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                                        ),
                                        Row(
                                          children: [
                                            _buildPaymentBadge(sale.paymentStatus),
                                            if (sale.isOverdue) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(4)),
                                                child: const Text('OVERDUE', style: TextStyle(color: Color(0xFFC62828), fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(sale.customerName ?? 'Customer #${sale.customerId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Date: ${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '₹${sale.totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    if (sale.outstandingBalance > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Balance: ₹${sale.outstandingBalance.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            icon: const Icon(Icons.payment, size: 14, color: BrandColors.primary),
                                            label: const Text('Collect', style: TextStyle(fontSize: 12, color: BrandColors.primary, fontWeight: FontWeight.bold)),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => CustomerPaymentFormScreen(prefilledSale: sale),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error loading sales: $err')),
      ),
    );
  }

  Widget _buildMetric(String label, String val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: BrandColors.primary,
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color bg = const Color(0xFFE8F5E9);
    Color fg = const Color(0xFF2E7D32);
    if (status == 'PENDING') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    } else if (status == 'PARTIALLY_PAID') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
