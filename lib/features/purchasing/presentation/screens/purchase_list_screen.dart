import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/partners/application/providers/partner_providers.dart';
import 'package:durvaeco/features/purchasing/application/providers/purchase_providers.dart';
import 'package:durvaeco/features/purchasing/data/models/purchase_dto.dart';

class PurchaseListScreen extends ConsumerStatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  ConsumerState<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends ConsumerState<PurchaseListScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ref.read(purchaseSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesListProvider);
    final selectedStatus = ref.watch(purchaseFilterStatusProvider);
    final searchQuery = ref.watch(purchaseSearchQueryProvider);
    ref.watch(activeSuppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
        onPressed: () => context.push('/purchases/new'),
      ),
      body: Column(
        children: [
          // Search & Filter Header Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, 0, Spacing.xs),
            child: Column(
              children: [
                // Search Input Field
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search PO number, vendor...',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(purchaseSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(purchaseSearchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(height: Spacing.xs),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedStatus == null,
                        selectedColor: BrandColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: BrandColors.primary,
                        labelStyle: TextStyle(
                          color: selectedStatus == null ? BrandColors.primary : const Color(0xFF475569),
                          fontWeight: selectedStatus == null ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = null,
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Draft'),
                        selected: selectedStatus == PurchaseStatus.draft,
                        selectedColor: Colors.grey.withValues(alpha: 0.2),
                        checkmarkColor: Colors.grey.shade800,
                        labelStyle: TextStyle(
                          color: selectedStatus == PurchaseStatus.draft ? Colors.grey.shade900 : const Color(0xFF475569),
                          fontWeight: selectedStatus == PurchaseStatus.draft ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = PurchaseStatus.draft,
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Pending'),
                        selected: selectedStatus == PurchaseStatus.pending,
                        selectedColor: Colors.orange.withValues(alpha: 0.2),
                        checkmarkColor: Colors.orange.shade800,
                        labelStyle: TextStyle(
                          color: selectedStatus == PurchaseStatus.pending ? Colors.orange.shade900 : const Color(0xFF475569),
                          fontWeight: selectedStatus == PurchaseStatus.pending ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = PurchaseStatus.pending,
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Approved'),
                        selected: selectedStatus == PurchaseStatus.approved,
                        selectedColor: Colors.blue.withValues(alpha: 0.2),
                        checkmarkColor: Colors.blue.shade800,
                        labelStyle: TextStyle(
                          color: selectedStatus == PurchaseStatus.approved ? Colors.blue.shade900 : const Color(0xFF475569),
                          fontWeight: selectedStatus == PurchaseStatus.approved ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = PurchaseStatus.approved,
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Received'),
                        selected: selectedStatus == PurchaseStatus.received,
                        selectedColor: Colors.green.withValues(alpha: 0.2),
                        checkmarkColor: Colors.green.shade800,
                        labelStyle: TextStyle(
                          color: selectedStatus == PurchaseStatus.received ? Colors.green.shade900 : const Color(0xFF475569),
                          fontWeight: selectedStatus == PurchaseStatus.received ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => ref.read(purchaseFilterStatusProvider.notifier).state = PurchaseStatus.received,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main List View
          Expanded(
            child: RefreshIndicator(
              color: BrandColors.primary,
              onRefresh: () async {
                ref.invalidate(purchasesListProvider);
                ref.invalidate(activeSuppliersProvider);
                try {
                  await ref.read(purchasesListProvider.future);
                } catch (_) {}
              },
              child: purchasesAsync.when(
                data: (purchases) {
                  if (purchases.isEmpty) {
                    final isFiltered = selectedStatus != null || searchQuery.isNotEmpty;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(Spacing.xl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isFiltered ? Icons.search_off_outlined : Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: Spacing.md),
                                  Text(
                                    isFiltered ? 'No matching purchase orders' : 'No purchase orders found',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isFiltered
                                        ? 'Try modifying your search or clearing active filters.'
                                        : 'Tap + New PO to generate your raw material purchase order.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                  if (isFiltered) ...[
                                    const SizedBox(height: Spacing.md),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        ref.read(purchaseSearchQueryProvider.notifier).state = '';
                                        ref.read(purchaseFilterStatusProvider.notifier).state = null;
                                      },
                                      icon: const Icon(Icons.filter_alt_off, size: 16),
                                      label: const Text('Clear Filters'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: BrandColors.primary,
                                        side: const BorderSide(color: BrandColors.primary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 96),
                    itemCount: purchases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final po = purchases[index];
                      return _PurchaseCard(purchase: po);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
                error: (err, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 8),
                              Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => ref.invalidate(purchasesListProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends ConsumerWidget {
  const _PurchaseCard({required this.purchase});

  final PurchaseDto purchase;

  Color _statusColor(PurchaseStatus s) {
    switch (s) {
      case PurchaseStatus.draft:
        return const Color(0xFF64748B);
      case PurchaseStatus.pending:
        return const Color(0xFFE65100);
      case PurchaseStatus.approved:
        return const Color(0xFF1565C0);
      case PurchaseStatus.partiallyReceived:
        return const Color(0xFF00796B);
      case PurchaseStatus.received:
        return const Color(0xFF2E7D32);
      case PurchaseStatus.cancelled:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(purchase.status);
    final recordedPayments = ref.watch(vendorPaymentsListProvider(purchase.id)).valueOrNull ?? [];
    final effectivePaid = recordedPayments.isNotEmpty
        ? recordedPayments.fold<double>(0.0, (sum, p) => sum + p.amount)
        : purchase.paidAmount;
    final isPaid = (purchase.totalAmount > 0 && (purchase.totalAmount - effectivePaid) <= 0.01) || purchase.isFullyPaid;
    final isPartial = !isPaid && effectivePaid > 0;
    final suppliers = ref.watch(activeSuppliersProvider).valueOrNull;
    final supplierDisplay = (purchase.supplierName != null && !purchase.supplierName!.startsWith('Supplier #'))
        ? purchase.supplierName!
        : (suppliers?.where((s) => s.id == purchase.supplierId).firstOrNull?.supplierName ?? 'Supplier #${purchase.supplierId}');

    return InkWell(
      onTap: () => context.push('/purchases/${purchase.id}', extra: purchase),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: PO Number and Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    purchase.purchaseNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Text(
                    purchase.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Supplier / Vendor Row
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    supplierDisplay,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bottom Row: Date, Payment Status & Amount
            Row(
              children: [
                // Date
                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '${purchase.purchaseDate.day.toString().padLeft(2, '0')}/${purchase.purchaseDate.month.toString().padLeft(2, '0')}/${purchase.purchaseDate.year}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),

                // Payment Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFE8F5E9)
                        : (isPartial ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : (isPartial ? 'PARTIAL' : 'UNPAID'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isPaid
                          ? const Color(0xFF2E7D32)
                          : (isPartial ? const Color(0xFFE65100) : const Color(0xFFC62828)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Amount
                Text(
                  '₹${purchase.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
