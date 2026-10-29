import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/widgets/property_card.dart';
import 'package:room_buddy/core/widgets/loading_widget.dart';

class AdminPropertiesScreen extends ConsumerStatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  ConsumerState<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends ConsumerState<AdminPropertiesScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(allPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Properties'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.rule),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/verification');
            },
            tooltip: 'Pending Verifications',
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['All', 'Verified', 'Unverified'].map((f) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (v) => setState(() => _filter = f),
                  selectedColor: AppColors.accent,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: propertiesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (properties) {
          final filtered = _filter == 'All'
              ? properties
              : properties.where((p) => p.isVerified == (_filter == 'Verified')).toList();

          if (filtered.isEmpty) return const Center(child: Text('No properties found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return PropertyCard(property: filtered[index]);
            },
          );
        },
      ),
    );
  }
}
