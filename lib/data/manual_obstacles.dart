import 'dart:math';
import 'package:latlong2/latlong.dart';

class ManualObstacles {

  static const double latMin = 56.460;
  static const double latMax = 56.478;
  static const double lngMin = 84.938;
  static const double lngMax = 84.958;

  static const int gridRows = 80;
  static const int gridCols = 80;

  static final List<_BuildingRect> buildings = [
    _BuildingRect(56.4692, 56.4703, 84.9472, 84.9485),
    _BuildingRect(56.4708, 56.4718, 84.9458, 84.9468),
    _BuildingRect(56.4685, 56.4695, 84.9488, 84.9500),
    _BuildingRect(56.4720, 56.4730, 84.9465, 84.9475),
    _BuildingRect(56.4715, 56.4720, 84.9438, 84.9448),
    _BuildingRect(56.4665, 56.4670, 84.9460, 84.9470),
  ];


  static final List<LatLng> fencePolygon = [
    LatLng(56.4695, 84.9465),
    LatLng(56.4700, 84.9482),
    LatLng(56.4710, 84.9490),
    LatLng(56.4720, 84.9480),
    LatLng(56.4725, 84.9465),
    LatLng(56.4715, 84.9450),
    LatLng(56.4702, 84.9448),
    LatLng(56.4695, 84.9465),
  ];

  static final List<LatLng> gates = [
    LatLng(56.4695, 84.9465),

  ];

  static List<List<bool>> generateGrid() {
    final grid = List.generate(gridRows, (_) => List.filled(gridCols, false));

    // 1. Размечаем здания
    for (var b in buildings) {
      final row1 = _latToRow(b.latMin);
      final row2 = _latToRow(b.latMax);
      final r1 = min(row1, row2);
      final r2 = max(row1, row2);
      final c1 = _lngToCol(b.lngMin);
      final c2 = _lngToCol(b.lngMax);

      for (int r = r1; r <= r2; r++) {
        for (int c = c1; c <= c2; c++) {
          if (r >= 0 && r < gridRows && c >= 0 && c < gridCols) {
            grid[r][c] = true;
          }
        }
      }
    }

    _markFence(grid);

    _clearGates(grid);

    return grid;
  }

  static void _markFence(List<List<bool>> grid) {
    for (int i = 0; i < fencePolygon.length - 1; i++) {
      _rasterizeLine(grid, fencePolygon[i], fencePolygon[i + 1]);
    }
  }

  static void _rasterizeLine(List<List<bool>> grid, LatLng p1, LatLng p2) {
    int r1 = _latToRow(p1.latitude);
    int c1 = _lngToCol(p1.longitude);
    int r2 = _latToRow(p2.latitude);
    int c2 = _lngToCol(p2.longitude);

    int dr = (r2 - r1).abs();
    int dc = (c2 - c1).abs();
    int sr = r1 < r2 ? 1 : -1;
    int sc = c1 < c2 ? 1 : -1;
    int err = dr - dc;

    while (true) {
      if (r1 >= 0 && r1 < gridRows && c1 >= 0 && c1 < gridCols) {
        grid[r1][c1] = true;
      }
      if (r1 == r2 && c1 == c2) break;
      int e2 = 2 * err;
      if (e2 > -dc) {
        err -= dc;
        r1 += sr;
      }
      if (e2 < dr) {
        err += dr;
        c1 += sc;
      }
    }
  }


  static void _clearGates(List<List<bool>> grid) {
    for (var gate in gates) {
      int r = _latToRow(gate.latitude);
      int c = _lngToCol(gate.longitude);
      if (r >= 0 && r < gridRows && c >= 0 && c < gridCols) {
        grid[r][c] = false;
      }
    }
  }


  static int _latToRow(double lat) =>
      ((latMax - lat) / (latMax - latMin) * gridRows)
          .clamp(0, gridRows - 1)
          .toInt();

  static int _lngToCol(double lng) =>
      ((lng - lngMin) / (lngMax - lngMin) * gridCols)
          .clamp(0, gridCols - 1)
          .toInt();

  static LatLng gridToLatLng(int r, int c) => LatLng(
    latMax - r * (latMax - latMin) / gridRows,
    lngMin + c * (lngMax - lngMin) / gridCols,
  );
}

class _BuildingRect {
  final double latMin, latMax, lngMin, lngMax;
  _BuildingRect(this.latMin, this.latMax, this.lngMin, this.lngMax);
}