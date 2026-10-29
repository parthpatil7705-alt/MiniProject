import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/services/firestore_service.dart';
import 'package:room_buddy/services/storage_service.dart';
import 'package:room_buddy/models/user_model.dart';
import 'package:room_buddy/providers/auth_provider.dart';

// Provider for FirestoreService
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// Provider for StorageService
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

// FutureProvider.family for getting a user by UID
final userProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUser(uid);
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllUsers();
});

// FutureProvider for getting current logged-in user's profile
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  // Watch userRefreshProvider to allow forcing a refresh
  ref.watch(userRefreshProvider);

  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  // 1. Check Firebase Auth user
  final user = authState.value ?? authService.currentUser;
  if (user != null) {
    // Never show the demo student profile for an authenticated account whose
    // Firestore profile is missing. That can make one account look like another.
    return firestoreService.getUser(user.uid);
  }

  // 2. Check local mock user ID
  final currentUid = authService.currentUserId;
  if (currentUid != null && currentUid.isNotEmpty) {
    final userData = await firestoreService.getUser(currentUid);
    if (userData != null) return userData;
  }

  // 3. Fallback to default student user for offline / direct student preview
  return await firestoreService.getUser('user_student');
});

// StateProvider for tracking if profile needs refresh
final userRefreshProvider = StateProvider<int>((ref) => 0);
