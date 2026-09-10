import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/dispatch/application/dispatch_providers.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';

class DeliveryDetailScreen extends ConsumerWidget {
  final int deliveryId;

  const DeliveryDetailScreen({super.key, required this.deliveryId});

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFFFF3E0);
    Color fg = const Color(0xFFE65100);
    if (status == 'DISPATCHED') {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1976D2);
    } else if (status == 'DELIVERED') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryAsync = ref.watch(deliveryDetailProvider(deliveryId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Challan #$deliveryId'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(deliveryDetailProvider(deliveryId)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: deliveryAsync.when(
        data: (delivery) => SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Challan Header Card
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
                            delivery.deliveryNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: BrandColors.primary),
                          ),
                          _buildStatusBadge(delivery.status),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text('Customer: ${delivery.customerName ?? "Customer #${delivery.customerId}"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Linked Order: ${delivery.invoiceNumber ?? "Invoice #${delivery.saleId}"}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: Spacing.xs),
                      Text('Delivery Date: ${delivery.deliveryDate.day}/${delivery.deliveryDate.month}/${delivery.deliveryDate.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (delivery.deliveryAddress != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(delivery.deliveryAddress!, style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Fleet & Transport Logistics Card
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
                      const Text('Logistics & Fleet Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                      const SizedBox(height: Spacing.sm),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF3E0),
                          foregroundColor: Color(0xFFE65100),
                          child: Icon(Icons.local_shipping, size: 20),
                        ),
                        title: Text(delivery.transporterName ?? 'Direct Fleet Dispatch', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Vehicle: ${delivery.vehicleNumber ?? "N/A"} • Driver: ${delivery.driverName ?? "N/A"} (${delivery.driverPhone ?? ""})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tracking / LR #: ${delivery.trackingNumber ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Freight: ₹${delivery.freightAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),

              // Items Table
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
                      const Text('Dispatched Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                      const SizedBox(height: Spacing.sm),
                      if (delivery.items.isEmpty)
                        const Text('No line items attached.', style: TextStyle(color: Colors.grey))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: delivery.items.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, index) {
                            final item = delivery.items[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.productName ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Item ID: ${item.productId}'),
                              trailing: Text('${item.quantity.toStringAsFixed(0)} pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary)),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Status Change Action Buttons
              if (delivery.status == 'DRAFT')
                ElevatedButton.icon(
                  onPressed: () async {
                    final repo = ref.read(deliveryRepositoryProvider);
                    final updated = DeliveryDto(
                      id: delivery.id,
                      deliveryNumber: delivery.deliveryNumber,
                      saleId: delivery.saleId,
                      customerId: delivery.customerId,
                      transporterId: delivery.transporterId,
                      vehicleId: delivery.vehicleId,
                      driverName: delivery.driverName,
                      driverPhone: delivery.driverPhone,
                      trackingNumber: delivery.trackingNumber,
                      deliveryAddress: delivery.deliveryAddress,
                      freightAmount: delivery.freightAmount,
                      deliveryDate: delivery.deliveryDate,
                      dispatchDate: DateTime.now(),
                      status: 'DISPATCHED',
                      items: delivery.items,
                    );
                    final res = await repo.updateDelivery(delivery.id, updated);
                    if (res.isSuccess && context.mounted) {
                      ref.invalidate(deliveryDetailProvider(deliveryId));
                      ref.invalidate(deliveryListProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shipment marked as DISPATCHED! Stock deducted.'), backgroundColor: BrandColors.primary),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Mark as Dispatched (Deduct Stock)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                  ),
                )
              else if (delivery.status == 'DISPATCHED')
                ElevatedButton.icon(
                  onPressed: () async {
                    final repo = ref.read(deliveryRepositoryProvider);
                    final updated = DeliveryDto(
                      id: delivery.id,
                      deliveryNumber: delivery.deliveryNumber,
                      saleId: delivery.saleId,
                      customerId: delivery.customerId,
                      transporterId: delivery.transporterId,
                      vehicleId: delivery.vehicleId,
                      driverName: delivery.driverName,
                      driverPhone: delivery.driverPhone,
                      trackingNumber: delivery.trackingNumber,
                      deliveryAddress: delivery.deliveryAddress,
                      freightAmount: delivery.freightAmount,
                      deliveryDate: delivery.deliveryDate,
                      dispatchDate: delivery.dispatchDate,
                      deliveredDate: DateTime.now(),
                      status: 'DELIVERED',
                      items: delivery.items,
                    );
                    final res = await repo.updateDelivery(delivery.id, updated);
                    if (res.isSuccess && context.mounted) {
                      ref.invalidate(deliveryDetailProvider(deliveryId));
                      ref.invalidate(deliveryListProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shipment marked as DELIVERED to customer!'), backgroundColor: Color(0xFF2E7D32)),
                      );
                    }
                  },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Confirm Customer Delivery (DELIVERED)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
