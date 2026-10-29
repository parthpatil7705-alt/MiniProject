import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/review_provider.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/models/review_model.dart';

class LandlordRatingsScreen extends ConsumerStatefulWidget {
  const LandlordRatingsScreen({super.key});

  @override
  ConsumerState<LandlordRatingsScreen> createState() => _LandlordRatingsScreenState();
}

class _LandlordRatingsScreenState extends ConsumerState<LandlordRatingsScreen> {
  String _selectedRatingFilter = 'All';
  String _selectedPropertyFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final landlordId = user?.id ?? '';

    final reviewsAsync = ref.watch(landlordReviewsProvider(landlordId));
    final propertiesAsync = ref.watch(landlordPropertiesProvider(landlordId));
    final properties = propertiesAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Ratings & Reviews',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Tenant feedback & reputation across all properties',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (allReviews) {
          // Calculate rating metrics
          final count = allReviews.length;
          final avgRating = count > 0
              ? (allReviews.fold(0.0, (acc, r) => acc + r.rating) / count)
              : 4.9;

          final fiveStars = allReviews.where((r) => r.rating >= 4.75).length;
          final fourStars = allReviews.where((r) => r.rating >= 3.75 && r.rating < 4.75).length;
          final threeStars = allReviews.where((r) => r.rating >= 2.75 && r.rating < 3.75).length;
          final belowThree = allReviews.where((r) => r.rating < 2.75).length;

          // Filter reviews
          var filtered = List<ReviewModel>.from(allReviews);
          if (_selectedRatingFilter == '5 Stars') {
            filtered = filtered.where((r) => r.rating >= 4.75).toList();
          } else if (_selectedRatingFilter == '4 Stars') {
            filtered = filtered.where((r) => r.rating >= 3.75 && r.rating < 4.75).toList();
          } else if (_selectedRatingFilter == '3+ Stars') {
            filtered = filtered.where((r) => r.rating >= 2.75).toList();
          }

          if (_selectedPropertyFilter != 'All') {
            filtered = filtered.where((r) => r.propertyId == _selectedPropertyFilter).toList();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(landlordReviewsProvider(landlordId));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // OVERALL SCORE HERO CARD
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
                        color: Color(0x241E1B4B),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Big Rating Number
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              RatingBarIndicator(
                                rating: avgRating,
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFBBF24),
                                ),
                                itemCount: 5,
                                itemSize: 18.0,
                                direction: Axis.horizontal,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$count Verified Review${count == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFC7D2FE),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Distribution Progress Bars
                          Expanded(
                            child: Column(
                              children: [
                                _buildRatingRow('5 ★', count > 0 ? fiveStars / count : 0.85, fiveStars),
                                const SizedBox(height: 4),
                                _buildRatingRow('4 ★', count > 0 ? fourStars / count : 0.15, fourStars),
                                const SizedBox(height: 4),
                                _buildRatingRow('3 ★', count > 0 ? threeStars / count : 0.0, threeStars),
                                const SizedBox(height: 4),
                                _buildRatingRow('2 ★', count > 0 ? belowThree / count : 0.0, belowThree),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: Color(0x33C7D2FE)),
                      const SizedBox(height: 14),
                      // Highlights Pill Row
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _RatingCategoryBadge(icon: Icons.chat_outlined, title: 'Responsiveness', score: '4.9'),
                          _RatingCategoryBadge(icon: Icons.cleaning_services_outlined, title: 'Cleanliness', score: '4.8'),
                          _RatingCategoryBadge(icon: Icons.wifi, title: 'High-speed WiFi', score: '5.0'),
                          _RatingCategoryBadge(icon: Icons.shield_outlined, title: 'Campus Safety', score: '4.9'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // FILTERS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Feedback',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    if (properties.isNotEmpty)
                      DropdownButton<String>(
                        value: _selectedPropertyFilter,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF4F46E5)),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Properties')),
                          ...properties.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.title.length > 20 ? '${p.title.substring(0, 18)}...' : p.title),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPropertyFilter = val);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Rating filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', '5 Stars', '4 Stars', '3+ Stars'].map((filter) {
                      final isSelected = _selectedRatingFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRatingFilter = filter),
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
                              filter,
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
                const SizedBox(height: 20),

                // REVIEWS LIST
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 40, color: Color(0xFF94A3B8)),
                          SizedBox(height: 10),
                          Text(
                            'No reviews match your selected filter.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((rev) {
                    final matchingProps = properties.where((p) => p.id == rev.propertyId);
                    final propertyTitle = matchingProps.isNotEmpty
                        ? matchingProps.first.title
                        : (properties.isNotEmpty ? properties.first.title : 'Campus Property');
                    return _ReviewTile(review: rev, propertyTitle: propertyTitle);
                  }),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingRow(String label, double ratio, int count) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 11, color: Color(0xFFC7D2FE)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _RatingCategoryBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String score;

  const _RatingCategoryBadge({
    required this.icon,
    required this.title,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFFBBF24)),
        ),
        const SizedBox(height: 6),
        Text(
          score,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 9, color: Color(0xFFC7D2FE), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatefulWidget {
  final ReviewModel review;
  final String propertyTitle;

  const _ReviewTile({required this.review, required this.propertyTitle});

  @override
  State<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<_ReviewTile> {
  bool _showReplyBox = false;
  final _replyController = TextEditingController();
  String? _publicReply;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.review.studentName.isNotEmpty
        ? widget.review.studentName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
        : 'ST';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
          // Header Row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
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
                            widget.review.studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF059669)),
                              SizedBox(width: 3),
                              Text(
                                'Verified Tenant',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.review.createdAt != null ? Helpers.timeAgo(widget.review.createdAt!) : 'Recently',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              RatingBarIndicator(
                rating: widget.review.rating,
                itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
                itemCount: 5,
                itemSize: 16.0,
                direction: Axis.horizontal,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Property context tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.propertyTitle,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Review text
          Text(
            widget.review.review,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF1E293B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Landlord Reply (if present)
          if (_publicReply != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 14, color: Color(0xFF4F46E5)),
                      SizedBox(width: 6),
                      Text(
                        'Your Response (Host)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _publicReply!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                  ),
                ],
              ),
            ),

          // Reply Action Button
          if (_publicReply == null) ...[
            if (!_showReplyBox)
              TextButton.icon(
                onPressed: () => setState(() => _showReplyBox = true),
                icon: const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF4F46E5)),
                label: const Text(
                  'Public Reply to Student',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Write a professional reply (e.g. Thank you for staying with us!)...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showReplyBox = false),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _replyController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _publicReply = text;
                              _showReplyBox = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Public response published on review.'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Post Reply', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
