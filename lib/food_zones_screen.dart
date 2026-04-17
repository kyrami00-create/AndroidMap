import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FoodZonesScreen extends StatefulWidget {
  const FoodZonesScreen({super.key});

  @override
  State<FoodZonesScreen> createState() => _FoodZonesScreenState();
}

class _FoodZonesScreenState extends State<FoodZonesScreen> {
  String _selectedBuilding = 'Все корпуса';
  Position? _currentLocation;
  bool _isLoadingLocation = true;
  String _locationError = '';

  final List<String> _buildings = [
    'Все корпуса',
    'Главный корпус',
    'Корпус Б',
    'Корпус В',
    'Библиотека',
    'Спорткомплекс',
  ];

  final List<FoodZone> _allZones = [
    FoodZone(
      name: 'Фуд-корт "Академический"',
      building: 'Главный корпус',
      floor: '2 этаж',
      description: 'Большой выбор: бургеры, пицца, суши, кофе',
      placesCount: 8,
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      workingHours: '10:00 - 20:00',
      capacity: '150 мест',
      wifi: true,
      charging: true,
      latitude: 56.4695,
      longitude: 84.9475,
    ),
    FoodZone(
      name: 'Столовая "Уют"',
      building: 'Главный корпус',
      floor: '1 этаж',
      description: 'Комплексные обеды, супы, салаты, выпечка',
      placesCount: 4,
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400',
      workingHours: '8:00 - 17:00',
      capacity: '80 мест',
      wifi: true,
      charging: false,
      latitude: 56.4690,
      longitude: 84.9480,
    ),
    FoodZone(
      name: 'Кофейня "Bean & Leaf"',
      building: 'Корпус Б',
      floor: '1 этаж',
      description: 'Кофе, чай, десерты, сэндвичи',
      placesCount: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=400',
      workingHours: '9:00 - 19:00',
      capacity: '30 мест',
      wifi: true,
      charging: true,
      latitude: 56.4700,
      longitude: 84.9470,
    ),
    FoodZone(
      name: 'Зона питания "Библиотека"',
      building: 'Библиотека',
      floor: 'Цокольный этаж',
      description: 'Быстрый перекус, снеки, напитки',
      placesCount: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=400',
      workingHours: '9:00 - 18:00',
      capacity: '40 мест',
      wifi: true,
      charging: true,
      latitude: 56.4685,
      longitude: 84.9485,
    ),
    FoodZone(
      name: 'Спорт-бар',
      building: 'Спорткомплекс',
      floor: '1 этаж',
      description: 'Правильное питание для спортсменов, протеиновые коктейли',
      placesCount: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      workingHours: '10:00 - 21:00',
      capacity: '50 мест',
      wifi: false,
      charging: false,
      latitude: 56.4698,
      longitude: 84.9478,
    ),
    FoodZone(
      name: 'Буфет "Перерыв"',
      building: 'Корпус В',
      floor: '3 этаж',
      description: 'Чай, кофе, пирожки, бутерброды',
      placesCount: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400',
      workingHours: '9:00 - 16:00',
      capacity: '20 мест',
      wifi: true,
      charging: false,
      latitude: 56.4705,
      longitude: 84.9465,
    ),
    FoodZone(
      name: 'Точка питания "Студент"',
      building: 'Корпус Б',
      floor: '2 этаж',
      description: 'Недорогие обеды, комплексные меню',
      placesCount: 3,
      imageUrl:
          'https://images.unsplash.com/photo-1579113800032-c38bd7635818?w=400',
      workingHours: '10:00 - 18:00',
      capacity: '60 мест',
      wifi: true,
      charging: true,
      latitude: 56.4692,
      longitude: 84.9472,
    ),
  ];

