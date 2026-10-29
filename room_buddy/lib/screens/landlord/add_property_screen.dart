import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/core/utils/validators.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:uuid/uuid.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _availableRoomsController = TextEditingController(text: '1');
  final _totalRoomsController = TextEditingController(text: '3');
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Campus City');
  final _stateController = TextEditingController(text: 'State');
  final _customImageUrlController = TextEditingController();

  String _propertyType = 'apartment';
  bool _isAvailable = true;
  final List<String> _selectedAmenities = [
    'WiFi',
    'AC',
    'Security',
    'Water Supply'
  ];
  final List<String> _selectedImages = [
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
  ];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _propertyTypeOptions = [
    {
      'type': 'apartment',
      'label': 'Apartment',
      'icon': Icons.apartment_rounded
    },
    {'type': 'pg', 'label': 'PG / Co-living', 'icon': Icons.groups_rounded},
    {'type': 'flat', 'label': 'Flat / Suite', 'icon': Icons.chair_rounded},
    {'type': 'hostel', 'label': 'Hostel', 'icon': Icons.bed_rounded},
    {'type': 'house', 'label': 'Full House', 'icon': Icons.home_rounded},
  ];

  final List<Map<String, dynamic>> _amenitiesList = [
    {'name': 'WiFi', 'icon': Icons.wifi_rounded},
    {'name': 'AC', 'icon': Icons.ac_unit_rounded},
    {'name': 'Parking', 'icon': Icons.local_parking_rounded},
    {'name': 'Laundry', 'icon': Icons.local_laundry_service_rounded},
    {'name': 'Kitchen', 'icon': Icons.countertops_rounded},
    {'name': 'Gym', 'icon': Icons.fitness_center_rounded},
    {'name': 'Security', 'icon': Icons.security_rounded},
    {'name': 'Power Backup', 'icon': Icons.battery_charging_full_rounded},
    {'name': 'Water Supply', 'icon': Icons.water_drop_rounded},
    {'name': 'Furnished', 'icon': Icons.weekend_rounded},
    {'name': 'Attached Bathroom', 'icon': Icons.bathtub_rounded},
    {'name': 'Balcony', 'icon': Icons.balcony_rounded},
    {'name': 'Food Included', 'icon': Icons.restaurant_rounded},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded},
  ];

  final List<Map<String, String>> _samplePhotoPresets = [
    {
      'title': 'Modern Studio',
      'url':
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800'
    },
    {
      'title': 'Campus Suite',
      'url':
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800'
    },
    {
      'title': 'Twin PG Room',
      'url': 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=800'
    },
    {
      'title': 'Sunny Living Space',
      'url': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800'
    },
    {
      'title': 'Cozy Bedroom',
      'url':
          'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=800'
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _availableRoomsController.dispose();
    _totalRoomsController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _customImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception("User not logged in");

      final newProperty = PropertyModel(
        id: const Uuid().v4(),
        landlordId: user.id,
        landlordName: user.name,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        propertyType: _propertyType,
        rent: double.parse(_rentController.text.trim()),
        deposit: double.parse(_depositController.text.trim()),
        availableRooms: int.parse(_availableRoomsController.text.trim()),
        totalRooms: int.parse(_totalRoomsController.text.trim()),
        location: PropertyLocation(
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        amenities: _selectedAmenities,
        images: _selectedImages.isNotEmpty
            ? _selectedImages
            : [
                'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800'
              ],
        isAvailable: _isAvailable,
        isVerified: true,
        rating: 5.0,
        reviewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createProperty(newProperty);
      ref.invalidate(landlordPropertiesProvider(user.id));
      ref.invalidate(availablePropertiesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Property listing published successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error creating listing: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Property',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Basic Information
              _buildSectionCard(
                title: 'Property Overview',
                icon: Icons.holiday_village_rounded,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Listing Title *',
                      hintText: 'e.g. Skyline Student Suite across Main Gate',
                      prefixIcon: const Icon(Icons.title_rounded, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Title'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Property Category',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _propertyTypeOptions.map((opt) {
                        final isSelected = _propertyType == opt['type'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _propertyType = opt['type']),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    opt['icon'] as IconData,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    opt['label'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText:
                          'Highlight proximity to college, utilities included, study atmosphere...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 4,
                    validator: Validators.validateDescription,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 2: Pricing & Capacity
              _buildSectionCard(
                title: 'Pricing & Room Capacity',
                icon: Icons.payments_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rentController,
                          decoration: InputDecoration(
                            labelText: 'Monthly Rent (₹) *',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded,
                                size: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: Validators.validateRent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _depositController,
                          decoration: InputDecoration(
                            labelText: 'Deposit (₹) *',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                size: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              Validators.validateRequired(v, 'Deposit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _availableRoomsController,
                          decoration: InputDecoration(
                            labelText: 'Available Rooms *',
                            prefixIcon: const Icon(Icons.meeting_room_outlined,
                                size: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              Validators.validateRequired(v, 'Available rooms'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _totalRoomsController,
                          decoration: InputDecoration(
                            labelText: 'Total Rooms *',
                            prefixIcon:
                                const Icon(Icons.home_work_outlined, size: 18),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              Validators.validateRequired(v, 'Total rooms'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 3: Location Details
              _buildSectionCard(
                title: 'Property Location',
                icon: Icons.location_on_outlined,
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Street Address *',
                      hintText: 'e.g. 42 University Heights, Near North Gate',
                      prefixIcon: const Icon(Icons.place_outlined, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => Validators.validateRequired(v, 'Address'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City *',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) =>
                              Validators.validateRequired(v, 'City'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            labelText: 'State *',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) =>
                              Validators.validateRequired(v, 'State'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 4: Amenities
              _buildSectionCard(
                title: 'Included Amenities',
                icon: Icons.verified_outlined,
                children: [
                  const Text(
                    'Select all facilities available for students:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenitiesList.map((amenity) {
                      final name = amenity['name'] as String;
                      final icon = amenity['icon'] as IconData;
                      final isSelected = _selectedAmenities.contains(name);

                      return FilterChip(
                        avatar: Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4F46E5),
                        ),
                        label: Text(name),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            val
                                ? _selectedAmenities.add(name)
                                : _selectedAmenities.remove(name);
                          });
                        },
                        selectedColor: const Color(0xFF4F46E5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 5: Property Photos
              _buildSectionCard(
                title: 'Photos & Showcase',
                icon: Icons.photo_library_outlined,
                children: [
                  const Text(
                    'Select pre-curated high quality photos or enter a photo URL:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  // Preset photo cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _samplePhotoPresets.map((preset) {
                        final url = preset['url']!;
                        final isSelected = _selectedImages.contains(url);

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  if (_selectedImages.length > 1) {
                                    _selectedImages.remove(url);
                                  }
                                } else {
                                  _selectedImages.add(url);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFFCBD5E1),
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10)),
                                    child: Image.network(
                                      url,
                                      height: 75,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 14,
                                          color: isSelected
                                              ? const Color(0xFF4F46E5)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            preset['title']!,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Custom photo URL
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customImageUrlController,
                          decoration: InputDecoration(
                            hintText: 'Or paste image URL (https://...)',
                            hintStyle: const TextStyle(
                                fontSize: 12, color: Color(0xFF94A3B8)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _customImageUrlController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _selectedImages.add(text);
                              _customImageUrlController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          // This button shares a Row with the URL field; the
                          // app-wide infinite minimum width breaks that layout.
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        child: const Text('Add',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Section 6: Immediate Availability Switch
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'List as Active & Accepting Tenants',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A)),
                    ),
                    subtitle: const Text(
                      'Students can immediately discover and send inquiries for this property.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    value: _isAvailable,
                    activeThumbColor: const Color(0xFF10B981),
                    activeTrackColor: const Color(0xFFD1FAE5),
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Publish Button
              Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x334F46E5),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 20),
                  label: Text(
                    _isLoading ? 'Publishing...' : 'Publish Property Listing',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
