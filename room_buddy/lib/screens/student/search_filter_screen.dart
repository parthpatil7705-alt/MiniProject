import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/constants/app_text_styles.dart';
import 'package:room_buddy/core/widgets/custom_button.dart';
import 'package:room_buddy/widgets/filter_chip_widget.dart';
import 'package:room_buddy/providers/property_provider.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  late double _minRent;
  late double _maxRent;
  String _selectedType = 'All';
  final _cityController = TextEditingController();
  bool _onlyAvailable = false;

  final List<String> _propertyTypes = ['All', 'Apartment', 'Hostel', 'PG', 'Flat', 'House'];

  @override
  void initState() {
    super.initState();
    final filters = ref.read(propertyFiltersProvider);
    _minRent = filters.minRent ?? 0;
    _maxRent = filters.maxRent ?? 50000;
    _selectedType = filters.propertyType ?? 'All';
    _cityController.text = filters.city ?? '';
    _onlyAvailable = filters.onlyAvailable ?? false;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Properties', style: AppTextStyles.h2),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Rent Range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Rent Range', style: AppTextStyles.h3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${_minRent.toInt()} - ₹${_maxRent.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: RangeValues(_minRent, _maxRent),
                  min: 0,
                  max: 50000,
                  divisions: 50,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  onChanged: (values) {
                    setState(() {
                      _minRent = values.start;
                      _maxRent = values.end;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Property Type
                Text('Accommodation Type', style: AppTextStyles.h3),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _propertyTypes.map((type) => FilterChipWidget(
                    label: type,
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = type);
                    },
                  )).toList(),
                ),
                const SizedBox(height: 20),

                // City / Area
                Text('City / Campus Locality', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Sangli, Vishrambag, College Corner',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Only Available Switch
                SwitchListTile(
                  title: const Text(
                    'Show only properties with available rooms',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  value: _onlyAvailable,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _onlyAvailable = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Clear All',
                        isOutlined: true,
                        onPressed: () {
                          ref.read(propertyFiltersProvider.notifier).state = PropertyFilters();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomButton(
                        text: 'Apply Filters',
                        onPressed: () {
                          ref.read(propertyFiltersProvider.notifier).state = PropertyFilters(
                            minRent: _minRent,
                            maxRent: _maxRent,
                            propertyType: _selectedType == 'All' ? null : _selectedType,
                            city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
                            onlyAvailable: _onlyAvailable,
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