  List<FoodZone> get _filteredZones {
    if (_selectedBuilding == 'Все корпуса') {
      return _allZones;
    }
    return _allZones
        .where((zone) => zone.building == _selectedBuilding)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Разрешение на геолокацию отклонено';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Разрешение на геолокацию заблокировано навсегда';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Ошибка получения местоположения: $e';
        _isLoadingLocation = false;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} м';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    }
  }

  String _getDistanceForZone(FoodZone zone) {
    if (_currentLocation == null) {
      return '? м';
    }

    double distance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      zone.latitude,
      zone.longitude,
    );

    return _formatDistance(distance);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0F2A),
      child: Column(
        children: [
          if (_isLoadingLocation)
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF1E2448),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Определение местоположения...',
                    style: TextStyle(color: Color(0xFFB0B0D0), fontSize: 12),
                  ),
                ],
              ),
            ),

          if (_locationError.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: _getCurrentLocation,
                    child: const Text(
                      'Повторить',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            height: 60,
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _buildings.length,
              itemBuilder: (context, index) {
                final building = _buildings[index];
                final isSelected = _selectedBuilding == building;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(building),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBuilding = building;
                      });
                    },
                    backgroundColor: const Color(0xFF1E2448),
                    selectedColor: const Color(0xFF7C4DFF),
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFFB0B0D0),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child:
                _filteredZones.isEmpty
                    ? const Center(
                      child: Text(
                        'Нет зон питания в этом корпусе',
                        style: TextStyle(
                          color: Color(0xFF9A9AB0),
                          fontSize: 16,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredZones.length,
                      itemBuilder: (context, index) {
                        final zone = _filteredZones[index];
                        return _buildZoneCard(zone);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(FoodZone zone) {
    String distance = _getDistanceForZone(zone);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF12163A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showZoneDetailDialog(zone, distance);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        zone.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: const Color(0xFF1E2448),
                            child: const Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Color(0xFF7C4DFF),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            height: 100,
                            color: const Color(0xFF1E2448),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF7C4DFF),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7C4DFF,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  zone.building,
                                  style: const TextStyle(
                                    color: Color(0xFFB47CFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Color(0xFF9A9AB0),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    zone.floor,
                                    style: const TextStyle(
                                      color: Color(0xFF9A9AB0),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              if (zone.wifi) ...[
                                const Icon(
                                  Icons.wifi,
                                  size: 16,
                                  color: Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (zone.charging) ...[
                                const Icon(
                                  Icons.power,
                                  size: 16,
                                  color: Color(0xFFFF9800),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2448),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${zone.placesCount} заведений',
                                  style: const TextStyle(
                                    color: Color(0xFFB0B0D0),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: Color(0xFF7C4DFF)),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  zone.description,
                  style: const TextStyle(
                    color: Color(0xFFB0B0D0),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF9A9AB0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      zone.workingHours,
                      style: const TextStyle(
                        color: Color(0xFF9A9AB0),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.people,
                      size: 14,
                      color: Color(0xFF9A9AB0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      zone.capacity,
                      style: const TextStyle(
                        color: Color(0xFF9A9AB0),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFF9A9AB0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: const TextStyle(
                        color: Color(0xFF9A9AB0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showZoneDetailDialog(FoodZone zone, String distance) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF12163A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                _buildDetailRow(Icons.business, 'Корпус', zone.building),
                _buildDetailRow(Icons.location_on, 'Этаж', zone.floor),
                _buildDetailRow(
                  Icons.access_time,
                  'Часы работы',
                  zone.workingHours,
                ),
                _buildDetailRow(Icons.people, 'Вместимость', zone.capacity),
                _buildDetailRow(
                  Icons.restaurant,
                  'Заведений',
                  '${zone.placesCount}',
                ),
                _buildDetailRow(Icons.location_on, 'Расстояние', distance),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        zone.description,
                        style: const TextStyle(color: Color(0xFFB0B0D0)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (zone.wifi) ...[
                            const Icon(
                              Icons.wifi,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Wi-Fi',
                              style: TextStyle(color: Color(0xFFB0B0D0)),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (zone.charging) ...[
                            const Icon(
                              Icons.power,
                              color: Color(0xFFFF9800),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Розетки',
                              style: TextStyle(color: Color(0xFFB0B0D0)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '📍 ${zone.name} находится в $distance от вас',
                              ),
                              backgroundColor: const Color(0xFF7C4DFF),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ПОКАЗАТЬ ИНФОРМАЦИЮ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2448),
                          foregroundColor: const Color(0xFF9A9AB0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ЗАКРЫТЬ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7C4DFF)),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFFB0B0D0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class FoodZone {
  final String name;
  final String building;
  final String floor;
  final String description;
  final int placesCount;
  final String imageUrl;
  final String workingHours;
  final String capacity;
  final bool wifi;
  final bool charging;
  final double latitude;
  final double longitude;

  FoodZone({
    required this.name,
    required this.building,
    required this.floor,
    required this.description,
    required this.placesCount,
    required this.imageUrl,
    required this.workingHours,
    required this.capacity,
    required this.wifi,
    required this.charging,
    required this.latitude,
    required this.longitude,
  });
}
