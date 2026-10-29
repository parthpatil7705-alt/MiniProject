import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_buddy/models/user_model.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/models/review_model.dart';
import 'package:room_buddy/models/enquiry_model.dart';
import 'package:room_buddy/models/booking_model.dart';
import 'package:room_buddy/models/roommate_preference_model.dart';
import 'package:room_buddy/core/constants/firebase_constants.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Local in-memory seed repository fallback (Walchand Campus, WCE Sangli)
  static final Map<String, UserModel> _localUsers = {
    'user_student': const UserModel(
      uid: 'user_student',
      email: 'student@roombuddy.com',
      name: 'Sanket Kulkarni',
      role: 'Student',
      phone: '+91 98220 12345',
      college: 'Walchand College of Engineering (WCE), Sangli',
      course: 'B.Tech Computer Science & Engineering',
      year: '3rd Year',
      bio:
          '3rd Year CSE student at Walchand College of Engineering (WCE). Looking for a clean, quiet stay near Walchand campus.',
    ),
    'user_landlord': const UserModel(
      uid: 'user_landlord',
      email: 'landlord@roombuddy.com',
      name: 'Sunil Patil',
      role: 'Landlord',
      phone: '+91 98230 67890',
      companyName: 'Patil Student Housing & Rentals',
      address: 'Opposite WCE Main Gate, Vishrambag, Sangli',
    ),
    'user_admin': const UserModel(
      uid: 'user_admin',
      email: 'admin@roombuddy.com',
      name: 'System Admin',
      role: 'Admin',
    ),
  };

  static final List<PropertyModel> _localProperties = [
    PropertyModel(
      id: 'prop_1',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Walchand Scholars Residency & Studio',
      description:
          'Ultra-modern furnished studio situated right across the Walchand College of Engineering (WCE) main gate in Vishrambag. Features high-speed fiber internet (500 Mbps), dedicated ergonomic study workstation, silent environment for coding & GATE preparation, in-unit laundry, and 24/7 security.',
      rent: 11500,
      deposit: 23000,
      propertyType: 'apartment',
      availableRooms: 2,
      totalRooms: 4,
      amenities: const [
        'WiFi',
        'AC',
        'Gym',
        'Laundry',
        'Kitchen',
        'Security',
        'Balcony',
        'Power Backup'
      ],
      images: const [
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
      ],
      location: const PropertyLocation(
        address: 'Opposite WCE Main Gate, Vishrambag',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8465,
        longitude: 74.6025,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.9,
      reviewCount: 18,
    ),
    PropertyModel(
      id: 'prop_2',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Vishrambag Student Residency & PG',
      description:
          'Comfortable air-conditioned PG rooms offering 3 nutritious home-style Maharashtrian meals daily. 5 minutes walk from Walchand College campus and Vishrambag Railway Station. Includes weekly housekeeping, high-speed WiFi, silent study hall, and RO water purifier.',
      rent: 7200,
      deposit: 14000,
      propertyType: 'pg',
      availableRooms: 5,
      totalRooms: 16,
      amenities: const [
        'WiFi',
        'Laundry',
        'Food Included',
        'AC',
        'Power Backup',
        'Security',
        'Cleaning'
      ],
      images: const [
        'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=800',
        'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=800',
      ],
      location: const PropertyLocation(
        address: 'Station Road, Near Vishrambag Railway Station',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8480,
        longitude: 74.6060,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.7,
      reviewCount: 24,
    ),
    PropertyModel(
      id: 'prop_3',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Saraswati Bhavan View 3BHK Flat',
      description:
          'Spacious 3BHK flat right next to the WCE campus boundary. Overlooking Saraswati Bhavan and green trees. Fully modular kitchen with microwave, refrigerator, large living lounge, and private balconies in every bedroom.',
      rent: 14000,
      deposit: 28000,
      propertyType: 'flat',
      availableRooms: 1,
      totalRooms: 3,
      amenities: const [
        'WiFi',
        'AC',
        'Balcony',
        'Kitchen',
        'Furnished',
        'Parking',
        'Elevator'
      ],
      images: const [
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
      ],
      location: const PropertyLocation(
        address: 'Behind WCE Saraswati Bhavan, College Corner',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8445,
        longitude: 74.6005,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.8,
      reviewCount: 12,
    ),
    PropertyModel(
      id: 'prop_4',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'WCE Coders & Tech Co-Living Loft',
      description:
          'Designed specifically for Walchand engineering students and coding hackathon teams. Equipped with dual-monitor workstations, high-speed mesh router, rooftop garden, coffee bar, and 24/7 study pods.',
      rent: 12500,
      deposit: 25000,
      propertyType: 'apartment',
      availableRooms: 3,
      totalRooms: 6,
      amenities: const [
        'WiFi',
        'AC',
        'Gym',
        'Kitchen',
        'Security',
        'Workstation',
        'Power Backup'
      ],
      images: const [
        'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=800',
        'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=800',
      ],
      location: const PropertyLocation(
        address: '100 Feet Road, Near WCE Hostel Gate, Vishrambag',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8430,
        longitude: 74.6040,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.9,
      reviewCount: 15,
    ),
    PropertyModel(
      id: 'prop_5',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'College Corner Budget Boys PG',
      description:
          'Affordable, clean, and community-focused student accommodation. Close to Walchand College of Engineering, Willingdon College, and Vishrambag bus stop. Twin-sharing rooms with study tables.',
      rent: 5500,
      deposit: 11000,
      propertyType: 'pg',
      availableRooms: 4,
      totalRooms: 12,
      amenities: const [
        'WiFi',
        'Food Included',
        'Security',
        'Laundry',
        'Water Purifier'
      ],
      images: const [
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
      ],
      location: const PropertyLocation(
        address: 'College Corner, Vishrambag',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8495,
        longitude: 74.5980,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.4,
      reviewCount: 9,
    ),
    PropertyModel(
      id: 'prop_6',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Gulmohar Colony Student Suites',
      description:
          'Peaceful 2BHK in lush Gulmohar Colony, Vishrambag. 8 mins bicycle ride to Walchand campus. Ideal for M.Tech, research scholars, and students preparing for GATE or campus placements.',
      rent: 8500,
      deposit: 17000,
      propertyType: 'flat',
      availableRooms: 2,
      totalRooms: 2,
      amenities: const [
        'WiFi',
        'AC',
        'Balcony',
        'Kitchen',
        'Terrace',
        'Furnished'
      ],
      images: const [
        'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800',
      ],
      location: const PropertyLocation(
        address: 'Gulmohar Colony, Vishrambag',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8410,
        longitude: 74.6080,
      ),
      isAvailable: true,
      isVerified: false,
      rating: 4.6,
      reviewCount: 7,
    ),
    PropertyModel(
      id: 'prop_7',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Willingdon Green Executive Villa',
      description:
          'Premium student villa between WCE and Willingdon College. Large garden, quiet study patio, private parking for two-wheelers, solar water heater, and en-suite bathrooms.',
      rent: 15500,
      deposit: 31000,
      propertyType: 'apartment',
      availableRooms: 1,
      totalRooms: 4,
      amenities: const [
        'WiFi',
        'AC',
        'Garden',
        'Gym',
        'Parking',
        'Kitchen',
        'Security'
      ],
      images: const [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
        'https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?w=800',
      ],
      location: const PropertyLocation(
        address: 'Willingdon Campus Road, Vishrambag',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8520,
        longitude: 74.5990,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.9,
      reviewCount: 22,
    ),
    PropertyModel(
      id: 'prop_8',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Wanless Road Student Hostel',
      description:
          'Modern hostel residence on Wanless Hospital Road, Sangli. 10 mins from Walchand campus. Includes dining hall with healthy meals, indoor games zone, and fast WiFi.',
      rent: 6200,
      deposit: 12400,
      propertyType: 'hostel',
      availableRooms: 6,
      totalRooms: 20,
      amenities: const [
        'WiFi',
        'Security',
        'Games Room',
        'Laundry',
        'Food Included',
        'AC'
      ],
      images: const [
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800',
      ],
      location: const PropertyLocation(
        address: 'Wanless Hospital Road, Sangli',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8550,
        longitude: 74.6110,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.5,
      reviewCount: 31,
    ),
    PropertyModel(
      id: 'prop_9',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Dhamani Road Penthouse Suite',
      description:
          'Luxury top-floor penthouse with panoramic view of Sangli-Miraj skyline, private wrap-around terrace, solar backup, high-speed WiFi, and 10 mins to Walchand campus.',
      rent: 17500,
      deposit: 35000,
      propertyType: 'apartment',
      availableRooms: 1,
      totalRooms: 2,
      amenities: const [
        'WiFi',
        'AC',
        'Terrace',
        'Gym',
        'Smart Home',
        'Parking',
        'Concierge'
      ],
      images: const [
        'https://images.unsplash.com/photo-1567496898669-ee935f5f647a?w=800',
      ],
      location: const PropertyLocation(
        address: 'Dhamani Road, Vishrambag',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8400,
        longitude: 74.6010,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 5.0,
      reviewCount: 14,
    ),
    PropertyModel(
      id: 'prop_10',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      title: 'Ganpati Mandir Road 2BHK Flat',
      description:
          'Cozy 2BHK shared flat in central Sangli with quick connectivity by city bus and auto to Walchand College of Engineering. Features fully equipped kitchen, dining area, and dedicated bike parking.',
      rent: 7500,
      deposit: 15000,
      propertyType: 'flat',
      availableRooms: 2,
      totalRooms: 2,
      amenities: const ['WiFi', 'Kitchen', 'Parking', 'Balcony', 'Laundry'],
      images: const [
        'https://images.unsplash.com/photo-1502005229762-ee152d829965?w=800',
      ],
      location: const PropertyLocation(
        address: 'Ganpati Mandir Road, Gaonbhag',
        city: 'Sangli',
        state: 'Maharashtra',
        latitude: 16.8580,
        longitude: 74.5750,
      ),
      isAvailable: true,
      isVerified: true,
      rating: 4.3,
      reviewCount: 8,
    ),
  ];

  static final List<ReviewModel> _localReviews = [
    ReviewModel(
      id: 'rev_1',
      propertyId: 'prop_1',
      studentId: 'user_student',
      studentName: 'Sanket Kulkarni',
      rating: 5.0,
      review:
          'Incredible landlord! Super fast fiber internet, peaceful environment, and just 3 mins walk to WCE Main Gate and CCF lab. Couldn’t recommend it more.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ReviewModel(
      id: 'rev_2',
      propertyId: 'prop_1',
      studentId: 'user_2',
      studentName: 'Pooja Deshmukh',
      rating: 5.0,
      review:
          'Safe and secure location with biometric access. Walking distance to WCE Saraswati Bhavan and library. Rooms are spacious and clean.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ReviewModel(
      id: 'rev_3',
      propertyId: 'prop_2',
      studentId: 'user_3',
      studentName: 'Amit Shinde',
      rating: 4.5,
      review:
          'The home-cooked Maharashtrian mess included in the PG is healthy and tasty. 5 mins walk to Vishrambag railway station!',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ReviewModel(
      id: 'rev_4',
      propertyId: 'prop_3',
      studentId: 'user_4',
      studentName: 'Sneha Joshi',
      rating: 5.0,
      review:
          'Gorgeous balcony view of WCE campus greens! Plenty of sunlight, quiet neighborhood, and very spacious rooms.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    ReviewModel(
      id: 'rev_5',
      propertyId: 'prop_4',
      studentId: 'user_5',
      studentName: 'Rohan Verma',
      rating: 5.0,
      review:
          'The co-working study pods and high-speed mesh WiFi are a dream for coding hackathons and group projects with batchmates.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final List<RoommatePreferenceModel> _localRoommates = [
    RoommatePreferenceModel(
      userId: 'roommate_1',
      userName: 'Prathamesh Kadam',
      college: 'Walchand College of Engineering (WCE)',
      budgetMin: 5000,
      budgetMax: 10000,
      preferredLocation: 'Vishrambag, Sangli',
      sleepSchedule: 'early_bird',
      cleanliness: 'very_clean',
      smoking: 'no',
      foodPreference: 'veg',
      studyHabits: 'quiet',
      guestPolicy: 'occasional',
      interests: const [
        'Competitive Coding',
        'Reading',
        'Algorithms',
        'Badminton'
      ],
      bio:
          'B.Tech CSE Sophomore @ WCE Sangli. Up by 6:30 AM, love clean study tables, hackathons, and quiet study vibes.',
    ),
    RoommatePreferenceModel(
      userId: 'roommate_2',
      userName: 'Snehal Patil',
      college: 'Walchand College of Engineering (WCE)',
      budgetMin: 6000,
      budgetMax: 12000,
      preferredLocation: 'College Corner, Sangli',
      sleepSchedule: 'night_owl',
      cleanliness: 'moderate',
      smoking: 'no',
      foodPreference: 'no_preference',
      studyHabits: 'with_music',
      guestPolicy: 'occasional',
      interests: const ['Robotics', 'Music', 'Fitness', 'Coffee'],
      bio:
          'Mechanical Junior @ WCE. Late-night project builder, love music and exploring cafes around Vishrambag.',
    ),
    RoommatePreferenceModel(
      userId: 'roommate_3',
      userName: 'Omkar Ghorpade',
      college: 'Walchand College of Engineering (WCE)',
      budgetMin: 7000,
      budgetMax: 13000,
      preferredLocation: '100 Feet Road, Vishrambag',
      sleepSchedule: 'flexible',
      cleanliness: 'very_clean',
      smoking: 'no',
      foodPreference: 'veg',
      studyHabits: 'quiet',
      guestPolicy: 'rare',
      interests: const ['AI/ML', 'Chess', 'Podcasts', 'Cycling'],
      bio:
          'M.Tech CSE student @ WCE Sangli. Minimalist lifestyle, respectful of personal boundaries and neat kitchen spaces.',
    ),
    RoommatePreferenceModel(
      userId: 'roommate_4',
      userName: 'Aishwarya Pawar',
      college: 'Walchand College of Engineering (WCE)',
      budgetMin: 5500,
      budgetMax: 9500,
      preferredLocation: 'Near WCE Main Gate',
      sleepSchedule: 'early_bird',
      cleanliness: 'very_clean',
      smoking: 'no',
      foodPreference: 'veg',
      studyHabits: 'group_study',
      guestPolicy: 'occasional',
      interests: const ['Yoga', 'Sketching', 'Baking', 'Volunteering'],
      bio:
          'Electrical Dept @ WCE. Calm nature, positive energy! Looking for a warm, cheerful roommate near campus.',
    ),
    RoommatePreferenceModel(
      userId: 'roommate_5',
      userName: 'Rohan Jadhav',
      college: 'Walchand College of Engineering (WCE)',
      budgetMin: 5000,
      budgetMax: 9000,
      preferredLocation: 'Station Road, Vishrambag',
      sleepSchedule: 'night_owl',
      cleanliness: 'moderate',
      smoking: 'no',
      foodPreference: 'no_preference',
      studyHabits: 'with_music',
      guestPolicy: 'occasional',
      interests: const ['Cricket', 'Guitar', 'Open Source', 'Web Dev'],
      bio:
          'Fullstack Dev & Guitarist. Looking for a flatmate who enjoys late-night tea at Vishrambag corner and tech discussions.',
    ),
  ];

  static final List<EnquiryModel> _localEnquiries = [
    EnquiryModel(
      id: 'enq_1',
      propertyId: 'prop_1',
      propertyTitle: 'Walchand Scholars Residency & Studio',
      studentId: 'user_student',
      studentName: 'Sanket Kulkarni',
      studentEmail: 'student@roombuddy.com',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      message:
          'Namaste Patil Uncle! Is the studio available for move-in from next semester? Does the rent include high-speed WiFi for online labs?',
      status: 'responded',
      responses: [
        EnquiryResponse(
          senderId: 'user_landlord',
          senderName: 'Sunil Patil',
          message:
              'Hello Sanket! Yes, available for next semester. 500Mbps fiber WiFi and 24hr water are included in rent. You can visit anytime opposite WCE main gate.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        )
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    EnquiryModel(
      id: 'enq_2',
      propertyId: 'prop_2',
      propertyTitle: 'Vishrambag Student Residency & PG',
      studentId: 'roommate_3',
      studentName: 'Omkar Ghorpade',
      studentEmail: 'omkar@wce.ac.in',
      landlordId: 'user_landlord',
      landlordName: 'Sunil Patil',
      message:
          'Hello, could I schedule a visit this Saturday around 3 PM to see the twin sharing room near Vishrambag station?',
      status: 'pending',
      responses: const [],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  // Users
  Future<void> createUser(UserModel user) async {
    final db = _db;
    if (db == null) {
      _localUsers[user.uid] = user;
      return;
    }
    await db
        .collection(FirebaseConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());
    _localUsers[user.uid] = user;
  }

  Future<UserModel?> getUser(String uid) async {
    final db = _db;
    if (db == null) return _localUsers[uid];
    final doc =
        await db.collection(FirebaseConstants.usersCollection).doc(uid).get();
    return doc.exists ? UserModel.fromDocument(doc) : null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .update(data);
    }
    final current = _localUsers[uid];
    if (current != null) {
      _localUsers[uid] = current.copyWith(
        name: data['name'] as String? ?? current.name,
        phone: data['phone'] as String? ?? current.phone,
        college: data['college'] as String? ?? current.college,
        course: data['course'] as String? ?? current.course,
        year: data['year'] as String? ?? current.year,
        bio: data['bio'] as String? ?? current.bio,
        photoUrl: data['photoUrl'] as String? ?? current.photoUrl,
        companyName: data['companyName'] as String? ?? current.companyName,
        address: data['address'] as String? ?? current.address,
      );
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    final db = _db;
    if (db == null) return Stream.value(_localUsers.values.toList());
    return db.collection(FirebaseConstants.usersCollection).snapshots().map(
          (snapshot) => snapshot.docs.map(UserModel.fromDocument).toList(),
        );
  }

  Future<void> deleteUser(String uid) async {
    final db = _db;
    if (db != null) {
      await db.collection(FirebaseConstants.usersCollection).doc(uid).delete();
    }
    _localUsers.remove(uid);
  }

  // Properties
  Future<String> createProperty(PropertyModel p) => addProperty(p);

  Future<String> addProperty(PropertyModel property) async {
    final newId = property.id.isNotEmpty
        ? property.id
        : 'prop_${DateTime.now().millisecondsSinceEpoch}';
    final p = property.copyWith(id: newId);
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.propertiesCollection)
          .doc(newId)
          .set(p.toMap());
    }
    _localProperties.insert(0, p);
    return newId;
  }

  Future<PropertyModel?> getProperty(String id) async {
    final db = _db;
    if (db == null) {
      for (final property in _localProperties) {
        if (property.id == id) return property;
      }
      return null;
    }
    final doc = await db
        .collection(FirebaseConstants.propertiesCollection)
        .doc(id)
        .get();
    return doc.exists ? PropertyModel.fromDocument(doc) : null;
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.propertiesCollection)
          .doc(id)
          .update(data);
    }
    final idx = _localProperties.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _localProperties[idx] = _localProperties[idx].copyWith(
        title: data['title'] as String? ?? _localProperties[idx].title,
        rent: (data['rent'] as num?)?.toDouble() ?? _localProperties[idx].rent,
      );
    }
  }

  Future<void> deleteProperty(String id) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.propertiesCollection)
          .doc(id)
          .delete();
    }
    _localProperties.removeWhere((p) => p.id == id);
  }

  Stream<List<PropertyModel>> getAllProperties() {
    final db = _db;
    if (db == null) return Stream.value(List.of(_localProperties));
    return db
        .collection(FirebaseConstants.propertiesCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(PropertyModel.fromDocument).toList(),
        );
  }

  Stream<List<PropertyModel>> getAvailableProperties() {
    final db = _db;
    if (db == null) {
      return Stream.value(
          _localProperties.where((p) => p.isAvailable).toList());
    }
    return db
        .collection(FirebaseConstants.propertiesCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PropertyModel.fromDocument)
              .where((property) => property.isAvailable)
              .toList(),
        );
  }

  Stream<List<PropertyModel>> getLandlordProperties(String landlordId) {
    final db = _db;
    if (db == null) {
      return Stream.value(
          _localProperties.where((p) => p.landlordId == landlordId).toList());
    }
    return db
        .collection(FirebaseConstants.propertiesCollection)
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(PropertyModel.fromDocument).toList());
  }

  Future<List<PropertyModel>> searchProperties(String query) async {
    final q = query.toLowerCase();
    final db = _db;
    final properties = db == null
        ? _localProperties
        : (await db.collection(FirebaseConstants.propertiesCollection).get())
            .docs
            .map(PropertyModel.fromDocument)
            .toList();
    return properties
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q))
        .toList();
  }

  // Reviews
  Future<void> addReview(ReviewModel review) async {
    final db = _db;
    if (db == null) {
      _localReviews.insert(0, review);
      return;
    }
    final reviewId = '${review.propertyId}_${review.studentId}';
    await db.collection(FirebaseConstants.reviewsCollection).doc(reviewId).set({
      ...review.toMap(),
      'id': reviewId,
    });
    _localReviews.insert(
        0,
        ReviewModel(
          id: reviewId,
          propertyId: review.propertyId,
          studentId: review.studentId,
          studentName: review.studentName,
          rating: review.rating,
          review: review.review,
          createdAt: review.createdAt,
          updatedAt: review.updatedAt,
        ));
  }

  Stream<List<ReviewModel>> getPropertyReviews(String propertyId) {
    final db = _db;
    if (db == null) {
      return Stream.value(
          _localReviews.where((r) => r.propertyId == propertyId).toList());
    }
    return db
        .collection(FirebaseConstants.reviewsCollection)
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map(
            (snapshot) => snapshot.docs.map(ReviewModel.fromDocument).toList());
  }

  Stream<List<ReviewModel>> getLandlordReviews(String landlordId) {
    final db = _db;
    if (db == null) {
      final propertyIds = _localProperties
          .where((p) => p.landlordId == landlordId)
          .map((p) => p.id)
          .toSet();
      return Stream.value(_localReviews
          .where((r) => propertyIds.contains(r.propertyId))
          .toList());
    }
    return db
        .collection(FirebaseConstants.reviewsCollection)
        .snapshots()
        .asyncMap((snapshot) async {
      final properties = await db
          .collection(FirebaseConstants.propertiesCollection)
          .where('landlordId', isEqualTo: landlordId)
          .get();
      final propertyIds = properties.docs.map((doc) => doc.id).toSet();
      return snapshot.docs
          .map(ReviewModel.fromDocument)
          .where((review) => propertyIds.contains(review.propertyId))
          .toList();
    });
  }

  // Recalculates and updates the average rating for a property from all local reviews.
  // The optional [newRating] arg is accepted but ignored (recalculated from all reviews).
  Future<void> updatePropertyRating(String propertyId,
      [double? newRating]) async {
    final db = _db;
    final reviews = db == null
        ? _localReviews.where((r) => r.propertyId == propertyId).toList()
        : (await db
                .collection(FirebaseConstants.reviewsCollection)
                .where('propertyId', isEqualTo: propertyId)
                .get())
            .docs
            .map(ReviewModel.fromDocument)
            .toList();
    if (reviews.isNotEmpty) {
      final avg =
          reviews.fold(0.0, (total, r) => total + r.rating) / reviews.length;
      if (db != null) {
        await db
            .collection(FirebaseConstants.propertiesCollection)
            .doc(propertyId)
            .update({
          'rating': avg,
          'reviewCount': reviews.length,
          'updatedAt': Timestamp.now(),
        });
      }
      final idx = _localProperties.indexWhere((p) => p.id == propertyId);
      if (idx != -1) {
        _localProperties[idx] = _localProperties[idx]
            .copyWith(rating: avg, reviewCount: reviews.length);
      }
    }
  }

  Future<bool> hasUserReviewed(String propertyId, String studentId) async {
    final db = _db;
    if (db == null) {
      return _localReviews
          .any((r) => r.propertyId == propertyId && r.studentId == studentId);
    }
    final deterministicReview = await db
        .collection(FirebaseConstants.reviewsCollection)
        .doc('${propertyId}_$studentId')
        .get();
    if (deterministicReview.exists) return true;
    // Legacy review IDs were not deterministic. Filter on property ID locally
    // to avoid requiring a composite Firestore index for this existence check.
    final legacyReviews = await db
        .collection(FirebaseConstants.reviewsCollection)
        .where('propertyId', isEqualTo: propertyId)
        .get();
    return legacyReviews.docs
        .any((doc) => doc.data()['studentId'] == studentId);
  }

  // Enquiries
  Future<void> createEnquiry(EnquiryModel enquiry) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.enquiriesCollection)
          .doc(enquiry.id)
          .set(enquiry.toMap());
    }
    _localEnquiries.insert(0, enquiry);
  }

  Stream<List<EnquiryModel>> getStudentEnquiries(String studentId) {
    final db = _db;
    if (db == null) {
      return Stream.value(
          _localEnquiries.where((e) => e.studentId == studentId).toList());
    }
    return db
        .collection(FirebaseConstants.enquiriesCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(EnquiryModel.fromDocument).toList());
  }

  Stream<List<EnquiryModel>> getLandlordEnquiries(String landlordId) {
    final db = _db;
    if (db == null) {
      return Stream.value(
          _localEnquiries.where((e) => e.landlordId == landlordId).toList());
    }
    return db
        .collection(FirebaseConstants.enquiriesCollection)
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(EnquiryModel.fromDocument).toList());
  }

  Future<void> respondToEnquiry(
      String enquiryId, EnquiryResponse response) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.enquiriesCollection)
          .doc(enquiryId)
          .update({
        'responses': FieldValue.arrayUnion([response.toMap()]),
        'status': 'responded',
        'updatedAt': Timestamp.now(),
      });
    }
    final idx = _localEnquiries.indexWhere((e) => e.id == enquiryId);
    if (idx != -1) {
      final old = _localEnquiries[idx];
      final updatedResponses = List<EnquiryResponse>.from(old.responses)
        ..add(response);
      _localEnquiries[idx] = EnquiryModel(
        id: old.id,
        propertyId: old.propertyId,
        propertyTitle: old.propertyTitle,
        studentId: old.studentId,
        studentName: old.studentName,
        studentEmail: old.studentEmail,
        landlordId: old.landlordId,
        landlordName: old.landlordName,
        message: old.message,
        status: 'responded',
        responses: updatedResponses,
        createdAt: old.createdAt,
      );
    }
  }

  Future<void> updateEnquiryStatus(String enquiryId, String status) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.enquiriesCollection)
          .doc(enquiryId)
          .update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    }
    final idx = _localEnquiries.indexWhere((e) => e.id == enquiryId);
    if (idx != -1) {
      final old = _localEnquiries[idx];
      _localEnquiries[idx] = EnquiryModel(
        id: old.id,
        propertyId: old.propertyId,
        propertyTitle: old.propertyTitle,
        studentId: old.studentId,
        studentName: old.studentName,
        studentEmail: old.studentEmail,
        landlordId: old.landlordId,
        landlordName: old.landlordName,
        message: old.message,
        status: status,
        responses: old.responses,
        createdAt: old.createdAt,
      );
    }
  }

  // Roommate Preferences
  Future<void> saveRoommatePreference(RoommatePreferenceModel pref) async {
    await updateRoommatePreference(pref);
  }

  Future<void> updateRoommatePreference(RoommatePreferenceModel pref) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.roommatePreferencesCollection)
          .doc(pref.userId)
          .set(pref.toMap(), SetOptions(merge: true));
    }
    final idx = _localRoommates.indexWhere((r) => r.userId == pref.userId);
    if (idx != -1) {
      _localRoommates[idx] = pref;
    } else {
      _localRoommates.add(pref);
    }
  }

  Future<RoommatePreferenceModel?> getRoommatePreference(String userId) async {
    final db = _db;
    if (db != null) {
      final doc = await db
          .collection(FirebaseConstants.roommatePreferencesCollection)
          .doc(userId)
          .get();
      return doc.exists ? RoommatePreferenceModel.fromDocument(doc) : null;
    }
    for (final pref in _localRoommates) {
      if (pref.userId == userId) return pref;
    }
    return null;
  }

  Future<List<RoommatePreferenceModel>> getAllRoommatePreferences() async {
    final db = _db;
    if (db == null) return List.of(_localRoommates);
    final snapshot = await db
        .collection(FirebaseConstants.roommatePreferencesCollection)
        .get();
    return snapshot.docs.map(RoommatePreferenceModel.fromDocument).toList();
  }

  // Admin
  Future<void> verifyProperty(String propertyId, bool isVerified) async {
    final db = _db;
    if (db != null) {
      await db
          .collection(FirebaseConstants.propertiesCollection)
          .doc(propertyId)
          .update({
        'isVerified': isVerified,
        'updatedAt': Timestamp.now(),
      });
    }
    final idx = _localProperties.indexWhere((p) => p.id == propertyId);
    if (idx != -1) {
      _localProperties[idx] =
          _localProperties[idx].copyWith(isVerified: isVerified);
    }
  }

  Stream<List<PropertyModel>> getUnverifiedProperties() {
    final db = _db;
    if (db == null)
      return Stream.value(
          _localProperties.where((p) => !p.isVerified).toList());
    return db
        .collection(FirebaseConstants.propertiesCollection)
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(PropertyModel.fromDocument).toList());
  }

  // ── Bookings ──────────────────────────────────────────────────────────────

  static final List<BookingModel> _localBookings = [];

  /// Student pays and creates a room-reservation request.
  Future<void> createBooking(BookingModel booking) async {
    final db = _db;
    if (db != null) {
      await db.collection('bookings').doc(booking.id).set(booking.toMap());
    }
    _localBookings.insert(0, booking);
  }

  /// All bookings made by a particular student.
  Stream<List<BookingModel>> getStudentBookings(String studentId) {
    final db = _db;
    if (db == null) {
      return Stream.value(
        _localBookings.where((b) => b.studentId == studentId).toList(),
      );
    }
    return db
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(BookingModel.fromDocument).toList());
  }

  /// All bookings received by a landlord across their properties.
  Stream<List<BookingModel>> getLandlordBookings(String landlordId) {
    final db = _db;
    if (db == null) {
      return Stream.value(
          _localBookings.where((b) => b.landlordId == landlordId).toList());
    }
    return db
        .collection('bookings')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(BookingModel.fromDocument).toList());
  }

  /// Landlord confirms or rejects a booking. Optional [note] visible to student.
  Future<void> updateBookingStatus(String bookingId, String status,
      {String? note}) async {
    final db = _db;
    if (db != null) {
      await db.collection('bookings').doc(bookingId).update({
        'status': status,
        if (note != null) 'landlordNote': note,
        'updatedAt': Timestamp.now(),
      });
    }
    final idx = _localBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _localBookings[idx] = _localBookings[idx].copyWith(
        status: status,
        landlordNote: note ?? _localBookings[idx].landlordNote,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Check if a student already has an active booking for a property.
  Future<bool> hasStudentBookedProperty(
      String propertyId, String studentId) async {
    final isActive = (BookingModel b) =>
        b.propertyId == propertyId &&
        b.studentId == studentId &&
        (b.status == 'pending' || b.status == 'confirmed');
    final db = _db;
    if (db == null) return _localBookings.any(isActive);
    final snapshot = await db
        .collection('bookings')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snapshot.docs.any((doc) => isActive(BookingModel.fromDocument(doc)));
  }

  // ── Unlocked Contacts (paid access) ───────────────────────────────────────

  /// Tracks which student has unlocked which property's contact info.
  static final Set<String> _unlockedContacts = {};

  String _unlockKey(String studentId, String propertyId) =>
      '${studentId}_$propertyId';

  /// Returns true if the student has already paid to unlock this property's contact.
  Future<bool> isContactUnlocked(String studentId, String propertyId) async {
    final db = _db;
    if (db == null)
      return _unlockedContacts.contains(_unlockKey(studentId, propertyId));
    final accessId = _unlockKey(studentId, propertyId);
    final doc = await db.collection('unlocked_contacts').doc(accessId).get();
    return doc.exists;
  }

  /// Simulates payment and marks the contact as unlocked for this student.
  Future<void> unlockContact(String studentId, String propertyId) async {
    final db = _db;
    if (db != null) {
      final accessId = _unlockKey(studentId, propertyId);
      await db.collection('unlocked_contacts').doc(accessId).set({
        'studentId': studentId,
        'propertyId': propertyId,
        'unlockedAt': Timestamp.now(),
      });
    }
    _unlockedContacts.add(_unlockKey(studentId, propertyId));
  }
}
