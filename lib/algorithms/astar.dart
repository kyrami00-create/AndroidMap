import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../data/manual_obstacles.dart';

class AStarGeo {
  static const double latMin = ManualObstacles.latMin;
  static const double latMax = ManualObstacles.latMax;
  static const double lngMin = ManualObstacles.lngMin;
  static const double lngMax = ManualObstacles.lngMax;
  static const int rows = ManualObstacles.gridRows;
  static const int cols = ManualObstacles.gridCols;


  static const List<List<int>> dirs = [
    [1, 0], [-1, 0], [0, 1], [0, -1],
    [1, 1], [1, -1], [-1, 1], [-1, -1],
  ];

  static final List<List<bool>> _barriers = ManualObstacles.generateGrid();

  static List<LatLng> findPath(LatLng start, LatLng end) {
    final sr = _toRow(start.latitude);
    final sc = _toCol(start.longitude);
    final er = _toRow(end.latitude);
    final ec = _toCol(end.longitude);


    if (_barriers[sr][sc] || _barriers[er][ec]) {

      return [start, end];
    }


    double h(_GridNode n) {
      final latLng = _toLatLng(n.r, n.c);
      return _haversine(latLng.latitude, latLng.longitude, end.latitude, end.longitude);
    }

    final open = <_GridNode>{};
    final closed = <_GridNode>{};

    final startNode = _GridNode(sr, sc, g: 0, f: h(_GridNode(sr, sc)));
    open.add(startNode);

    while (open.isNotEmpty) {
      final current = open.reduce((a, b) => a.f < b.f ? a : b);

      if (current.r == er && current.c == ec) {
        return _reconstructPath(current);
      }

      open.remove(current);
      closed.add(current);

      for (final dir in dirs) {
        final nr = current.r + dir[0];
        final nc = current.c + dir[1];

        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        if (_barriers[nr][nc]) continue; // <-- обход зданий

        final neighbor = _GridNode(nr, nc);
        if (closed.contains(neighbor)) continue;

        final isDiag = dir[0].abs() + dir[1].abs() == 2;
        final tentG = current.g + (isDiag ? 1.414 : 1.0);

        _GridNode? existing;
        try {
          existing = open.firstWhere((n) => n == neighbor);
        } catch (_) {}

        if (existing == null) {
          neighbor.g = tentG;
          neighbor.f = tentG + h(neighbor);
          neighbor.parent = current;
          open.add(neighbor);
        } else if (tentG < existing.g) {
          existing.g = tentG;
          existing.f = tentG + h(existing);
          existing.parent = current;
        }
      }
    }

    return [start, end];
  }

  static List<LatLng> _reconstructPath(_GridNode end) {
    final path = <LatLng>[];
    _GridNode? node = end;
    while (node != null) {
      path.insert(0, _toLatLng(node.r, node.c));
      node = node.parent;
    }
    return path;
  }

  static int _toRow(double lat) =>
      ((latMax - lat) / (latMax - latMin) * rows).clamp(0, rows - 1).toInt();

  static int _toCol(double lng) =>
      ((lng - lngMin) / (lngMax - lngMin) * cols).clamp(0, cols - 1).toInt();

  static LatLng _toLatLng(int r, int c) => LatLng(
    latMax - r * (latMax - latMin) / rows,
    lngMin + c * (lngMax - lngMin) / cols,
  );


  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}

class _GridNode {
  final int r, c;
  double g, f;
  _GridNode? parent;
  _GridNode(this.r, this.c, {this.g = 0, this.f = 0, this.parent});

  @override
  bool operator ==(Object other) => other is _GridNode && other.r == r && other.c == c;

  @override
  int get hashCode => r * 10000 + c;
}