import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/constants/app_text_styles.dart';
import 'package:room_buddy/providers/auth_provider.dart';
import 'package:room_buddy/providers/user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _hasNavigated) return;

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final userData = await ref.read(firestoreServiceProvider).getUser(user.uid);
        if (userData != null && mounted && !_hasNavigated) {
          _hasNavigated = true;
          switch (userData.role.toLowerCase()) {
            case 'student':
              Navigator.pushReplacementNamed(context, '/student-home');
              return;
            case 'landlord':
              Navigator.pushReplacementNamed(context, '/landlord-dashboard');
              return;
            case 'admin':
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
              return;
            default:
              Navigator.pushReplacementNamed(context, '/login');
              return;
          }
        }
      }
    } catch (e) {
      debugPrint('Auth check fallback: $e');
    }

    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.apartment,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'RoomBuddy',
              style: AppTextStyles.h1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
