import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/constants/app_colors.dart';
import 'package:room_buddy/core/widgets/custom_button.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/models/roommate_preference_model.dart';
import 'package:room_buddy/providers/roommate_provider.dart';
import 'package:room_buddy/providers/user_provider.dart';

class RoommatePreferencesScreen extends ConsumerStatefulWidget {
  const RoommatePreferencesScreen({super.key});

  @override
  ConsumerState<RoommatePreferencesScreen> createState() => _RoommatePreferencesScreenState();
}

class _RoommatePreferencesScreenState extends ConsumerState<RoommatePreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _minBudgetController;
  late TextEditingController _maxBudgetController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;

  String _sleepSchedule = 'Early Bird';
  String _cleanliness = 'Neat';
  bool _smoking = false;
  String _foodPreference = 'Any';
  String _studyHabits = 'Quiet';
  String _guestPolicy = 'Occasional';
  List<String> _selectedInterests = [];
  bool _isLoading = false;

  final List<String> _availableInterests = [
    'Sports', 'Music', 'Reading', 'Gaming', 'Cooking', 'Fitness', 'Movies', 'Travel', 'Photography', 'Art'
  ];

  @override
  void initState() {
    super.initState();
    _minBudgetController = TextEditingController();
    _maxBudgetController = TextEditingController();
    _locationController = TextEditingController();
    _bioController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final existingPref = ref.read(roommatePreferenceProvider(user.id)).value;
        if (existingPref != null) {
          setState(() {
            _minBudgetController.text = existingPref.minBudget.toString();
            _maxBudgetController.text = existingPref.maxBudget.toString();
            _locationController.text = existingPref.preferredLocation;
            _bioController.text = existingPref.bio;
            _sleepSchedule = existingPref.sleepSchedule;
            _cleanliness = existingPref.cleanliness;
            _smoking = existingPref.smoking.toLowerCase() == 'yes';
            _foodPreference = existingPref.foodPreference;
            _studyHabits = existingPref.studyHabits;
            _guestPolicy = existingPref.guestPolicy;
            _selectedInterests = List.from(existingPref.interests);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception("User not logged in");

      final pref = RoommatePreferenceModel(
        userId: user.id,
        userName: user.name,
        college: user.college,
        minBudget: double.tryParse(_minBudgetController.text) ?? 0.0,
        maxBudget: double.tryParse(_maxBudgetController.text) ?? 0.0,
        preferredLocation: _locationController.text,
        sleepSchedule: _sleepSchedule,
        cleanliness: _cleanliness,
        smoking: _smoking ? 'yes' : 'no',
        foodPreference: _foodPreference,
        studyHabits: _studyHabits,
        guestPolicy: _guestPolicy,
        interests: _selectedInterests,
        bio: _bioController.text,
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateRoommatePreference(pref);
      
      ref.invalidate(roommatePreferenceProvider(user.id));
      ref.invalidate(compatibleRoommatesProvider);

      if (mounted) {
        Helpers.showSnackBar(context, 'Preferences saved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error saving preferences: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roommate Preferences'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minBudgetController,
                      decoration: const InputDecoration(labelText: 'Min Budget (₹)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxBudgetController,
                      decoration: const InputDecoration(labelText: 'Max Budget (₹)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Preferred Location'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sleepSchedule,
                decoration: const InputDecoration(labelText: 'Sleep Schedule'),
                items: ['Early Bird', 'Night Owl', 'Flexible'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _sleepSchedule = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _cleanliness,
                decoration: const InputDecoration(labelText: 'Cleanliness'),
                items: ['Neat', 'Average', 'Messy'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _cleanliness = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Smoking Allowed?'),
                value: _smoking,
                onChanged: (v) => setState(() => _smoking = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _foodPreference,
                decoration: const InputDecoration(labelText: 'Food Preference'),
                items: ['Veg', 'Non-Veg', 'Any'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _foodPreference = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _studyHabits,
                decoration: const InputDecoration(labelText: 'Study Habits'),
                items: ['Quiet', 'Music allowed', 'Group Study'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _studyHabits = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _guestPolicy,
                decoration: const InputDecoration(labelText: 'Guest Policy'),
                items: ['Strict (No guests)', 'Occasional', 'Flexible'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _guestPolicy = v!),
              ),
              const SizedBox(height: 24),
              const Text('Interests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                    selectedColor: AppColors.accent.withValues(alpha: 0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Save Preferences',
                onPressed: _savePreferences,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
