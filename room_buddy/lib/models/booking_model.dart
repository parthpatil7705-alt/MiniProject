import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String landlordId;
  final String landlordName;
  final double rent;
  /// Status: 'pending' | 'confirmed' | 'rejected' | 'cancelled'
  final String status;
  final String? landlordNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    this.id = '',
    this.propertyId = '',
    this.propertyTitle = '',
    this.studentId = '',
    this.studentName = '',
    this.studentEmail = '',
    this.landlordId = '',
    this.landlordName = '',
    this.rent = 0.0,
    this.status = 'pending',
    this.landlordNote,
    this.createdAt,
    this.updatedAt,
  });

  BookingModel copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? landlordId,
    String? landlordName,
    double? rent,
    String? status,
    String? landlordNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      landlordId: landlordId ?? this.landlordId,
      landlordName: landlordName ?? this.landlordName,
      rent: rent ?? this.rent,
      status: status ?? this.status,
      landlordNote: landlordNote ?? this.landlordNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'landlordId': landlordId,
      'landlordName': landlordName,
      'rent': rent,
      'status': status,
      'landlordNote': landlordNote,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      propertyTitle: map['propertyTitle'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentEmail: map['studentEmail'] as String? ?? '',
      landlordId: map['landlordId'] as String? ?? '',
      landlordName: map['landlordName'] as String? ?? '',
      rent: (map['rent'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      landlordNote: map['landlordNote'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory BookingModel.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) return const BookingModel();
    final map = doc.data() as Map<String, dynamic>;
    map['id'] = doc.id;
    return BookingModel.fromMap(map);
  }
}
