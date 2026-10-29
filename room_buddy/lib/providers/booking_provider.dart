import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/models/booking_model.dart';
import 'package:room_buddy/providers/user_provider.dart';

/// All bookings for the given student.
final studentBookingsProvider = StreamProvider.family<List<BookingModel>, String>(
  (ref, studentId) {
    final service = ref.watch(firestoreServiceProvider);
    return service.getStudentBookings(studentId);
  },
);

/// All booking requests received by a landlord.
final landlordBookingsProvider = StreamProvider.family<List<BookingModel>, String>(
  (ref, landlordId) {
    final service = ref.watch(firestoreServiceProvider);
    return service.getLandlordBookings(landlordId);
  },
);
