import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RoommatePreferenceModel {
  final String userId;
  final String userName;
  final String college;
  final double budgetMin;
  final double budgetMax;
  final String preferredLocation;
  final String sleepSchedule; // 'early_bird', 'night_owl', 'flexible'
  final String cleanliness; // 'very_clean', 'moderate', 'relaxed'
  final String smoking; // 'no', 'yes', 'no_preference'
  final String foodPreference; // 'veg', 'non_veg', 'no_preference'
  final String studyHabits; // 'quiet', 'with_music', 'flexible'
  final String guestPolicy; // 'no_guests', 'occasional', 'frequent'
  final List<String> interests;
  final String bio;
  final String photoUrl;
  final DateTime? updatedAt;

  double get minBudget => budgetMin;
  double get maxBudget => budgetMax;

  RoommatePreferenceModel({
    String? id,
    String userId = '',
    this.userName = '',
    this.college = '',
    double budgetMin = 0.0,
    double budgetMax = 0.0,
    double? minBudget,
    double? maxBudget,
    this.preferredLocation = '',
    this.sleepSchedule = '',
    this.cleanliness = '',
    this.smoking = '',
    this.foodPreference = '',
    this.studyHabits = '',
    this.guestPolicy = '',
    this.interests = const [],
    this.bio = '',
    this.photoUrl = '',
    this.updatedAt,
  })  : userId = id ?? userId,
        budgetMin = minBudget ?? budgetMin,
        budgetMax = maxBudget ?? budgetMax;

  RoommatePreferenceModel copyWith({
    String? userId,
    String? userName,
    String? college,
    double? budgetMin,
    double? budgetMax,
    String? preferredLocation,
    String? sleepSchedule,
    String? cleanliness,
    String? smoking,
    String? foodPreference,
    String? studyHabits,
    String? guestPolicy,
    List<String>? interests,
    String? bio,
    String? photoUrl,
    DateTime? updatedAt,
  }) {
    return RoommatePreferenceModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      college: college ?? this.college,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      cleanliness: cleanliness ?? this.cleanliness,
      smoking: smoking ?? this.smoking,
      foodPreference: foodPreference ?? this.foodPreference,
      studyHabits: studyHabits ?? this.studyHabits,
      guestPolicy: guestPolicy ?? this.guestPolicy,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'college': college,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'preferredLocation': preferredLocation,
      'sleepSchedule': sleepSchedule,
      'cleanliness': cleanliness,
      'smoking': smoking,
      'foodPreference': foodPreference,
      'studyHabits': studyHabits,
      'guestPolicy': guestPolicy,
      'interests': interests,
      'bio': bio,
      'photoUrl': photoUrl,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory RoommatePreferenceModel.fromMap(Map<String, dynamic> map) {
    return RoommatePreferenceModel(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      college: map['college'] as String? ?? '',
      budgetMin: (map['budgetMin'] as num?)?.toDouble() ?? 0.0,
      budgetMax: (map['budgetMax'] as num?)?.toDouble() ?? 0.0,
      preferredLocation: map['preferredLocation'] as String? ?? '',
      sleepSchedule: map['sleepSchedule'] as String? ?? '',
      cleanliness: map['cleanliness'] as String? ?? '',
      smoking: map['smoking'] as String? ?? '',
      foodPreference: map['foodPreference'] as String? ?? '',
      studyHabits: map['studyHabits'] as String? ?? '',
      guestPolicy: map['guestPolicy'] as String? ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      bio: map['bio'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory RoommatePreferenceModel.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) return RoommatePreferenceModel();
    var map = doc.data() as Map<String, dynamic>;
    return RoommatePreferenceModel.fromMap(map);
  }

  int calculateCompatibility(RoommatePreferenceModel other) {
    double score = 0;
    double maxScore = 100;

    // Budget overlap (15 pts)
    if (budgetMax >= other.budgetMin && budgetMin <= other.budgetMax) {
      score += 15;
    }

    // Location match (15 pts)
    if (preferredLocation.isNotEmpty && 
        preferredLocation.toLowerCase() == other.preferredLocation.toLowerCase()) {
      score += 15;
    }

    // Strict attributes (10 pts each = 30 pts)
    if (smoking == other.smoking || smoking == 'no_preference' || other.smoking == 'no_preference') score += 10;
    if (foodPreference == other.foodPreference || foodPreference == 'no_preference' || other.foodPreference == 'no_preference') score += 10;
    if (sleepSchedule == other.sleepSchedule || sleepSchedule == 'flexible' || other.sleepSchedule == 'flexible') score += 10;

    // Soft attributes (5 pts each = 15 pts)
    if (cleanliness == other.cleanliness) {
      score += 5;
    } else if ((cleanliness == 'very_clean' && other.cleanliness == 'moderate') || 
               (cleanliness == 'moderate' && other.cleanliness == 'very_clean') ||
               (cleanliness == 'moderate' && other.cleanliness == 'relaxed') ||
               (cleanliness == 'relaxed' && other.cleanliness == 'moderate')) {
      score += 2;
    }
    
    if (studyHabits == other.studyHabits || studyHabits == 'flexible' || other.studyHabits == 'flexible') score += 5;
    if (guestPolicy == other.guestPolicy) {
      score += 5;
    }

    // Shared interests (Up to 15 pts)
    if (interests.isNotEmpty && other.interests.isNotEmpty) {
      int sharedCount = 0;
      for (var interest in interests) {
        if (other.interests.map((e) => e.toLowerCase()).contains(interest.toLowerCase())) {
          sharedCount++;
        }
      }
      double interestScore = (sharedCount / max(interests.length, other.interests.length)) * 15;
      score += interestScore.clamp(0.0, 15.0);
    }

    // College match bonus (10 pts)
    if (college.isNotEmpty && college.toLowerCase() == other.college.toLowerCase()) {
      score += 10;
      maxScore += 10; // Extra points so we adjust max
    }

    return ((score / maxScore) * 100).round().clamp(0, 100);
  }
}
