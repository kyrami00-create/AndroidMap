import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'screens/evaluation_and_food_purcashe_road.dart';
import 'screens/search_coworking.dart';
import 'screens/eating_zones.dart';
import 'data/cafe_data.dart';
import 'algorithms/astar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Navigator',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6200EA),
        scaffoldBackgroundColor: const Color(0xFF0A0F2A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFFB47CFF),
          surface: Color(0xFF12163A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F142E),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const CampusNavigationScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// ГЛАВНАЯ НАВИГАЦИЯ
// ─────────────────────────────────────────────

class CampusNavigationScreen extends StatefulWidget {
  const CampusNavigationScreen({super.key});

  @override
  State<CampusNavigationScreen> createState() => _CampusNavigationScreenState();
}

class _CampusNavigationScreenState extends State<CampusNavigationScreen> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(title: 'Навигация по кампусу', icon: Icons.map),
    NavigationItem(title: 'Зоны питания', icon: Icons.food_bank),
    NavigationItem(title: 'Покупка еды и оценка заведения', icon: Icons.star_rate),
    NavigationItem(title: 'Поиск места для учёбы', icon: Icons.search),
  ];

  final List<Widget> _screens = [
    NavigationMapScreen(),
    EatingZones(),
    EvaluationAndFoodPurcasheRoad(),
    SearchCoworking(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_currentIndex].title),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildScrollableBottomNavBar(),
    );
  }

  Widget _buildScrollableBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F142E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildNavBarItem(
                  icon: item.icon,
                  title: item.title,
                  isSelected: isSelected,
                  onTap: () => setState(() => _currentIndex = index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C4DFF).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFB47CFF) : const Color(0xFF6A6A8B),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFFB47CFF) : const Color(0xFF9A9AB0),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  const NavigationItem({required this.title, required this.icon});
}

class NavigationMapScreen extends StatefulWidget {
  const NavigationMapScreen({super.key});

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseCtrl;
  late AnimationController _routeGlowCtrl;
  late AnimationController _routeAppearCtrl;

  LatLng _currentCenter = const LatLng(56.4695, 84.9475);
  double _currentZoom = 17;

