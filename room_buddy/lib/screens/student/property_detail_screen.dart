import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/error_widget.dart';
import 'package:room_buddy/core/widgets/custom_button.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/widgets/amenity_chip.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/models/enquiry_model.dart';
import 'package:room_buddy/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final PropertyModel? initialProperty;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    this.initialProperty,
  });

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  int _activeImageIndex = 0;
  bool _contactUnlocked = false;
  bool _isUnlocking = false;
  bool _isBooking = false;
  String? _bookingStatus; // null | 'pending' | 'confirmed' | 'rejected'

  @override
  void initState() {
    super.initState();
    _loadContactAccess();
  }

  Future<void> _loadContactAccess() async {
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;
      final unlocked = await ref
          .read(firestoreServiceProvider)
          .isContactUnlocked(user.uid, widget.propertyId);
      if (mounted) setState(() => _contactUnlocked = unlocked);
    } catch (_) {
      // Keep the contact locked if access cannot be confirmed from the database.
    }
  }

  /// Simulates a ₹29 payment and unlocks the landlord contact details.
  Future<void> _unlockContact(String studentId, String propertyId) async {
    setState(() => _isUnlocking = true);
    // Simulate payment gateway delay
    await Future.delayed(const Duration(milliseconds: 1200));
    final service = ref.read(firestoreServiceProvider);
    await service.unlockContact(studentId, propertyId);
    if (mounted)
      setState(() {
        _contactUnlocked = true;
        _isUnlocking = false;
      });
  }

  /// Creates a room reservation request.
  Future<void> _reserveRoom(PropertyModel property) async {
    final user = ref.read(currentUserProvider).value;
    final studentId = user?.uid ?? 'user_student';
    final studentName = user?.name ?? 'Student';
    final studentEmail = user?.email ?? 'student@roombuddy.com';

    // Check for duplicate active booking
    final service = ref.read(firestoreServiceProvider);
    final alreadyBooked =
        await service.hasStudentBookedProperty(property.id, studentId);
    if (alreadyBooked) {
      if (mounted)
        Helpers.showSnackBar(
            context, 'You already have an active booking for this property.');
      return;
    }

    setState(() => _isBooking = true);
    final booking = BookingModel(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: property.id,
      propertyTitle: property.title,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      landlordId: property.landlordId,
      landlordName: property.landlordName,
      rent: property.rent,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await service.createBooking(booking);
    if (mounted) {
      setState(() {
        _isBooking = false;
        _bookingStatus = 'pending';
      });
      Helpers.showSnackBar(context,
          'Room reservation request sent to ${property.landlordName}! Awaiting confirmation.');
    }
  }

  Future<void> _launchDirections(PropertyModel property) async {
    final lat = property.location.latitude != 0.0
        ? property.location.latitude
        : 16.8457;
    final lng = property.location.longitude != 0.0
        ? property.location.longitude
        : 74.6017;
    final address = Uri.encodeComponent(
        '${property.location.address}, ${property.location.city}');

    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$address');
    final fallbackUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening location: ${property.location.address}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEnquiryDialog(BuildContext context, PropertyModel property) {
    final messageController = TextEditingController(
      text:
          'Hi ${property.landlordName}, I am interested in renting this ${property.propertyType}. Is it still available?',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('Contact Landlord',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sending inquiry to ${property.landlordName}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (messageController.text.trim().isEmpty) return;
              final user = ref.read(currentUserProvider).value;
              final studentId = user?.uid ?? 'user_student';
              final studentName = user?.name ?? 'Alex Johnson';
              final studentEmail = user?.email ?? 'student@roombuddy.com';

              final enquiry = EnquiryModel(
                id: 'enq_${DateTime.now().millisecondsSinceEpoch}',
                propertyId: property.id,
                propertyTitle: property.title,
                studentId: studentId,
                studentName: studentName,
                studentEmail: studentEmail,
                landlordId: property.landlordId,
                landlordName: property.landlordName,
                message: messageController.text.trim(),
                status: 'pending',
                responses: const [],
                createdAt: DateTime.now(),
              );

              await ref.read(firestoreServiceProvider).createEnquiry(enquiry);

              if (context.mounted) {
                Navigator.pop(context);
                Helpers.showSnackBar(context,
                    'Enquiry sent to ${property.landlordName} successfully!');
              }
            },
            child: const Text('Send Message',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordContactCard(PropertyModel property) {
    final user = ref.read(currentUserProvider).value;
    final studentId = user?.uid ?? 'user_student';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Landlord name header (always visible)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    property.landlordName.isNotEmpty
                        ? property.landlordName[0]
                        : 'L',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.landlordName.isNotEmpty
                            ? property.landlordName
                            : 'Property Owner',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const Text('Verified Owner • Quick Response',
                          style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Locked / Unlocked contact section
          _contactUnlocked
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: '+91 98230 67890',
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 10),
                      _ContactRow(
                        icon: Icons.location_on_rounded,
                        label: 'Address',
                        value: property.location.address.isNotEmpty
                            ? '${property.location.address}, ${property.location.city}'
                            : 'Contact landlord for address',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                )
              : Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8F4FF), Color(0xFFEEF2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Contact Info Locked',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF312E81))),
                                Text(
                                    'Unlock phone & address to connect directly',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Blurred preview rows
                      _BlurredContactRow(
                          icon: Icons.phone_rounded, label: 'Phone'),
                      const SizedBox(height: 8),
                      _BlurredContactRow(
                          icon: Icons.location_on_rounded, label: 'Address'),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: _isUnlocking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.lock_open_rounded,
                                  color: Colors.white, size: 18),
                          label: Text(
                            _isUnlocking
                                ? 'Processing Payment...'
                                : 'Unlock Contact for ₹29',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          onPressed: _isUnlocking
                              ? null
                              : () => _unlockContact(studentId, property.id),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                          'One-time fee • Secure payment • Instant access',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDetailActionBar(PropertyModel property) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Compare',
                        isOutlined: true,
                        icon: Icons.compare_arrows_rounded,
                        onPressed: () {
                          final notifier =
                              ref.read(comparePropertiesProvider.notifier);
                          if (!notifier.isInCompare(property.id)) {
                            notifier.addProperty(property);
                            Helpers.showSnackBar(
                                context, 'Added to compare list');
                          } else {
                            Helpers.showSnackBar(
                                context, 'Already in compare list');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Enquire',
                        isOutlined: true,
                        icon: Icons.chat_rounded,
                        onPressed: () => _showEnquiryDialog(context, property),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isBooking
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : CustomButton(
                              text: _bookingStatus == 'pending'
                                  ? 'Requested'
                                  : 'Reserve',
                              icon: _bookingStatus == 'pending'
                                  ? Icons.hourglass_top_rounded
                                  : Icons.bookmark_add_rounded,
                              onPressed: _bookingStatus == 'pending'
                                  ? null
                                  : () => _reserveRoom(property),
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
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = widget.initialProperty != null
        ? AsyncValue.data(widget.initialProperty)
        : ref.watch(propertyByIdProvider(widget.propertyId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Property Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF334155)),
            onPressed: () {
              Helpers.showSnackBar(
                  context, 'Property link copied to clipboard');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: propertyAsync.when(
              data: (property) {
                if (property == null)
                  return const AppErrorWidget(message: 'Property not found');

                final images = property.images.isNotEmpty
                    ? property.images
                    : [
                        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800'
                      ];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = constraints.maxWidth.isFinite &&
                            constraints.maxWidth < 1080
                        ? constraints.maxWidth
                        : 1080.0;
                    return SingleChildScrollView(
                      child: Center(
                        child: SizedBox(
                          width: contentWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main Photo Display
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 280,
                                    width: double.infinity,
                                    child: CachedNetworkImage(
                                      imageUrl: images[_activeImageIndex.clamp(
                                          0, images.length - 1)],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: const Color(0xFFE2E8F0),
                                        child: const Center(
                                            child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: const Color(0xFFE2E8F0),
                                        child: const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 48, color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                  // Image Badge overlay
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Color(0x33000000),
                                              blurRadius: 6),
                                        ],
                                      ),
                                      child: Text(
                                        property.propertyType.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Row(
                                      children: [
                                        if (property.isVerified)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.95),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.verified_rounded,
                                                    color: AppColors.verified,
                                                    size: 14),
                                                SizedBox(width: 4),
                                                Text('Verified',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .verified)),
                                              ],
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: property.isAvailable
                                                ? const Color(0xFFECFDF5)
                                                : const Color(0xFFFEF2F2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: property.isAvailable
                                                      ? AppColors.verified
                                                      : AppColors.error,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                property.isAvailable
                                                    ? 'Available'
                                                    : 'Taken',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: property.isAvailable
                                                      ? AppColors.verified
                                                      : AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Thumbnails row if multiple images
                              if (images.length > 1)
                                Container(
                                  height: 70,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  color: Colors.white,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      final isSelected =
                                          idx == _activeImageIndex;
                                      return GestureDetector(
                                        onTap: () => setState(
                                            () => _activeImageIndex = idx),
                                        child: Container(
                                          width: 64,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: images[idx],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Main Details Container
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title and Rating
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            property.title,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: const Color(0xFFFDE68A)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded,
                                                  size: 18,
                                                  color: Color(0xFFD97706)),
                                              const SizedBox(width: 4),
                                              Text(
                                                property.rating
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF92400E)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Location text
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            color: Color(0xFF64748B), size: 18),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${property.location.address}, ${property.location.city}',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    // Price and Deposit Highlight Card
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFFC7D2FE)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Monthly Rent',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF4F46E5)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                Helpers.formatCurrency(
                                                    property.rent),
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF312E81),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                              width: 1,
                                              height: 40,
                                              color: const Color(0xFFC7D2FE)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Security Deposit',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                Helpers.formatCurrency(
                                                    property.deposit),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 22),

                                    // Room Specifications
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFE2E8F0)),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(Icons.bed_outlined,
                                                    color: AppColors.primary,
                                                    size: 24),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${property.availableRooms} of ${property.totalRooms} Rooms',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0F172A)),
                                                ),
                                                const Text('Available',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF64748B))),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFE2E8F0)),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .holiday_village_outlined,
                                                    color: AppColors.accent,
                                                    size: 24),
                                                const SizedBox(height: 6),
                                                Text(
                                                  Helpers.getPropertyTypeLabel(
                                                      property.propertyType),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0F172A)),
                                                ),
                                                const Text('Property Type',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF64748B))),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFE2E8F0)),
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                    Icons.rate_review_outlined,
                                                    color: Color(0xFFF59E0B),
                                                    size: 24),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${property.reviewCount} Reviews',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0F172A)),
                                                ),
                                                const Text('Verified',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF64748B))),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Description
                                    const Text(
                                      'About this Property',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      property.description,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF334155),
                                          height: 1.5),
                                    ),
                                    const SizedBox(height: 24),

                                    // Amenities Grid
                                    const Text(
                                      'Amenities & Facilities',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: property.amenities
                                          .map((a) => AmenityChip(label: a))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 24),

                                    // Location & Campus Proximity Card
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Location & Proximity',
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A)),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(
                                              Icons.explore_rounded,
                                              size: 16,
                                              color: AppColors.primary),
                                          label: const Text('Campus Map',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                  fontSize: 13)),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, '/property-map',
                                                arguments: property);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Visual Map Banner preview
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                  context, '/property-map',
                                                  arguments: property);
                                            },
                                            child: Container(
                                              height: 110,
                                              width: double.infinity,
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFFE0E7FF),
                                                    Color(0xFFC7D2FE),
                                                    Color(0xFFDDD6FE)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Stack(
                                                children: [
                                                  // Map grid lines design
                                                  Positioned.fill(
                                                    child: CustomPaint(
                                                      painter:
                                                          _MapGridPainter(),
                                                    ),
                                                  ),
                                                  // Center Pin
                                                  Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha: 0.8),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                            Helpers
                                                                .formatCurrency(
                                                                    property
                                                                        .rent),
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        const Icon(
                                                            Icons
                                                                .location_on_rounded,
                                                            color: AppColors
                                                                .primary,
                                                            size: 36),
                                                      ],
                                                    ),
                                                  ),
                                                  // Campus proximity badge
                                                  Positioned(
                                                    bottom: 8,
                                                    left: 10,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.95),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                              color: Color(
                                                                  0x1A000000),
                                                              blurRadius: 4),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: const [
                                                          Icon(
                                                              Icons
                                                                  .directions_walk_rounded,
                                                              color: Color(
                                                                  0xFF10B981),
                                                              size: 14),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            '3 mins walk to WCE Main Gate (250m)',
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Color(
                                                                    0xFF0F172A)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.9),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .open_in_full_rounded,
                                                              size: 12,
                                                              color: AppColors
                                                                  .primary),
                                                          SizedBox(width: 4),
                                                          Text('Tap to Explore',
                                                              style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: AppColors
                                                                      .primary)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .location_on_rounded,
                                                        color:
                                                            AppColors.primary,
                                                        size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            property.location
                                                                .address,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 14,
                                                                color: Color(
                                                                    0xFF0F172A)),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            '${property.location.city}, ${property.location.state}',
                                                            style: const TextStyle(
                                                                color: Color(
                                                                    0xFF64748B),
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),

                                                // Nearby landmarks chips
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 6,
                                                  children: const [
                                                    _NearbyChip(
                                                        icon:
                                                            Icons.train_rounded,
                                                        label:
                                                            'Vishrambag Stn: 450m',
                                                        color:
                                                            Color(0xFFE11D48)),
                                                    _NearbyChip(
                                                        icon: Icons
                                                            .local_library_rounded,
                                                        label:
                                                            'WCE Library: 250m',
                                                        color:
                                                            Color(0xFF0D9488)),
                                                    _NearbyChip(
                                                        icon: Icons
                                                            .restaurant_rounded,
                                                        label:
                                                            'Student Mess: 150m',
                                                        color:
                                                            Color(0xFFD97706)),
                                                  ],
                                                ),
                                                const SizedBox(height: 14),

                                                // Action Buttons
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          OutlinedButton.icon(
                                                        icon: const Icon(
                                                            Icons
                                                                .navigation_rounded,
                                                            size: 16),
                                                        label: const Text(
                                                            'Directions',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12)),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              const Color(
                                                                  0xFF1E293B),
                                                          side: const BorderSide(
                                                              color: Color(
                                                                  0xFFCBD5E1)),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 10),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                        onPressed: () =>
                                                            _launchDirections(
                                                                property),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child:
                                                          ElevatedButton.icon(
                                                        icon: const Icon(
                                                            Icons.map_rounded,
                                                            size: 16,
                                                            color:
                                                                Colors.white),
                                                        label: const Text(
                                                            'Campus Map',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white)),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              AppColors.primary,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 10),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.pushNamed(
                                                              context,
                                                              '/property-map',
                                                              arguments:
                                                                  property);
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Landlord Contact Card (locked until payment)
                                    const Text(
                                      'Landlord Information',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildLandlordContactCard(property),
                                    const SizedBox(height: 24),

                                    // Reviews Header & Action
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Student Reviews',
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, '/reviews',
                                                arguments: {
                                                  'propertyId': property.id,
                                                  'propertyTitle':
                                                      property.title,
                                                });
                                          },
                                          child: const Text('View All Reviews',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (err, _) => AppErrorWidget(message: err.toString()),
            ),
          ),
          if (propertyAsync.hasValue && propertyAsync.value != null)
            _buildDetailActionBar(propertyAsync.value!),
        ],
      ),
    );
  }
}

class _NearbyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NearbyChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final thinRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final parkPaint = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Draw little park green zone
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(15, 10, 80, 50),
        const Radius.circular(10),
      ),
      parkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 110, 45, 95, 55),
        const Radius.circular(10),
      ),
      parkPaint,
    );

    // Draw main roads
    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(size.width * 0.35, size.height * 0.6, size.width * 0.65,
          size.height * 0.75, size.width, size.height * 0.5);
    canvas.drawPath(path, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.45, 0)
      ..lineTo(size.width * 0.55, size.height);
    canvas.drawPath(path2, thinRoadPaint);

    final path3 = Path()
      ..moveTo(0, 30)
      ..lineTo(size.width * 0.45, 30);
    canvas.drawPath(path3, thinRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Helper widgets for the landlord contact card ────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ContactRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlurredContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BlurredContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              // Blurred placeholder bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFCBD5E1),
                        const Color(0xFFE2E8F0)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
