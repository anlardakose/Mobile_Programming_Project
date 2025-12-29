import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:googleapis/fcm/v1.dart' as fcm_api;
import 'package:googleapis_auth/auth_io.dart';

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

  // Service Account Key'i Firestore'dan al (V1 API için)
  Future<Map<String, dynamic>?> _getServiceAccountKey() async {
    try {
      final doc = await _firestore.collection('config').doc('fcm').get();
      if (doc.exists && doc.data()?['serviceAccountKey'] != null) {
        final keyString = doc.data()!['serviceAccountKey'] as String;
        return jsonDecode(keyString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('FCM Service Account Key Firestore\'dan alınamadı: ${e.toString()}');
    }
    return null;
  }

  // FCM V1 API ile push notification gönder
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Service Account Key'i Firestore'dan al
      final serviceAccountKey = await _getServiceAccountKey();
      
      if (serviceAccountKey == null) {
        debugPrint('FCM Service Account Key ayarlanmamış. Push notification gönderilemedi.');
        debugPrint('Lütfen Firestore\'da "config/fcm" document\'ine "serviceAccountKey" field\'ı ekleyin (JSON string olarak).');
        return;
      }

      // Service Account Credentials oluştur
      final credentials = ServiceAccountCredentials.fromJson(serviceAccountKey);
      
      // OAuth2 client oluştur
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(
        credentials,
        scopes,
      );

      try {
        // FCM API instance oluştur
        final fcm = fcm_api.FcmApi(client);
        
        // Project ID'yi service account key'den al
        final projectId = serviceAccountKey['project_id'] as String? ?? 
                         'mobileprogrammingproject-bd318';
        
        // Message oluştur
        final message = fcm_api.Message()
          ..token = token
          ..notification = (fcm_api.Notification()
            ..title = title
            ..body = body);

        // Data field'larını ekle (string olmalı)
        final dataMap = <String, String>{};
        data.forEach((key, value) {
          dataMap[key] = value.toString();
        });
        message.data = dataMap;

        // Android config
        message.android = (fcm_api.AndroidConfig()
          ..priority = fcm_api.AndroidConfig_Priority.HIGH
          ..notification = (fcm_api.AndroidNotification()
            ..sound = 'default'));

        // Bildirimi gönder
        final projectPath = 'projects/$projectId';
        final request = fcm_api.SendMessageRequest()..message = message;
        final response = await fcm.projects.messages.send(request, projectPath);

        debugPrint('Push notification başarıyla gönderildi: ${response.name}');
      } finally {
        client.close();
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

