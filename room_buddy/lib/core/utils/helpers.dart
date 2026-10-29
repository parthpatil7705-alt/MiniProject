import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String getTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 365) return '${(difference.inDays / 365).floor()}y ago';
    if (difference.inDays > 30) return '${(difference.inDays / 30).floor()}mo ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  static String timeAgo(DateTime? date) => getTimeAgo(date);

  static IconData getPropertyTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
      case 'flat':
        return Icons.apartment;
      case 'hostel':
        return Icons.business;
      case 'pg':
        return Icons.house_siding;
      case 'house':
        return Icons.home;
      default:
        return Icons.location_city;
    }
  }

  static String getPropertyTypeLabel(String type) {
    if (type.isEmpty) return 'Unknown';
    if (type.toLowerCase() == 'pg') return 'PG';
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
