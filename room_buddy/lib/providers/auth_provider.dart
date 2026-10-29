import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_buddy/services/auth_service.dart';

// Provider for AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StreamProvider for auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
