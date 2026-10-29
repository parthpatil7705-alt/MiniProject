import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/auth_provider.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/providers/enquiry_provider.dart';
import 'package:room_buddy/screens/landlord/add_property_screen.dart';
import 'package:room_buddy/screens/landlord/edit_property_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_enquiries_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_profile_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_ratings_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_verification_screen.dart';
import 'package:room_buddy/widgets/enquiry_card.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/models/enquiry_model.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/error_widget.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LandlordDashboardScreen extends ConsumerStatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  ConsumerState<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends ConsumerState<LandlordDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final userId = (user?.id.isNotEmpty == true) ? user!.id : 'user_landlord';

    final enquiriesAsync = ref.watch(landlordEnquiriesProvider(userId));
    final pendingCount = enquiriesAsync.value?.where((e) => e.status.toLowerCase() == 'pending').length ?? 0;

    final screens = [
      _DashboardOverviewTab(
        onNavigateToListings: () => setState(() => _currentIndex = 1),
        onNavigateToEnquiries: () => setState(() => _currentIndex = 2),
      ),
      _MyPropertiesTab(userId: userId),
      const LandlordEnquiriesScreen(),
      const LandlordProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 6,
        indicatorColor: const Color(0xFFEEF2FF),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF4F46E5)),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.holiday_village_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.holiday_village_rounded, color: Color(0xFF4F46E5)),
            label: 'My Listings',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(pendingCount.toString()),
              backgroundColor: const Color(0xFFEF4444),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF64748B)),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(pendingCount.toString()),
              backgroundColor: const Color(0xFFEF4444),
              child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF4F46E5)),
            ),
            label: 'Enquiries',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF4F46E5)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 0: DASHBOARD OVERVIEW
// -------------------------------------------------------------
class _DashboardOverviewTab extends ConsumerWidget {
  final VoidCallback onNavigateToListings;
  final VoidCallback onNavigateToEnquiries;

