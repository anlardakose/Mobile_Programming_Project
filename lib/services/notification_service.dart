import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm bildirimleri al
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return NotificationModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: ${e.toString()}');
    }
  }

  // Tek bir bildirimi al
  Future<NotificationModel?> getNotificationById(String id) async {
    try {
      final doc = await _firestore.collection('notifications').doc(id).get();
      if (doc.exists) {
        return NotificationModel.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load notification: ${e.toString()}');
    }
  }

  // Yeni bildirim oluştur
  Future<bool> createNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).set(
            notification.toJson(),
          );
      return true;
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  // Bildirim durumunu güncelle
  Future<bool> updateNotificationStatus(
    String notificationId,
    NotificationStatus newStatus,
  ) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': newStatus.toString(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update notification status: ${e.toString()}');
    }
  }

  // Bildirim açıklamasını güncelle (Admin için)
  Future<bool> updateNotificationDescription(
    String notificationId,
    String newDescription,
  ) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'description': newDescription,
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update notification description: ${e.toString()}');
    }
  }

  // Bildirimi takip et
  Future<bool> followNotification(String notificationId, String userId) async {
    try {
      final doc = await _firestore.collection('notifications').doc(notificationId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final followedBy = List<String>.from(data['followedBy'] ?? []);
        
        if (!followedBy.contains(userId)) {
          followedBy.add(userId);
          await _firestore.collection('notifications').doc(notificationId).update({
            'followedBy': followedBy,
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to follow notification: ${e.toString()}');
    }
  }

  // Bildirim takibini bırak
  Future<bool> unfollowNotification(String notificationId, String userId) async {
    try {
      final doc = await _firestore.collection('notifications').doc(notificationId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final followedBy = List<String>.from(data['followedBy'] ?? []);
        
        followedBy.remove(userId);
        await _firestore.collection('notifications').doc(notificationId).update({
          'followedBy': followedBy,
        });
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to unfollow notification: ${e.toString()}');
    }
  }

  // Bildirimi sil (Admin için)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  // Bildirimleri dinle (real-time updates için)
  Stream<List<NotificationModel>> getNotificationsStream() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }
}


