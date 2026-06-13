# Event Marketplace - Proje Yol Haritası

## Proje Özeti
Üniversite öğrencilerine yönelik etkinlik keşif ve bilet satın alma platformu.  
Kullanıcılar etkinlik oluşturabilir, keşfedebilir ve katılabilir.

---

## Teknoloji Stack

| Katman      | Teknoloji                        | Gerekçe                                      |
|-------------|----------------------------------|----------------------------------------------|
| Frontend    | Flutter + Dart                   | Ders gereksinimi, cross-platform              |
| Backend     | Firebase (BaaS)                  | Hızlı kurulum, Flutter ile mükemmel entegrasyon |
| Database    | Cloud Firestore                  | NoSQL, gerçek zamanlı, ölçeklenebilir         |
| Auth        | Firebase Authentication          | Email/şifre + Google Sign-In                 |
| Storage     | Firebase Storage                 | Etkinlik görselleri                          |
| State Mgmt  | Provider veya Riverpod           | Hafif, anlaşılır                             |

---

## Uygulama Özellikleri (MVP)

### Kullanıcı Rolleri
- **Katılımcı (Attendee):** Etkinlik arar, bilet alır, geçmişini görür
- **Organizatör (Organizer):** Etkinlik oluşturur, yönetir, katılımcı listesini görür

### Temel Ekranlar
1. Splash / Onboarding
2. Giriş Yap / Kayıt Ol
3. Ana Sayfa — etkinlik keşfi (liste + kategori filtresi)
4. Etkinlik Detay
5. Bilet Satın Alma / Kayıt
6. Profil & Biletlerim
7. Etkinlik Oluştur (Organizatör)
8. Etkinliklerimi Yönet (Organizatör)

---

## Veri Modeli (Firestore)

### `users` koleksiyonu
```
users/{userId}
  - uid: String
  - name: String
  - email: String
  - role: "attendee" | "organizer"
  - avatarUrl: String
  - createdAt: Timestamp
```

### `events` koleksiyonu
```
events/{eventId}
  - title: String
  - description: String
  - category: String         // music, tech, sport, art, food, other
  - organizerId: String
  - organizerName: String
  - imageUrl: String
  - location: String
  - date: Timestamp
  - price: double            // 0 = ücretsiz
  - capacity: int
  - registeredCount: int
  - isActive: bool
  - createdAt: Timestamp
```

### `registrations` koleksiyonu
```
registrations/{registrationId}
  - userId: String
  - eventId: String
  - eventTitle: String
  - ticketCode: String       // UUID
  - purchasedAt: Timestamp
  - status: "confirmed" | "cancelled"
```

---

## Klasör Yapısı (Flutter)

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── validators.dart
│
├── models/
│   ├── user_model.dart
│   ├── event_model.dart
│   └── registration_model.dart
│
├── services/
│   ├── auth_service.dart
│   ├── event_service.dart
│   └── registration_service.dart
│
├── providers/                     // State management
│   ├── auth_provider.dart
│   ├── event_provider.dart
│   └── registration_provider.dart
│
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   ├── home_screen.dart
    │   └── widgets/
    │       ├── event_card.dart
    │       └── category_chip.dart
    ├── event/
    │   ├── event_detail_screen.dart
    │   └── create_event_screen.dart
    ├── ticket/
    │   └── my_tickets_screen.dart
    └── profile/
        └── profile_screen.dart
```

---

## Geliştirme Aşamaları

### Faz 1 — Proje Kurulumu (1-2 gün)
- [ ] Flutter projesi oluştur
- [ ] Firebase projesi kur (console.firebase.google.com)
- [ ] `flutterfire configure` ile bağla
- [ ] Gerekli paketleri `pubspec.yaml`'a ekle
- [ ] Tema ve renk paleti tanımla

### Faz 2 — Auth (2-3 gün)
- [ ] Firebase Auth entegrasyonu
- [ ] Kayıt ol ekranı (email + şifre + rol seçimi)
- [ ] Giriş yap ekranı
- [ ] AuthProvider ile session yönetimi
- [ ] Splash ekranı (oturum kontrolü)

### Faz 3 — Etkinlik CRUD (3-4 gün)
- [ ] Event modeli + Firestore servis katmanı
- [ ] Ana sayfa: etkinlik listesi
- [ ] Kategori filtresi
- [ ] Etkinlik detay ekranı
- [ ] Etkinlik oluşturma formu (organizatör)
- [ ] Firebase Storage ile görsel yükleme

### Faz 4 — Kayıt / Bilet (2-3 gün)
- [ ] Registration modeli + servis katmanı
- [ ] Etkinliğe kayıt ol butonu
- [ ] Kapasite kontrolü
- [ ] "Biletlerim" ekranı
- [ ] Benzersiz bilet kodu üretimi

### Faz 5 — Organizatör Paneli (2 gün)
- [ ] "Etkinliklerimi Yönet" ekranı
- [ ] Etkinlik düzenleme
- [ ] Etkinlik silme / pasife alma
- [ ] Katılımcı listesi görüntüleme

### Faz 6 — Profil & Son Dokunuşlar (1-2 gün)
- [ ] Profil ekranı (bilgi güncelleme, avatar)
- [ ] Arama çubuğu
- [ ] Loading skeleton'lar
- [ ] Hata mesajları ve form validasyonları
- [ ] Uygulama ikonu + splash

---

## Kullanılacak Paketler (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0

  # State Management
  provider: ^6.1.0

  # UI
  cached_network_image: ^3.3.0
  image_picker: ^1.1.0
  intl: ^0.19.0

  # Utils
  uuid: ^4.3.0
  go_router: ^14.0.0
```

---

## Ekran Akışı (Navigation)

```
Splash
  ├── (oturum var) ──► Home
  └── (oturum yok) ──► Login
                          └── Register

Home (BottomNavBar)
  ├── Discover (etkinlik listesi)
  ├── My Tickets
  ├── Create Event  ← sadece organizatör görür
  └── Profile
```

---

## Zaman Tahmini
| Faz        | Süre    |
|------------|---------|
| Kurulum    | 1-2 gün |
| Auth       | 2-3 gün |
| Etkinlikler| 3-4 gün |
| Biletler   | 2-3 gün |
| Organizatör| 2 gün   |
| Finalize   | 1-2 gün |
| **Toplam** | **~3 hafta** |

---

## Notlar
- Ödeme entegrasyonu yok (kapsam dışı — "ücretsiz kayıt" veya simüle bilet)
- Gerçek zamanlı güncelleme için Firestore `StreamBuilder` kullanılacak
- Tüm form alanlarında Dart-tarafı validasyon yapılacak
- Koyu tema (dark mode) opsiyonel, açık tema öncelikli
