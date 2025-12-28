# Flutter Kurulum Rehberi (Windows)

## Adım 1: Sistem Gereksinimlerini Kontrol Et

- Windows 10 veya üzeri
- En az 2 GB boş disk alanı
- Git (zaten kurulu ✓)

## Adım 2: Flutter SDK'yı İndir

1. **Flutter'ı indir**: https://docs.flutter.dev/get-started/install/windows
   - Sayfa açıldığında "flutter_windows_3.x.x-stable.zip" dosyasını indir
   - Veya direkt link: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip

2. **İndirilen zip dosyasını çıkart**:
   - Önerilen konum: `C:\src\flutter`
   - Veya: `C:\Users\<KullanıcıAdı>\flutter`
   - **ÖNEMLİ**: Klasör yolunda boşluk veya özel karakter olmamalı!

## Adım 3: Flutter'ı PATH'e Ekle

### Yöntem 1: Sistem Değişkenlerinden (Önerilen)

1. **Windows Tuşu + R** → `sysdm.cpl` yaz → Enter
2. **Advanced** sekmesine git
3. **Environment Variables** butonuna tıkla
4. **System variables** bölümünde **Path** seç → **Edit** tıkla
5. **New** tıkla → Flutter'ın bin klasörünün yolunu ekle:
   ```
   C:\src\flutter\bin
   ```
   (veya Flutter'ı çıkarttığın klasör + \bin)
6. **OK** tıkla (tüm pencerelerde)

### Yöntem 2: PowerShell'den (Alternatif)

PowerShell'i **Yönetici olarak** aç ve şunu çalıştır:

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", [EnvironmentVariableTarget]::Machine)
```

(Klasör yolunu kendi Flutter klasörüne göre değiştir)

## Adım 4: PowerShell/Terminal'i Yeniden Başlat

- Açık olan tüm PowerShell/CMD pencerelerini kapat
- Yeni bir PowerShell penceresi aç

## Adım 5: Flutter'ı Test Et

Yeni PowerShell'de:

```bash
flutter --version
```

Eğer versiyon bilgisi görünürse kurulum başarılı! ✓

## Adım 6: Flutter Doctor Çalıştır

```bash
flutter doctor
```

Bu komut eksik olan şeyleri gösterecek:

- ✓ Flutter (Installed)
- ⚠ Android toolchain (kurulması gerekiyor)
- ⚠ VS Code / Android Studio (isteğe bağlı)
- ⚠ Chrome (Web development için)

## Adım 7: Android Studio Kurulumu (Android Development İçin)

1. **Android Studio İndir**: https://developer.android.com/studio
2. Kurulum yap
3. İlk açılışta:
   - **More Actions** → **SDK Manager**
   - **SDK Platforms** sekmesinde **Android SDK Platform 34** seç
   - **SDK Tools** sekmesinde:
     - ✓ Android SDK Build-Tools
     - ✓ Android SDK Command-line Tools
     - ✓ Android SDK Platform-Tools
     - ✓ Android Emulator
   - **Apply** → **OK**

4. **Android Studio'yu aç** ve:
   - **More Actions** → **SDK Manager**
   - **SDK Platforms** → **Show Package Details**
   - **Android 14.0 (Tiramisu)** → **Android SDK Platform 34**
   - **Apply** → Kurulumu bekle

## Adım 8: Android License'ları Kabul Et

```bash
flutter doctor --android-licenses
```

Her soruda **y** yazıp Enter'a bas.

## Adım 9: Flutter Doctor'ı Tekrar Çalıştır

```bash
flutter doctor -v
```

Çıktıda yeşil tikler (✓) görmeli. Sarı uyarılar (⚠) olabilir, önemli değil.

## Adım 10: Flutter Projesini Test Et

Proje klasörüne git ve:

```bash
cd "C:\Users\anlar\Desktop\Mobile Programming"
flutter pub get
flutter doctor
```

## Hızlı Kontrol Listesi

- [ ] Flutter SDK indirildi ve çıkartıldı
- [ ] Flutter PATH'e eklendi
- [ ] PowerShell yeniden başlatıldı
- [ ] `flutter --version` çalışıyor
- [ ] `flutter doctor` çalıştırıldı
- [ ] Android Studio kuruldu (Android için)
- [ ] Android licenses kabul edildi

## Sorun Giderme

**"flutter is not recognized" hatası:**
- PATH'e doğru eklendiğinden emin ol
- PowerShell'i yeniden başlat

**"Unable to locate Android SDK" hatası:**
- Android Studio'yu kur
- `flutter doctor --android-licenses` çalıştır

**"Git is not installed" hatası:**
- Git zaten kurulu, PATH'e eklenmiş olmalı

## Sonraki Adım

Flutter kurulduktan sonra:
1. Firebase yapılandırmasına geç
2. `flutter create .` komutuyla projeyi oluştur
3. Firebase config dosyalarını ekle

