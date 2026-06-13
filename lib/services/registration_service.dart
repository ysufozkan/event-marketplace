import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';

class RegistrationService {
  final _db = FirebaseFirestore.instance;

  Future<RegistrationModel> registerForEvent({
    required String userId,
    required String userName,
    required EventModel event,
  }) async {
    final existing = await _db
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: event.id)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final existingReg = RegistrationModel.fromMap(
          existing.docs.first.data(), existing.docs.first.id);
      if (existingReg.isConfirmed) {
        throw Exception('You are already registered for this event');
      }
    }

    final eventSnap =
        await _db.collection('events').doc(event.id).get();
    final data = eventSnap.data()!;
    final registeredCount = data['registeredCount'] as int;
    final capacity = data['capacity'] as int;

    if (registeredCount >= capacity) {
      throw Exception('This event is at full capacity');
    }

    final ticketCode =
        const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    final now = DateTime.now();
    final regRef = _db.collection('registrations').doc();

    final registration = RegistrationModel(
      id: regRef.id,
      userId: userId,
      userName: userName,
      eventId: event.id,
      eventTitle: event.title,
      eventLocation: event.location,
      eventDate: event.date,
      eventImageUrl: event.imageUrl,
      ticketCode: ticketCode,
      purchasedAt: now,
      status: 'confirmed',
    );

    await regRef.set(registration.toMap());
    await _db
        .collection('events')
        .doc(event.id)
        .update({'registeredCount': registeredCount + 1});

    return registration;
  }

  Future<void> cancelRegistration(
      String registrationId, String eventId) async {
    final eventSnap =
        await _db.collection('events').doc(eventId).get();
    final registeredCount =
        (eventSnap.data()?['registeredCount'] as int?) ?? 0;

    await _db
        .collection('registrations')
        .doc(registrationId)
        .update({'status': 'cancelled'});

    if (registeredCount > 0) {
      await _db
          .collection('events')
          .doc(eventId)
          .update({'registeredCount': registeredCount - 1});
    }
  }

  Stream<List<RegistrationModel>> getUserRegistrations(String userId) {
    return _db
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RegistrationModel.fromMap(d.data(), d.id))
            .where((r) => r.isConfirmed)
            .toList()
          ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt)));
  }

  Stream<List<RegistrationModel>> getEventRegistrations(String eventId) {
    return _db
        .collection('registrations')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RegistrationModel.fromMap(d.data(), d.id))
            .where((r) => r.isConfirmed)
            .toList()
          ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt)));
  }

  Future<RegistrationModel?> validateTicket(String code) async {
    final snap = await _db
        .collection('registrations')
        .where('ticketCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final reg =
        RegistrationModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    return reg.isConfirmed ? reg : null;
  }

  Future<RegistrationModel?> getRegistration(
      String userId, String eventId) async {
    final snap = await _db
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final reg =
        RegistrationModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    return reg.isConfirmed ? reg : null;
  }
}
