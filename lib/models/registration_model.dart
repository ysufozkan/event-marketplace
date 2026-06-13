import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String id;
  final String userId;
  final String userName;
  final String eventId;
  final String eventTitle;
  final String eventLocation;
  final DateTime eventDate;
  final String eventImageUrl;
  final String ticketCode;
  final DateTime purchasedAt;
  final String status;

  RegistrationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.eventId,
    required this.eventTitle,
    required this.eventLocation,
    required this.eventDate,
    required this.eventImageUrl,
    required this.ticketCode,
    required this.purchasedAt,
    required this.status,
  });

  bool get isConfirmed => status == 'confirmed';

  factory RegistrationModel.fromMap(Map<String, dynamic> map, String id) {
    return RegistrationModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Kullanıcı',
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      eventLocation: map['eventLocation'] ?? '',
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      eventImageUrl: map['eventImageUrl'] ?? '',
      ticketCode: map['ticketCode'] ?? '',
      purchasedAt: (map['purchasedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'confirmed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventLocation': eventLocation,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventImageUrl': eventImageUrl,
      'ticketCode': ticketCode,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'status': status,
    };
  }
}
