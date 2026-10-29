import 'package:flutter/material.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/constants/app_text_styles.dart';
import 'package:room_buddy/models/roommate_preference_model.dart';
import 'package:room_buddy/widgets/amenity_chip.dart';

class RoommateDetailScreen extends StatelessWidget {
  final RoommatePreferenceModel preference;
  final int score;

  const RoommateDetailScreen({
    super.key,
    required this.preference,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Roommate Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(preference.userName.isNotEmpty ? preference.userName : 'Unknown User', style: AppTextStyles.h2),
            Text(preference.college.isNotEmpty ? preference.college : 'Unknown College', style: AppTextStyles.bodyText),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Column(
                children: [
                  Text('$score%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text('Compatibility Score', style: AppTextStyles.subtitle),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (preference.bio.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Bio', style: AppTextStyles.h3),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(preference.bio),
              ),
              const SizedBox(height: 24),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Preferences', style: AppTextStyles.h3),
            ),
            const SizedBox(height: 16),
            _buildPreferenceRow('Sleep Schedule', preference.sleepSchedule),
            _buildPreferenceRow('Cleanliness', preference.cleanliness),
            _buildPreferenceRow('Smoking', preference.smoking),
            _buildPreferenceRow('Food', preference.foodPreference),
            _buildPreferenceRow('Study Habits', preference.studyHabits),
            _buildPreferenceRow('Guest Policy', preference.guestPolicy),
            _buildPreferenceRow('Budget Range', '₹${preference.budgetMin.toInt()} - ₹${preference.budgetMax.toInt()}'),
            _buildPreferenceRow('Location', preference.preferredLocation),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Interests', style: AppTextStyles.h3),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preference.interests.map((interest) => AmenityChip(label: interest)).toList(),
            ),
            const SizedBox(height: 40),
            const Text(
              'This information helps you find compatible roommates',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value.isNotEmpty ? value : 'Not specified'),
        ],
      ),
    );
  }
}
