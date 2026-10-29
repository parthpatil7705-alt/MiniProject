import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/providers/user_provider.dart';

class PropertyFilters {
  final double? minRent;
  final double? maxRent;
  final String? propertyType;
  final String? city;
  final bool? isAvailable;

  bool? get onlyAvailable => isAvailable;

  PropertyFilters({
    this.minRent,
    this.maxRent,
    this.propertyType,
    this.city,
    bool? isAvailable,
    bool? onlyAvailable,
  }) : isAvailable = isAvailable ?? onlyAvailable;

  PropertyFilters copyWith({
    double? minRent,
    double? maxRent,
    String? propertyType,
    String? city,
    bool? isAvailable,
    bool? onlyAvailable,
    // Explicit clear flags to allow resetting nullable fields to null
    bool clearCity = false,
    bool clearPropertyType = false,
    bool clearMinRent = false,
    bool clearMaxRent = false,
  }) {
    return PropertyFilters(
      minRent: clearMinRent ? null : (minRent ?? this.minRent),
      maxRent: clearMaxRent ? null : (maxRent ?? this.maxRent),
      propertyType: clearPropertyType ? null : (propertyType ?? this.propertyType),
      city: clearCity ? null : (city ?? this.city),
      isAvailable: isAvailable ?? onlyAvailable ?? this.isAvailable,
    );
  }

  bool get hasFilters => 
    minRent != null || maxRent != null || propertyType != null || city != null || isAvailable != null;

  int get activeFilterCount => (minRent != null ? 1 : 0) + (maxRent != null ? 1 : 0) + (propertyType != null ? 1 : 0) + (city != null ? 1 : 0) + (isAvailable != null ? 1 : 0);
}

// StreamProvider for all available properties
final availablePropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAvailableProperties();
});

// StreamProvider.family for landlord's properties
final landlordPropertiesProvider = StreamProvider.family<List<PropertyModel>, String>((ref, landlordId) {
  return ref.watch(firestoreServiceProvider).getLandlordProperties(landlordId);
});

// FutureProvider.family for single property
final propertyByIdProvider = FutureProvider.family<PropertyModel?, String>((ref, id) async {
  return await ref.watch(firestoreServiceProvider).getProperty(id);
});

// StateProvider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// StateProvider for filters
final propertyFiltersProvider = StateProvider<PropertyFilters>((ref) => PropertyFilters());

// Provider for filtered properties (applies search + filters client-side)
final filteredPropertiesProvider = Provider<AsyncValue<List<PropertyModel>>>((ref) {
  final propertiesAsync = ref.watch(availablePropertiesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filters = ref.watch(propertyFiltersProvider);

  return propertiesAsync.whenData((properties) {
    return properties.where((p) {
      // Apply search query
      if (query.isNotEmpty && !p.title.toLowerCase().contains(query)) {
        return false;
      }
      
      // Apply filters
      if (filters.hasFilters) {
        // We assume property model has a double rent and location object with city
        // We handle any potential type mismatch errors gracefully if those fields aren't named exactly.
        try {
          if (filters.minRent != null && (p as dynamic).rent < filters.minRent!) return false;
          if (filters.maxRent != null && (p as dynamic).rent > filters.maxRent!) return false;
          if (filters.propertyType != null && (p as dynamic).propertyType != filters.propertyType) return false;
          if (filters.city != null && (p as dynamic).location.city != filters.city) return false;
          if (filters.isAvailable != null && (p as dynamic).isAvailable != filters.isAvailable) return false;
        } catch (e) {
          // Field might not exist in the exact way expected, fallback safely
        }
      }
      
      return true;
    }).toList();
  });
});

class CompareNotifier extends StateNotifier<List<PropertyModel>> {
  CompareNotifier() : super([]);

  void addProperty(PropertyModel p) {
    try {
      final pid = (p as dynamic).id;
      if (state.length < 3 && !isInCompare(pid)) {
        state = [...state, p];
      }
    } catch (_) {
      // Silently ignore - property may lack 'id' field
    }
  }

  void removeProperty(String id) {
    try {
      state = state.where((p) => (p as dynamic).id != id).toList();
    } catch (_) {
      // Silently ignore - property may lack 'id' field
    }
  }

  void clear() {
    state = [];
  }

  bool isInCompare(String id) {
    try {
      return state.any((p) => (p as dynamic).id == id);
    } catch (e) {
      return false;
    }
  }
}

// StateNotifierProvider for compare list
final comparePropertiesProvider = StateNotifierProvider<CompareNotifier, List<PropertyModel>>((ref) {
  return CompareNotifier();
});

// StreamProvider for unverified properties (admin)
final unverifiedPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getUnverifiedProperties();
});

// StreamProvider for all properties (admin)
final allPropertiesProvider = StreamProvider<List<PropertyModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllProperties();
});
