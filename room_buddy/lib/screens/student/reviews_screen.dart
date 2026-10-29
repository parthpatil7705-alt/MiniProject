import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/constants/app_text_styles.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/providers/review_provider.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/widgets/review_card.dart';
import 'package:room_buddy/widgets/rating_bar_widget.dart';
import 'package:room_buddy/models/review_model.dart';
import 'package:uuid/uuid.dart';

class ReviewsScreen extends ConsumerWidget {
  final String propertyId;
  final String propertyTitle;

  const ReviewsScreen({super.key, required this.propertyId, required this.propertyTitle});

  void _showAddReviewSheet(BuildContext context, WidgetRef ref) {
    double selectedRating = 5.0;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write a Review', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            Center(
              child: RatingBarWidget(
                rating: selectedRating,
                size: 40,
                onRatingChanged: (rating) => selectedRating = rating,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Share your experience (min 10 chars)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (textController.text.length < 10) {
                    Helpers.showSnackBar(context, 'Review must be at least 10 characters long');
                    return;
                  }
                  
                  final user = ref.read(currentUserProvider).value;
                  if (user != null) {
                    // ignore: unused_local_variable
                    final review = ReviewModel(
                      id: const Uuid().v4(),
                      propertyId: propertyId,
                      userId: user.id,
                      userName: user.name,
                      rating: selectedRating,
                      comment: textController.text,
                      createdAt: DateTime.now(),
                    );
                    
                    try {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      await firestoreService.addReview(review);
                      await firestoreService.updatePropertyRating(propertyId, selectedRating);
                      ref.invalidate(propertyReviewsProvider(propertyId));
                      ref.invalidate(hasReviewedProvider(propertyId));
                      if (context.mounted) {
                        Navigator.pop(context);
                        Helpers.showSnackBar(context, 'Review submitted successfully! 🌟');
                      }
                    } catch (e) {
                      if (context.mounted) Helpers.showSnackBar(context, e.toString());
                    }
                  }
                },
                child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(propertyReviewsProvider(propertyId));
    final hasReviewedAsync = ref.watch(hasReviewedProvider(propertyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(propertyTitle)),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                title: 'No Reviews',
                subtitle: 'No reviews yet. Be the first to review!',
                icon: Icons.star_border,
              ),
            );
          }
          
          final avgRating = reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;
          
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(avgRating.toStringAsFixed(1), style: AppTextStyles.h1),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBarWidget(rating: avgRating, size: 24),
                        const SizedBox(height: 4),
                        Text('Based on ${reviews.length} reviews', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ReviewCard(review: reviews[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: hasReviewedAsync.when(
        data: (hasReviewed) => hasReviewed ? null : FloatingActionButton.extended(
          onPressed: () => _showAddReviewSheet(context, ref),
          icon: const Icon(Icons.edit),
          label: const Text('Write a Review'),
          backgroundColor: AppColors.accent,
        ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}
