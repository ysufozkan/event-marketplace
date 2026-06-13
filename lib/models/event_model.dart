import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String organizerId;
  final String organizerName;
  final String imageUrl;
  final String location;
  final DateTime date;
  final double price;
  final int capacity;
  final int registeredCount;
  final bool isActive;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.organizerId,
    required this.organizerName,
    required this.imageUrl,
    required this.location,
    required this.date,
    required this.price,
    required this.capacity,
    required this.registeredCount,
    required this.isActive,
    required this.createdAt,
  });

  bool get isFree => price == 0;
  bool get isFull => registeredCount >= capacity;
  int get spotsLeft => capacity - registeredCount;

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      location: map['location'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      price: (map['price'] ?? 0).toDouble(),
      capacity: map['capacity'] ?? 0,
      registeredCount: map['registeredCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'imageUrl': imageUrl,
      'location': location,
      'date': Timestamp.fromDate(date),
      'price': price,
      'capacity': capacity,
      'registeredCount': registeredCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
