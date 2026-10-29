import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/providers/property_provider.dart';

class PropertyCompareScreen extends ConsumerStatefulWidget {
  const PropertyCompareScreen({super.key});

  @override
  ConsumerState<PropertyCompareScreen> createState() =>
      _PropertyCompareScreenState();
}

class _PropertyCompareScreenState extends ConsumerState<PropertyCompareScreen> {
  bool _highlightDifferences = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Pricing',
    'Space & Specs',
    'Amenities',
    'Location & Trust',
  ];

  // Helper to determine lowest rent
  String? _getLowestRentPropertyId(List<PropertyModel> list) {
    if (list.length < 2) return null;
    PropertyModel lowest = list.first;
    for (final p in list) {
      if (p.rent < lowest.rent) {
        lowest = p;
      }
    }
    return lowest.id;
  }

  // Helper to determine highest rating
  String? _getHighestRatingPropertyId(List<PropertyModel> list) {
    if (list.length < 2) return null;
    PropertyModel highest = list.first;
    for (final p in list) {
      if (p.averageRating > highest.averageRating) {
        highest = p;
      }
    }
    return highest.id;
  }

  // Helper to determine lowest deposit
  String? _getLowestDepositPropertyId(List<PropertyModel> list) {
    if (list.length < 2) return null;
    PropertyModel lowest = list.first;
    for (final p in list) {
      if (p.deposit < lowest.deposit) {
        lowest = p;
      }
    }
    return lowest.id;
  }

  // Standard set of student-essential amenities plus union of current properties
  List<String> _getCombinedAmenities(List<PropertyModel> list) {
    const defaultPriority = [
      'WiFi',
      'AC',
      'Food Included',
      'Attached Bathroom',
      'Power Backup',
      'Parking',
      'Laundry',
      'Kitchen',
      'Security',
      'Furnished',
      'Cleaning',
      'Balcony',
      'Gym',
    ];

    final Set<String> amenitySet = {};
    for (final def in defaultPriority) {
      amenitySet.add(def);
    }
    for (final p in list) {
      for (final a in p.amenities) {
        if (a.trim().isNotEmpty) {
          amenitySet.add(a.trim());
        }
      }
    }
    return amenitySet.toList();
  }

  bool _propertyHasAmenity(PropertyModel property, String amenityName) {
    final cleanTarget =
        amenityName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return property.amenities.any((a) {
      final cleanA = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      return cleanA == cleanTarget ||
          cleanA.contains(cleanTarget) ||
          cleanTarget.contains(cleanA);
    });
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') ||
        lower.contains('wi-fi') ||
        lower.contains('internet')) return Icons.wifi_rounded;
    if (lower.contains('ac') || lower.contains('air') || lower.contains('cool'))
      return Icons.ac_unit_rounded;
    if (lower.contains('park')) return Icons.local_parking_rounded;
    if (lower.contains('laund') || lower.contains('wash'))
      return Icons.local_laundry_service_rounded;
    if (lower.contains('kitch') || lower.contains('cook'))
      return Icons.countertops_rounded;
    if (lower.contains('gym') || lower.contains('fitness'))
      return Icons.fitness_center_rounded;
    if (lower.contains('secur') ||
        lower.contains('guard') ||
        lower.contains('cctv')) return Icons.security_rounded;
    if (lower.contains('power') ||
        lower.contains('backup') ||
        lower.contains('generator')) return Icons.battery_charging_full_rounded;
    if (lower.contains('water')) return Icons.water_drop_rounded;
    if (lower.contains('furnish') || lower.contains('sofa'))
      return Icons.weekend_rounded;
    if (lower.contains('bath') || lower.contains('washroom'))
      return Icons.bathtub_rounded;
    if (lower.contains('balcon') || lower.contains('terrace'))
      return Icons.balcony_rounded;
    if (lower.contains('food') ||
        lower.contains('meal') ||
        lower.contains('mess')) return Icons.restaurant_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('elevat') || lower.contains('lift'))
      return Icons.elevator_rounded;
    if (lower.contains('work') ||
        lower.contains('desk') ||
        lower.contains('study')) return Icons.desk_rounded;
    return Icons.check_circle_outline_rounded;
  }

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Clear Comparison?'),
          ],
        ),
        content: const Text(
            'Are you sure you want to remove all properties from comparison?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
            ),
            onPressed: () {
              ref.read(comparePropertiesProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showAddPropertySheet(
      BuildContext context, List<PropertyModel> currentCompare) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPropertyModal(
        currentlyCompared: currentCompare,
        onPropertySelected: (property) {
          ref.read(comparePropertiesProvider.notifier).addProperty(property);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${property.title} added to comparison'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primaryDark,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compareList = ref.watch(comparePropertiesProvider);

    if (compareList.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Compare Properties',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: _buildEmptyState(context),
      );
    }

    final lowestRentId = _getLowestRentPropertyId(compareList);
    final lowestDepositId = _getLowestDepositPropertyId(compareList);
    final highestRatingId = _getHighestRatingPropertyId(compareList);

    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive column sizing:
    // If 1 property: takes 220px
    // If 2 properties: takes 50% width on mobile without overflow
    // If 3 properties: takes 175px each with horizontal scroll
    final double columnWidth = compareList.length == 1
        ? (screenWidth > 500 ? 240.0 : screenWidth - 72)
        : (compareList.length == 2 && screenWidth < 600)
            ? ((screenWidth - 48) / 2).clamp(155.0, 220.0)
            : 175.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Compare Properties',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${compareList.length}/3',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (compareList.length < 3)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary),
              tooltip: 'Add Property',
              onPressed: () => _showAddPropertySheet(context, compareList),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            tooltip: 'Clear All',
            onPressed: () => _showClearConfirmDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Sub-header Banner & Filter Bar
          _buildTopBannerAndFilterBar(context, compareList),

          // Main Comparison Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Column Header Cards
                  _buildPropertyHeaderRow(
                    context,
                    compareList,
                    columnWidth,
                    lowestRentId,
                    highestRatingId,
                  ),

                  const SizedBox(height: 16),

                  // Categorized Comparison Sections
                  if (_selectedCategory == 'All' ||
                      _selectedCategory == 'Pricing')
                    _buildPricingSection(
                      context,
                      compareList,
                      columnWidth,
                      lowestRentId,
                      lowestDepositId,
                    ),

                  if (_selectedCategory == 'All' ||
                      _selectedCategory == 'Space & Specs')
                    _buildSpaceSpecsSection(
                      context,
                      compareList,
                      columnWidth,
                    ),

                  if (_selectedCategory == 'All' ||
                      _selectedCategory == 'Location & Trust')
                    _buildLocationTrustSection(
                      context,
                      compareList,
                      columnWidth,
                      highestRatingId,
                    ),

                  if (_selectedCategory == 'All' ||
                      _selectedCategory == 'Amenities')
                    _buildAmenitiesSection(
                      context,
                      compareList,
                      columnWidth,
                    ),

                  // Bottom Action Strip
                  _buildBottomActionStrip(context, compareList, columnWidth),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Top banner with recommendation if only 1 property, plus category filter chips
  Widget _buildTopBannerAndFilterBar(
      BuildContext context, List<PropertyModel> compareList) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compareList.length == 1)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add at least 1 more property to see differences side-by-side!',
                      style: TextStyle(
                        color: Color(0xFF3730A3),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 32),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () =>
                        _showAddPropertySheet(context, compareList),
                    child: const Text('+ Add',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

          // Horizontal Filter Chips and "Highlight Differences" toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (compareList.length > 1) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _highlightDifferences = !_highlightDifferences;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: _highlightDifferences
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _highlightDifferences
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.difference_rounded,
                            size: 15,
                            color: _highlightDifferences
                                ? const Color(0xFFB45309)
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Diffs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _highlightDifferences
                                  ? const Color(0xFFB45309)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header Cards for each property + "+ Add Slot" if < 3
  Widget _buildPropertyHeaderRow(
    BuildContext context,
    List<PropertyModel> compareList,
    double columnWidth,
    String? lowestRentId,
    String? highestRatingId,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...compareList.map((property) {
            final isLowestRent = property.id == lowestRentId;
            final isTopRated = property.id == highestRatingId;

            return Container(
              width: columnWidth,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLowestRent
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE2E8F0),
                  width: isLowestRent ? 1.5 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F172A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Thumbnail with Badges
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Stack(
                      children: [
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF334155)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: property.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: property.images.first,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Container(
                                    color: const Color(0xFF1E293B),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (c, u, e) => const Center(
                                    child: Icon(Icons.apartment_rounded,
                                        color: Colors.white38, size: 36),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.apartment_rounded,
                                      color: Colors.white38, size: 36),
                                ),
                        ),
                        // Dark gradient on top of image for button contrast
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Type Tag
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              property.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Remove from Compare Button
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(comparePropertiesProvider.notifier)
                                  .removeProperty(property.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${property.title} removed from compare'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        // Best Value or Top Rated Tag on bottom of image
                        if (isLowestRent || isTopRated)
                          Positioned(
                            bottom: 6,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowestRent
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLowestRent
                                        ? Icons.sell_rounded
                                        : Icons.star_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isLowestRent ? 'Best Rent' : 'Top Rated',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Card Body Details
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Rent Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Helpers.formatCurrency(property.rentAmount),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const Text(
                              '/mo',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Rating & Location Row
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppColors.star),
                            const SizedBox(width: 2),
                            Text(
                              property.averageRating > 0
                                  ? property.averageRating.toStringAsFixed(1)
                                  : 'New',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // View Listing CTA
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.2),
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/property-detail',
                                arguments: property,
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('View',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(width: 3),
                                Icon(Icons.arrow_forward_rounded, size: 13),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // "+ Add Property" Slot (if list has fewer than 3 properties)
          if (compareList.length < 3)
            InkWell(
              onTap: () => _showAddPropertySheet(context, compareList),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: columnWidth,
                height: 245,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add Property',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Slot ${compareList.length + 1} of 3',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Section 1: Pricing
  Widget _buildPricingSection(
    BuildContext context,
    List<PropertyModel> compareList,
    double columnWidth,
    String? lowestRentId,
    String? lowestDepositId,
  ) {
    return _buildSectionCard(
      title: 'Pricing & Financials',
      icon: Icons.payments_rounded,
      iconColor: const Color(0xFF0D9488),
      children: [
        _buildComparisonRow(
          title: 'Monthly Rent',
          subtitle: 'Regular monthly payment',
          icon: Icons.currency_rupee_rounded,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            final isLowest = p.id == lowestRentId;
            return _ValueBox(
              primaryText: Helpers.formatCurrency(p.rentAmount),
              badgeText: isLowest ? 'Best Price' : null,
              badgeColor: const Color(0xFF10B981),
              isHighlighted: isLowest,
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Security Deposit',
          subtitle: 'Refundable on move-out',
          icon: Icons.account_balance_wallet_outlined,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            final isLowest = p.id == lowestDepositId;
            return _ValueBox(
              primaryText: Helpers.formatCurrency(p.depositAmount),
              badgeText: isLowest ? 'Lowest Deposit' : null,
              badgeColor: const Color(0xFF0D9488),
              isHighlighted: isLowest,
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Total Upfront Cost',
          subtitle: 'Rent + Security Deposit',
          icon: Icons.receipt_long_outlined,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            final total = p.rentAmount + p.depositAmount;
            return _ValueBox(
              primaryText: Helpers.formatCurrency(total),
              secondaryText: 'First month',
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Rent per Room / Bed',
          subtitle: 'Calculated per available spot',
          icon: Icons.calculate_outlined,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            final rooms = p.availableRooms > 0 ? p.availableRooms : 1;
            final perRoom = p.rentAmount / rooms;
            return _ValueBox(
              primaryText: Helpers.formatCurrency(perRoom),
              secondaryText: 'per room/bed',
            );
          },
        ),
      ],
    );
  }

  // Section 2: Space & Specs
  Widget _buildSpaceSpecsSection(
    BuildContext context,
    List<PropertyModel> compareList,
    double columnWidth,
  ) {
    return _buildSectionCard(
      title: 'Space & Accommodation',
      icon: Icons.home_work_rounded,
      iconColor: const Color(0xFF4F46E5),
      children: [
        _buildComparisonRow(
          title: 'Property Type',
          icon: Icons.domain_rounded,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            return _ValueBox(
              primaryText: p.type.toUpperCase(),
              secondaryText: p.propertyType,
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Available Rooms',
          subtitle: 'Open for immediate booking',
          icon: Icons.bed_rounded,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            final hasRooms = p.availableRooms > 0;
            return _ValueBox(
              primaryText: '${p.availableRooms} Available',
              badgeText: hasRooms ? 'Vacant' : 'Full',
              badgeColor:
                  hasRooms ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Total Capacity',
          subtitle: 'Overall room count',
          icon: Icons.meeting_room_outlined,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            return _ValueBox(
              primaryText: '${p.totalRooms} Rooms',
              secondaryText: '${p.availableRooms} free / ${p.totalRooms} total',
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Furnishing State',
          icon: Icons.chair_outlined,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            final isFurnished = _propertyHasAmenity(p, 'Furnished');
            return _ValueBox(
              primaryText: isFurnished ? 'Fully Furnished' : 'Semi / Standard',
              icon: isFurnished ? Icons.check_circle : Icons.info_outline,
              iconColor: isFurnished
                  ? const Color(0xFF10B981)
                  : const Color(0xFF64748B),
            );
          },
        ),
      ],
    );
  }

  // Section 3: Location & Verification
  Widget _buildLocationTrustSection(
    BuildContext context,
    List<PropertyModel> compareList,
    double columnWidth,
    String? highestRatingId,
  ) {
    return _buildSectionCard(
      title: 'Location & Trust',
      icon: Icons.verified_user_rounded,
      iconColor: const Color(0xFF10B981),
      children: [
        _buildComparisonRow(
          title: 'Campus Verification',
          subtitle: 'Verified by Walchand / RoomBuddy',
          icon: Icons.shield_rounded,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            return _ValueBox(
              primaryText: p.isVerified ? 'Verified' : 'Pending',
              badgeText: p.isVerified ? '100% Legit' : 'Under Review',
              badgeColor: p.isVerified
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF97316),
              icon: p.isVerified
                  ? Icons.verified_rounded
                  : Icons.pending_actions_rounded,
              iconColor: p.isVerified
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF97316),
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Student Ratings',
          subtitle: 'Peer reviews & ratings',
          icon: Icons.star_rounded,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            final isTop = p.id == highestRatingId;
            return _ValueBox(
              primaryText: '${p.averageRating.toStringAsFixed(1)} ★',
              secondaryText: '(${p.reviewCount} reviews)',
              badgeText: isTop ? 'Top Rated' : null,
              badgeColor: const Color(0xFFF59E0B),
              isHighlighted: isTop,
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'City & Locality',
          icon: Icons.location_on_rounded,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            return _ValueBox(
              primaryText: p.city,
              secondaryText: p.address.isNotEmpty ? p.address : p.state,
            );
          },
        ),
        _buildDivider(),
        _buildComparisonRow(
          title: 'Host / Landlord',
          icon: Icons.person_outline_rounded,
          compareList: compareList,
          columnWidth: columnWidth,
          valueBuilder: (p) {
            return _ValueBox(
              primaryText: p.landlordName.isNotEmpty
                  ? p.landlordName
                  : 'Property Manager',
              secondaryText: 'Direct Landlord',
            );
          },
        ),
      ],
    );
  }

  // Section 4: Amenities Matrix
  Widget _buildAmenitiesSection(
    BuildContext context,
    List<PropertyModel> compareList,
    double columnWidth,
  ) {
    final amenities = _getCombinedAmenities(compareList);

    return _buildSectionCard(
      title: 'Amenities & Facilities Matrix',
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF8B5CF6),
      children: [
        for (int i = 0; i < amenities.length; i++) ...[
          if (i > 0) _buildDivider(),
          _buildAmenityComparisonRow(
            amenityName: amenities[i],
            compareList: compareList,
            columnWidth: columnWidth,
          ),
        ],
      ],
    );
  }

  // Row for a single amenity with side-by-side indicator capsules
  Widget _buildAmenityComparisonRow({
    required String amenityName,
    required List<PropertyModel> compareList,
    required double columnWidth,
  }) {
    // If difference filter is ON, check if all properties are identical for this amenity
    if (_highlightDifferences && compareList.length > 1) {
      final firstHas = _propertyHasAmenity(compareList.first, amenityName);
      final allSame = compareList
          .every((p) => _propertyHasAmenity(p, amenityName) == firstHas);
      if (allSame) {
        return const SizedBox.shrink(); // hide identical items
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getAmenityIcon(amenityName),
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                amenityName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: compareList.map((property) {
                final has = _propertyHasAmenity(property, amenityName);
                return Container(
                  width: columnWidth,
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        has ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: has
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        has
                            ? Icons.check_circle_rounded
                            : Icons.remove_circle_outline_rounded,
                        size: 15,
                        color: has
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        has ? 'Included' : 'Not Available',
                        style: TextStyle(
                          color: has
                              ? const Color(0xFF15803D)
                              : const Color(0xFF64748B),
                          fontWeight: has ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom action buttons for each property
  Widget _buildBottomActionStrip(
    BuildContext context,
    List<PropertyModel> compareList,
    double columnWidth,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Next Steps & Inquiries',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: compareList.map((property) {
                return Container(
                  width: columnWidth,
                  margin: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/property-detail',
                        arguments: property,
                      );
                    },
                    child: const Text(
                      'View Details',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Section Card Container Wrapper
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // Generic Comparison Row with attribute title on top and horizontal values
  Widget _buildComparisonRow({
    required String title,
    String? subtitle,
    required IconData icon,
    required List<PropertyModel> compareList,
    required double columnWidth,
    required Widget Function(PropertyModel property) valueBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 6),
                Text(
                  '• $subtitle',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: compareList.map((property) {
                return Container(
                  width: columnWidth,
                  margin: const EdgeInsets.only(right: 12),
                  child: valueBuilder(property),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, color: Color(0xFFF1F5F9), indent: 14, endIndent: 14);
  }

  // Beautiful, lively empty state
  Widget _buildEmptyState(BuildContext context) {
    final availableAsync = ref.watch(availablePropertiesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Illustration glow circle
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFCCFBF1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.compare_arrows_rounded,
                size: 46,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Properties Selected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Select up to 3 properties to compare rent, amenities, deposits, and room specs side-by-side.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Primary Browse Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(220, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text(
              'Browse Properties',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 36),

          // Quick Start / Recommended to Compare Section
          availableAsync.when(
            data: (properties) {
              if (properties.isEmpty) return const SizedBox.shrink();
              final preview = properties.take(3).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          color: AppColors.warning, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Quick Add to Compare',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...preview.map((property) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: property.images.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: property.images.first,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFF1E293B),
                                      child: const Icon(Icons.apartment,
                                          color: Colors.white54),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${Helpers.formatCurrency(property.rentAmount)}/mo • ${property.type}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              minimumSize: const Size(60, 36),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ref
                                  .read(comparePropertiesProvider.notifier)
                                  .addProperty(property);
                            },
                            child: const Text('+ Add',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Reusable Value Display Box for comparison cells
class _ValueBox extends StatelessWidget {
  final String primaryText;
  final String? secondaryText;
  final String? badgeText;
  final Color? badgeColor;
  final IconData? icon;
  final Color? iconColor;
  final bool isHighlighted;

  const _ValueBox({
    required this.primaryText,
    this.secondaryText,
    this.badgeText,
    this.badgeColor,
    this.icon,
    this.iconColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            isHighlighted ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isHighlighted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isHighlighted ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: iconColor ?? AppColors.textPrimary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  primaryText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isHighlighted
                        ? const Color(0xFF15803D)
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (secondaryText != null) ...[
            const SizedBox(height: 2),
            Text(
              secondaryText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (badgeText != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Add Property Bottom Sheet Modal
class _AddPropertyModal extends ConsumerStatefulWidget {
  final List<PropertyModel> currentlyCompared;
  final ValueChanged<PropertyModel> onPropertySelected;

  const _AddPropertyModal({
    required this.currentlyCompared,
    required this.onPropertySelected,
  });

  @override
  ConsumerState<_AddPropertyModal> createState() => _AddPropertyModalState();
}

class _AddPropertyModalState extends ConsumerState<_AddPropertyModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final availableAsync = ref.watch(availablePropertiesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Modal Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Comparison',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Select a property to compare specs and price',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title, location or property type...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: Color(0xFF64748B)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Property List
          Expanded(
            child: availableAsync.when(
              data: (properties) {
                final comparedIds =
                    widget.currentlyCompared.map((p) => p.id).toSet();
                final filtered = properties.where((p) {
                  if (comparedIds.contains(p.id))
                    return false; // already in compare
                  if (_searchQuery.isEmpty) return true;
                  return p.title.toLowerCase().contains(_searchQuery) ||
                      p.city.toLowerCase().contains(_searchQuery) ||
                      p.propertyType.toLowerCase().contains(_searchQuery) ||
                      p.address.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No matching properties found to add.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 68,
                              height: 68,
                              child: item.images.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.images.first,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFF1E293B),
                                      child: const Icon(Icons.apartment,
                                          color: Colors.white38),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.city} • ${item.type.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      Helpers.formatCurrency(item.rentAmount),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Text(
                                      '/mo',
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.star_rounded,
                                        size: 13, color: AppColors.star),
                                    Text(
                                      item.averageRating > 0
                                          ? item.averageRating
                                              .toStringAsFixed(1)
                                          : 'New',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(68, 36),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => widget.onPropertySelected(item),
                            child: const Text(
                              '+ Add',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: LoadingWidget()),
              error: (e, st) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
