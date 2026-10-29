import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/error_widget.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/widgets/property_card.dart';
import 'package:room_buddy/screens/student/property_list_screen.dart';
import 'package:room_buddy/screens/student/student_profile_screen.dart';
import 'package:room_buddy/screens/student/roommate_discovery_screen.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    _HomeTab(onNavigateToSearch: () => setState(() => _currentIndex = 1)),
    const PropertyListScreen(),
    const RoommateDiscoveryScreen(),
    const StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final compareList = ref.watch(comparePropertiesProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: compareList.isNotEmpty && _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/compare');
              },
              icon:
                  const Icon(Icons.compare_arrows_rounded, color: Colors.white),
              label: Text(
                'Compare (${compareList.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              elevation: 4,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Roommates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToSearch;
  const _HomeTab({required this.onNavigateToSearch});

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Apartment', 'PG', 'Flat', 'Hostel'];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final propertiesAsync = ref.watch(availablePropertiesProvider);
    final compareList = ref.watch(comparePropertiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: userAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${user?.name.split(' ').first ?? 'Student'} 👋',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Find your stay near Walchand Campus, Sangli',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Welcome'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.textPrimary, size: 22),
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications are up to date.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(availablePropertiesProvider);
          ref.invalidate(currentUserProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Search Trigger
                  GestureDetector(
                    onTap: widget.onNavigateToSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x060F172A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Search by college, city, or area (e.g. Vishrambag)...',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Value Proposition Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F1E1B4B),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.verified_user_rounded,
                                      color: Color(0xFF6EE7B7), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'WCE Student Accommodations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Zero brokerage fees • Verified property owners • Compatible student roommate matching within walking distance of campus.',
                                style: TextStyle(
                                  color: Color(0xFFC7D2FE),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Filter Pills
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat == _selectedCategory;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedCategory = cat);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campus Map Explorer Card
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/property-map');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x060F172A),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.map_rounded,
                                color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Walchand Campus Map Explorer',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Explore stays near WCE Sangli, Vishrambag Stn & College Corner',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Featured Properties Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Featured Accommodations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Top rated stays near Walchand Campus',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: widget.onNavigateToSearch,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('View All',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Featured Properties Horizontal Carousel
                  propertiesAsync.when(
                    data: (properties) {
                      // 1. Firebase loaded successfully, but landlords have published no properties
                      if (properties.isEmpty) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: EmptyStateWidget(
                            icon: Icons.holiday_village_outlined,
                            title: 'No properties available yet',
                            subtitle:
                                'Landlords haven’t published any listings yet. Please check back later.',
                            actionLabel: 'Refresh listings',
                            actionIcon: Icons.refresh_rounded,
                            onAction: () =>
                                ref.invalidate(availablePropertiesProvider),
                          ),
                        );
                      }

                      final filtered = _selectedCategory == 'All'
                          ? properties
                          : properties
                              .where((p) =>
                                  p.propertyType.toLowerCase() ==
                                  _selectedCategory.toLowerCase())
                              .toList();

                      // 2. Properties exist, but category filter hid them
                      if (filtered.isEmpty) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: EmptyStateWidget(
                            icon: Icons.filter_alt_off_rounded,
                            title: 'No properties match your search or filters',
                            subtitle:
                                'No properties found in "$_selectedCategory". Try clearing category filters.',
                            actionLabel: 'Clear filters',
                            actionIcon: Icons.clear_rounded,
                            onAction: () =>
                                setState(() => _selectedCategory = 'All'),
                          ),
                        );
                      }

                      final featured = filtered.take(6).toList();
                      return SizedBox(
                        height: 285,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: featured.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 14.0),
                              child: SizedBox(
                                width: 260,
                                child: PropertyCard(
                                  property: featured[index],
                                  isInCompare: compareList
                                      .any((p) => p.id == featured[index].id),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/property-detail',
                                    arguments: featured[index],
                                  ),
                                  onCompare: () {
                                    final notifier = ref.read(
                                        comparePropertiesProvider.notifier);
                                    if (!notifier
                                        .isInCompare(featured[index].id)) {
                                      if (compareList.length >= 3) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Max 3 properties can be compared.'),
                                            action: SnackBarAction(
                                              label: 'View Compare',
                                              onPressed: () =>
                                                  Navigator.pushNamed(
                                                      context, '/compare'),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }
                                      notifier.addProperty(featured[index]);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${featured[index].title} added to compare'),
                                          action: SnackBarAction(
                                            label:
                                                'Compare (${compareList.length + 1})',
                                            onPressed: () =>
                                                Navigator.pushNamed(
                                                    context, '/compare'),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      notifier
                                          .removeProperty(featured[index].id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${featured[index].title} removed from compare'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const SizedBox(height: 260, child: LoadingWidget()),
                    error: (err, _) => SizedBox(
                      height: 260,
                      child: AppErrorWidget(
                        message: err.toString(),
                        onRetry: () =>
                            ref.invalidate(availablePropertiesProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Roommate Matching Teaser Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060F172A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.accentLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.group_rounded,
                                color: AppColors.accent, size: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Find Compatible Roommates',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Match by branch, study habits, food habits, and budget with fellow WCE students.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/roommate-discovery');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Find Now',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
