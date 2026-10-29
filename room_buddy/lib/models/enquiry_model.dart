import 'package:cloud_firestore/cloud_firestore.dart';

class EnquiryResponse {
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  const EnquiryResponse({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory EnquiryResponse.fromMap(Map<String, dynamic> map) {
    return EnquiryResponse(
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}

class EnquiryModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String landlordId;
  final String landlordName;
  final String message;
  final String status; // 'pending', 'responded', 'closed'
  final List<EnquiryResponse> responses;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EnquiryModel({
    this.id = '',
    this.propertyId = '',
    this.propertyTitle = '',
    this.studentId = '',
    this.studentName = '',
    this.studentEmail = '',
    this.landlordId = '',
    this.landlordName = '',
    this.message = '',
    this.status = 'pending',
    this.responses = const [],
    this.createdAt,
    this.updatedAt,
  });

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
      'message': message,
      'status': status,
      'responses': responses.map((x) => x.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory EnquiryModel.fromMap(Map<String, dynamic> map) {
    return EnquiryModel(
      id: map['id'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      propertyTitle: map['propertyTitle'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentEmail: map['studentEmail'] as String? ?? '',
      landlordId: map['landlordId'] as String? ?? '',
      landlordName: map['landlordName'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      responses: map['responses'] != null 
          ? List<EnquiryResponse>.from(
              (map['responses'] as List).map((x) => EnquiryResponse.fromMap(x as Map<String, dynamic>)))
          : const [],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory EnquiryModel.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) return const EnquiryModel();
    var map = doc.data() as Map<String, dynamic>;
    map['id'] = doc.id;
    return EnquiryModel.fromMap(map);
  }
}
