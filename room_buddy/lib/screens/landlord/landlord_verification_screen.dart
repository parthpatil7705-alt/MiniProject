import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/providers/user_provider.dart';

class LandlordVerificationScreen extends StatefulWidget {
  const LandlordVerificationScreen({super.key});

  @override
  State<LandlordVerificationScreen> createState() => _LandlordVerificationScreenState();
}

class _LandlordVerificationScreenState extends State<LandlordVerificationScreen> {
  String _selectedDocType = 'Ownership Deed';
  String? _uploadedFileName;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _verificationSteps = [
    {
      'title': 'Government ID Verification',
      'subtitle': 'Verified via National Passport / Driver\'s License',
      'status': 'Verified',
      'icon': Icons.badge_outlined,
      'date': 'Approved on Nov 12, 2025',
      'isComplete': true,
    },
    {
      'title': 'Property Ownership & Lease Titles',
      'subtitle': 'Registered Title Deeds for campus rental units',
      'status': 'Verified',
      'icon': Icons.description_outlined,
      'date': 'Approved on Jan 08, 2026',
      'isComplete': true,
    },
    {
      'title': 'Campus Proximity & Utility Bill',
      'subtitle': 'Electricity, Water & High-speed Fiber Bill proof',
      'status': 'Verified',
      'icon': Icons.receipt_long_outlined,
      'date': 'Approved on Feb 14, 2026',
      'isComplete': true,
    },
    {
      'title': 'Student Safety & Biometric Compliance',
      'subtitle': '24/7 emergency contact & physical access review',
      'status': 'Verified',
      'icon': Icons.security_outlined,
      'date': 'Approved on Mar 01, 2026',
      'isComplete': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(currentUserProvider).value;

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
                  'Host Verification & Trust',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Verified Landlord Badge & Student Safety Credentials',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // HERO TRUST BADGE BANNER
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x28065F46),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6EE7B7), width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.verified_user_rounded, size: 36, color: Color(0xFF6EE7B7)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '100% VERIFIED HOST',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF6EE7B7)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host ID: ${user?.uid ?? 'user_landlord'} • ${user?.name ?? 'Robert Smith'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFA7F3D0), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Trust Score', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11)),
                              Text('98 / 100', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Student Inquiries', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11)),
                              Text('3.2x Higher', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ACTIVE VERIFICATION CREDENTIALS
              const Text(
                'Active Verification Documents',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Documents validated and authenticated by RoomBuddy Trust & Safety team',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),

              ..._verificationSteps.map((step) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(step['icon'] as IconData, size: 22, color: const Color(0xFF059669)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    step['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['subtitle'] as String,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step['date'] as String,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // SUBMIT ADDITIONAL DOCUMENTS
              Container(
                padding: const EdgeInsets.all(20),
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
                    const Row(
                      children: [
                        Icon(Icons.upload_file_rounded, color: Color(0xFF4F46E5), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Submit New Property Certificate',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Have a new property or updated municipal fire/safety certificate? Upload it here for instant review.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedDocType,
                      decoration: InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: [
                        'Ownership Deed',
                        'Municipal Fire Safety NOC',
                        'University Authorization Letter',
                        'CCTV / Security Proof',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDocType = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // File upload drop box
                    InkWell(
                      onTap: () async {
                        setState(() => _isUploading = true);
                        await Future.delayed(const Duration(milliseconds: 600));
                        setState(() {
                          _uploadedFileName = 'Document_${DateTime.now().millisecondsSinceEpoch % 10000}.pdf';
                          _isUploading = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _uploadedFileName != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  Icon(
                                    _uploadedFileName != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                                    size: 32,
                                    color: _uploadedFileName != null ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _uploadedFileName != null
                                        ? 'File Selected: $_uploadedFileName'
                                        : 'Click to select PDF or image document',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _uploadedFileName != null ? const Color(0xFF059669) : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Max file size: 10MB (PDF, JPG, PNG)',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: _uploadedFileName == null
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Document submitted! Review will complete within 24 hours.'),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              setState(() => _uploadedFileName = null);
                            },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Submit for Review', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // TRUST GUARANTEE ACCORDION
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 30, color: Color(0xFF4F46E5)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RoomBuddy Verified Host Guarantee',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF312E81)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Verified landlords receive premium search placement, a prominent green trust badge, and direct university portal priority.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF4338CA)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
