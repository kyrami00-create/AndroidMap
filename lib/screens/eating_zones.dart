import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/cafe_data.dart';

class _Centroid {
  double lat, lng;
  _Centroid(this.lat, this.lng);
}

class _KMeans {
  final int k;
  final int maxIter;
  final Random _rng = Random(7);

  _KMeans({this.k = 3, this.maxIter = 60});

  void fit(List<CafePoint> pts) {
    if (pts.isEmpty) return;
    final n = min(k, pts.length);
    final centroids = _initPlusPlus(pts, n);
    bool changed = true;
    int iter = 0;

    while (changed && iter++ < maxIter) {
      changed = false;
      for (final p in pts) {
        final id = _nearest(p, centroids);
        if (p.clusterId != id) {
          p.clusterId = id;
          changed = true;
        }
      }
      for (int i = 0; i < n; i++) {
        final members = pts.where((p) => p.clusterId == i).toList();
        if (members.isEmpty) continue;
        centroids[i].lat =
            members.map((p) => p.position.latitude).reduce((a, b) => a + b) /
                members.length;
        centroids[i].lng =
            members.map((p) => p.position.longitude).reduce((a, b) => a + b) /
                members.length;
      }
    }
  }

  List<_Centroid> _initPlusPlus(List<CafePoint> pts, int n) {
    final cs = <_Centroid>[];
    cs.add(_Centroid(
      pts[_rng.nextInt(pts.length)].position.latitude,
      pts[_rng.nextInt(pts.length)].position.longitude,
    ));
    while (cs.length < n) {
      final dists = pts.map((p) {
        double md = double.infinity;
        for (final c in cs) {
          final d = _dist(p.position.latitude, p.position.longitude, c.lat, c.lng);
          if (d < md) md = d;
        }
        return md * md;
      }).toList();
      final total = dists.reduce((a, b) => a + b);
      double r = _rng.nextDouble() * total;
      int idx = 0;
      for (int i = 0; i < dists.length; i++) {
        r -= dists[i];
        if (r <= 0) { idx = i; break; }
      }
      cs.add(_Centroid(pts[idx].position.latitude, pts[idx].position.longitude));
    }
    return cs;
  }

  int _nearest(CafePoint p, List<_Centroid> cs) {
    int best = 0;
    double md = double.infinity;
    for (int i = 0; i < cs.length; i++) {
      final d = _dist(p.position.latitude, p.position.longitude, cs[i].lat, cs[i].lng);
      if (d < md) { md = d; best = i; }
    }
    return best;
  }

  double _dist(double la1, double lo1, double la2, double lo2) {
    final a = la1 - la2, b = lo1 - lo2;
    return sqrt(a * a + b * b);
  }
}

const List<Color> _clusterColors = [
  Color(0xFFFF6B6B),
  Color(0xFF4ECDC4),
  Color(0xFFFFE66D),
  Color(0xFF95E1D3),
  Color(0xFFF38181),
];

class EatingZones extends StatefulWidget {
  const EatingZones({super.key});

  @override
  State<EatingZones> createState() => _EatingZonesState();
}