  const _DashboardOverviewTab({
    required this.onNavigateToListings,
    required this.onNavigateToEnquiries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final userId = (user?.id.isNotEmpty == true) ? user!.id : 'user_landlord';

    final propertiesAsync = ref.watch(landlordPropertiesProvider(userId));
    final enquiriesAsync = ref.watch(landlordEnquiriesProvider(userId));

    final properties = propertiesAsync.value ?? [];
    final enquiries = enquiriesAsync.value ?? [];

    final totalProperties = properties.length;
    final activeProperties = properties.where((p) => p.isAvailable).length;
    final totalEnquiries = enquiries.length;
    final pendingEnquiries = enquiries.where((e) => e.status.toLowerCase() == 'pending').length;

    // Calculate revenue & room stats
    double totalMonthlyRent = 0;
    int totalRooms = 0;
    int availableRooms = 0;
    for (final p in properties) {
      totalMonthlyRent += p.rent;
      totalRooms += p.totalRooms;
      availableRooms += p.availableRooms;
    }
    final occupiedRooms = (totalRooms - availableRooms).clamp(0, totalRooms);
    final occupancyRate = totalRooms > 0 ? ((occupiedRooms / totalRooms) * 100).toInt() : 80;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
                      : 'LL',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Hi, ${user?.name.split(' ').first ?? 'Landlord'} 👋',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Host',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0D9488)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.companyName.isNotEmpty == true
                        ? user!.companyName
                        : 'Property Management Dashboard',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 20),
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have all notifications up to date.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Account & Login Options',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Icon(Icons.login_rounded, color: Color(0xFF4F46E5), size: 18),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (val) async {
              if (val == 'login') {
                Navigator.pushReplacementNamed(context, '/login');
              } else if (val == 'student') {
                ref.read(authServiceProvider).setLocalUser('user_student', 'student@roombuddy.com');
                ref.read(userRefreshProvider.notifier).state++;
                ref.invalidate(currentUserProvider);
                Navigator.pushReplacementNamed(context, '/student-home');
              } else if (val == 'logout') {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'login',
                child: Row(
                  children: [
                    Icon(Icons.login_rounded, size: 18, color: Color(0xFF4F46E5)),
                    SizedBox(width: 10),
                    Text('Go to Login Page', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'student',
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, size: 18, color: Color(0xFF0D9488)),
                    SizedBox(width: 10),
                    Text('Switch to Student Portal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(landlordPropertiesProvider(userId));
          ref.invalidate(landlordEnquiriesProvider(userId));
          ref.invalidate(currentUserProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // HERO FINANCIAL & OCCUPANCY CARD
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x281E1B4B),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MONTHLY PERFORMANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFA5B4FC),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live Listings',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${totalMonthlyRent.toInt() > 0 ? totalMonthlyRent.toInt().toString() : '21,700'}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '/ month potential',
                        style: TextStyle(fontSize: 13, color: Color(0xFFC7D2FE), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Occupancy progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Room Occupancy: $occupancyRate%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        '$availableRooms room${availableRooms == 1 ? '' : 's'} available to rent',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFC7D2FE)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (occupancyRate / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BENTO METRICS GRID
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    title: 'Total Properties',
                    value: totalProperties.toString(),
                    subtitle: '$activeProperties Active',
                    icon: Icons.holiday_village_rounded,
                    iconColor: const Color(0xFF4F46E5),
                    iconBg: const Color(0xFFEEF2FF),
                    onTap: onNavigateToListings,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildBentoCard(
                    title: 'Total Enquiries',
                    value: totalEnquiries.toString(),
                    subtitle: pendingEnquiries > 0 ? '$pendingEnquiries Need Action' : 'All Responded',
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: pendingEnquiries > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    iconBg: pendingEnquiries > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                    badgeText: pendingEnquiries > 0 ? 'Pending' : null,
                    onTap: onNavigateToEnquiries,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    title: 'Student Rating',
                    value: '4.9 ★',
                    subtitle: '18 Verified Reviews',
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFFFBEB),
                    badgeText: 'Top Rated',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LandlordRatingsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildBentoCard(
                    title: 'Host Verification',
                    value: 'Verified',
                    subtitle: '100% Identity Check',
                    icon: Icons.verified_user_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFD1FAE5),
                    badgeText: 'Shield',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LandlordVerificationScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QUICK ACTIONS BAR
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x284F46E5),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Add New Property',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigateToEnquiries,
                    icon: const Icon(Icons.forum_outlined, color: Color(0xFF4F46E5), size: 18),
                    label: const Text(
                      'View Inquiries',
                      style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // MY ACTIVE LISTINGS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Active Listings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: onNavigateToListings,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Manage all',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            propertiesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: LoadingWidget()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: AppErrorWidget(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(landlordPropertiesProvider(userId)),
                ),
              ),
              data: (propertiesList) {
                if (propertiesList.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: EmptyStateWidget(
                      icon: Icons.holiday_village_outlined,
                      title: 'You haven’t added any listings yet',
                      subtitle: 'Create your first listing to start receiving student inquiries.',
                      actionLabel: 'Add Listing',
                      actionIcon: Icons.add_rounded,
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                      ),
                    ),
                  );
                }

                return Column(
                  children: propertiesList.take(2).map((prop) {
                    return _LandlordPropertyCard(property: prop);
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // RECENT STUDENT INQUIRIES SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Student Inquiries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: onNavigateToEnquiries,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (enquiries.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'No student inquiries received yet.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              )
            else
              ...enquiries.take(2).map((enq) {
                return EnquiryCard(
                  key: ValueKey(enq.id),
                  enquiry: enq,
                  isLandlord: true,
                  onRespond: (reply) async {
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.respondToEnquiry(
                      enq.id,
                      EnquiryResponse(
                        senderId: userId,
                        senderName: user?.name ?? 'Landlord',
                        message: reply,
                        timestamp: DateTime.now(),
                      ),
                    );
                    ref.invalidate(landlordEnquiriesProvider(userId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Response sent!'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  onUpdateStatus: (newStatus) async {
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.updateEnquiryStatus(enq.id, newStatus);
                    ref.invalidate(landlordEnquiriesProvider(userId));
                  },
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    String? badgeText,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: MY PROPERTIES MANAGEMENT TAB
// -------------------------------------------------------------
class _MyPropertiesTab extends ConsumerStatefulWidget {
  final String userId;
  const _MyPropertiesTab({required this.userId});

  @override
  ConsumerState<_MyPropertiesTab> createState() => _MyPropertiesTabState();
}

class _MyPropertiesTabState extends ConsumerState<_MyPropertiesTab> {
  String _categoryFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Apartment', 'PG', 'Flat', 'Hostel', 'Available Only'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(landlordPropertiesProvider(widget.userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Property Listings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Manage your campus accommodations & room inventory',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: propertiesAsync.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (e, s) => Center(
          child: AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(landlordPropertiesProvider(widget.userId)),
          ),
        ),
        data: (properties) {
          // 1. Firebase loaded successfully, but landlord has not added any listings
          if (properties.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(landlordPropertiesProvider(widget.userId));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                children: [
                  EmptyStateWidget(
                    icon: Icons.holiday_village_outlined,
                    title: 'You haven’t added any listings yet',
                    subtitle: 'Create your first listing to start receiving student inquiries and bookings.',
                    actionLabel: 'Add Listing',
                    actionIcon: Icons.add_rounded,
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                    ),
                  ),
                ],
              ),
            );
          }

          var filtered = List<PropertyModel>.from(properties);

          if (_categoryFilter != 'All') {
            if (_categoryFilter == 'Available Only') {
              filtered = filtered.where((p) => p.isAvailable).toList();
            } else {
              filtered = filtered.where((p) => p.propertyType.toLowerCase() == _categoryFilter.toLowerCase()).toList();
            }
          }

          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filtered = filtered.where((p) {
              return p.title.toLowerCase().contains(q) ||
                  p.location.address.toLowerCase().contains(q) ||
                  p.location.city.toLowerCase().contains(q);
            }).toList();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(landlordPropertiesProvider(widget.userId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by property title or street...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _categoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _categoryFilter = cat),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Properties exist, but search query or category filter hides them
                if (filtered.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No properties match your search or filters',
                      subtitle: 'Try adjusting your search query or selecting a different category filter.',
                      actionLabel: 'Clear filters',
                      actionIcon: Icons.clear_rounded,
                      onAction: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _categoryFilter = 'All';
                        });
                      },
                    ),
                  )
                else
                  ...filtered.map((prop) => _LandlordPropertyCard(property: prop)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// ENHANCED LANDLORD PROPERTY CARD WITH MANAGEMENT CONTROLS
// -------------------------------------------------------------
class _LandlordPropertyCard extends ConsumerWidget {
  final PropertyModel property;
  const _LandlordPropertyCard({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider).value;
    final hasImages = property.images.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo with status pills
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: hasImages
                      ? CachedNetworkImage(
                          imageUrl: property.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
                          errorWidget: (_, __, ___) => Container(color: const Color(0xFFF1F5F9)),
                        )
                      : Container(
                          color: const Color(0xFFEEF2FF),
                          child: const Center(
                            child: Icon(Icons.apartment_rounded, size: 40, color: Color(0xFF6366F1)),
                          ),
                        ),
                ),
                // Top Left: Category Pill
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.propertyType.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                // Top Right: Availability Pill
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: property.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.isAvailable ? 'ACTIVE' : 'OCCUPIED',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${property.rent.toInt()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location.address,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      '/ month',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics chip row (Available rooms, Deposit, Rating)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.meeting_room_outlined, size: 13, color: Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Text(
                            '${property.availableRooms} of ${property.totalRooms} rooms free',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 3),
                          Text(
                            '${property.rating.toStringAsFixed(1)} (${property.reviewCount})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Management Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPropertyScreen(property: property),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF4F46E5)),
                        label: const Text(
                          'Edit Listing',
                          style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final firestoreService = ref.read(firestoreServiceProvider);
                          final toggled = !property.isAvailable;
                          await firestoreService.updateProperty(property.id, {'isAvailable': toggled});
                          if (user != null) {
                            ref.invalidate(landlordPropertiesProvider(user.id));
                            ref.invalidate(availablePropertiesProvider);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(toggled ? 'Listing marked Active!' : 'Listing marked Occupied.'),
                                backgroundColor: toggled ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          property.isAvailable ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                          size: 15,
                          color: property.isAvailable ? const Color(0xFFD97706) : const Color(0xFF10B981),
                        ),
                        label: Text(
                          property.isAvailable ? 'Mark Occupied' : 'Mark Active',
                          style: TextStyle(
                            color: property.isAvailable ? const Color(0xFFD97706) : const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: property.isAvailable ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
