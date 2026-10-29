import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/error_widget.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:room_buddy/models/enquiry_model.dart';
import 'package:room_buddy/models/booking_model.dart';
import 'package:room_buddy/providers/enquiry_provider.dart';
import 'package:room_buddy/providers/booking_provider.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/widgets/enquiry_card.dart';

class LandlordEnquiriesScreen extends ConsumerStatefulWidget {
  const LandlordEnquiriesScreen({super.key});

  @override
  ConsumerState<LandlordEnquiriesScreen> createState() => _LandlordEnquiriesScreenState();
}

class _LandlordEnquiriesScreenState extends ConsumerState<LandlordEnquiriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _filter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final userId = user?.id ?? 'user_landlord';
    final userName = user?.name ?? 'Robert Smith';

    final enquiriesAsync = ref.watch(landlordEnquiriesProvider(userId));
    final bookingsAsync = ref.watch(landlordBookingsProvider(userId));

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
              'Enquiries & Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Manage student inquiries and room reservations',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Enquiries'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Bookings'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Enquiries Tab
          enquiriesAsync.when(
            loading: () => const Center(child: LoadingWidget()),
            error: (e, s) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(landlordEnquiriesProvider(userId)),
            ),
            data: (enquiries) {
              final totalCount = enquiries.length;
              final pendingCount = enquiries.where((e) => e.status.toLowerCase() == 'pending').length;
              final respondedCount = enquiries.where((e) => e.status.toLowerCase() == 'responded').length;
              final closedCount = enquiries.where((e) => e.status.toLowerCase() == 'closed').length;

              var list = _filter == 'All'
                  ? enquiries
                  : enquiries.where((e) => e.status.toLowerCase() == _filter.toLowerCase()).toList();

              if (_searchQuery.trim().isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                list = list.where((e) {
                  return e.studentName.toLowerCase().contains(query) ||
                      e.propertyTitle.toLowerCase().contains(query) ||
                      e.message.toLowerCase().contains(query);
                }).toList();
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(landlordEnquiriesProvider(userId)),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                    // Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by student name, property or message...',
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

                    // Filter Pill Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', totalCount, const Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pending', pendingCount, const Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          _buildFilterChip('Responded', respondedCount, const Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          _buildFilterChip('Closed', closedCount, const Color(0xFF64748B)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (list.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 40),
                        child: EmptyStateWidget(
                          icon: Icons.mark_email_unread_outlined,
                          title: _searchQuery.isNotEmpty ? 'No Matching Enquiries' : 'No Enquiries Found',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try searching with different keywords.'
                              : 'You do not have any ${_filter == 'All' ? '' : _filter.toLowerCase()} enquiries at this time.',
                        ),
                      )
                    else
                      ...list.map((enquiry) {
                        return EnquiryCard(
                          key: ValueKey(enquiry.id),
                          enquiry: enquiry,
                          isLandlord: true,
                          onRespond: (replyMessage) async {
                            final firestoreService = ref.read(firestoreServiceProvider);
                            final newResponse = EnquiryResponse(
                              senderId: userId,
                              senderName: userName,
                              message: replyMessage,
                              timestamp: DateTime.now(),
                            );
                            await firestoreService.respondToEnquiry(enquiry.id, newResponse);
                            ref.invalidate(landlordEnquiriesProvider(userId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reply sent successfully!'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          onUpdateStatus: (newStatus) async {
                            final firestoreService = ref.read(firestoreServiceProvider);
                            await firestoreService.updateEnquiryStatus(enquiry.id, newStatus);
                            ref.invalidate(landlordEnquiriesProvider(userId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Enquiry status updated to $newStatus'),
                                  backgroundColor: const Color(0xFF4F46E5),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),

          // â”€â”€ Bookings Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          bookingsAsync.when(
            loading: () => const Center(child: LoadingWidget()),
            error: (e, s) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(landlordBookingsProvider(userId)),
            ),
            data: (bookings) {
              if (bookings.isEmpty) {
                return const Center(
                  child: EmptyStateWidget(
                    icon: Icons.bookmark_border_rounded,
                    title: 'No Booking Requests Yet',
                    subtitle: 'Room reservation requests from students will appear here.',
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(landlordBookingsProvider(userId)),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _BookingRequestCard(
                          booking: bookings[index],
                          onConfirm: () async {
                            await ref.read(firestoreServiceProvider).updateBookingStatus(
                                  bookings[index].id,
                                  'confirmed',
                                  note: 'Your room has been confirmed! Please contact the landlord to proceed.',
                                );
                            ref.invalidate(landlordBookingsProvider(userId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking confirmed! Room reserved.'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                      onReject: () async {
                        await ref.read(firestoreServiceProvider).updateBookingStatus(
                              bookings[index].id,
                              'rejected',
                              note: 'Sorry, the room is no longer available.',
                            );
                        ref.invalidate(landlordBookingsProvider(userId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking rejected.'),
                              backgroundColor: Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, Color activeColor) {
    final isSelected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Booking Request Card
class _BookingRequestCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const _BookingRequestCard({
    required this.booking,
    required this.onConfirm,
    required this.onReject,
  });

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed': return const Color(0xFF10B981);
      case 'rejected': return const Color(0xFFEF4444);
      case 'cancelled': return const Color(0xFF94A3B8);
      default: return const Color(0xFFF59E0B);
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case 'confirmed': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      case 'cancelled': return Icons.remove_circle_rounded;
      default: return Icons.hourglass_top_rounded;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case 'confirmed': return 'Confirmed';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default: return 'Pending Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == 'pending';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: _statusColor.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _statusLabel,
                  style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  booking.createdAt != null
                      ? '${booking.createdAt!.day}/${booking.createdAt!.month}/${booking.createdAt!.year}'
                      : 'Today',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        booking.studentName.isNotEmpty ? booking.studentName[0] : 'S',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
                          Text(booking.studentEmail,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                // Property info
                Row(
                  children: [
                    const Icon(Icons.home_rounded, color: Color(0xFF64748B), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.propertyTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'â‚¹${booking.rent.toStringAsFixed(0)}/month',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                if (booking.landlordNote != null && booking.landlordNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      booking.landlordNote!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                if (isPending) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: onReject,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                          label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: onConfirm,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
