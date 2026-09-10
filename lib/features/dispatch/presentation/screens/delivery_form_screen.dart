import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/dispatch/application/delivery_form_controller.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/customer_dto.dart';
import 'package:durvaeco/features/partners/data/models/transporter_dto.dart';
import 'package:durvaeco/features/partners/data/models/vehicle_dto.dart';
import 'package:durvaeco/features/sales/application/sales_providers.dart';
import 'package:durvaeco/features/sales/data/models/sale_dto.dart';

class DeliveryFormScreen extends ConsumerStatefulWidget {
  final SaleDto? prefilledSale;
  final DeliveryDto? existingDelivery;

  const DeliveryFormScreen({
    super.key,
    this.prefilledSale,
    this.existingDelivery,
  });

  @override
  ConsumerState<DeliveryFormScreen> createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends ConsumerState<DeliveryFormScreen> {
  final _deliveryNoCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _trackingCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _freightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(deliveryFormControllerProvider.notifier);
      if (widget.existingDelivery != null) {
        controller.initForEdit(widget.existingDelivery!);
        _deliveryNoCtrl.text = widget.existingDelivery!.deliveryNumber;
        _driverNameCtrl.text = widget.existingDelivery!.driverName ?? '';
        _driverPhoneCtrl.text = widget.existingDelivery!.driverPhone ?? '';
        _trackingCtrl.text = widget.existingDelivery!.trackingNumber ?? '';
        _addressCtrl.text = widget.existingDelivery!.deliveryAddress ?? '';
        _freightCtrl.text = widget.existingDelivery!.freightAmount.toString();
        _notesCtrl.text = widget.existingDelivery!.notes ?? '';
      } else if (widget.prefilledSale != null) {
        controller.initFromSale(widget.prefilledSale!);
        _deliveryNoCtrl.text = 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        _freightCtrl.text = widget.prefilledSale!.transportCharge.toString();
      } else {
        controller.initForCreate();
        _deliveryNoCtrl.text = 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      }
    });
  }

  @override
  void dispose() {
    _deliveryNoCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _trackingCtrl.dispose();
    _addressCtrl.dispose();
    _freightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(deliveryFormControllerProvider);
    final formNotifier = ref.read(deliveryFormControllerProvider.notifier);

    final salesAsync = ref.watch(salesListProvider);
    final customersAsync = ref.watch(customersListProvider);
    final transportersAsync = ref.watch(transportersListProvider);
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingDelivery != null ? 'Edit Delivery Dispatch' : 'New Outward Dispatch'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order & Dispatch Details
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
                    const Text('Shipment Header', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _deliveryNoCtrl,
                      decoration: const InputDecoration(labelText: 'Delivery / Challan Number *', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateDeliveryNumber,
                    ),
                    const SizedBox(height: Spacing.md),
                    salesAsync.when(
                      data: (List<SaleDto> sales) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: formState.saleId > 0 ? formState.saleId : null,
                        decoration: const InputDecoration(labelText: 'Sales Order / Invoice *', border: OutlineInputBorder()),
                        items: sales.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.invoiceNumber} - ${s.customerName ?? ""}', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: widget.prefilledSale != null
                            ? null
                            : (val) {
                                if (val != null) {
                                  final sale = sales.firstWhere((s) => s.id == val);
                                  formNotifier.initFromSale(sale);
                                }
                              },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading sales: $err'),
                    ),
                    const SizedBox(height: Spacing.md),
                    customersAsync.when(
                      data: (List<CustomerDto> customers) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: formState.customerId > 0 ? formState.customerId : null,
                        decoration: const InputDecoration(labelText: 'Customer *', border: OutlineInputBorder()),
                        items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.customerName, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) formNotifier.updateCustomerId(val);
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading customers: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Fleet & Transporter Assignment
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
                    const Text('Transporter & Fleet Logistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                    const SizedBox(height: Spacing.md),
                    transportersAsync.when(
                      data: (List<TransporterDto> transporters) => DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: formState.transporterId,
                        decoration: const InputDecoration(labelText: 'Transporter', border: OutlineInputBorder()),
                        items: transporters.map((t) => DropdownMenuItem(value: t.id, child: Text(t.transporterName, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => formNotifier.updateTransporterId(val),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    const SizedBox(height: Spacing.md),
                    vehiclesAsync.when(
                      data: (List<VehicleDto> vehicles) {
                        final filteredVehicles = formState.transporterId != null
                            ? vehicles.where((v) => v.transporterId == formState.transporterId).toList()
                            : vehicles;
                        return DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: formState.vehicleId,
                          decoration: const InputDecoration(labelText: 'Vehicle / Truck', border: OutlineInputBorder()),
                          items: filteredVehicles
                              .map((v) => DropdownMenuItem(
                                    value: v.id,
                                    child: Text('${v.vehicleNumber} (${v.vehicleType})', overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final veh = vehicles.firstWhere((v) => v.id == val);
                              formNotifier.updateVehicle(veh);
                              _driverNameCtrl.text = veh.driverName ?? '';
                              _driverPhoneCtrl.text = veh.driverPhone ?? '';
                            }
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _driverNameCtrl,
                            decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder()),
                            onChanged: formNotifier.updateDriverName,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _driverPhoneCtrl,
                            decoration: const InputDecoration(labelText: 'Driver Phone', border: OutlineInputBorder()),
                            onChanged: formNotifier.updateDriverPhone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _trackingCtrl,
                            decoration: const InputDecoration(labelText: 'Tracking / LR No', border: OutlineInputBorder()),
                            onChanged: formNotifier.updateTrackingNumber,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _freightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Freight (₹)', border: OutlineInputBorder()),
                            onChanged: (v) => formNotifier.updateFreightAmount(double.tryParse(v) ?? 0.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Delivery Destination Address', border: OutlineInputBorder()),
                      onChanged: formNotifier.updateDeliveryAddress,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),

            // Dispatched Line Items
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
                        const Text('Items to Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BrandColors.primary)),
                        Text('Total: ${formState.totalDispatchedUnits.toStringAsFixed(0)} pcs', style: const TextStyle(fontWeight: FontWeight.bold, color: BrandColors.primary)),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    if (formState.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Select a sales order to load items for dispatch.', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: formState.items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final item = formState.items[index];
                          final qtyCtrl = TextEditingController(text: item.quantity.toStringAsFixed(0));
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.productName ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Product ID: ${item.productId}'),
                            trailing: SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: qtyCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Dispatch Qty',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onChanged: (v) {
                                  final num = double.tryParse(v) ?? 0.0;
                                  formNotifier.updateItemQuantity(index, num);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            ElevatedButton(
              onPressed: formState.formStatus == DeliveryFormStatus.submitting
                  ? null
                  : () async {
                      final success = await formNotifier.submit();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.existingDelivery != null ? 'Delivery updated!' : 'Delivery dispatch created!'),
                            backgroundColor: BrandColors.primary,
                          ),
                        );
                        Navigator.of(context).pop();
                      } else if (formState.failure != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${formState.failure!.message}'), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
              ),
              child: formState.formStatus == DeliveryFormStatus.submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm & Create Dispatch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
