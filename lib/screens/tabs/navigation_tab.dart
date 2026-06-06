import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../services/permission_service.dart';
import '../../providers/wheelchair_provider.dart';

/// ============================================================================
/// [NavigationTab] — Bản đồ (Full-screen)
/// ============================================================================
class NavigationTab extends StatefulWidget {
  const NavigationTab({super.key});

  @override
  State<NavigationTab> createState() => _NavigationTabState();
}

class _NavigationTabState extends State<NavigationTab> {
  bool _hasLocationPermission = false;
  LatLng _userLocation = const LatLng(10.8506293, 106.7631626);
  GoogleMapController? _mapController;

  String _currentAddress = 'Đang tải vị trí...';
  double? _lastProcessedLat;
  double? _lastProcessedLng;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPerm = await PermissionService.requestLocationPermission();
    if (mounted) {
      setState(() {
        _hasLocationPermission = hasPerm;
      });
    }
    if (hasPerm) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('[NavigationTab] Lỗi lấy vị trí hiện tại: $e');
    }
  }

  Future<void> _launchGoogleMaps(double destLat, double destLng) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')),
        );
      }
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    if (_lastProcessedLat == lat && _lastProcessedLng == lng) return;

    _lastProcessedLat = lat;
    _lastProcessedLng = lng;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SmartWheelchairApp/1.0',
          'Accept-Language': 'vi-VN,vi;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        if (address != null) {
          final components =
              [
                    address['suburb'] ??
                        address['quarter'] ??
                        address['neighbourhood'],
                    address['city_district'] ??
                        address['county'] ??
                        address['town'] ??
                        address['city'],
                    address['state'] ?? address['province'] ?? address['city'],
                  ]
                  .where((c) => c != null && c.toString().isNotEmpty)
                  .map((c) => c.toString())
                  .toSet()
                  .toList();

          final addressStr = components.isNotEmpty
              ? components.join(', ')
              : (data['display_name'] ??
                    'Tọa độ: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}');

          if (mounted) {
            setState(() {
              _currentAddress = addressStr;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _currentAddress =
              'Tọa độ: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      debugPrint('[NavigationTab] Lỗi geocoding Nominatim: $e');
      if (mounted) {
        setState(() {
          _currentAddress =
              'Tọa độ: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WheelchairProvider>(
      builder: (context, provider, _) {
        final wheelchairLat = provider.sensorData?.latitude ?? 10.8506293;
        final wheelchairLng = provider.sensorData?.longitude ?? 106.7631626;
        final wheelchairLatLng = LatLng(wheelchairLat, wheelchairLng);

        _updateAddress(wheelchairLat, wheelchairLng);

        return Stack(
          children: [
            // REAL GOOGLE MAP FULL SCREEN
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: wheelchairLatLng,
                zoom: 15.0,
              ),
              mapType: MapType.normal,
              myLocationEnabled:
                  _hasLocationPermission, // Hiển thị vị trí hiện tại nếu có quyền
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('wheelchair_current_location'),
                  position: wheelchairLatLng,
                  infoWindow: const InfoWindow(title: 'Vị trí xe lăn hiện tại'),
                ),
              },
            ),

            // TOP SAFE AREA OVERLAY - TRẠNG THÁI KẾT NỐI
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: AppTheme.liquidGlass(
                  borderRadius: AppTheme.radiusPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: provider.isConnected
                                ? AppTheme.statusOnline
                                : AppTheme.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isConnected
                              ? 'Đang theo dõi vị trí xe lăn'
                              : 'Chưa kết nối xe lăn',
                          style: AppTheme.labelBold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // FAB: TÌM ĐƯỜNG ĐI (GÓC DƯỚI PHẢI)
            Positioned(
              right: 16,
              bottom: 120, // Nâng lên để không đè vào BottomNavigationBar
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Nút My Location
                  AppTheme.liquidGlass(
                    borderRadius: AppTheme.radiusPill,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _getCurrentLocation();
                          _mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(target: _userLocation, zoom: 15.0),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: AppTheme.tealSignal,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nút Tìm đường
                  AppTheme.liquidGlass(
                    borderRadius: AppTheme.radiusPill,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _launchGoogleMaps(wheelchairLat, wheelchairLng),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_rounded,
                                color: AppTheme.tealSignal,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tìm đường',
                                style: AppTheme.labelBold.copyWith(
                                  color: AppTheme.tealSignal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BOTTOM INFO (GÓC DƯỚI TRÁI)
            Positioned(
              left: 16,
              bottom: 120, // Nâng lên cùng hàng với nút
              right:
                  180, // Tăng khoảng trống để không bị dính vào cụm nút Tìm Đường
              child: AppTheme.liquidGlass(
                borderRadius: AppTheme.radiusLg,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Vị trí của xe lăn', style: AppTheme.caption),
                      const SizedBox(height: 4),
                      Text(
                        _currentAddress,
                        style: AppTheme.labelBold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
