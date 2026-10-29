import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:room_buddy/core/utils/helpers.dart';
import 'package:room_buddy/models/property_model.dart';
import 'package:room_buddy/providers/property_provider.dart';

enum MapTileType {
  streets,
  satellite,
}

class PropertyMapScreen extends ConsumerStatefulWidget {
  final PropertyModel? property;
  final bool isSinglePropertyView;

  const PropertyMapScreen({
    super.key,
    this.property,
    this.isSinglePropertyView = false,
  });

  @override
  ConsumerState<PropertyMapScreen> createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends ConsumerState<PropertyMapScreen> {
  late PropertyModel? _selectedProperty;
  String _selectedCategory = 'All';
  MapTileType _currentMapType = MapTileType.streets;
  final MapController _mapController = MapController();

  // Walchand College of Engineering (WCE), Sangli center coordinates
  static const LatLng _wceCenter = LatLng(16.8457, 74.6017);

  final List<String> _categories = ['All', 'Apartment', 'PG', 'Flat', 'Hostel'];

  // Actual GPS coordinates for Walchand Campus landmarks
  final List<Map<String, dynamic>> _walchandLandmarks = [
    {
      'name': 'WCE Main Gate',
      'subtitle': 'Vishrambag Main Road',
      'type': 'Campus Gate',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF4F46E5),
      'latLng': const LatLng(16.8448, 74.6022),
    },
    {
      'name': 'Ajit Gulabchand Library',
      'subtitle': 'Central Technical Library',
      'type': 'Library',
      'icon': Icons.local_library_rounded,
      'color': const Color(0xFF0D9488),
      'latLng': const LatLng(16.8455, 74.6010),
    },
    {
      'name': 'Vishrambag Railway Stn',
      'subtitle': 'Central Transit',
      'type': 'Transit',
      'icon': Icons.train_rounded,
      'color': const Color(0xFFE11D48),
      'latLng': const LatLng(16.8492, 74.6075),
    },
    {
      'name': 'WCE Student Mess & Canteen',
      'subtitle': 'Near Quadrangle',
      'type': 'Food',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFD97706),
      'latLng': const LatLng(16.8440, 74.6030),
    },
    {
      'name': 'Wanless Hospital',
      'subtitle': 'Health Clinic',
      'type': 'Health',
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFF059669),
      'latLng': const LatLng(16.8530, 74.6120),
    },
    {
      'name': 'Saraswati Bhavan',
      'subtitle': 'WCE Heritage Admin',
      'type': 'Academic',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF7C3AED),
      'latLng': const LatLng(16.8452, 74.6015),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.property;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.property != null) {
        final lat = widget.property!.location.latitude != 0.0
            ? widget.property!.location.latitude
            : _wceCenter.latitude;
        final lng = widget.property!.location.longitude != 0.0
            ? widget.property!.location.longitude
            : _wceCenter.longitude;
        _mapController.move(LatLng(lat, lng), 16.5);
      }
    });
  }

  // Real navigation launcher in Google Maps
  Future<void> _launchDirections(PropertyModel property) async {
    final lat = property.location.latitude != 0.0
        ? property.location.latitude
        : _wceCenter.latitude;
    final lng = property.location.longitude != 0.0
        ? property.location.longitude
        : _wceCenter.longitude;
    final address = Uri.encodeComponent(
        '${property.location.address}, ${property.location.city}');

    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$address');
    final fallbackUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening location: ${property.location.address}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Open Walchand College in Google Maps
  Future<void> _openWalchandInGoogleMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=Walchand+College+of+Engineering+Sangli');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Walking distance to WCE Main Gate
  String _getWalkingDistance(PropertyModel property) {
    switch (property.id) {
      case 'prop_1':
        return '250m • 3 min walk to WCE Gate';
      case 'prop_2':
        return '450m • 6 min walk to WCE Gate';
      case 'prop_3':
        return '200m • 2 min walk to WCE Gate';
      case 'prop_4':
        return '350m • 4 min walk to WCE Gate';
      case 'prop_5':
        return '600m • 8 min walk to WCE Gate';
      case 'prop_6':
        return '900m • 11 min walk to WCE Gate';
      case 'prop_7':
        return '850m • 10 min walk to WCE Gate';
      case 'prop_8':
        return '1.2 km • 15 min walk to WCE Gate';
      case 'prop_9':
        return '1.0 km • 12 min walk to WCE Gate';
      default:
        return '500m • 6 min walk to WCE Gate';
    }
  }

  String _getTileUrl() {
    switch (_currentMapType) {
      case MapTileType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTileType.streets:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(allPropertiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSinglePropertyView && widget.property != null
                  ? 'Walchand Campus Area & Location'
                  : 'Walchand Campus Live Map Explorer',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Text(
              'Real geographic area • Walchand College (WCE Sangli)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.my_location_rounded, color: Color(0xFF4F46E5)),
            tooltip: 'Recenter on WCE Main Gate',
            onPressed: () {
              _mapController.move(_wceCenter, 16.2);
            },
          ),
          IconButton(
            icon:
                const Icon(Icons.open_in_new_rounded, color: Color(0xFF4F46E5)),
            tooltip: 'Open in Google Maps',
            onPressed: _openWalchandInGoogleMaps,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: propertiesAsync.when(
        data: (properties) {
          final displayProperties =
              widget.isSinglePropertyView && widget.property != null
                  ? [widget.property!]
                  : (_selectedCategory == 'All'
                      ? properties
                      : properties
                          .where((p) =>
                              p.propertyType.toLowerCase() ==
                              _selectedCategory.toLowerCase())
                          .toList());

          // Marker list from actual coordinates
          final markers = <Marker>[
            // 1. Walchand Campus Landmarks
            ..._walchandLandmarks.map((lm) {
              final latLng = lm['latLng'] as LatLng;
              final color = lm['color'] as Color;
              final icon = lm['icon'] as IconData;
              final name = lm['name'] as String;

              return Marker(
                point: latLng,
                width: 140,
                height: 70,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1F000000), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // 2. Accommodation Property Markers
            ...displayProperties.map((prop) {
              final lat = prop.location.latitude != 0.0
                  ? prop.location.latitude
                  : _wceCenter.latitude;
              final lng = prop.location.longitude != 0.0
                  ? prop.location.longitude
                  : _wceCenter.longitude;
              final isSelected = _selectedProperty?.id == prop.id;

              return Marker(
                point: LatLng(lat, lng),
                width: 110,
                height: 52,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProperty = prop;
                    });
                    _mapController.move(
                        LatLng(lat, lng), _mapController.camera.zoom);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF312E81)
                                : const Color(0xFFCBD5E1),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0x554F46E5)
                                  : const Color(0x26000000),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home_work_rounded,
                              size: 13,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Helpers.formatCurrency(prop.rent),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: const Size(10, 6),
                        painter: _MapPinArrowPainter(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ];

          return Stack(
            children: [
              // 1. REAL GEOGRAPHIC MAP TILES
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.property != null
                      ? LatLng(
                          widget.property!.location.latitude != 0.0
                              ? widget.property!.location.latitude
                              : _wceCenter.latitude,
                          widget.property!.location.longitude != 0.0
                              ? widget.property!.location.longitude
                              : _wceCenter.longitude,
                        )
                      : _wceCenter,
                  initialZoom: 16.0,
                  minZoom: 13.0,
                  maxZoom: 18.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  // Real Street / Satellite Tile Layer
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    userAgentPackageName: 'com.roombuddy.sangli.wce',
                    maxZoom: 19,
                  ),

                  // Walchand Campus Circle Indicator
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _wceCenter,
                        radius: 140,
                        useRadiusInMeter: true,
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                        borderColor: const Color(0xFF4F46E5),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                  // Real GPS Markers
                  MarkerLayer(markers: markers),
                ],
              ),

              // 2. CATEGORY PILLS BAR (when not in single property mode)
              if (!widget.isSinglePropertyView)
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                _selectedCategory = cat;
                                _selectedProperty = null;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF4F46E5),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            elevation: 3,
                            shadowColor: const Color(0x26000000),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // 2.5 FLOATING MAP STYLE TOGGLE PILL
              Positioned(
                top: widget.isSinglePropertyView ? 14 : 64,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MapStyleChip(
                        title: 'Street Map',
                        icon: Icons.map_outlined,
                        isSelected: _currentMapType == MapTileType.streets,
                        onTap: () => setState(
                            () => _currentMapType = MapTileType.streets),
                      ),
                      const SizedBox(width: 4),
                      _MapStyleChip(
                        title: 'Satellite',
                        icon: Icons.satellite_alt_rounded,
                        isSelected: _currentMapType == MapTileType.satellite,
                        onTap: () => setState(
                            () => _currentMapType = MapTileType.satellite),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. ZOOM CONTROLS & COMPASS
              Positioned(
                right: 16,
                top: 70,
                child: Column(
                  children: [
                    _MapActionButton(
                      icon: Icons.add,
                      tooltip: 'Zoom In',
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          (_mapController.camera.zoom + 0.8).clamp(13.0, 18.5),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _MapActionButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom Out',
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          (_mapController.camera.zoom - 0.8).clamp(13.0, 18.5),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _MapActionButton(
                      icon: Icons.navigation_rounded,
                      tooltip: 'WCE Sangli Center',
                      onPressed: () {
                        _mapController.move(_wceCenter, 16.2);
                      },
                    ),
                  ],
                ),
              ),

              // 4. MAP TYPE CHIP BADGE
              Positioned(
                left: 16,
                bottom: _selectedProperty != null ? 220 : 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _currentMapType == MapTileType.satellite
                            ? 'Walchand Campus Satellite'
                            : 'Walchand Campus (WCE Sangli)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. SELECTED PROPERTY BOTTOM CARD
              if (_selectedProperty != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _PropertyBottomCard(
                    property: _selectedProperty!,
                    walkingDistance: _getWalkingDistance(_selectedProperty!),
                    onClose: () => setState(() => _selectedProperty = null),
                    onDirections: () => _launchDirections(_selectedProperty!),
                    onViewDetails: () {
                      Navigator.pushNamed(
                        context,
                        '/property-detail',
                        arguments: _selectedProperty!,
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading Walchand Campus Area Map...',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        error: (err, _) => Center(child: Text('Error loading map data: $err')),
      ),
    );
  }
}

class _MapStyleChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapStyleChip({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0x28000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1E293B), size: 18),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}

class _MapPinArrowPainter extends CustomPainter {
  final Color color;
  _MapPinArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PropertyBottomCard extends StatelessWidget {
  final PropertyModel property;
  final String walkingDistance;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback onViewDetails;

  const _PropertyBottomCard({
    required this.property,
    required this.walkingDistance,
    required this.onClose,
    required this.onDirections,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shadowColor: const Color(0x3D0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: CachedNetworkImage(
                      imageUrl: property.images.isNotEmpty
                          ? property.images.first
                          : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400',
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: const Color(0xFFE2E8F0)),
                      errorWidget: (context, url, err) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(Icons.home, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              property.propertyType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (property.isVerified)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded,
                                    size: 12, color: Color(0xFF10B981)),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          const Spacer(),
                          InkWell(
                            onTap: onClose,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.directions_walk_rounded,
                              size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              walkingDistance,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            Helpers.formatCurrency(property.rent),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const Text(
                            ' / month',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const Spacer(),
                          const Icon(Icons.star_rounded,
                              size: 15, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            property.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.navigation_rounded, size: 14),
                    label: const Text('Directions',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
