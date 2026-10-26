import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/inventory/data/models/audit_log_dto.dart';
import 'package:durvaeco/features/inventory/application/providers/inventory_providers.dart';

final auditLogSearchProvider = StateProvider<String>((ref) => '');
final auditLogTableFilterProvider = StateProvider<String?>((ref) => null);

final allAuditLogsProvider = FutureProvider<List<AuditLogDto>>((ref) async {
  final repo = ref.watch(auditLogRepositoryProvider);
  final tableFilter = ref.watch(auditLogTableFilterProvider);
  final result = await repo.listAuditLogs(tableName: tableFilter);
  return result.when(
    success: (list) => list,
    failure: (f) => throw Exception(f.message),
  );
});

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(allAuditLogsProvider);
    final selectedTable = ref.watch(auditLogTableFilterProvider);
    final search = ref.watch(auditLogSearchProvider);

    final tables = [
      'Products',
      'Purchases',
      'Sales',
      'ProductionOrders',
      'Warehouses',
      'StockBalances',
      'Users',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by user, action, or record ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                  onChanged: (v) => ref.read(auditLogSearchProvider.notifier).state = v.trim().toLowerCase(),
                ),
                const SizedBox(height: Spacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: const Text('All Entities', style: TextStyle(fontSize: 12)),
                          selected: selectedTable == null,
                          selectedColor: BrandColors.primary,
                          labelStyle: TextStyle(
                            color: selectedTable == null ? Colors.white : const Color(0xFF64748B),
                            fontWeight: selectedTable == null ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => ref.read(auditLogTableFilterProvider.notifier).state = null,
                        ),
                      ),
                      ...tables.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(t, style: const TextStyle(fontSize: 12)),
                              selected: selectedTable == t,
                              selectedColor: BrandColors.primary,
                              labelStyle: TextStyle(
                                color: selectedTable == t ? Colors.white : const Color(0xFF64748B),
                                fontWeight: selectedTable == t ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => ref.read(auditLogTableFilterProvider.notifier).state = t,
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Log List
          Expanded(
            child: RefreshIndicator(
              color: BrandColors.primary,
              onRefresh: () async => ref.invalidate(allAuditLogsProvider),
              child: logsAsync.when(
                data: (logs) {
                  final filtered = logs.where((log) {
                    if (search.isEmpty) return true;
                    final matchTable = log.tableName.toLowerCase().contains(search);
                    final matchAction = log.action.toLowerCase().contains(search);
                    final matchUser = log.changedBy?.toLowerCase().contains(search) ?? false;
                    final matchRecord = log.recordId.toString().contains(search);
                    return matchTable || matchAction || matchUser || matchRecord;
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('No audit logs recorded for this criteria.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                    itemBuilder: (ctx, index) {
                      final log = filtered[index];
                      return _AuditLogCard(log: log);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: BrandColors.primary)),
                error: (err, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(child: Text('Error loading audit trail: $err')),
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

class _AuditLogCard extends StatefulWidget {
  const _AuditLogCard({required this.log});
  final AuditLogDto log;

  @override
  State<_AuditLogCard> createState() => _AuditLogCardState();
}

class _AuditLogCardState extends State<_AuditLogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    Color actionColor = const Color(0xFF1565C0);
    Color actionBg = const Color(0xFFE3F2FD);

    final actionUpper = log.action.toUpperCase();
    if (actionUpper.contains('CREATE') || actionUpper.contains('INSERT')) {
      actionColor = const Color(0xFF2E7D32);
      actionBg = const Color(0xFFE8F5E9);
    } else if (actionUpper.contains('DELETE') || actionUpper.contains('REMOVE')) {
      actionColor = Colors.red;
      actionBg = Colors.red.shade50;
    } else if (actionUpper.contains('UPDATE') || actionUpper.contains('EDIT')) {
      actionColor = const Color(0xFFE65100);
      actionBg = const Color(0xFFFFF3E0);
    }

    final hasDiff = (log.oldValues != null && log.oldValues!.isNotEmpty) ||
        (log.newValues != null && log.newValues!.isNotEmpty);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: hasDiff ? () => setState(() => _expanded = !_expanded) : null,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: actionBg, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      log.action.toUpperCase(),
                      style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${log.tableName} #${log.recordId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  const Spacer(),
                  Text(
                    '${log.changeDate.day}/${log.changeDate.month}/${log.changeDate.year} ${log.changeDate.hour}:${log.changeDate.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Changed by: ${log.changedBy ?? "System"}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  if (hasDiff)
                    Text(
                      _expanded ? 'Hide Details ▲' : 'View Details ▼',
                      style: const TextStyle(fontSize: 11, color: BrandColors.primary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              if (_expanded && hasDiff) ...[
                const Divider(height: 16),
                if (log.oldValues != null && log.oldValues!.isNotEmpty) ...[
                  const Text('Old Values:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4)),
                    child: Text(log.oldValues!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                ],
                if (log.newValues != null && log.newValues!.isNotEmpty) ...[
                  const Text('New Values:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4)),
                    child: Text(log.newValues!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
