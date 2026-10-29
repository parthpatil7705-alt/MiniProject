import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/core/widgets/custom_button.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/models/user_model.dart';
import 'package:room_buddy/providers/auth_provider.dart';
import 'package:room_buddy/providers/user_provider.dart';
import 'package:room_buddy/providers/property_provider.dart';
import 'package:room_buddy/screens/landlord/landlord_ratings_screen.dart';
import 'package:room_buddy/screens/landlord/landlord_verification_screen.dart';

class LandlordProfileScreen extends ConsumerStatefulWidget {
  const LandlordProfileScreen({super.key});

  @override
  ConsumerState<LandlordProfileScreen> createState() => _LandlordProfileScreenState();
}

class _LandlordProfileScreenState extends ConsumerState<LandlordProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _companyController = TextEditingController();
    _addressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _companyController.text = user.companyName.isNotEmpty ? user.companyName : user.college;
        _addressController.text = user.address;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final updated = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        companyName: _companyController.text.trim(),
        address: _addressController.text.trim(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateUser(user.uid, updated.toMap());
      ref.invalidate(currentUserProvider);

      setState(() => _isEditing = false);
      if (mounted) Helpers.showSnackBar(context, 'Profile updated successfully!');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error updating profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value ??
        const UserModel(
          uid: 'user_landlord',
          email: 'landlord@roombuddy.com',
          name: 'Robert Smith',
          role: 'Landlord',
          phone: '+1 555-0144',
          companyName: 'Smith Housing Co.',
          address: '100 University Ave, City Center',
        );
    final properties = ref.watch(landlordPropertiesProvider(user.id)).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Landlord Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login_rounded, color: Color(0xFF64748B)),
            tooltip: 'Go to Login Page',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_outlined, color: const Color(0xFF4F46E5)),
            tooltip: _isEditing ? 'Cancel Editing' : 'Edit Profile',
            onPressed: () {
              if (!_isEditing) {
                _nameController.text = user.name;
                _phoneController.text = user.phone;
                _companyController.text = user.companyName.isNotEmpty ? user.companyName : user.college;
                _addressController.text = user.address;
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero Landlord Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2A1E1B4B),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with Verified Ring
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
                                      : 'LL',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.companyName.isNotEmpty
                              ? user.companyName
                              : (user.college.isNotEmpty ? user.college : 'Independent Property Manager'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC7D2FE),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Badge Pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LandlordVerificationScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF6EE7B7)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified Host',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LandlordRatingsScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                                    SizedBox(width: 4),
                                    Text(
                                      '4.9 Rating',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.apartment_rounded,
                          color: const Color(0xFF4F46E5),
                          bg: const Color(0xFFEEF2FF),
                          count: properties.length.toString(),
                          label: 'Listings',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.bolt_rounded,
                          color: const Color(0xFF10B981),
                          bg: const Color(0xFFD1FAE5),
                          count: '98%',
                          label: 'Response',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.timer_outlined,
                          color: const Color(0xFFF59E0B),
                          bg: const Color(0xFFFEF3C7),
                          count: '< 1 hr',
                          label: 'Avg Speed',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Details Form / Display
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Landlord Profile',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v!.trim().isEmpty ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _companyController,
                              decoration: InputDecoration(
                                labelText: 'Company or Agency Name',
                                prefixIcon: const Icon(Icons.business_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Office / Business Address',
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: 'Save Changes',
                              isLoading: _isLoading,
                              onPressed: _updateProfile,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Profile Info & Settings Section
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F172A),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact & Business Information',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(Icons.email_outlined, 'Email Address', user.email),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildDetailRow(
                            Icons.phone_outlined,
                            'Phone Number',
                            user.phone.isNotEmpty ? user.phone : 'Not provided yet',
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildDetailRow(
                            Icons.business_outlined,
                            'Company / Agency',
                            user.companyName.isNotEmpty
                                ? user.companyName
                                : (user.college.isNotEmpty ? user.college : 'Independent Host'),
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildDetailRow(
                            Icons.pin_drop_outlined,
                            'Business Address',
                            user.address.isNotEmpty ? user.address : 'City Center, University Area',
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Quick Action Menu Tiles
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.shield_outlined,
                          title: 'Verification & Trust Documents',
                          subtitle: 'Verified Identity, Title Deeds & Safety Status',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LandlordVerificationScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                        _buildMenuTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Payout Accounts & Invoices',
                          subtitle: 'Direct deposit into verified bank account',
                          onTap: () {
                            Helpers.showSnackBar(context, 'Payout account configured.');
                          },
                        ),
                        const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                        _buildMenuTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notification Settings',
                          subtitle: 'Instant SMS & Email alerts for student enquiries',
                          onTap: () {
                            Helpers.showSnackBar(context, 'Notifications are enabled.');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out of your Landlord account?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: const Color(0xFFFEF2F2),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required Color bg,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
