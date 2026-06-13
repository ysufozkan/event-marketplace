import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  // Lazy getter — Storage yalnızca uploadImage çağrıldığında init edilir,
  // böylece Windows'ta Firestore ile C++ SDK çakışması önlenir.
  FirebaseStorage get _storage => FirebaseStorage.instance;

  Stream<List<EventModel>> getEvents({String? category}) {
    return _db
        .collection('events')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      var events = snap.docs
          .map((d) => EventModel.fromMap(d.data(), d.id))
          .toList();
      if (category != null && category != 'Tümü') {
        events = events.where((e) => e.category == category).toList();
      }
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    });
  }

  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final ref = _storage.ref().child('events/${const Uuid().v4()}.$ext');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return await ref.getDownloadURL();
  }

  Future<void> createEvent(EventModel event) async {
    await _db.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.collection('events').doc(id).update(data);
  }

  Future<void> deactivateEvent(String id) async {
    await _db.collection('events').doc(id).update({'isActive': false});
  }

  Stream<List<EventModel>> getEventsByOrganizer(String organizerId) {
    return _db
        .collection('events')
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventModel.fromMap(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> seedEvents() async {
    final snap = await _db.collection('events').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final now = DateTime.now();
    final events = [
      {
        'title': 'Yapay Zeka ve Gelecek Semineri',
        'description': 'Yapay zekanın günlük hayatımıza ve kariyer fırsatlarına etkilerini uzman konuşmacılarla keşfedin. Öğrenci ve akademisyenlere açık interaktif bir etkinlik.',
        'category': 'Teknoloji',
        'organizerId': 'seed',
        'organizerName': 'Bilgisayar Topluluğu',
        'imageUrl': 'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800',
        'location': 'Üniversite Konferans Salonu A',
        'date': Timestamp.fromDate(now.add(const Duration(days: 5))),
        'price': 0.0,
        'capacity': 150,
        'registeredCount': 87,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Akustik Gece — Canlı Müzik',
        'description': 'Üniversitenin en yetenekli müzisyenlerinin sahne alacağı unutulmaz bir akustik performans gecesi. Hafif içecekler dahildir.',
        'category': 'Müzik',
        'organizerId': 'seed',
        'organizerName': 'Müzik Kulübü',
        'imageUrl': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800',
        'location': 'Kampüs Açık Amfi',
        'date': Timestamp.fromDate(now.add(const Duration(days: 8))),
        'price': 25.0,
        'capacity': 200,
        'registeredCount': 134,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Flutter ile Mobil Uygulama Geliştirme',
        'description': 'Sıfırdan başlayarak Flutter ile kendi uygulamanızı geliştirin. Pratik workshop formatında, dizüstü bilgisayarınızı getirmeniz yeterli.',
        'category': 'Teknoloji',
        'organizerId': 'seed',
        'organizerName': 'Yazılım Geliştirme Kulübü',
        'imageUrl': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800',
        'location': 'Mühendislik Binası Lab 3',
        'date': Timestamp.fromDate(now.add(const Duration(days: 12))),
        'price': 0.0,
        'capacity': 40,
        'registeredCount': 38,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Bahar Spor Şenliği',
        'description': 'Futbol, basketbol, voleybol ve daha fazlası! Takımını oluştur, kaydol ve şampiyonluk kupası için mücadele et.',
        'category': 'Spor',
        'organizerId': 'seed',
        'organizerName': 'Spor Koordinatörlüğü',
        'imageUrl': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800',
        'location': 'Üniversite Spor Kompleksi',
        'date': Timestamp.fromDate(now.add(const Duration(days: 15))),
        'price': 10.0,
        'capacity': 300,
        'registeredCount': 210,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Modern Sanat Sergisi — Genç Sanatçılar',
        'description': 'Üniversiteli genç sanatçıların özgün eserlerinin sergilendiği sanat galerisi etkinliği. Resim, heykel ve dijital sanat bir arada.',
        'category': 'Sanat',
        'organizerId': 'seed',
        'organizerName': 'Güzel Sanatlar Topluluğu',
        'imageUrl': 'https://images.unsplash.com/photo-1531243269054-5ebf6f34081e?w=800',
        'location': 'Kültür Merkezi Galeri',
        'date': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'price': 0.0,
        'capacity': 100,
        'registeredCount': 45,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Dünya Mutfakları Festivali',
        'description': 'Farklı ülkelerden öğrencilerin kendi kültürlerinin yemeklerini sunduğu lezzet festivali. Tadım biletleri sınırlıdır!',
        'category': 'Yemek',
        'organizerId': 'seed',
        'organizerName': 'Uluslararası Öğrenci Topluluğu',
        'imageUrl': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
        'location': 'Merkez Kafeterya',
        'date': Timestamp.fromDate(now.add(const Duration(days: 20))),
        'price': 35.0,
        'capacity': 250,
        'registeredCount': 98,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
    ];

    final batch = _db.batch();
    for (final event in events) {
      final ref = _db.collection('events').doc();
      batch.set(ref, event);
    }
    await batch.commit();
  }
}
