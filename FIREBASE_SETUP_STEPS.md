# Firebase Yapılandırma Adımları

## ✅ Tamamlananlar:
- [x] Flutter kuruldu
- [x] Flutter projesi oluşturuldu
- [x] Paketler yüklendi

## 📋 Yapılacaklar:

### Adım 1: Firebase Console'da Proje Oluştur

1. **Firebase Console'a git**: https://console.firebase.google.com/
2. **"Add project" (veya "Create a project")** tıkla
3. Proje adı: `smart-campus-app` (veya istediğin isim)
4. Google Analytics: **Şimdilik kapalı bırak** (isteğe bağlı)
5. **Create project** tıkla
6. Birkaç saniye bekle, proje hazır olunca **Continue** tıkla

### Adım 2: Android Uygulamasını Firebase'e Ekle

1. Firebase Console'da proje açıkken, **"Add app"** ikonuna tıkla (veya **Project Overview** sayfasında Android ikonuna tıkla)

2. Android package name: 
   - `android/app/build.gradle` dosyasını aç
   - `applicationId` değerini bul (muhtemelen `com.example.smart_campus_app`)
   - Bu değeri Firebase Console'a yapıştır

3. App nickname (optional): `Smart Campus Android`

4. Debug signing certificate SHA-1: **Şimdilik boş bırak** (sonra ekleriz)

5. **Register app** tıkla

6. **`google-services.json` dosyasını indir**
   - İndirilen dosyayı `android/app/` klasörüne kopyala

7. **Next** → **Next** → **Continue to console** tıkla

### Adım 3: Firebase Servislerini Etkinleştir

#### 3.1 Authentication (Kimlik Doğrulama)
1. Sol menüden **Authentication** → **Get started** tıkla
2. **Sign-in method** sekmesine git
3. **Email/Password** → **Enable** → **Save**

#### 3.2 Firestore Database (Veritabanı)
1. Sol menüden **Firestore Database** → **Create database** tıkla
2. **Start in test mode** seç (geliştirme için)
3. **Next** tıkla
4. **Location** seç: `europe-west` (veya en yakın bölge)
5. **Enable** tıkla

#### 3.3 Storage (Fotoğraf Depolama)
1. Sol menüden **Storage** → **Get started** tıkla
2. **Start in test mode** seç
3. **Next** → **Done**

#### 3.4 Cloud Messaging (Bildirimler) - Opsiyonel
1. Sol menüden **Cloud Messaging** → **Get started** tıkla
2. Varsayılan ayarlarla devam et

### Adım 4: Android Yapılandırması

`android/app/build.gradle` dosyasına Google Services plugin'ini ekle (ben ekleyeceğim)

### Adım 5: FlutterFire CLI ile Firebase Options Oluştur

Terminal'de şunu çalıştır:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Bu komut:
- Firebase projeni seçmeni isteyecek
- Platform seçimi yapacaksın (Android'i seç)
- `lib/firebase_options.dart` dosyasını otomatik oluşturacak

### Adım 6: main.dart'ı Güncelle

`lib/main.dart` dosyasında Firebase'i başlatacağız (ben güncelleyeceğim)

## 🎯 Özet

Şu an yapman gerekenler:
1. ✅ Firebase Console'da proje oluştur
2. ✅ Android app ekle ve `google-services.json` indir → `android/app/` klasörüne kopyala
3. ✅ Authentication → Email/Password etkinleştir
4. ✅ Firestore Database oluştur (test mode)
5. ✅ Storage oluştur (test mode)
6. ✅ `google-services.json` dosyasını `android/app/` klasörüne kopyaladığında bana haber ver, devam edelim!