  List<LatLng> _route = [];
  CafePoint? _routeFrom;
  CafePoint? _routeTo;
  bool _routeMode = false;
  bool _buildingRoute = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _routeGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _routeAppearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _routeGlowCtrl.dispose();
    _routeAppearCtrl.dispose();
    super.dispose();
  }

  void _onMarkerTap(CafePoint cafe) {
    if (!_routeMode) {
      _showSnack(cafe.name, icon: _typeIcon(cafe.type));
      return;
    }
    if (_routeFrom == null) {
      setState(() => _routeFrom = cafe);
      _showSnack('Начало: ${cafe.name} — выберите конечную точку');
    } else if (cafe != _routeFrom && _routeTo == null) {
      setState(() { _routeTo = cafe; _buildingRoute = true; });
      _buildRoute();
    }
  }

  void _buildRoute() async {
    if (_routeFrom == null || _routeTo == null) return;
    final path = await Future(
          () => AStarGeo.findPath(_routeFrom!.position, _routeTo!.position),
    );
    _routeAppearCtrl.forward(from: 0);
    setState(() {
      _route = path;
      _buildingRoute = false;
    });
    _showSnack('Маршрут построен');
  }

  void _clearRoute() {
    setState(() {
      _route = [];
      _routeFrom = null;
      _routeTo = null;
    });
  }

  void _toggleRouteMode() {
    setState(() {
      _routeMode = !_routeMode;
      _clearRoute();
    });
    if (_routeMode) {
      _showSnack('Режим маршрута: выберите начальную точку');
    }
  }

  void _showSnack(String msg, {IconData? icon}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFFB47CFF)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontSize: 13, color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF12163A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _markerColor(CafePoint c) {
    switch (c.type) {
      case 'canteen': return const Color(0xFF7C4DFF);
      case 'cafe':    return const Color(0xFFB47CFF);
      case 'store':   return const Color(0xFF4ECDC4);
      default:        return const Color(0xFFFFE66D);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'canteen': return Icons.restaurant;
      case 'cafe':    return Icons.local_cafe;
      case 'store':   return Icons.store;
      default:        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildMap()),
        _buildLegend(),
      ],
    );
  }


  Widget _buildToolbar() {
    return Container(
      color: const Color(0xFF0F142E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [

          _ToolButton(
            label: _routeMode ? 'A*  ВКЛ' : 'Маршрут',
            icon: Icons.alt_route,
            active: _routeMode,
            activeColor: const Color(0xFF4ECDC4),
            onTap: _toggleRouteMode,
          ),

          if (_routeMode) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _routeFrom == null
                    ? 'Выберите начало'
                    : _routeTo == null
                    ? '${_routeFrom!.name.split(' ').first}  →  ?'
                    : '${_routeFrom!.name.split(' ').first}  →  ${_routeTo!.name.split(' ').first}',
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            if (_routeFrom != null || _route.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Color(0xFF9A9AB0)),
                tooltip: 'Очистить маршрут',
                onPressed: _clearRoute,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

            if (_buildingRoute)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4ECDC4),
                ),
              ),
          ] else
            const Spacer(),


          if (!_routeMode) ...[
            _LegendDot(color: const Color(0xFF7C4DFF), label: 'Столовая'),
            _LegendDot(color: const Color(0xFFB47CFF), label: 'Кафе'),
            _LegendDot(color: const Color(0xFF4ECDC4), label: 'Магазин'),
            _LegendDot(color: const Color(0xFFFFE66D), label: 'Киоск'),
          ],
        ],
      ),
    );
  }


  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(56.4695, 84.9475),
        initialZoom: 17,
        minZoom: 16,
        maxZoom: 19,
        onTap: (TapPosition tapPos, LatLng point) {
          if (!_routeMode) return;
          const double snapRadius = 0.0007;
          CafePoint? nearest;
          double minDist = double.infinity;
          for (final cafe in campusCafes) {
            final dlat = cafe.position.latitude - point.latitude;
            final dlng = cafe.position.longitude - point.longitude;
            final dist = dlat * dlat + dlng * dlng;
            if (dist < minDist) { minDist = dist; nearest = cafe; }
          }
          final tapPoint = (minDist < snapRadius * snapRadius && nearest != null)
              ? null
              : point;
          if (tapPoint != null) {
            final virtual = CafePoint(
              name: '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
              position: point,
              type: 'kiosk',
            );
            _onMarkerTap(virtual);
          } else if (nearest != null) {
            _onMarkerTap(nearest);
          }
        },
        onPositionChanged: (MapPosition position, bool hasGesture) {
          if (hasGesture) {
            final center = position.center;
            if (center != null) {
              _currentCenter = center;
              _currentZoom = position.zoom ?? 17;
              if (center.latitude < 56.460 ||
                  center.latitude > 56.478 ||
                  center.longitude < 84.938 ||
                  center.longitude > 84.958) {
                _animateBackToCenter();
              }
            }
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.flutter_androidmap1',
          tileBuilder: (context, widget, tile) {
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.35, 0.25, 0.50, 0, 8,
                0.25, 0.30, 0.45, 0, 8,
                0.50, 0.35, 0.70, 0, 12,
                0,    0,    0,    1, 0,
              ]),
              child: widget,
            );
          },
        ),

        if (_route.length > 1)
          AnimatedBuilder(
            animation: Listenable.merge([_routeGlowCtrl, _routeAppearCtrl]),
            builder: (context, _) {
              final glow = _routeGlowCtrl.value;
              final appear = _routeAppearCtrl.value;

              final visibleCount = (_route.length * appear).round().clamp(2, _route.length);
              final visibleRoute = _route.sublist(0, visibleCount);

              return PolylineLayer(
                polylines: [
                  Polyline(
                    points: visibleRoute,
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.06 + glow * 0.10),
                    strokeWidth: 24,
                  ),
                  Polyline(
                    points: visibleRoute,
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.12 + glow * 0.12),
                    strokeWidth: 14,
                  ),
                  Polyline(
                    points: visibleRoute,
                    color: const Color(0xFF7FFFD4).withValues(alpha: 0.25 + glow * 0.20),
                    strokeWidth: 7,
                  ),
                  Polyline(
                    points: visibleRoute,
                    color: const Color(0xFFE0FFF8).withValues(alpha: 0.85 + glow * 0.15),
                    strokeWidth: 3.0,
                  ),
                  Polyline(
                    points: visibleRoute,
                    color: Colors.white.withValues(alpha: 0.60 + glow * 0.25),
                    strokeWidth: 1.2,
                  ),
                ],
              );
            },
          ),


        MarkerLayer(
          markers: campusCafes.map((cafe) {
            final color = _markerColor(cafe);
            final isStart = cafe == _routeFrom;
            final isEnd = cafe == _routeTo;
            final isHighlighted = isStart || isEnd;

            return Marker(
              point: cafe.position,
              width: 44,
              height: 54,
              child: GestureDetector(
                onTap: () => _onMarkerTap(cafe),
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final scale = isHighlighted
                        ? 0.85 + _pulseCtrl.value * 0.2
                        : 1.0;
                    final borderColor = isStart
                        ? const Color(0xFF4ECDC4)
                        : isEnd
                        ? const Color(0xFFFFE66D)
                        : color;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: borderColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor,
                                width: isHighlighted ? 2.5 : 1.5,
                              ),
                              boxShadow: isHighlighted
                                  ? [
                                BoxShadow(
                                  color: borderColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                                  : null,
                            ),
                            child: Icon(
                              _typeIcon(cafe.type),
                              color: borderColor,
                              size: 18,
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(10, 6),
                          painter: _MarkerTailPainter(color: borderColor),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildLegend() {
    if (!_routeMode || _route.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _routeGlowCtrl,
      builder: (_, __) {
        final glow = _routeGlowCtrl.value;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F2A),
            border: Border(
              top: BorderSide(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.2 + glow * 0.2),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4ECDC4).withValues(alpha: 0.4 + glow * 0.3),
                      Colors.white.withValues(alpha: 0.7 + glow * 0.3),
                      const Color(0xFF4ECDC4).withValues(alpha: 0.4 + glow * 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.4 + glow * 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_routeFrom?.name ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF4ECDC4), fontSize: 11,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '→  ${_routeTo?.name ?? ''}',
                      style: TextStyle(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.7),
                        fontSize: 11,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${_route.length} узлов',
                  style: const TextStyle(color: Color(0xFF4ECDC4), fontSize: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _animateBackToCenter() async {
    final start = _currentCenter;
    const end = LatLng(56.4695, 84.9475);
    const steps = 20;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 16));
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      _mapController.move(LatLng(lat, lng), _currentZoom);
    }
  }
}

class _ToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToolButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : const Color(0xFF6A6A8B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active ? Border.all(color: activeColor.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(color: Color(0xFF9A9AB0), fontSize: 10)),
        ],
      ),
    );
  }
}

class _MarkerTailPainter extends CustomPainter {
  final Color color;
  _MarkerTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(_MarkerTailPainter old) => old.color != color;
}