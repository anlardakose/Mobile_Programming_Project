# Firebase Yapılandırma Rehberi

## Adım 1: Flutter Kurulumu (Eğer kurulu değilse)
1. Flutter'ı indir: https://docs.flutter.dev/get-started/install/windows
2. Kurulum yap ve PATH'e ekle
3. Terminal'de test et: `flutter doctor`

## Adım 2: Flutter Projesini Oluştur
```bash
flutter create .
```

## Adım 3: Firebase Console'da Proje Oluştur

1. **Firebase Console'a git**: https://console.firebase.google.com/
2. **"Add project" (Proje Ekle)** tıkla
3. Proje adını gir: `smart-campus-app` (veya istediğin isim)
4. Google Analytics'i etkinleştir (isteğe bağlı)
5. **Create project** tıkla

## Adım 4: Android Uygulamasını Firebase'e Ekle

1. Firebase Console'da projeyi aç
2. **Android** ikonuna tıkla (Add app)
3. Android package name: `com.example.smart_campus_app` (android/app/build.gradle'da bulabilirsin)
4. App nickname: `Smart Campus Android`
5. Debug signing certificate SHA-1: (şimdilik boş bırak, sonra ekleriz)
6. **Register app** tıkla
7. `google-services.json` dosyasını indir
8. İndirilen dosyayı `android/app/` klasörüne kopyala

## Adım 5: iOS Uygulamasını Firebase'e Ekle (macOS gerekiyor, Windows'ta yapılamaz)

**Not**: Windows'ta iOS uygulaması geliştirilemez. Sadece Android için yapılandırma yapılabilir.

## Adım 6: FlutterFire CLI ile Yapılandırma (Önerilen)

```bash
# FlutterFire CLI'yı kur
dart pub global activate flutterfire_cli

# Firebase projesini yapılandır
flutterfire configure
```

Bu komut otomatik olarak:
- Firebase projeni seçmeni sağlar
- Gerekli platformları (Android, iOS, Web) seçmeni sağlar
- `firebase_options.dart` dosyasını oluşturur

## Adım 7: Manuel Yapılandırma (Alternatif)

### Android için:
1. `google-services.json` dosyasını `android/app/` klasörüne kopyala
2. `android/app/build.gradle` dosyasına şunu ekle:
```gradle
dependencies {
    // ...
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
}
```

3. `android/build.gradle` dosyasına şunu ekle:
```gradle
buildscript {
    dependencies {
        // ...
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

4. `android/app/build.gradle` dosyasının sonuna ekle:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Firebase Options Dosyası Oluştur:

`lib/firebase_options.dart` dosyasını oluştur (FlutterFire CLI ile otomatik oluşturulur) veya manuel olarak:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.example.smartCampusApp',
  );
}
```

**Değerleri Firebase Console > Project Settings > Your apps > Android app** bölümünden alabilirsin.

## Adım 8: main.dart'ı Güncelle

`lib/main.dart` dosyasında Firebase'i başlat:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

## Adım 9: Firebase Servislerini Etkinleştir

Firebase Console'da şu servisleri etkinleştir:

1. **Authentication**:
   - Authentication > Sign-in method
   - Email/Password'ı etkinleştir

2. **Firestore Database**:
   - Firestore Database > Create database
   - Test mode ile başla (geliştirme için)
   - Location seç (en yakın bölgeyi seç)

3. **Storage** (Fotoğraflar için):
   - Storage > Get started
   - Test mode ile başla

4. **Cloud Messaging** (Bildirimler için):
   - Cloud Messaging > Get started

## Adım 10: Test Et

```bash
flutter run
```

Uygulamanın Firebase'e bağlandığını kontrol et.

## Sorun Giderme

- **google-services.json bulunamadı hatası**: Dosyanın `android/app/` klasöründe olduğundan emin ol
- **API key hatası**: Firebase Console'dan doğru değerleri kopyaladığından emin ol
- **Build hatası**: `flutter clean` ve `flutter pub get` komutlarını çalıştır

