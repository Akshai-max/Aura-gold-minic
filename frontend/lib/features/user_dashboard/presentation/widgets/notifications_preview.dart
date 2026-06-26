import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ags_gold/core/theme/app_theme.dart';
import 'package:ags_gold/features/notifications/domain/notification.dart';

class NotificationsPreview extends StatelessWidget {
  final List<AppNotification> notifications;
  final VoidCallback? onViewAll;

  const NotificationsPreview({
    super.key,
    required this.notifications,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d • HH:mm');

    return Card(
      child: notifications.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No unread notifications.'),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                    child: Icon(
                      _categoryIcon(notification.category),
                      color: AppTheme.primaryGold,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    dateFormat.format(notification.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'workflow':
        return Icons.approval_outlined;
      case 'security':
        return Icons.security_outlined;
      case 'transaction':
        return Icons.receipt_long_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
