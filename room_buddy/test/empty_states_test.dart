import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/screens/student/property_list_screen.dart';
import 'package:room_buddy/screens/student/student_home_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_dashboard_screen.dart';

// 1x1 transparent PNG bytes for mock HTTP client
final _transparentPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });
  group('EmptyStateWidget Tests', () {
    testWidgets('renders title, subtitle, action button, and triggers onAction callback', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.holiday_village_outlined,
              title: 'No properties available yet',
              subtitle: 'Landlords haven’t published any listings yet. Please check back later.',
              actionLabel: 'Refresh listings',
              actionIcon: Icons.refresh_rounded,
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No properties available yet'), findsOneWidget);
      expect(find.text('Landlords haven’t published any listings yet. Please check back later.'), findsOneWidget);
      expect(find.text('Refresh listings'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.text('Refresh listings'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });
  });

  group('Student PropertyListScreen Empty States', () {
    testWidgets('shows "No properties available yet" and "Refresh listings" when stream returns empty list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availablePropertiesProvider.overrideWith((ref) => Stream.value(<PropertyModel>[])),
          ],
          child: const MaterialApp(
            home: PropertyListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No properties available yet'), findsOneWidget);
      expect(find.text('Landlords haven’t published any listings yet. Please check back later.'), findsOneWidget);
      expect(find.text('Refresh listings'), findsOneWidget);
    });

    testWidgets('shows "No properties match your search or filters" and "Clear filters" when listings exist but filtered out', (tester) async {
      final sampleProperty = PropertyModel(
        id: 'prop_1',
        landlordId: 'landlord_1',
        title: 'Spacious 2BHK Vishrambag',
        description: 'Near WCE campus',
        rent: 8000,
        deposit: 16000,
        propertyType: 'Apartment',
        availableRooms: 2,
        totalRooms: 4,
        amenities: const ['Wi-Fi'],
        images: const [],
        location: const PropertyLocation(
          address: 'Vishrambag',
          city: 'Sangli',
          state: 'Maharashtra',
          latitude: 16.8457,
          longitude: 74.6017,
        ),
        isAvailable: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availablePropertiesProvider.overrideWith((ref) => Stream.value([sampleProperty])),
            searchQueryProvider.overrideWith((ref) => 'NonExistentTitleXYZ'),
          ],
          child: const MaterialApp(
            home: PropertyListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No properties match your search or filters'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);

      // Tap "Clear filters"
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      // Now query is cleared, property should be visible
      expect(find.text('Spacious 2BHK Vishrambag'), findsOneWidget);
    });
  });

  group('StudentHomeScreen Empty States', () {
    testWidgets('shows "No properties available yet" with "Refresh listings" button when stream returns empty list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => Future.value(null)),
            availablePropertiesProvider.overrideWith((ref) => Stream.value(<PropertyModel>[])),
          ],
          child: const MaterialApp(
            home: StudentHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No properties available yet'), findsOneWidget);
      expect(find.text('Landlords haven’t published any listings yet. Please check back later.'), findsOneWidget);
      expect(find.text('Refresh listings'), findsOneWidget);
    });
  });

  group('LandlordDashboardScreen Empty States', () {
    testWidgets('shows "You haven’t added any listings yet" and "Add Listing" button when landlord has no listings', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool didPushRoute = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => Future.value(null)),
            landlordPropertiesProvider('user_landlord').overrideWith((ref) => Stream.value(<PropertyModel>[])),
          ],
          child: MaterialApp(
            navigatorObservers: [
              _RouteObserver(onPush: () {
                didPushRoute = true;
              }),
            ],
            home: const LandlordDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On current tab (Tab 0), exactly 1 empty state widget is on screen
      expect(find.text('You haven’t added any listings yet'), findsOneWidget);
      expect(find.text('Add Listing'), findsWidgets);

      // In IndexedStack both Tab 0 (Overview) and Tab 1 (My Listings) have the empty state
      expect(find.text('You haven’t added any listings yet', skipOffstage: false), findsNWidgets(2));

      // Tap "Add Listing" button
      await tester.tap(find.text('Add Listing').first);
      await tester.pump();

      expect(didPushRoute, isTrue);
    });
  });
}

class _RouteObserver extends NavigatorObserver {
  final VoidCallback onPush;
  _RouteObserver({required this.onPush});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      onPush();
    }
  }
}
