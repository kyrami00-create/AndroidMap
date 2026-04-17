import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FoodSelectionScreen extends StatefulWidget {
  const FoodSelectionScreen({super.key});

  @override
  State<FoodSelectionScreen> createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  String _selectedCategory = 'Все';
  Position? _currentLocation;
  bool _isLoadingLocation = true;
  String _locationError = '';

  final List<String> _categories = [
    'Все',
    '🍽️ Столовые',
    '☕ Кафе',
    '🍔 Бургерные',
    '🥗 Здоровое питание',
  ];

  final List<FoodPlace> _allPlaces = [
    FoodPlace(
      name: 'Студенческая столовая №1',
      description: 'Горячие обеды, супы, гарниры, выпечка',
      priceRange: '💰💰',
      rating: 4.2,
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      category: '🍽️ Столовые',
      workingHours: '8:00 - 18:00',
      latitude: 56.4695,
      longitude: 84.9475,
    ),
    FoodPlace(
      name: 'Coffee Like',
      description: 'Кофе, десерты, сэндвичи, вафли',
      priceRange: '💰💰💰',
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
      category: '☕ Кафе',
      workingHours: '9:00 - 20:00',
      latitude: 56.4690,
      longitude: 84.9480,
    ),
    FoodPlace(
      name: 'Burger House',
      description: 'Сочные бургеры, картошка фри, наггетсы',
      priceRange: '💰💰💰',
      rating: 4.5,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      category: '🍔 Бургерные',
      workingHours: '10:00 - 22:00',
      latitude: 56.4700,
      longitude: 84.9470,
    ),
    FoodPlace(
      name: 'Здоровая еда',
      description: 'Салаты, боулы, смузи, веган меню',
      priceRange: '💰💰💰',
      rating: 4.4,
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      category: '🥗 Здоровое питание',
      workingHours: '10:00 - 19:00',
      latitude: 56.4685,
      longitude: 84.9485,
    ),
    FoodPlace(
      name: 'Блинная "У мамы"',
      description: 'Блины с разными начинками, чай, компот',
      priceRange: '💰',
      rating: 4.6,
      imageUrl:
          'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
      category: '🍽️ Столовые',
      workingHours: '9:00 - 17:00',
      latitude: 56.4698,
      longitude: 84.9478,
    ),
    FoodPlace(
      name: 'Pizza Day',
      description: 'Пицца, паста, салаты, лимонады',
      priceRange: '💰💰💰',
      rating: 4.3,
      imageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      category: '☕ Кафе',
      workingHours: '11:00 - 23:00',
      latitude: 56.4705,
      longitude: 84.9465,
    ),
  ];

  List<FoodPlace> get _filteredPlaces {
    if (_selectedCategory == 'Все') {
      return _allPlaces;
    }
    return _allPlaces
        .where((place) => place.category == _selectedCategory)
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

  String _getDistanceForPlace(FoodPlace place) {
    if (_currentLocation == null) {
      return '? м';
    }

    double distance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      place.latitude,
      place.longitude,
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
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
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
                _filteredPlaces.isEmpty
                    ? const Center(
                      child: Text(
                        'Нет заведений в этой категории',
                        style: TextStyle(
                          color: Color(0xFF9A9AB0),
                          fontSize: 16,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPlaces.length,
                      itemBuilder: (context, index) {
                        final place = _filteredPlaces[index];
                        return _buildFoodCard(place);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(FoodPlace place) {
    String distance = _getDistanceForPlace(place);

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
            _showDetailDialog(place, distance);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    place.imageUrl,
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
                        place.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Color(0xFFF9A826),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.rating.toString(),
                                style: const TextStyle(
                                  color: Color(0xFFF9A826),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            place.priceRange,
                            style: const TextStyle(
                              color: Color(0xFF7C4DFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFF9A9AB0),
                              ),
                              const SizedBox(width: 2),
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
                      const SizedBox(height: 8),

                      Text(
                        place.description,
                        style: const TextStyle(
                          color: Color(0xFFB0B0D0),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF9A9AB0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.workingHours,
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

                const Icon(Icons.chevron_right, color: Color(0xFF7C4DFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(FoodPlace place, String distance) {
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
                  place.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                _buildDetailRow(Icons.star, 'Рейтинг', '${place.rating} / 5.0'),
                _buildDetailRow(
                  Icons.attach_money,
                  'Ценовая категория',
                  place.priceRange,
                ),
                _buildDetailRow(
                  Icons.access_time,
                  'Часы работы',
                  place.workingHours,
                ),
                _buildDetailRow(Icons.location_on, 'Расстояние', distance),
                _buildDetailRow(Icons.category, 'Тип', place.category),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    place.description,
                    style: const TextStyle(color: Color(0xFFB0B0D0)),
                    textAlign: TextAlign.center,
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
                                '📍 ${place.name} находится в $distance от вас',
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

class FoodPlace {
  final String name;
  final String description;
  final String priceRange;
  final double rating;
  final String imageUrl;
  final String category;
  final String workingHours;
  final double latitude;
  final double longitude;

  FoodPlace({
    required this.name,
    required this.description,
    required this.priceRange,
    required this.rating,
    required this.imageUrl,
    required this.category,
    required this.workingHours,
    required this.latitude,
    required this.longitude,
  });
}
