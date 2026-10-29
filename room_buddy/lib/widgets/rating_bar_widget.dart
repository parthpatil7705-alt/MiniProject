import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:room_buddy/core/constants/app_colors.dart';

class RatingBarWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Function(double)? onRatingChanged;

  const RatingBarWidget({
    super.key,
    required this.rating,
    this.size = 20,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (onRatingChanged == null) {
      return RatingBarIndicator(
        rating: rating,
        itemBuilder: (context, index) => const Icon(
          Icons.star,
          color: AppColors.star,
        ),
        itemCount: 5,
        itemSize: size,
        direction: Axis.horizontal,
      );
    }

    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: size,
      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: AppColors.star,
      ),
      onRatingUpdate: onRatingChanged!,
    );
  }
}
