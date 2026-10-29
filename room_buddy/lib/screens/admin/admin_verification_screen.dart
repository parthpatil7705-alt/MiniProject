import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';
import 'package:room_buddy/core/widgets/empty_state_widget.dart';
import 'package:room_buddy/providers/property_provider.dart';

class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unverifiedAsync = ref.watch(unverifiedPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Verification'),
        backgroundColor: AppColors.primary,
      ),
      body: unverifiedAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (properties) {
          if (properties.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.check_circle_outline,
              title: 'All caught up!',
              subtitle: 'No properties pending verification',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final prop = properties[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prop.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Type: ${prop.propertyType.toUpperCase()}'),
                      Text('Rent: ₹${prop.rent}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Delete/Reject property logic
                            },
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Approve property logic
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                            child: const Text('Approve'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
