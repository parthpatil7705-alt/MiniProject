import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/models/enquiry_model.dart';
import 'package:room_buddy/providers/user_provider.dart';

// StreamProvider.family for student enquiries
final studentEnquiriesProvider = StreamProvider.family<List<EnquiryModel>, String>((ref, studentId) {
  return ref.watch(firestoreServiceProvider).getStudentEnquiries(studentId);
});

// StreamProvider.family for landlord enquiries
final landlordEnquiriesProvider = StreamProvider.family<List<EnquiryModel>, String>((ref, landlordId) {
  return ref.watch(firestoreServiceProvider).getLandlordEnquiries(landlordId);
});
