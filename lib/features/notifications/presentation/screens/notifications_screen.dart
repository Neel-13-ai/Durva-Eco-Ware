import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:durvaeco/app/theme/tokens.dart';
import 'package:durvaeco/features/notifications/application/notification_providers.dart';
import 'package:durvaeco/features/notifications/data/models/notification_dto.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'ALL'; // ALL, UNREAD, ALERTS

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'LOW_STOCK':
        return Icons.warning_amber_rounded;
      case 'PURCHASE_PENDING':
        return Icons.shopping_bag_outlined;
      case 'PRODUCTION_ALERT':
        return Icons.precision_manufacturing_outlined;
      case 'DISPATCH_READY':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'LOW_STOCK':
        return const Color(0xFFC62828);
      case 'PURCHASE_PENDING':
        return const Color(0xFF00796B);
      case 'PRODUCTION_ALERT':
        return const Color(0xFF1565C0);
      case 'DISPATCH_READY':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF673AB7);
    }
  }

  void _handleDeepLink(NotificationDto item) {
    ref.read(notificationRepositoryProvider).markAsRead(item.id);
    ref.invalidate(notificationsListProvider);

    switch (item.notificationType) {
      case 'LOW_STOCK':
        context.push('/inventory');
        break;
      case 'PURCHASE_PENDING':
        context.push('/purchases');
        break;
      case 'PRODUCTION_ALERT':
        context.push('/production');
        break;
      case 'DISPATCH_READY':
        context.push('/dispatch');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(notificationsListProvider),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: notificationsAsync.when(
        data: (allNotifications) {
          final filtered = allNotifications.where((n) {
            if (_filter == 'UNREAD') return !n.isRead;
            if (_filter == 'ALERTS') return n.notificationType == 'LOW_STOCK' || n.notificationType == 'PRODUCTION_ALERT';
            return true;
          }).toList();

          return Column(
            children: [
              // Filter Chips Row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All', style: TextStyle(fontSize: 12)),
                      selected: _filter == 'ALL',
                      selectedColor: BrandColors.primary,
                      onSelected: (_) => setState(() => _filter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Unread Only', style: TextStyle(fontSize: 12)),
                      selected: _filter == 'UNREAD',
                      selectedColor: BrandColors.primary,
                      onSelected: (_) => setState(() => _filter = 'UNREAD'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Urgent Alerts', style: TextStyle(fontSize: 12)),
                      selected: _filter == 'ALERTS',
                      selectedColor: BrandColors.primary,
                      onSelected: (_) => setState(() => _filter = 'ALERTS'),
                    ),
                  ],
                ),
              ),

              // List of Notifications
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: Spacing.md),
                            const Text('All caught up!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: Spacing.xs),
                            const Text('No notifications matching your filter.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(Spacing.md),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                        itemBuilder: (ctx, index) {
                          final item = filtered[index];
                          final color = _getTypeColor(item.notificationType);

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.md),
                              side: BorderSide(
                                color: item.isRead ? const Color(0xFFE2E8F0) : BrandColors.primary.withValues(alpha: 0.5),
                                width: item.isRead ? 1.0 : 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(Radii.md),
                              onTap: () => _handleDeepLink(item),
                              child: Padding(
                                padding: const EdgeInsets.all(Spacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color.withValues(alpha: 0.1),
                                      foregroundColor: color,
                                      child: Icon(_getTypeIcon(item.notificationType), size: 20),
                                    ),
                                    const SizedBox(width: Spacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 14)),
                                              if (!item.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(color: BrandColors.primary, shape: BoxShape.circle),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(item.message, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ),
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
        error: (err, _) => Center(child: Text('Error loading notifications: $err')),
      ),
    );
  }
}
