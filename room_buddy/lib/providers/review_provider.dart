import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/models/review_model.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/auth_provider.dart';

// StreamProvider.family for property reviews
final propertyReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, propertyId) {
  return ref.watch(firestoreServiceProvider).getPropertyReviews(propertyId);
});

// FutureProvider.family for checking if user has reviewed
final hasReviewedProvider = FutureProvider.family<bool, String>((ref, propertyId) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  
  return await ref.watch(firestoreServiceProvider).hasUserReviewed(propertyId, user.uid);
});

// StreamProvider.family for landlord reviews across all properties
final landlordReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, landlordId) {
  return ref.watch(firestoreServiceProvider).getLandlordReviews(landlordId);
});

