import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<NotificationType, bool> _notificationSettings = {
    NotificationType.health: true,
    NotificationType.safety: true,
    NotificationType.environment: true,
    NotificationType.lostFound: true,
    NotificationType.technical: true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var type in NotificationType.values) {
        final key = 'notification_${type.toString()}';
        _notificationSettings[type] = prefs.getBool(key) ?? true;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in _notificationSettings.entries) {
      await prefs.setBool('notification_${entry.key.toString()}', entry.value);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
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

  String _getTypeName(NotificationType type) {
    return type.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Types',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select which types of notifications you want to receive',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ...NotificationType.values.map((type) {
                    return SwitchListTile(
                      secondary: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                      ),
                      title: Text(_getTypeName(type)),
                      value: _notificationSettings[type] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _notificationSettings[type] = value;
                        });
                        _saveSettings();
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

