import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/common_widgets.dart';

class NotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const NotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class NotificationsScreen extends StatelessWidget {
  final List<NotificationItem> notifications;

  const NotificationsScreen({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartTopBar(title: 'Notifications', showBack: true),
      body: SmartPage(
        title: 'Notifications',
        subtitle: 'Current profile, sales, prep, and waste alerts.',
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          if (notifications.isEmpty)
            const EmptyStateCard(
              icon: Icons.check_circle_outline,
              title: 'All clear',
              message: 'No urgent profile or operations alerts right now.',
            )
          else
            ...notifications.map((item) => _NotificationCard(item: item)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SmartCard(
        color: AppTheme.surfaceHigh,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
