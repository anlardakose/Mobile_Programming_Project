import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapMarker {
  final double latitude;
  final double longitude;
  final String title;

  MapMarker({
    required this.latitude,
    required this.longitude,
    required this.title,
  });
}

class MapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final List<MapMarker> markers;
  final bool allowSelection;
  final Function(double, double)? onLocationSelected;

  const MapScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.markers = const [],
    this.allowSelection = false,
    this.onLocationSelected,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        if (_selectedLocation == null && widget.initialLatitude == null) {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        }
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  LatLng get _initialCameraPosition {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      return LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    // Varsayılan konum (Atatürk Üniversitesi yaklaşık koordinatları)
    return const LatLng(39.9033, 41.2542);
  }

  Set<Marker> get _markers {
    final Set<Marker> markers = {};

    // Widget'tan gelen marker'lar
    for (int i = 0; i < widget.markers.length; i++) {
      final marker = widget.markers[i];
      markers.add(
        Marker(
          markerId: MarkerId('marker_$i'),
          position: LatLng(marker.latitude, marker.longitude),
          infoWindow: InfoWindow(title: marker.title),
        ),
      );
    }

    // Seçilen konum marker'ı (eğer seçim modundaysa)
    if (widget.allowSelection && _selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
            widget.onLocationSelected?.call(
              newPosition.latitude,
              newPosition.longitude,
            );
          },
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialCameraPosition,
            zoom: 15,
          ),
          markers: _markers,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: widget.allowSelection
              ? (LatLng location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                  widget.onLocationSelected?.call(
                    location.latitude,
                    location.longitude,
                  );
                }
              : null,
        ),
        if (widget.allowSelection)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _selectedLocation != null
                  ? () {
                      widget.onLocationSelected?.call(
                        _selectedLocation!.latitude,
                        _selectedLocation!.longitude,
                      );
                      Navigator.of(context).pop({
                        'latitude': _selectedLocation!.latitude,
                        'longitude': _selectedLocation!.longitude,
                      });
                    }
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Select This Location'),
            ),
          ),
      ],
    );
  }
}

