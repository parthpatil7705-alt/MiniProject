import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/providers/user_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _roleFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['All', 'Student', 'Landlord'].map((role) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(role),
                  selected: _roleFilter == role,
                  onSelected: (_) => setState(() => _roleFilter = role),
                  selectedColor: AppColors.accent,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load users: $error'),
          ),
        ),
        data: (users) {
          final visibleUsers = users.where((user) {
            return _roleFilter == 'All' ||
                user.role.toLowerCase() == _roleFilter.toLowerCase();
          }).toList();

          if (visibleUsers.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleUsers.length,
            itemBuilder: (context, index) {
              final user = visibleUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? NetworkImage(user.photoUrl)
                        : null,
                    child:
                        user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user.name.isEmpty ? user.email : user.name),
                  subtitle: Text('${user.email}\n${user.role} • ${user.uid}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
