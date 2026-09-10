import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/dispatch/application/dispatch_providers.dart';
import 'package:durvaeco/features/dispatch/data/models/delivery_dto.dart';
import 'package:durvaeco/features/dispatch/presentation/screens/delivery_detail_screen.dart';
import 'package:durvaeco/features/dispatch/presentation/screens/delivery_form_screen.dart';
import 'package:durvaeco/features/dispatch/presentation/screens/pending_dispatch_screen.dart';

class DispatchHistoryScreen extends ConsumerStatefulWidget {
  const DispatchHistoryScreen({super.key});

  @override
  ConsumerState<DispatchHistoryScreen> createState() => _DispatchHistoryScreenState();
}

class _DispatchHistoryScreenState extends ConsumerState<DispatchHistoryScreen> {
  String _filter = 'ALL';
  String _search = '';

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

  @override
  Widget build(BuildContext context) {
    final deliveriesAsync = ref.watch(deliveryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Logistics & Fleet'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Pending Dispatch Queue',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PendingDispatchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(deliveryListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DeliveryFormScreen()),
          );
        },
        backgroundColor: BrandColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Dispatch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: deliveriesAsync.when(
        data: (List<DeliveryDto> allDeliveries) {
          final filtered = allDeliveries.where((d) {
            final matchesSearch = _search.isEmpty ||
                d.deliveryNumber.toLowerCase().contains(_search.toLowerCase()) ||
                (d.customerName?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
                (d.transporterName?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
                (d.driverName?.toLowerCase().contains(_search.toLowerCase()) ?? false);

            if (!matchesSearch) return false;

            if (_filter == 'DRAFT') return d.status == 'DRAFT';
            if (_filter == 'DISPATCHED') return d.status == 'DISPATCHED';
            if (_filter == 'DELIVERED') return d.status == 'DELIVERED';
            return true;
          }).toList();

          final totalDispatched = allDeliveries.where((d) => d.status == 'DISPATCHED').length;
          final totalDelivered = allDeliveries.where((d) => d.status == 'DELIVERED').length;

          return Column(
            children: [
              // Metrics Banner
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Row(
                  children: [
                    _buildMetric('Total Dispatches', allDeliveries.length.toString(), const Color(0xFF1976D2)),
                    _buildMetric('In Transit', totalDispatched.toString(), const Color(0xFFE65100)),
                    _buildMetric('Delivered', totalDelivered.toString(), const Color(0xFF2E7D32)),
                  ],
                ),
              ),

              // Search & Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search delivery #, customer, driver...',
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
                          _buildFilterChip('ALL', 'All Shipments'),
                          _buildFilterChip('DRAFT', 'Drafts'),
                          _buildFilterChip('DISPATCHED', 'In Transit'),
                          _buildFilterChip('DELIVERED', 'Delivered'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Deliveries List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No delivery dispatches found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                        itemBuilder: (ctx, index) {
                          final delivery = filtered[index];
                          final totalUnits = delivery.items.fold(0.0, (sum, i) => sum + i.quantity);

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
                                  MaterialPageRoute<void>(
                                    builder: (_) => DeliveryDetailScreen(deliveryId: delivery.id),
                                  ),
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
                                          delivery.deliveryNumber,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BrandColors.primary),
                                        ),
                                        _buildStatusBadge(delivery.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(delivery.customerName ?? 'Customer #${delivery.customerId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Transporter: ${delivery.transporterName ?? "Direct Fleet"} • Truck: ${delivery.vehicleNumber ?? "N/A"}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Date: ${delivery.deliveryDate.day}/${delivery.deliveryDate.month}/${delivery.deliveryDate.year}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '${totalUnits.toStringAsFixed(0)} pcs dispatched',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
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
        error: (err, _) => Center(child: Text('Error loading deliveries: $err')),
      ),
    );
  }
}
