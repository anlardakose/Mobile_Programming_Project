import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  NotificationModel? _notification;
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadNotification();
  }

  Future<void> _loadNotification() async {
    try {
      final provider = context.read<NotificationProvider>();
      // Önce provider'dan bul
      final notifications = provider.notifications;
      try {
        _notification = notifications.firstWhere(
          (n) => n.id == widget.notificationId,
        );
      } catch (e) {
        // Provider'da bulunamazsa servisten al
        final notificationService = NotificationService();
        _notification = await notificationService.getNotificationById(widget.notificationId);
      }
      
      if (_notification != null) {
        final userId = context.read<AuthProvider>().currentUser?.id ?? '';
        _isFollowing = _notification!.followedBy?.contains(userId) ?? false;
      }
    } catch (e) {
      // Hata durumunda null bırak
      _notification = null;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _updateStatus(NotificationStatus newStatus) async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.updateNotificationStatus(
      widget.notificationId,
      newStatus,
    );

    if (!mounted) return;

    if (success) {
      _loadNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final provider = context.read<NotificationProvider>();
    final success = _isFollowing
        ? await provider.unfollowNotification(widget.notificationId, userId)
        : await provider.followNotification(widget.notificationId, userId);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isFollowing = !_isFollowing;
      });
    }
  }

  Future<void> _editTitle(BuildContext context) async {
    final titleController = TextEditingController(text: _notification?.title ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(titleController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final provider = context.read<NotificationProvider>();
      final success = await provider.updateNotificationTitle(
        widget.notificationId,
        result,
      );

      if (!mounted) return;

      if (success) {
        _loadNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update title')),
        );
      }
    }
  }

  Future<void> _editDescription(BuildContext context) async {
    final descriptionController = TextEditingController(text: _notification?.description ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            hintText: 'Enter new description',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(descriptionController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final provider = context.read<NotificationProvider>();
      final success = await provider.updateNotificationDescription(
        widget.notificationId,
        result,
      );

      if (!mounted) return;

      if (success) {
        _loadNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update description')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_notification == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Details')),
        body: const Center(child: Text('Notification not found')),
      );
    }

    final notification = _notification!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isAdmin = authProvider.isAdmin;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notification Details'),
            actions: [
              IconButton(
                icon: Icon(_isFollowing ? Icons.favorite : Icons.favorite_border),
                onPressed: _toggleFollow,
                tooltip: _isFollowing ? 'Unfollow' : 'Follow',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(notification.type),
                        color: _getTypeColor(notification.type),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.typeDisplayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(notification.status)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              notification.statusDisplayName,
                              style: TextStyle(
                                color: _getStatusColor(notification.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTitle(context),
                        tooltip: 'Edit Title',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editDescription(context),
                          tooltip: 'Edit Description',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Created At
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(notification.createdAt),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Location
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(notification.latitude, notification.longitude),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('notification_location'),
                          position: LatLng(notification.latitude, notification.longitude),
                          infoWindow: InfoWindow(title: notification.title),
                        ),
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Photos
                if (notification.photoUrls != null &&
                    notification.photoUrls!.isNotEmpty) ...[
                  Text(
                    'Photos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: notification.photoUrls!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              notification.photoUrls![index],
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Admin Actions
                if (isAdmin) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Admin Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Status Update Buttons
                  if (notification.status == NotificationStatus.open)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(NotificationStatus.underReview),
                        child: const Text('Mark as Under Review'),
                      ),
                    ),
                  if (notification.status == NotificationStatus.underReview) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(NotificationStatus.resolved),
                        child: const Text('Mark as Resolved'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _updateStatus(NotificationStatus.open),
                        child: const Text('Reopen'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
