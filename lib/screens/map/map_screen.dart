import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../notification/notification_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool allowSelection;

  const MapScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.allowSelection = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Position? _currentPosition;
  NotificationModel? _selectedNotification;

  @override
  void initState() {
    super.initState();
    
    // Varsayılan konumu hemen ayarla
    _selectedLocation = const LatLng(39.9033, 41.2542); // Atatürk Üniversitesi
    
    // Eğer initial konum varsa onu kullan
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    }
    
    // Konum almayı dene (arka planda)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
    
    // Bildirimleri yükle (eğer seçim modu değilse)
    if (!widget.allowSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotificationProvider>().loadNotifications();
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // İzin reddedildi, varsayılan konumu kullan
          if (mounted) {
            _setDefaultLocation();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // İzin kalıcı olarak reddedildi, varsayılan konumu kullan
        if (mounted) {
          _setDefaultLocation();
        }
        return;
      }

      if (!mounted) return;

      // Konum almayı dene
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Timeout oldu, varsayılan konumu kullan
          if (mounted) {
            _setDefaultLocation();
          }
          throw TimeoutException('Location timeout');
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
        if (_selectedLocation == null && widget.initialLatitude == null) {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        }
      });

      // Güncel konum alındı ama kamerayı hareket ettirme
      // Sadece marker göster, harita Atatürk Üniversitesi'nde kalsın
      // Kullanıcı isterse "My Location" butonuna basabilir
    } catch (e) {
      // Hata durumunda varsayılan konumu kullan
      if (mounted) {
        _setDefaultLocation();
      }
    }
  }

  void _setDefaultLocation() {
    if (!mounted) return;
    
    // Varsayılan konum: Atatürk Üniversitesi
    const defaultLat = 39.9033;
    const defaultLng = 41.2542;
    
    setState(() {
      if (_selectedLocation == null && widget.initialLatitude == null) {
        _selectedLocation = const LatLng(defaultLat, defaultLng);
      }
    });

    // Harita kontrolü varsa kamerayı hareket ettir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            const LatLng(defaultLat, defaultLng),
            15,
          ),
        );
      }
    });
  }

  LatLng get _initialCameraPosition {
    // İlk açılışta her zaman Atatürk Üniversitesi'ne odaklan
    // Güncel konum alınırsa sadece marker gösterilir, kamerayı hareket ettirme
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      return LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    // Varsayılan konum (Atatürk Üniversitesi yaklaşık koordinatları)
    return const LatLng(39.9033, 41.2542);
  }

  // Bildirim türüne göre pin rengi
  BitmapDescriptor _getMarkerColor(NotificationType type) {
    switch (type) {
      case NotificationType.health:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case NotificationType.safety:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case NotificationType.environment:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case NotificationType.lostFound:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case NotificationType.technical:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  // Bildirim türüne göre ikon
  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.health:
        return Icons.medical_services;
      case NotificationType.safety:
        return Icons.security;
      case NotificationType.environment:
        return Icons.eco;
      case NotificationType.lostFound:
        return Icons.search;
      case NotificationType.technical:
        return Icons.build;
    }
  }

  // Bildirim türüne göre renk
  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.health:
        return Colors.red;
      case NotificationType.safety:
        return Colors.orange;
      case NotificationType.environment:
        return Colors.green;
      case NotificationType.lostFound:
        return Colors.blue;
      case NotificationType.technical:
        return Colors.purple;
    }
  }

  // Ne kadar önce oluşturulduğunu hesapla
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  Set<Marker> _buildMarkers(List<NotificationModel> notifications) {
    final Set<Marker> markers = {};

    // Eğer seçim modundaysa, sadece seçilen konumu göster
    if (widget.allowSelection) {
      final location = _selectedLocation ?? _initialCameraPosition;
      markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          draggable: true,
          onDragEnd: (newPosition) {
            if (!mounted) return;
            setState(() {
              _selectedLocation = newPosition;
            });
          },
        ),
      );
      return markers;
    }

    // Güncel konumu marker olarak ekle (mavi nokta)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Güncel Konumum',
            snippet: 'Şu anki konumunuz',
          ),
        ),
      );
    }

    // Bildirimleri marker olarak ekle
    for (final notification in notifications) {
      markers.add(
        Marker(
          markerId: MarkerId(notification.id),
          position: LatLng(notification.latitude, notification.longitude),
          icon: _getMarkerColor(notification.type),
          onTap: () {
            if (!mounted) return;
            setState(() {
              _selectedNotification = notification;
            });
          },
        ),
      );
    }

    return markers;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final notifications = widget.allowSelection ? [] : provider.notifications;
        
        return Stack(
          children: [
            // Harita
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCameraPosition,
                zoom: 15,
              ),
              markers: _buildMarkers(notifications.cast<NotificationModel>()),
              myLocationButtonEnabled: true,
              myLocationEnabled: _currentPosition != null,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (controller) {
                _mapController = controller;
                // Harita oluşturulduktan sonra kamerayı Atatürk Üniversitesi'ne odakla
                // Güncel konum alınırsa sadece marker gösterilir, kamerayı hareket ettirme
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _mapController != null) {
                    // İlk açılışta her zaman Atatürk Üniversitesi'ne odaklan
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        const LatLng(39.9033, 41.2542), // Atatürk Üniversitesi
                        15,
                      ),
                    );
                  }
                });
              },
              onTap: (LatLng location) {
                if (!mounted) return;
                
                if (widget.allowSelection) {
                  setState(() {
                    _selectedLocation = location;
                  });
                } else {
                  // Haritaya tıklandığında bilgi kartını kapat
                  setState(() {
                    _selectedNotification = null;
                  });
                }
              },
            ),
            
            // Seçim modu için konum seç butonu
            if (widget.allowSelection)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: _selectedLocation != null
                      ? () {
                          if (!mounted) return;
                          Navigator.of(context).pop({
                            'latitude': _selectedLocation!.latitude,
                            'longitude': _selectedLocation!.longitude,
                          });
                        }
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Bu Konumu Seç'),
                ),
              ),
            
            // Bildirim bilgi kartı (seçim modu değilse)
            if (!widget.allowSelection && _selectedNotification != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildInfoCard(_selectedNotification!),
              ),
            
            // Harita açıklaması (legend)
            if (!widget.allowSelection)
              Positioned(
                top: 16,
                left: 16,
                child: _buildLegend(),
              ),
          ],
        );
      },
    );
  }

  // Pin bilgi kartı
  Widget _buildInfoCard(NotificationModel notification) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve tür
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.typeDisplayName,
                        style: TextStyle(
                          color: _getTypeColor(notification.type),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Kapat butonu
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedNotification = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Zaman bilgisi
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getTimeAgo(notification.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Detayı Gör butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationDetailScreen(
                        notificationId: notification.id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getTypeColor(notification.type),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Detayı Gör'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Harita açıklama kartı (legend)
  Widget _buildLegend() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bildirim Türleri',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(NotificationType.health, 'Sağlık'),
            _buildLegendItem(NotificationType.safety, 'Güvenlik'),
            _buildLegendItem(NotificationType.environment, 'Çevre'),
            _buildLegendItem(NotificationType.lostFound, 'Kayıp-Buluntu'),
            _buildLegendItem(NotificationType.technical, 'Teknik'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(NotificationType type, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getTypeColor(type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
