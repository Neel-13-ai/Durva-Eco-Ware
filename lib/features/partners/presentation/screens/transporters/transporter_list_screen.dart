import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/transporter_dto.dart';

class TransporterListScreen extends ConsumerWidget {
  const TransporterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportersAsync = ref.watch(transportersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transporters & Fleet'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car_outlined),
            tooltip: 'View All Vehicles',
            onPressed: () => context.push('/partners/vehicles'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(transportersListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Transporter'),
        onPressed: () => context.push('/partners/transporters/new'),
      ),
      body: transportersAsync.when(
        data: (transporters) {
          if (transporters.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Color(0xFF94A3B8)),
                  SizedBox(height: Spacing.md),
                  Text('No transporters added', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Tap + Add Transporter to manage your logistics vendors & trucks', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: transporters.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              final t = transporters[index];
              return _TransporterCard(transporter: t);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _TransporterCard extends StatelessWidget {
  const _TransporterCard({required this.transporter});

  final TransporterDto transporter;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/partners/transporters/${transporter.id}/edit'),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    transporter.transporterCode,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                  ),
                ),
                const Spacer(),
                if (transporter.phone != null)
                  Text(transporter.phone!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              transporter.transporterName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            if (transporter.contactPerson != null) ...[
              const SizedBox(height: 2),
              Text('Contact: ${transporter.contactPerson!}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ],
        ),
      ),
    );
  }
}
