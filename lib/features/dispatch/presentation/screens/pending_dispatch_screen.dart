import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/dispatch/application/dispatch_providers.dart';
import 'package:durvaeco/features/dispatch/presentation/screens/delivery_form_screen.dart';

class PendingDispatchScreen extends ConsumerWidget {
  const PendingDispatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingDispatchQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Dispatch Queue'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingDispatchQueueProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: pendingAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF2E7D32)),
                  SizedBox(height: Spacing.md),
                  Text('All Confirmed Orders Dispatched!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: Spacing.xs),
                  Text('No pending sales orders requiring outward delivery.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (ctx, index) {
              final sale = sales[index];
              final totalUnits = sale.items.fold(0.0, (sum, i) => sum + i.quantity);

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
                          Text(
                            sale.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
                            child: const Text('AWAITING DISPATCH', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(sale.customerName ?? 'Customer #${sale.customerId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Warehouse: ${sale.warehouseName ?? "Warehouse #${sale.warehouseId}"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Units to Dispatch: ${totalUnits.toStringAsFixed(0)} pcs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Order Value: ₹${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DeliveryFormScreen(prefilledSale: sale),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_shipping, size: 16),
                          label: const Text('Create Delivery Dispatch'),
                          style: ElevatedButton.styleFrom(backgroundColor: BrandColors.primary, foregroundColor: Colors.white),
                        ),
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
      ),
    );
  }
}
