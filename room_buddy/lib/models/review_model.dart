import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String propertyId;
  final String studentId;
  String get userId => studentId;
  String get userName => studentName;
  final String studentName;
  final double rating;
  final String review;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    this.id = '',
    this.propertyId = '',
    String? userId,
    String studentId = '',
    String? userName,
    String studentName = '',
    this.rating = 0.0,
    String review = '',
    String? comment,
    this.createdAt,
    this.updatedAt,
  })  : studentId = userId ?? studentId,
        studentName = userName ?? studentName,
        review = comment ?? (review.isNotEmpty ? review : '');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'studentId': studentId,
      'studentName': studentName,
      'rating': rating,
      'review': review,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      review: map['review'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory ReviewModel.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) return ReviewModel();
    var map = doc.data() as Map<String, dynamic>;
    map['id'] = doc.id;
    return ReviewModel.fromMap(map);
  }
}
