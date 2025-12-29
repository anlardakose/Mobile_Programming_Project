import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtreleme
  NotificationType? _filterType;
  bool _filterOpenOnly = false;
  bool _filterFollowingOnly = false;
  String _searchQuery = '';

  NotificationType? get filterType => _filterType;
  bool get filterOpenOnly => _filterOpenOnly;
  bool get filterFollowingOnly => _filterFollowingOnly;
  String get searchQuery => _searchQuery;

  // Filtrelenmiş bildirimler
  List<NotificationModel> getFilteredNotifications(String? userId) {
    var filtered = List<NotificationModel>.from(_notifications);

    // Tip filtresi
    if (_filterType != null) {
      filtered = filtered.where((n) => n.type == _filterType).toList();
    }

    // Sadece açık olanlar
    if (_filterOpenOnly) {
      filtered = filtered.where((n) => n.status == NotificationStatus.open).toList();
    }

    // Arama sorgusu
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               n.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Takip edilenler
    if (_filterFollowingOnly && userId != null) {
      filtered = filtered.where((n) {
        return n.followedBy?.contains(userId) ?? false;
      }).toList();
    }

    // Tarihe göre sırala (en yeni üstte)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }
  

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getAllNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNotification(NotificationModel notification) async {
    try {
      final created = await _notificationService.createNotification(notification);
      if (created) {
        await loadNotifications();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotificationStatus(
    String notificationId,
    NotificationStatus newStatus,
  ) async {
    try {
      final updated = await _notificationService.updateNotificationStatus(
        notificationId,
        newStatus,
      );
      if (updated) {
        await loadNotifications();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> followNotification(String notificationId, String userId) async {
    try {
      return await _notificationService.followNotification(notificationId, userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unfollowNotification(String notificationId, String userId) async {
    try {
      return await _notificationService.unfollowNotification(notificationId, userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final deleted = await _notificationService.deleteNotification(notificationId);
      if (deleted) {
        await loadNotifications();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createEmergencyNotification({
    required String title,
    required String message,
    required String adminUserId,
    required String adminUserName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final created = await _notificationService.createEmergencyNotification(
        title: title,
        message: message,
        adminUserId: adminUserId,
        adminUserName: adminUserName,
        latitude: latitude,
        longitude: longitude,
      );

      if (created) {
        await loadNotifications();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setFilterType(NotificationType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterOpenOnly(bool value) {
    _filterOpenOnly = value;
    notifyListeners();
  }

  void setFilterFollowingOnly(bool value) {
    _filterFollowingOnly = value;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterType = null;
    _filterOpenOnly = false;
    _filterFollowingOnly = false;
    _searchQuery = '';
    notifyListeners();
  }
}


