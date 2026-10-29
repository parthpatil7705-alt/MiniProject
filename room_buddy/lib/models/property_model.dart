import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyLocation {
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;

  const PropertyLocation({
    this.address = '',
    this.city = '',
    this.state = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PropertyLocation.fromMap(Map<String, dynamic> map) {
    return PropertyLocation(
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PropertyModel {
  final String id;
  final String landlordId;
  final String landlordName;
  final String title;
  final String description;
  final double rent;
  final double deposit;
  final String propertyType; // 'apartment', 'hostel', 'pg', 'flat', 'house'
  final int availableRooms;
  final int totalRooms;
  final List<String> amenities;
  final List<String> images;
  final PropertyLocation location;
  final bool isAvailable;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get rentAmount => rent;
  double get depositAmount => deposit;
  String get type => propertyType;
  double get averageRating => rating;
  String get address => location.address;
  String get city => location.city;
  String get state => location.state;

  const PropertyModel({
    this.id = '',
    this.landlordId = '',
    this.landlordName = '',
    this.title = '',
    this.description = '',
    this.rent = 0.0,
    this.deposit = 0.0,
    this.propertyType = '',
    this.availableRooms = 0,
    this.totalRooms = 0,
    this.amenities = const [],
    this.images = const [],
    this.location = const PropertyLocation(),
    this.isAvailable = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  PropertyModel copyWith({
    String? id,
    String? landlordId,
    String? landlordName,
    String? title,
    String? description,
    double? rent,
    double? deposit,
    String? propertyType,
    int? availableRooms,
    int? totalRooms,
    List<String>? amenities,
    List<String>? images,
    PropertyLocation? location,
    bool? isAvailable,
    bool? isVerified,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      landlordId: landlordId ?? this.landlordId,
      landlordName: landlordName ?? this.landlordName,
      title: title ?? this.title,
      description: description ?? this.description,
      rent: rent ?? this.rent,
      deposit: deposit ?? this.deposit,
      propertyType: propertyType ?? this.propertyType,
      availableRooms: availableRooms ?? this.availableRooms,
      totalRooms: totalRooms ?? this.totalRooms,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landlordId': landlordId,
      'landlordName': landlordName,
      'title': title,
      'description': description,
      'rent': rent,
      'deposit': deposit,
      'propertyType': propertyType,
      'availableRooms': availableRooms,
      'totalRooms': totalRooms,
      'amenities': amenities,
      'images': images,
      'location': location.toMap(),
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'] as String? ?? '',
      landlordId: map['landlordId'] as String? ?? '',
      landlordName: map['landlordName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rent: (map['rent'] as num?)?.toDouble() ?? 0.0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0.0,
      propertyType: map['propertyType'] as String? ?? '',
      availableRooms: map['availableRooms'] as int? ?? 0,
      totalRooms: map['totalRooms'] as int? ?? 0,
      amenities: List<String>.from(map['amenities'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      location: map['location'] != null 
          ? PropertyLocation.fromMap(map['location'] as Map<String, dynamic>)
          : const PropertyLocation(),
      isAvailable: map['isAvailable'] as bool? ?? true,
      isVerified: map['isVerified'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory PropertyModel.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) return const PropertyModel();
    var map = doc.data() as Map<String, dynamic>;
    map['id'] = doc.id;
    return PropertyModel.fromMap(map);
  }
}
