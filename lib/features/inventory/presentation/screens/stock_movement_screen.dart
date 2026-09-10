import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/inventory/data/models/stock_transaction_dto.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';

class StockMovementScreen extends ConsumerStatefulWidget {
  const StockMovementScreen({super.key});

  @override
  ConsumerState<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends ConsumerState<StockMovementScreen> {
  StockTransactionType? _selectedType;

  void _filterType(StockTransactionType? type) {
    setState(() => _selectedType = type);
    ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
      type: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(stockTransactionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Ledger'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(stockTransactionsListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Movements',
                    isSelected: _selectedType == null,
                    onSelected: () => _filterType(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Inward (+)',
                    isSelected: _selectedType == StockTransactionType.inward,
                    onSelected: () => _filterType(StockTransactionType.inward),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Outward (-)',
                    isSelected: _selectedType == StockTransactionType.outward,
                    onSelected: () => _filterType(StockTransactionType.outward),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Adjustments',
                    isSelected: _selectedType == StockTransactionType.adjustment,
                    onSelected: () => _filterType(StockTransactionType.adjustment),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Transfers',
                    isSelected: _selectedType == StockTransactionType.transfer,
                    onSelected: () => _filterType(StockTransactionType.transfer),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text('No stock movements recorded', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                  itemBuilder: (ctx, index) {
                    final tx = transactions[index];
                    return _TransactionCard(tx: tx);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: BrandColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? BrandColors.primary : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});

  final StockTransactionDto tx;

  @override
  Widget build(BuildContext context) {
    final isInward = tx.transactionType == StockTransactionType.inward || tx.quantityIn > 0;
    final isOutward = tx.transactionType == StockTransactionType.outward || tx.quantityOut > 0;
    final isAdjustment = tx.transactionType == StockTransactionType.adjustment;

    Color badgeColor;
    Color badgeBg;
    String typeLabel;
    String qtyText;

    if (isAdjustment) {
      badgeColor = Colors.purple;
      badgeBg = Colors.purple.shade50;
      typeLabel = 'ADJUSTMENT';
      qtyText = tx.quantityIn > 0 ? '+${tx.quantityIn}' : '-${tx.quantityOut}';
    } else if (isInward) {
      badgeColor = const Color(0xFF2E7D32);
      badgeBg = const Color(0xFFE8F5E9);
      typeLabel = 'INWARD';
      qtyText = '+${tx.quantityIn}';
    } else if (isOutward) {
      badgeColor = Colors.red;
      badgeBg = Colors.red.shade50;
      typeLabel = 'OUTWARD';
      qtyText = '-${tx.quantityOut}';
    } else {
      badgeColor = Colors.blue;
      badgeBg = Colors.blue.shade50;
      typeLabel = 'TRANSFER';
      qtyText = '${tx.quantityIn > 0 ? tx.quantityIn : tx.quantityOut}';
    }

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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(Radii.sm)),
                  child: Text(typeLabel, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Text(
                  '${tx.transactionDate.day}/${tx.transactionDate.month}/${tx.transactionDate.year} ${tx.transactionDate.hour}:${tx.transactionDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const Spacer(),
                Text(
                  qtyText,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: badgeColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tx.productName ?? 'Product #${tx.productId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Warehouse: ${tx.warehouseName ?? "#${tx.warehouseId}"}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                if (tx.batchNo != null && tx.batchNo!.isNotEmpty) ...[
                  const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                  Text('Batch: ${tx.batchNo}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ],
            ),
            if (tx.notes != null && tx.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tx.notes!,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
