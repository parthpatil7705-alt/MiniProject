import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:room_buddy/core/theme/app_theme.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/models/roommate_preference_model.dart';

import 'package:room_buddy/screens/splash_screen.dart';
import 'package:room_buddy/screens/auth/login_screen.dart';
import 'package:room_buddy/screens/auth/register_screen.dart';
import 'package:room_buddy/screens/student/student_home_screen.dart';
import 'package:room_buddy/screens/student/property_list_screen.dart';
import 'package:room_buddy/screens/student/property_detail_screen.dart';
import 'package:room_buddy/screens/student/property_compare_screen.dart';
import 'package:room_buddy/screens/student/property_map_screen.dart';
import 'package:room_buddy/screens/student/reviews_screen.dart';
import 'package:room_buddy/screens/student/roommate_discovery_screen.dart';
import 'package:room_buddy/screens/student/roommate_detail_screen.dart';
import 'package:room_buddy/screens/student/roommate_preferences_screen.dart';
import 'package:room_buddy/screens/student/student_profile_screen.dart';
import 'package:room_buddy/screens/student/search_filter_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_dashboard_screen.dart';
import 'package:room_buddy/screens/landlord/add_property_screen.dart';
import 'package:room_buddy/screens/landlord/edit_property_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_enquiries_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_profile_screen.dart';
import 'package:room_buddy/screens/admin/admin_dashboard_screen.dart';
import 'package:room_buddy/screens/admin/admin_users_screen.dart';
import 'package:room_buddy/screens/admin/admin_properties_screen.dart';
import 'package:room_buddy/screens/admin/admin_verification_screen.dart';

import 'package:room_buddy/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      debugPrint(
          'Firebase: Running in local demo mode with in-memory seed data.');
    }
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(const ProviderScope(child: RoomBuddyApp()));
}

class RoomBuddyApp extends StatelessWidget {
  const RoomBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomBuddy',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/student-home': (context) => const StudentHomeScreen(),
        '/property-list': (context) => const PropertyListScreen(),
        '/property-compare': (context) => const PropertyCompareScreen(),
        '/compare': (context) => const PropertyCompareScreen(),
        '/roommate-discovery': (context) => const RoommateDiscoveryScreen(),
        '/roommate-preferences': (context) => const RoommatePreferencesScreen(),
        '/student-profile': (context) => const StudentProfileScreen(),
        '/landlord-dashboard': (context) => const LandlordDashboardScreen(),
        '/add-property': (context) => const AddPropertyScreen(),
        '/landlord-enquiries': (context) => const LandlordEnquiriesScreen(),
        '/landlord-profile': (context) => const LandlordProfileScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-users': (context) => const AdminUsersScreen(),
        '/admin-properties': (context) => const AdminPropertiesScreen(),
        '/admin-verification': (context) => const AdminVerificationScreen(),
        '/search-filter': (context) => const SearchFilterScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/property-detail' ||
            (settings.name?.startsWith('/property-detail') ?? false)) {
          final args = settings.arguments;
          final property = args is PropertyModel ? args : null;
          final propertyId = args is String ? args : (property?.id ?? 'prop_1');
          return MaterialPageRoute(
            builder: (context) => PropertyDetailScreen(
              propertyId: propertyId,
              initialProperty: property,
            ),
          );
        }
        if (settings.name == '/property-map') {
          final args = settings.arguments;
          final property = args is PropertyModel ? args : null;
          return MaterialPageRoute(
            builder: (context) => PropertyMapScreen(
              property: property,
              isSinglePropertyView: property != null,
            ),
          );
        }
        if (settings.name == '/reviews') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ReviewsScreen(
              propertyId: args?['propertyId'] as String? ?? 'prop_1',
              propertyTitle: args?['propertyTitle'] as String? ?? 'Reviews',
            ),
          );
        }
        if (settings.name == '/edit-property') {
          final args = settings.arguments;
          if (args is! PropertyModel) return null;
          return MaterialPageRoute(
            builder: (context) => EditPropertyScreen(property: args),
          );
        }
        if (settings.name == '/roommate-detail') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args == null || args['preference'] is! RoommatePreferenceModel)
            return null;
          return MaterialPageRoute(
            builder: (context) => RoommateDetailScreen(
              preference: args['preference'] as RoommatePreferenceModel,
              score: args['score'] as int? ?? 85,
            ),
          );
        }
        return null;
      },
    );
  }
}
