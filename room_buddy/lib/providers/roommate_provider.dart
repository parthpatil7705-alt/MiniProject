import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/models/roommate_preference_model.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/auth_provider.dart';

// StateProvider for roommate refresh
final roommateRefreshProvider = StateProvider<int>((ref) => 0);

// FutureProvider.family for user's roommate preferences
final roommatePreferenceProvider = FutureProvider.family<RoommatePreferenceModel?, String>((ref, userId) async {
  ref.watch(roommateRefreshProvider);
  return await ref.watch(firestoreServiceProvider).getRoommatePreference(userId);
});

// FutureProvider for compatible roommates
final compatibleRoommatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(roommateRefreshProvider);
  
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  // Get current user's preferences
  final currentUserPref = await firestoreService.getRoommatePreference(user.uid);
  if (currentUserPref == null) return [];
  
  // Get all preferences
  final allPrefs = await firestoreService.getAllRoommatePreferences();
  
  List<Map<String, dynamic>> scoredRoommates = [];
  
  for (var pref in allPrefs) {
    if (pref.userId == user.uid) continue;

    // Use the model's built-in compatibility algorithm
    final score = currentUserPref.calculateCompatibility(pref);

    // Only show matches with at least 30% compatibility
    if (score >= 30) {
      scoredRoommates.add({
        'preference': pref,
        'score': score,
      });
    }
  }
  
  // Sort by score descending
  scoredRoommates.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  
  return scoredRoommates;
});

