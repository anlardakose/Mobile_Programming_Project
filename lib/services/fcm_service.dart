import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FCM token'ı al ve Firestore'a kaydet
  Future<String?> getTokenAndSave(String userId) async {
    try {
      // Notification izinleri iste
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Token'ı al
        String? token = await _messaging.getToken();
        
        if (token != null) {
          // Firestore'a kaydet
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
          
          debugPrint('FCM Token kaydedildi: $token');
          return token;
        }
      } else {
        debugPrint('FCM izinleri reddedildi');
      }
      
      return null;
    } catch (e) {
      debugPrint('FCM Token alınamadı: ${e.toString()}');
      return null;
    }
  }

  // Token'ı güncelle
  Future<void> refreshToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('FCM Token güncellenemedi: ${e.toString()}');
    }
  }

  // Tüm kullanıcılara acil durum bildirimi gönder
  Future<void> sendEmergencyNotificationToAllUsers({
    required String title,
    required String message,
  }) async {
    try {
      // Tüm kullanıcıların FCM token'larını al
      final usersSnapshot = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      final List<String> tokens = [];
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['fcmToken'] != null && (data['fcmToken'] as String).isNotEmpty) {
          tokens.add(data['fcmToken'] as String);
        }
      }

      if (tokens.isEmpty) {
        debugPrint('Hiçbir kullanıcının FCM token\'ı bulunamadı');
        return;
      }

      // Her token için acil durum bildirimi gönder
      int successCount = 0;
      for (String token in tokens) {
        try {
          await _sendPushNotification(
            token: token,
            title: '🚨 ACİL DURUM: $title',
            body: message,
            data: {
              'type': 'emergency',
              'title': title,
              'message': message,
            },
          );
          successCount++;
        } catch (e) {
          debugPrint('Token için bildirim gönderilemedi: $token - ${e.toString()}');
        }
      }

      debugPrint('$successCount/${tokens.length} kullanıcıya acil durum bildirimi gönderildi');
    } catch (e) {
      debugPrint('Acil durum bildirimi gönderilemedi: ${e.toString()}');
    }
  }

  // Takip eden kullanıcılara push notification gönder
  Future<void> sendNotificationToFollowers({
    required String notificationId,
    required String notificationTitle,
    required String oldStatus,
    required String newStatus,
    required List<String> followerUserIds,
  }) async {
    if (followerUserIds.isEmpty) {
      return;
    }

    try {
      // Takip eden kullanıcıların FCM token'larını al
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followerUserIds)
          .get();

      final List<String> tokens = [];
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['fcmToken'] != null) {
          tokens.add(data['fcmToken'] as String);
        }
      }

      if (tokens.isEmpty) {
        debugPrint('Takip eden kullanıcıların FCM token\'ı bulunamadı');
        return;
      }

      // Status değişikliği mesajı oluştur
      final statusMessages = {
        'open': 'Açık',
        'underReview': 'İnceleniyor',
        'resolved': 'Çözüldü',
      };

      final oldStatusText = statusMessages[oldStatus] ?? oldStatus;
      final newStatusText = statusMessages[newStatus] ?? newStatus;

      // Her token için bildirim gönder
      for (String token in tokens) {
        await _sendPushNotification(
          token: token,
          title: 'Bildirim Durumu Güncellendi',
          body: '$notificationTitle bildirimi "$oldStatusText" durumundan "$newStatusText" durumuna güncellendi.',
          data: {
            'type': 'status_update',
            'notificationId': notificationId,
            'oldStatus': oldStatus,
            'newStatus': newStatus,
          },
        );
      }

      debugPrint('${tokens.length} kullanıcıya push notification gönderildi');
    } catch (e) {
      debugPrint('Push notification gönderilemedi: ${e.toString()}');
    }
  }

  // Server Key'i Firestore'dan al
  Future<String?> _getServerKey() async {
    try {
      final doc = await _firestore.collection('config').doc('fcm').get();
      if (doc.exists && doc.data()?['serverKey'] != null) {
        return doc.data()!['serverKey'] as String;
      }
    } catch (e) {
      debugPrint('FCM Server Key Firestore\'dan alınamadı: ${e.toString()}');
    }
    return null;
  }

  // FCM HTTP API ile push notification gönder
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Server Key'i Firestore'dan al
      final serverKey = await _getServerKey();
      
      if (serverKey == null || serverKey.isEmpty) {
        debugPrint('FCM Server Key ayarlanmamış. Push notification gönderilemedi.');
        debugPrint('Lütfen Firestore\'da "config/fcm" document\'ine "serverKey" field\'ı ekleyin.');
        return;
      }

      // FCM HTTP API endpoint
      const url = 'https://fcm.googleapis.com/fcm/send';

      // Data field'larını string'e çevir
      final dataMap = <String, String>{};
      data.forEach((key, value) {
        dataMap[key] = value.toString();
      });

      // Request body oluştur
      final requestBody = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': dataMap,
        'priority': 'high',
        'android': {
          'priority': 'high',
        },
      };

      // HTTP POST isteği gönder
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint('Push notification başarıyla gönderildi');
      } else {
        debugPrint('Push notification gönderilemedi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Push notification hatası: ${e.toString()}');
    }
  }

  // Background message handler (top-level function olmalı)
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    debugPrint('Background message alındı: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
  }
}

