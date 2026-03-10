import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../services/location_service.dart';
import '../services/maps_service.dart';
import '../models/models.dart';
import '../models/crime_incident.dart';

// Route color palette
const _routeColors = [
  Color(0xFF4CAF50), // safest  → green
  Color(0xFFFFA726), // mid     → orange
  Color(0xFFEF5350), // worst   → red
];

const _routeLabels = ['Best', 'Alternative', 'Avoid'];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // ── Services ──────────────────────────────────────────
  final LocationService _locationService = LocationService();
  final MapsService _mapsService = MapsService();

  // ── Map ───────────────────────────────────────────────
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _destinationLatLng;
  String _destinationLabel = '';
  bool _isLoadingLocation = true;
  bool _isSearching = false;
  bool _isNightMode = false;

  // ── Routes ────────────────────────────────────────────
  List<RouteSafety> _routes = [];
  int _selectedRouteIndex = 0;

  // ── Map objects ───────────────────────────────────────
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Circle> _dangerCircles = {};

  // ── Controllers ────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  // ── Search ────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchSuggestions = false;

  @override
  void initState() {
    super.initState();
    _isNightMode = DateTime.now().hour < 6 || DateTime.now().hour >= 20;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scoreAnimation = CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic);

    _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreController.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════════════════

  Future<void> _initLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentPosition = pos;
      _isLoadingLocation = false;
    });
    if (pos != null) {
      _addOriginMarker(LatLng(pos.latitude, pos.longitude));
    }
  }

  void _addOriginMarker(LatLng pos) {
    _markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'You are here'),
      zIndex: 10,
    ));
    setState(() {});
  }

  // ══════════════════════════════════════════════════════
  // DESTINATION SEARCH
  // ══════════════════════════════════════════════════════

  Future<void> _searchDestination() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _routes = [];
      _polylines.clear();
      _dangerCircles.clear();
      _showSearchSuggestions = false;
    });
    FocusScope.of(context).unfocus();

    // Geocode
    GeocodingResult? geo = await _mapsService.geocodeAddress(query);

    if (!mounted) return;

    if (geo == null) {
      // Fallback: place destination 1 km away (demo mode)
      final origin = LatLng(
        _currentPosition!.latitude + 0.007,
        _currentPosition!.longitude + 0.009,
      );
      geo = GeocodingResult(latLng: origin, formattedAddress: query);
    }

    setState(() {
      _destinationLatLng = geo!.latLng;
      _destinationLabel = geo.formattedAddress;
    });

    _addDestinationMarker(geo.latLng);
    await _computeRoutes();
  }

  void _addDestinationMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'dest');
    _markers.add(Marker(
      markerId: const MarkerId('dest'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: 'Destination', snippet: _destinationLabel),
      zIndex: 10,
    ));
    setState(() {});
  }

  // ── Tap on map to place destination ───────────────────
  void _onMapTap(LatLng pos) {
    if (_routes.isNotEmpty) return; // already showing routes — don't interfere
    setState(() {
      _destinationLatLng = pos;
      _destinationLabel = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      _searchController.text = _destinationLabel;
    });
    _addDestinationMarker(pos);
  }

  // ══════════════════════════════════════════════════════
  // ROUTE COMPUTATION
  // ══════════════════════════════════════════════════════

  Future<void> _computeRoutes() async {
    if (_currentPosition == null || _destinationLatLng == null) return;

    setState(() {
      _isSearching = true;
      _routes = [];
      _polylines.clear();
      _dangerCircles.clear();
    });

    final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    final routes = await _mapsService.getRoutesWithSafety(
      origin: origin,
      destination: _destinationLatLng!,
      isNightTime: _isNightMode,
    );

    if (!mounted) return;

    setState(() {
      _routes = routes;
      _isSearching = false;
      _selectedRouteIndex = 0;
    });

    _drawRoutes();
    _fitMapToRoutes();
    _scoreController.forward(from: 0);
  }

  void _drawRoutes() {
    _polylines.clear();
    _dangerCircles.clear();

    for (int i = 0; i < _routes.length; i++) {
      final route = _routes[i];
      final isSelected = i == _selectedRouteIndex;
      final color = _routeColors[i.clamp(0, _routeColors.length - 1)];

      _polylines.add(Polyline(
        polylineId: PolylineId('route_$i'),
        points: route.polylinePoints,
        color: isSelected ? color : color.withAlpha(120),
        width: isSelected ? 7 : 4,
        patterns: isSelected ? [] : [PatternItem.dash(12), PatternItem.gap(8)],
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        zIndex: isSelected ? 5 : 1,
      ));

      // Danger circles for selected route
      if (isSelected) {
        for (int j = 0; j < route.nearbyCrimes.length; j++) {
          final crime = route.nearbyCrimes[j];
          final crimeColor = switch (crime.severity) {
            'high'   => const Color(0xFFEF5350),
            'medium' => const Color(0xFFFFA726),
            _        => const Color(0xFF66BB6A),
          };
          _dangerCircles.add(Circle(
            circleId: CircleId('danger_${i}_$j'),
            center: LatLng(crime.latitude, crime.longitude),
            radius: switch (crime.severity) {
              'high'   => 90,
              'medium' => 60,
              _        => 40,
            }.toDouble(),
            fillColor: crimeColor.withAlpha(50),
            strokeColor: crimeColor.withAlpha(120),
            strokeWidth: 1,
          ));
        }
      }
    }

    setState(() {});
  }

  Future<void> _fitMapToRoutes() async {
    if (_routes.isEmpty || _mapController == null) return;

    final allPoints = _routes.expand((r) => r.polylinePoints).toList();
    if (allPoints.isEmpty) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        80,
      ),
    );
  }

  void _selectRoute(int index) {
    setState(() => _selectedRouteIndex = index);
    _drawRoutes();
    _scoreController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _toggleNightMode() {
    setState(() => _isNightMode = !_isNightMode);
    if (_routes.isNotEmpty) _computeRoutes();
    HapticFeedback.lightImpact();
  }

  void _clearRoutes() {
    setState(() {
      _routes = [];
      _polylines.clear();
      _dangerCircles.clear();
      _markers.removeWhere((m) => m.markerId.value == 'dest');
      _searchController.clear();
      _destinationLatLng = null;
      _destinationLabel = '';
    });
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation) return _buildLoadingScreen();
    if (_currentPosition == null) return _buildNoLocationScreen();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 14.5,
            ),
            onMapCreated: (c) { _mapController = c; },
            polylines: _polylines,
            markers: _markers,
            circles: _dangerCircles,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ── Search bar ──────────────────────────────────
          _buildSearchBar(),

          // ── Route cards (bottom) ────────────────────────
          if (_routes.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildRoutePanel(),
            ),

          // ── Loading indicator ───────────────────────────
          if (_isSearching)
            _buildSearchingOverlay(),

          // ── FABs ────────────────────────────────────────
          Positioned(
            bottom: _routes.isNotEmpty ? 300 : 32,
            right: 16,
            child: _buildFabs(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // SEARCH BAR
  // ══════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search destination…',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchDestination(),
                    onTap: () => setState(() => _showSearchSuggestions = true),
                  ),
                ),
                if (_searchController.text.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: _clearRoutes,
                    padding: EdgeInsets.zero,
                  ),
                ],
                // Night mode toggle
                GestureDetector(
                  onTap: _toggleNightMode,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isNightMode
                          ? const Color(0xFF1A1A2E)
                          : AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isNightMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                          size: 16,
                          color: _isNightMode ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isNightMode ? 'Night' : 'Day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isNightMode ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Go button / route count badge
          if (_destinationLatLng != null && _routes.isEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: _computeRoutes,
                icon: const Icon(Icons.route_rounded),
                label: const Text('Find Safe Routes'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ROUTE PANEL
  // ══════════════════════════════════════════════════════

  Widget _buildRoutePanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_routes.length} Routes Found',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_routes.first.isMock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(80)),
                    ),
                    child: const Text(
                      '⚡ Demo Mode',
                      style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // Route cards horizontal scroll
          SizedBox(
            height: 176,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _routes.length,
              itemBuilder: (_, i) => _buildRouteCard(i),
            ),
          ),

          // AI Safety narration for selected route
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _buildNarrationPanel(),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildRouteCard(int index) {
    final route = _routes[index];
    final isSelected = index == _selectedRouteIndex;
    final color = _routeColors[index.clamp(0, _routeColors.length - 1)];
    final label = _routeLabels[index.clamp(0, _routeLabels.length - 1)];
    final score = route.safetyScore.overall.toInt();

    return GestureDetector(
      onTap: () => _selectRoute(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 188,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withAlpha(80), blurRadius: 16, spreadRadius: 1)]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route label + recommended badge
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (index == 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '★',
                        style: TextStyle(color: Colors.amber, fontSize: 10),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    route.summary,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Animated score ring
              Center(
                child: AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (_, __) {
                    final shown = isSelected
                        ? (score * _scoreAnimation.value).toInt()
                        : score;
                    return SizedBox(
                      width: 62,
                      height: 62,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: shown / 100,
                              strokeWidth: 5,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$shown',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 1,
                                ),
                              ),
                              Text(
                                '/100',
                                style: TextStyle(
                                  color: color.withAlpha(160),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip(Icons.directions_walk_rounded, route.durationText),
                  _statChip(Icons.straighten_rounded, route.distanceText),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${route.nearbyCrimes.length} incidents',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    route.safetyScore.safetyLevel,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // ── AI Narration Panel ─────────────────────────────────
  Widget _buildNarrationPanel() {
    if (_routes.isEmpty) return const SizedBox.shrink();
    final route = _routes[_selectedRouteIndex];
    if (route.safetyNarration.isEmpty) return const SizedBox.shrink();

    final color = _routeColors[_selectedRouteIndex.clamp(0, _routeColors.length - 1)];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Safety Brief',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  route.safetyNarration,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Score breakdown sheet ──────────────────────────────
  void _showScoreBreakdown(RouteSafety route) {
    final color = _routeColors[_selectedRouteIndex.clamp(0, _routeColors.length - 1)];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_rounded, color: color),
                const SizedBox(width: 10),
                Text(
                  'Safety Score Breakdown',
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _scoreRow('🚨 Crime Score', route.safetyScore.crimeScore, AppColors.danger),
            _scoreRow('💡 Lighting Score', route.safetyScore.lightingScore, AppColors.warning),
            _scoreRow('🕐 Time of Day', route.safetyScore.timeScore, AppColors.info),
            _scoreRow('📊 Overall Safety', route.safetyScore.overall, color),
            const SizedBox(height: 12),
            Text(
              '${route.nearbyCrimes.length} crimes within 400m of this route.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                '${value.toInt()}/100',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // FABs
  // ══════════════════════════════════════════════════════

  Widget _buildFabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Locate me
        FloatingActionButton.small(
          heroTag: 'locate_map',
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          onPressed: () {
            if (_currentPosition != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  14.5,
                ),
              );
            }
          },
          child: const Icon(Icons.my_location_rounded),
        ),
        const SizedBox(height: 10),
        // Breakdown
        if (_routes.isNotEmpty)
          FloatingActionButton.small(
            heroTag: 'breakdown',
            backgroundColor: _routeColors[_selectedRouteIndex.clamp(0, 2)],
            foregroundColor: Colors.white,
            onPressed: () => _showScoreBreakdown(_routes[_selectedRouteIndex]),
            child: const Icon(Icons.analytics_rounded),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // SEARCHING OVERLAY
  // ══════════════════════════════════════════════════════

  Widget _buildSearchingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withAlpha(60),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Analysing safety…',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Checking crime data along routes',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // MISC SCREENS
  // ══════════════════════════════════════════════════════

  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFF0F0F1E),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text('Getting your location…',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Routes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text('Location required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initLocation,
              icon: const Icon(Icons.location_on_rounded),
              label: const Text('Enable Location'),
            ),
          ],
        ),
      ),
    );
  }
}
