import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/masters/application/providers/master_providers.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';
import 'package:durvaeco/features/sales/data/models/customer_payment_dto.dart';
import 'package:durvaeco/features/sales/presentation/screens/sales_form_screen.dart';
import 'package:durvaeco/features/sales/presentation/screens/customer_payment_form_screen.dart';

class SalesDetailScreen extends ConsumerWidget {
  final int saleId;
  final SaleDto? initialSale;

  const SalesDetailScreen({super.key, required this.saleId, this.initialSale});

  void _showVoidConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void / Delete Invoice?'),
        content: const Text(
          'This invoice will be permanently deleted and inventory allocations will be released. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Voiding invoice...')),
              );
              final result = await ref.read(salesRepositoryProvider).deleteSale(saleId);
              result.when(
                success: (_) {
                  ref.invalidate(salesListProvider);
                  ref.invalidate(saleDetailProvider(saleId));
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Invoice voided successfully'),
                      backgroundColor: BrandColors.primary,
                    ),
                  );
                  if (context.mounted) {
                    context.pop();
                  }
                },
                failure: (err) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to void invoice: ${err.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            child: const Text('Void Invoice', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final paymentsAsync = ref.watch(salePaymentsProvider(saleId));
    final customers = ref.watch(activeCustomersProvider).valueOrNull;
    final warehouses = ref.watch(activeWarehousesProvider).valueOrNull;
    final sale = saleAsync.valueOrNull ?? initialSale;

    return Scaffold(
      appBar: AppBar(
        title: Text(sale?.invoiceNumber.isNotEmpty == true ? sale!.invoiceNumber : 'Invoice #$saleId'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (sale != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SalesFormScreen(existingSale: sale),
                    ),
                  );
                } else if (val == 'void') {
                  _showVoidConfirmation(context, ref);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: BrandColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Invoice'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'void',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Void Invoice', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: RefreshIndicator(
        color: BrandColors.primary,
        onRefresh: () async {
          ref.invalidate(saleDetailProvider(saleId));
          ref.invalidate(salePaymentsProvider(saleId));
          ref.invalidate(activeCustomersProvider);
          ref.invalidate(activeWarehousesProvider);
        },
        child: sale != null
            ? _buildContent(context, ref, sale, saleAsync.isLoading, paymentsAsync, customers, warehouses)
            : saleAsync.when(
                data: (loadedSale) => _buildContent(context, ref, loadedSale, false, paymentsAsync, customers, warehouses),
                loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
                error: (err, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SaleDto sale,
    bool isLoadingItems,
    AsyncValue<List<CustomerPaymentDto>> paymentsAsync,
    List<dynamic>? customers,
    List<dynamic>? warehouses,
  ) {
    final customerDisplay = (sale.customerName != null && sale.customerName!.isNotEmpty && !sale.customerName!.startsWith('Customer #'))
        ? sale.customerName!
        : (customers?.where((c) => c.id == sale.customerId).firstOrNull?.customerName ?? (sale.customerId > 0 ? 'Customer #${sale.customerId}' : 'Retail Customer'));

    final warehouseDisplay = (sale.warehouseName != null && sale.warehouseName!.isNotEmpty && !sale.warehouseName!.startsWith('Warehouse #'))
        ? sale.warehouseName!
        : (warehouses?.where((w) => w.id == sale.warehouseId).firstOrNull?.name ?? (sale.warehouseId > 0 ? 'Warehouse #${sale.warehouseId}' : 'Main Warehouse'));

    return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
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
                          Text(
                            sale.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: BrandColors.primary),
                          ),
                          Row(
                            children: [
                              _buildStatusBadge(sale.status),
                              const SizedBox(width: 8),
                              _buildPaymentBadge(sale.paymentStatus),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text('Customer: $customerDisplay', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Dispatch Warehouse: $warehouseDisplay', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: Spacing.xs),
                      Text('Sale Date: ${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (sale.dueDate != null)
                        Text('Due Date: ${sale.dueDate!.day}/${sale.dueDate!.month}/${sale.dueDate!.year}', style: TextStyle(fontSize: 12, color: sale.isOverdue ? Colors.red : Colors.grey)),
                      if (sale.notes != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Text('Notes: ${sale.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Line Items
              Card(
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
                      const Text('Invoice Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                      const SizedBox(height: Spacing.sm),
                      if (sale.items.isEmpty)
                        const Text('No line items found.', style: TextStyle(color: Colors.grey))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sale.items.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, index) {
                            final item = sale.items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.productName ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Qty: ${item.quantity} | Unit Rate: ₹${item.unitPrice} | Tax: ₹${item.tax}'),
                              trailing: Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Valuation Summary Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', '₹${sale.subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      _buildSummaryRow('Discount', '- ₹${sale.discount.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      _buildSummaryRow('Tax', '+ ₹${sale.tax.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      _buildSummaryRow('Transport Charge', '+ ₹${sale.transportCharge.toStringAsFixed(2)}'),
                      const Divider(),
                      _buildSummaryRow('Total Invoice Value', '₹${sale.totalAmount.toStringAsFixed(2)}', isBold: true),
                      const SizedBox(height: 4),
                      _buildSummaryRow('Paid Amount', '₹${sale.paidAmount.toStringAsFixed(2)}', color: const Color(0xFF2E7D32)),
                      const SizedBox(height: 4),
                      _buildSummaryRow('Outstanding Balance', '₹${sale.outstandingBalance.toStringAsFixed(2)}', color: sale.outstandingBalance > 0 ? Colors.red : const Color(0xFF2E7D32), isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Payment History
              Card(
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
                          const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                          if (sale.outstandingBalance > 0)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CustomerPaymentFormScreen(prefilledSale: sale),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Record Payment'),
                              style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      paymentsAsync.when(
                        data: (payments) {
                          if (payments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text('No payments recorded yet for this invoice.', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: payments.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, index) {
                              final p = payments[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE8F5E9),
                                  foregroundColor: Color(0xFF2E7D32),
                                  child: Icon(Icons.check, size: 18),
                                ),
                                title: Text(p.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year} • ${p.paymentMethodName ?? "Payment"}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                  ],
                                ),
                                onTap: () => context.push('/sales/payments/${p.id}'),
                              );
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('Error loading payments: $err'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 15 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.grey[700])),
        Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFE8F5E9);
    Color fg = const Color(0xFF2E7D32);
    if (status == 'DRAFT') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
    } else if (status == 'CANCELLED') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
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
