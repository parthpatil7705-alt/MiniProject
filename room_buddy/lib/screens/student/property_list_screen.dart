import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/error_widget.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/widgets/property_card.dart';
import 'package:room_buddy/screens/student/search_filter_screen.dart';

class PropertyListScreen extends ConsumerWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPropertiesAsync = ref.watch(availablePropertiesProvider);
    final propertiesAsync = ref.watch(filteredPropertiesProvider);
    final filters = ref.watch(propertyFiltersProvider);
    final compareList = ref.watch(comparePropertiesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: TextField(
            controller: TextEditingController(text: searchQuery)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: searchQuery.length),
              ),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search Vishrambag, WCE campus, flats...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textMuted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.primary),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppColors.primary),
            tooltip: 'Walchand Campus Map',
            onPressed: () {
              Navigator.pushNamed(context, '/property-map');
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: filters.activeFilterCount > 0,
              label: Text(filters.activeFilterCount.toString()),
              backgroundColor: AppColors.primary,
              child:
                  const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            ),
            tooltip: 'Filters',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const SearchFilterScreen(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Active Filter Chips
          if (filters.activeFilterCount > 0)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Filters:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (filters.city != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _FilterTag(
                          label: filters.city!,
                          onDelete: () {
                            ref.read(propertyFiltersProvider.notifier).state =
                                filters.copyWith(clearCity: true);
                          },
                        ),
                      ),
                    if (filters.propertyType != null &&
                        filters.propertyType != 'All')
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _FilterTag(
                          label: filters.propertyType!,
                          onDelete: () {
                            ref.read(propertyFiltersProvider.notifier).state =
                                filters.copyWith(clearPropertyType: true);
                          },
                        ),
                      ),
                    if (filters.maxRent != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _FilterTag(
                          label: 'Up to ₹${filters.maxRent!.toInt()}',
                          onDelete: () {
                            ref.read(propertyFiltersProvider.notifier).state =
                                filters.copyWith(
                                    clearMinRent: true, clearMaxRent: true);
                          },
                        ),
                      ),
                    TextButton(
                      onPressed: () {
                        ref.read(propertyFiltersProvider.notifier).state =
                            PropertyFilters();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Reset All',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),

          // Main Properties Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(availablePropertiesProvider);
              },
              child: allPropertiesAsync.when(
                loading: () => const Center(child: LoadingWidget()),
                error: (error, stack) => AppErrorWidget(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(availablePropertiesProvider),
                ),
                data: (allProperties) {
                  // 1. Firebase loaded successfully, but landlords have published no properties
                  if (allProperties.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        EmptyStateWidget(
                          icon: Icons.holiday_village_outlined,
                          title: 'No properties available yet',
                          subtitle:
                              'Landlords haven’t published any listings yet. Please check back later.',
                          actionLabel: 'Refresh listings',
                          actionIcon: Icons.refresh_rounded,
                          onAction: () {
                            ref.invalidate(availablePropertiesProvider);
                          },
                        ),
                      ],
                    );
                  }

                  // 2. Properties exist in Firestore; inspect filtered results (search & filters)
                  return propertiesAsync.when(
                    loading: () => const Center(child: LoadingWidget()),
                    error: (error, stack) => AppErrorWidget(
                      message: error.toString(),
                      onRetry: () =>
                          ref.invalidate(availablePropertiesProvider),
                    ),
                    data: (properties) {
                      if (properties.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 60),
                            EmptyStateWidget(
                              icon: Icons.search_off_rounded,
                              title:
                                  'No properties match your search or filters',
                              subtitle:
                                  'Try adjusting your search terms, removing filters, or widening your price range.',
                              actionLabel: 'Clear filters',
                              actionIcon: Icons.filter_alt_off_rounded,
                              onAction: () {
                                ref
                                    .read(propertyFiltersProvider.notifier)
                                    .state = PropertyFilters();
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                              },
                            ),
                          ],
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;

                          // Responsive column calculation
                          int crossAxisCount = 1;
                          if (width >= 1200) {
                            crossAxisCount = 4;
                          } else if (width >= 860) {
                            crossAxisCount = 3;
                          } else if (width >= 580) {
                            crossAxisCount = 2;
                          }

                          return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1300),
                              child: CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  // Results count header
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 16, 20, 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${properties.length} Accommodations Available',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const Row(
                                            children: [
                                              Icon(Icons.verified_user_rounded,
                                                  size: 14,
                                                  color: AppColors.verified),
                                              SizedBox(width: 4),
                                              Text(
                                                'Sangli / WCE Area',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Grid / List
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 4.0),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        mainAxisExtent: 275,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final property = properties[index];
                                          final isInComp = compareList
                                              .any((p) => p.id == property.id);

                                          return PropertyCard(
                                            property: property,
                                            isInCompare: isInComp,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/property-detail',
                                                arguments: property,
                                              );
                                            },
                                            onCompare: () {
                                              final notifier = ref.read(
                                                  comparePropertiesProvider
                                                      .notifier);
                                              if (!notifier
                                                  .isInCompare(property.id)) {
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
                                                                context,
                                                                '/compare'),
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                notifier.addProperty(property);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        '${property.title} added to compare'),
                                                    action: SnackBarAction(
                                                      label:
                                                          'Compare (${compareList.length + 1})',
                                                      onPressed: () =>
                                                          Navigator.pushNamed(
                                                              context,
                                                              '/compare'),
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    duration: const Duration(
                                                        seconds: 3),
                                                  ),
                                                );
                                              } else {
                                                notifier.removeProperty(
                                                    property.id);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        '${property.title} removed from compare'),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        },
                                        childCount: properties.length,
                                      ),
                                    ),
                                  ),

                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 32),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: compareList.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: AppColors.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 10,
                      offset: Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.compare_arrows_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${compareList.length} / 3 Properties Selected',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/compare'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Compare Now',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _FilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _FilterTag({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
