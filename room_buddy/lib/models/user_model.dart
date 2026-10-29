import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student', 'landlord', 'admin'
  final String phone;
  final String photoUrl;
  
  // Student fields
  final String college;
  final String course;
  final String year;
  final String bio;
  
  // Landlord fields
  final String companyName;
  final String address;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  String get id => uid;
  String get profilePicture => photoUrl;

  const UserModel({
    String? id,
    String uid = '',
    this.email = '',
    this.name = '',
    this.role = 'student',
    this.phone = '',
    this.photoUrl = '',
    this.college = '',
    this.course = '',
    this.year = '',
    this.bio = '',
    this.companyName = '',
    this.address = '',
    this.createdAt,
    this.updatedAt,
  }) : uid = id ?? uid;

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? photoUrl,
    String? college,
    String? course,
    String? year,
    String? bio,
    String? companyName,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      college: college ?? this.college,
      course: course ?? this.course,
      year: year ?? this.year,
      bio: bio ?? this.bio,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'photoUrl': photoUrl,
      'college': college,
      'course': course,
      'year': year,
      'bio': bio,
      'companyName': companyName,
      'address': address,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      college: map['college'] as String? ?? '',
      course: map['course'] as String? ?? '',
      year: map['year'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) return const UserModel();
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
