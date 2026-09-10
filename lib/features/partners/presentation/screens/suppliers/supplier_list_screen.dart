import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/partners/data/models/supplier_dto.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers Master'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(suppliersListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
        onPressed: () => context.push('/partners/suppliers/new'),
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 64, color: Color(0xFF94A3B8)),
                  SizedBox(height: Spacing.md),
                  Text('No suppliers registered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Tap + Add Supplier to add your first raw material vendor', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: suppliers.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              final s = suppliers[index];
              return _SupplierCard(supplier: s);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.supplier});

  final SupplierDto supplier;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/partners/suppliers/${supplier.id}/edit'),
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
                    color: BrandColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    supplier.supplierCode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (supplier.phone != null)
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(supplier.phone!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              supplier.supplierName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            if (supplier.contactPerson != null) ...[
              const SizedBox(height: 2),
              Text('Contact: ${supplier.contactPerson!}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
            if (supplier.address != null || supplier.city != null) ...[
              const SizedBox(height: 2),
              Text(
                '${supplier.address ?? ""}${supplier.city != null ? ", ${supplier.city}" : ""}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
