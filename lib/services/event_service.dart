import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
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
      if (category != null) {
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
        'title': 'AI & The Future Seminar',
        'description': 'Explore the impact of artificial intelligence on daily life and career opportunities with expert speakers. An interactive event open to students and academics.',
        'category': 'Technology',
        'organizerId': 'seed',
        'organizerName': 'Computer Science Society',
        'imageUrl': 'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800',
        'location': 'University Conference Hall A',
        'date': Timestamp.fromDate(now.add(const Duration(days: 5))),
        'price': 0.0,
        'capacity': 150,
        'registeredCount': 87,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Acoustic Night — Live Music',
        'description': "An unforgettable acoustic performance night featuring the university's most talented musicians. Light refreshments included.",
        'category': 'Music',
        'organizerId': 'seed',
        'organizerName': 'Music Club',
        'imageUrl': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800',
        'location': 'Campus Open Amphitheater',
        'date': Timestamp.fromDate(now.add(const Duration(days: 8))),
        'price': 25.0,
        'capacity': 200,
        'registeredCount': 134,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Mobile App Development with Flutter',
        'description': 'Build your own app with Flutter from scratch. Hands-on workshop format — just bring your laptop.',
        'category': 'Technology',
        'organizerId': 'seed',
        'organizerName': 'Software Development Club',
        'imageUrl': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800',
        'location': 'Engineering Building Lab 3',
        'date': Timestamp.fromDate(now.add(const Duration(days: 12))),
        'price': 0.0,
        'capacity': 40,
        'registeredCount': 38,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Spring Sports Festival',
        'description': 'Soccer, basketball, volleyball and more! Form your team, register, and compete for the championship trophy.',
        'category': 'Sports',
        'organizerId': 'seed',
        'organizerName': 'Sports Coordination Office',
        'imageUrl': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800',
        'location': 'University Sports Complex',
        'date': Timestamp.fromDate(now.add(const Duration(days: 15))),
        'price': 10.0,
        'capacity': 300,
        'registeredCount': 210,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'Modern Art Exhibition — Young Artists',
        'description': 'An art gallery event showcasing original works by young university artists. Painting, sculpture and digital art all in one place.',
        'category': 'Art',
        'organizerId': 'seed',
        'organizerName': 'Fine Arts Society',
        'imageUrl': 'https://images.unsplash.com/photo-1531243269054-5ebf6f34081e?w=800',
        'location': 'Cultural Center Gallery',
        'date': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'price': 0.0,
        'capacity': 100,
        'registeredCount': 45,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'title': 'World Cuisines Festival',
        'description': 'A food festival where students from different countries present dishes from their own cultures. Tasting tickets are limited!',
        'category': 'Food',
        'organizerId': 'seed',
        'organizerName': 'International Students Society',
        'imageUrl': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
        'location': 'Central Cafeteria',
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
