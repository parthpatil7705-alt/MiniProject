import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/error_widget.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:room_buddy/core/widgets/custom_button.dart';
import 'package:room_buddy/models/roommate_preference_model.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/roommate_provider.dart';
import 'package:room_buddy/widgets/roommate_card.dart';
import 'package:room_buddy/screens/student/roommate_detail_screen.dart';
import 'package:room_buddy/screens/student/roommate_preferences_screen.dart';

class RoommateDiscoveryScreen extends ConsumerWidget {
  const RoommateDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final userId = currentUser?.id ?? '';
    final preferencesAsync = ref.watch(roommatePreferenceProvider(userId));
    final compatibleAsync = ref.watch(compatibleRoommatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Roommates'),
        backgroundColor: AppColors.primary,
      ),
      body: preferencesAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, stack) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(roommatePreferenceProvider(userId)),
        ),
        data: (preference) {
          if (preference == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_search, size: 80, color: AppColors.accent),
                    const SizedBox(height: 16),
                    const Text(
                      'Set Your Preferences',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tell us what you are looking for in a roommate to see compatible matches.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Set Preferences',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RoommatePreferencesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return compatibleAsync.when(
            loading: () => const LoadingWidget(),
            error: (err, stack) => AppErrorWidget(
              message: err.toString(),
              onRetry: () => ref.invalidate(compatibleRoommatesProvider),
            ),
            data: (roommates) {
              if (roommates.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.group_off,
                  title: 'No matches found',
                  subtitle: 'No compatible roommates found. Try updating your preferences.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(compatibleRoommatesProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: roommates.length,
                  itemBuilder: (context, index) {
                    final match = roommates[index];
                    final pref = match['preference'] as RoommatePreferenceModel;
                    final score = match['score'] as int;
                    return RoommateCard(
                      preference: pref,
                      score: score,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoommateDetailScreen(
                              preference: pref,
                              score: score,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
