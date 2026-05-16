import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../services/permission_service.dart';

/// ============================================================================
/// [NavigationTab] — Điều hướng & Bản đồ (Full-screen)
/// ============================================================================
class NavigationTab extends StatefulWidget {
  const NavigationTab({super.key});

  @override
  State<NavigationTab> createState() => _NavigationTabState();
}

class _NavigationTabState extends State<NavigationTab> {
  bool _hasLocationPermission = false;

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
  }
  // Vị trí mặc định (Ví dụ: Trung tâm Hà Nội hoặc TP.HCM)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(21.028511, 105.804817), // Hà Nội
    zoom: 15.0,
  );

  GoogleMapController? _mapController;

  Future<void> _launchGoogleMaps() async {
    const lat = 21.028511;
    const lng = 105.804817;
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // REAL GOOGLE MAP FULL SCREEN
        GoogleMap(
          initialCameraPosition: _initialPosition,
          mapType: MapType.normal,
          myLocationEnabled: _hasLocationPermission, // Hiển thị vị trí hiện tại nếu có quyền

          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: {
            const Marker(
              markerId: MarkerId('wheelchair_current_location'),
              position: LatLng(21.028511, 105.804817),
              infoWindow: InfoWindow(title: 'Vị trí xe lăn hiện tại'),
            ),
          },
        ),

        // TOP SAFE AREA OVERLAY - TRẠNG THÁI KẾT NỐI
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.canvasWhite.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.pureBlack.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.statusOnline, 
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Đang theo dõi vị trí xe lăn', style: AppTheme.labelBold),
                ],
              ),
            ),
          ),
        ),

        // FAB: TÌM ĐƯỜNG ĐI (GÓC DƯỚI PHẢI)
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút My Location
              FloatingActionButton.small(
                heroTag: 'myLocationBtn',
                backgroundColor: AppTheme.canvasWhite,
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(_initialPosition),
                  );
                },
                child: const Icon(Icons.my_location_rounded, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              // Nút Tìm đường
              FloatingActionButton.extended(
                heroTag: 'routeBtn',
                backgroundColor: AppTheme.primaryBlue,
                icon: const Icon(Icons.directions_rounded, color: AppTheme.canvasWhite),
                label: Text('Tìm đường', style: AppTheme.labelBold.copyWith(color: AppTheme.canvasWhite)),
                onPressed: _launchGoogleMaps,
              ),
            ],
          ),
        ),

        // BOTTOM INFO (GÓC DƯỚI TRÁI)
        Positioned(
          left: 16,
          bottom: 16,
          right: 160, // Chừa khoảng trống cho FAB
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.canvasWhite.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pureBlack.withValues(alpha: 0.1),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Xe lăn thông minh', style: AppTheme.caption),
                const SizedBox(height: 4),
                Text('Đại Cồ Việt, Hai Bà Trưng', style: AppTheme.labelBold, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
