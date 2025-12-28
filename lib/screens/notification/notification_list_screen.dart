import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'notification_detail_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.health:
        return Icons.medical_services;
      case NotificationType.safety:
        return Icons.security;
      case NotificationType.environment:
        return Icons.eco;
      case NotificationType.lostFound:
        return Icons.search;
      case NotificationType.technical:
        return Icons.build;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.health:
        return Colors.red;
      case NotificationType.safety:
        return Colors.orange;
      case NotificationType.environment:
        return Colors.green;
      case NotificationType.lostFound:
        return Colors.blue;
      case NotificationType.technical:
        return Colors.purple;
    }
  }

  Color _getStatusColor(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.open:
        return Colors.green;
      case NotificationStatus.underReview:
        return Colors.orange;
      case NotificationStatus.resolved:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search notifications...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<NotificationProvider>().setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              context.read<NotificationProvider>().setSearchQuery(value);
            },
          ),
        ),
        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Types'),
                  selected: context.watch<NotificationProvider>().filterType == null,
                  onSelected: (selected) {
                    context.read<NotificationProvider>().setFilterType(null);
                  },
                ),
                const SizedBox(width: 8),
                ...NotificationType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(type.toString().split('.').last),
                      selected: context.watch<NotificationProvider>().filterType == type,
                      onSelected: (selected) {
                        context.read<NotificationProvider>().setFilterType(
                              selected ? type : null,
                            );
                      },
                    ),
                  );
                }),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Open Only'),
                  selected: context.watch<NotificationProvider>().filterOpenOnly,
                  onSelected: (selected) {
                    context.read<NotificationProvider>().setFilterOpenOnly(selected);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Notification List
        Expanded(
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = provider.filteredNotifications;

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await provider.loadNotifications();
                },
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(notification.type).withOpacity(0.2),
                          child: Icon(
                            _getTypeIcon(notification.type),
                            color: _getTypeColor(notification.type),
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(notification.status)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    notification.statusDisplayName,
                                    style: TextStyle(
                                      color: _getStatusColor(notification.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getTimeAgo(notification.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NotificationDetailScreen(
                                notificationId: notification.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