class _EatingZonesState extends State<EatingZones>
    with SingleTickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  late AnimationController _pulseCtrl;

  late List<CafePoint> _cafes;
  bool _clustered = false;
  bool _animating = false;
  int _kValue = 3;

  @override
  void initState() {
    super.initState();
    _cafes = campusCafes
        .map((c) => CafePoint(
      name: c.name,
      position: c.position,
      type: c.type,
      building: c.building,
      floor: c.floor,
      description: c.description,
      placesCount: c.placesCount,
      imageUrl: c.imageUrl,
      workingHours: c.workingHours,
      capacity: c.capacity,
      wifi: c.wifi,
      charging: c.charging,
    ))
        .toList();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _getDistanceForZone(CafePoint zone) {
    return '? м';
  }

  void _runClustering() async {
    setState(() => _animating = true);
    await Future.delayed(const Duration(milliseconds: 60));
    _KMeans(k: _kValue).fit(_cafes);
    setState(() {
      _clustered = true;
      _animating = false;
    });
  }

  void _resetClusters() {
    setState(() {
      for (final c in _cafes) {
        c.clusterId = -1;
      }
      _clustered = false;
    });
  }

  Color _markerColor(CafePoint c) {
    if (!_clustered || c.clusterId < 0) return const Color(0xFF7C4DFF);
    return _clusterColors[c.clusterId % _clusterColors.length];
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'canteen':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'store':
        return Icons.store;
      default:
        return Icons.fastfood;
    }
  }

  void _showZoneDetails(CafePoint zone) {
    final distance = _getDistanceForZone(zone);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2448),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zone.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFB0B0D0)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  zone.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: const Color(0xFF2A2D5A),
                    child: const Center(
                      child: Icon(Icons.restaurant,
                          size: 48, color: Color(0xFF7C4DFF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.business, 'Корпус', zone.building),
              _buildDetailRow(Icons.location_on, 'Этаж', zone.floor),
              _buildDetailRow(Icons.access_time, 'Часы работы', zone.workingHours),
              _buildDetailRow(Icons.people, 'Вместимость', zone.capacity),
              _buildDetailRow(Icons.restaurant, 'Заведений', '${zone.placesCount}'),
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
                          const Icon(Icons.wifi, color: Color(0xFF4CAF50), size: 20),
                          const SizedBox(width: 4),
                          const Text('Wi-Fi',
                              style: TextStyle(color: Color(0xFFB0B0D0))),
                          const SizedBox(width: 16),
                        ],
                        if (zone.charging) ...[
                          const Icon(Icons.power, color: Color(0xFFFF9800), size: 20),
                          const SizedBox(width: 4),
                          const Text('Розетки',
                              style: TextStyle(color: Color(0xFFB0B0D0))),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlPanel(),
        Expanded(child: _buildMap()),
        if (_clustered) _buildLegend(),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: const Color(0xFF0F142E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Text('K =',
              style: TextStyle(color: Color(0xFF9A9AB0), fontSize: 13)),
          const SizedBox(width: 4),
          Text('$_kValue',
              style: const TextStyle(
                  color: Color(0xFFB47CFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Expanded(
            child: Slider(
              value: _kValue.toDouble(),
              min: 2,
              max: 5,
              divisions: 3,
              activeColor: const Color(0xFF7C4DFF),
              inactiveColor: const Color(0xFF2A2D5A),
              onChanged: _clustered
                  ? null
                  : (v) => setState(() => _kValue = v.toInt()),
            ),
          ),
          if (_animating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFB47CFF)),
            )
          else
            _ClusterButton(
              label: _clustered ? 'Сбросить' : 'Кластеризация',
              icon: _clustered ? Icons.refresh : Icons.bubble_chart,
              color: _clustered ? const Color(0xFF444870) : const Color(0xFF7C4DFF),
              onTap: _clustered ? _resetClusters : _runClustering,
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapCtrl,
      options: const MapOptions(
        initialCenter: LatLng(56.4697, 84.9468),
        initialZoom: 16.5,
        minZoom: 15.5,
        maxZoom: 19,
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
                0, 0, 0, 1, 0,
              ]),
              child: widget,
            );
          },
        ),
        MarkerLayer(
          markers: _cafes.map((cafe) {
            final color = _markerColor(cafe);
            return Marker(
              point: cafe.position,
              width: 44,
              height: 52,
              child: GestureDetector(
                onTap: () => _showZoneDetails(cafe),
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final scale =
                    _animating ? 0.85 + _pulseCtrl.value * 0.15 : 1.0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: scale,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 1.5),
                            ),
                            child: Icon(_typeIcon(cafe.type),
                                color: color, size: 18),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(10, 6),
                          painter: _MarkerTailPainter(color: color),
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
    final Map<int, List<CafePoint>> groups = {};
    for (final c in _cafes) {
      groups.putIfAbsent(c.clusterId, () => []).add(c);
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      color: const Color(0xFF0F142E),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Кластеры',
              style: TextStyle(
                  color: Color(0xFFB47CFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sorted.map((e) {
                final color = _clusterColors[e.key % _clusterColors.length];
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Кластер ${e.key + 1}  (${e.value.length})',
                          style: TextStyle(color: color, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ClusterButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
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