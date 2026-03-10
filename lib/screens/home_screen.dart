import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../services/location_service.dart';
import '../services/crime_data_service.dart';
import '../models/crime_incident.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Services
  final LocationService _locationService = LocationService();
  final CrimeDataService _crimeService = CrimeDataService();

  // Map state
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isLoadingCrimes = false;
  bool _mapReady = false;

  // Crime state
  List<CrimeIncident> _crimes = [];
  AreaSafetyReport? _safetyReport;
  String _activeFilter = 'all'; // 'all', 'high', 'medium', 'low'
  bool _showHeatmap = true;

  // Map markers & circles
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  // Custom marker icons (pre-rendered)
  BitmapDescriptor? _highMarkerIcon;
  BitmapDescriptor? _mediumMarkerIcon;
  BitmapDescriptor? _lowMarkerIcon;

  // Animations
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;
  late AnimationController _cardSlideController;
  late Animation<Offset> _cardSlideAnimation;

  // Selected crime (for details panel)
  CrimeIncident? _selectedCrime;

  // Camera position (tracking to reload on move)
  LatLng? _lastFetchCenter;
  Timer? _cameraIdleTimer;

  static const double _defaultZoom = 14.5;
  static const double _markerIconSize = 44.0;

  @override
  void initState() {
    super.initState();

    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );

    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardSlideController, curve: Curves.easeOutCubic));

    _initMarkerIcons().then((_) => _initLocation());
  }

  @override
  void dispose() {
    _cameraIdleTimer?.cancel();
    _mapController?.dispose();
    _scoreAnimController.dispose();
    _cardSlideController.dispose();
    super.dispose();
  }

  // =====================================================
  // INIT
  // =====================================================

  Future<void> _initMarkerIcons() async {
    _highMarkerIcon = await _createMarkerIcon(const Color(0xFFEF5350)); // red
    _mediumMarkerIcon = await _createMarkerIcon(const Color(0xFFFFA726)); // orange
    _lowMarkerIcon = await _createMarkerIcon(const Color(0xFF66BB6A)); // green
  }

  Future<BitmapDescriptor> _createMarkerIcon(Color color) async {
    final size = _markerIconSize;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    final shadowPaint = Paint()..color = color.withAlpha(80);

    // Shadow
    canvas.drawCircle(Offset(size / 2, size / 2 + 2), size / 2 - 4, shadowPaint);
    // Main circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, paint);
    // White border
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Inner dot
    canvas.drawCircle(Offset(size / 2, size / 2), 6, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _initLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
    });

    if (position != null) {
      final center = LatLng(position.latitude, position.longitude);
      _addSelfMarker(center);
      await _fetchAndDrawCrimes(center);
    }
  }

  void _addSelfMarker(LatLng pos) {
    _markers.add(
      Marker(
        markerId: const MarkerId('me'),
        position: pos,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndex: 100,
      ),
    );
  }

  // =====================================================
  // CRIME FETCH & DRAW
  // =====================================================

  Future<void> _fetchAndDrawCrimes(LatLng center) async {
    if (_isLoadingCrimes) return;
    setState(() {
      _isLoadingCrimes = true;
      _selectedCrime = null;
    });

    _lastFetchCenter = center;

    final crimes = await _crimeService.fetchCrimesNear(location: center);

    if (!mounted) return;

    final report = _crimeService.calculateSafetyScore(crimes, center);

    setState(() {
      _crimes = crimes;
      _safetyReport = report;
      _isLoadingCrimes = false;
    });

    _drawCrimeMarkers();
    _scoreAnimController.forward(from: 0);
  }

  void _drawCrimeMarkers() {
    final newMarkers = <Marker>{};
    final newCircles = <Circle>{};

    // Keep self marker
    final selfMarker = _markers.where((m) => m.markerId.value == 'me');
    newMarkers.addAll(selfMarker);

    final filtered = _filteredCrimes;

    for (int i = 0; i < filtered.length; i++) {
      final crime = filtered[i];

      BitmapDescriptor icon;
      Color circleColor;

      switch (crime.severity) {
        case 'high':
          icon = _highMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          circleColor = const Color(0xFFEF5350);
        case 'medium':
          icon = _mediumMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          circleColor = const Color(0xFFFFA726);
        default:
          icon = _lowMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          circleColor = const Color(0xFF66BB6A);
      }

      final markerId = MarkerId('crime_$i');

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(crime.latitude, crime.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: crime.categoryLabel,
            snippet: crime.location ?? 'Unknown location',
          ),
          onTap: () => _onCrimeTap(crime),
          zIndex: switch (crime.severity) {
            'high' => 3,
            'medium' => 2,
            _ => 1,
          },
        ),
      );

      // Heatmap circles (only when showHeatmap is on)
      if (_showHeatmap) {
        newCircles.add(
          Circle(
            circleId: CircleId('circle_$i'),
            center: LatLng(crime.latitude, crime.longitude),
            radius: switch (crime.severity) {
              'high' => 120,
              'medium' => 80,
              _ => 50,
            }.toDouble(),
            fillColor: circleColor.withAlpha(switch (crime.severity) {
              'high' => 55,
              'medium' => 40,
              _ => 30,
            }),
            strokeColor: circleColor.withAlpha(100),
            strokeWidth: 1,
          ),
        );
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
      _circles.clear();
      _circles.addAll(newCircles);
    });
  }

  List<CrimeIncident> get _filteredCrimes {
    if (_activeFilter == 'all') return _crimes;
    return _crimes.where((c) => c.severity == _activeFilter).toList();
  }

  void _onCrimeTap(CrimeIncident crime) {
    setState(() => _selectedCrime = crime);
    _cardSlideController.forward(from: 0);
  }

  void _dismissDetail() {
    _cardSlideController.reverse().then((_) {
      if (mounted) setState(() => _selectedCrime = null);
    });
  }

  // =====================================================
  // CAMERA IDLE → RELOAD
  // =====================================================

  void _onCameraIdle() {
    _cameraIdleTimer?.cancel();
    _cameraIdleTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!_mapReady || _mapController == null) return;
      final visibleRegion = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
        (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
      );

      // Only fetch if moved significantly (> 800m)
      if (_lastFetchCenter != null) {
        final moved = _distance(_lastFetchCenter!, center);
        if (moved < 800) return;
      }
      _fetchAndDrawCrimes(center);
    });
  }

  double _distance(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.asin(math.sqrt(x));
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingLocation
          ? _buildLoadingScreen()
          : _currentPosition == null
              ? _buildNoLocationScreen()
              : _buildMapScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 64, color: AppColors.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'Getting your location...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Preparing crime heatmap',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('SafeGuard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, size: 72, color: AppColors.textTertiary),
            const SizedBox(height: 20),
            const Text('Location permission required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Enable location to see the crime heatmap', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 28),
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

  Widget _buildMapScreen() {
    return Stack(
      children: [
        // ── Full-screen Google Map ──
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: _defaultZoom,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _mapReady = true;
          },
          markers: _markers,
          circles: _circles,
          onCameraIdle: _onCameraIdle,
          onTap: (_) => _dismissDetail(),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          mapType: MapType.normal,
        ),

        // ── Top Bar ──
        _buildTopBar(),

        // ── Filter Pills ──
        Positioned(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 68,
          left: 16,
          child: _buildFilterPills(),
        ),

        // ── Loading Overlay ──
        if (_isLoadingCrimes)
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: _buildLoadingBadge(),
          ),

        // ── Safety Score Card (bottom) ──
        if (_safetyReport != null && _selectedCrime == null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildSafetyScoreCard(),
          ),

        // ── Crime Detail Sheet ──
        if (_selectedCrime != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _cardSlideAnimation,
              child: _buildCrimeDetailSheet(_selectedCrime!),
            ),
          ),

        // ── FAB: locate me ──
        Positioned(
          bottom: _safetyReport != null ? 180 : 100,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'locate',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            onPressed: () {
              if (_currentPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    _defaultZoom,
                  ),
                );
              }
            },
            child: const Icon(Icons.my_location_rounded),
          ),
        ),

        // ── FAB: toggle heatmap ──
        Positioned(
          bottom: _safetyReport != null ? 228 : 148,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'heatmap',
            backgroundColor: _showHeatmap ? AppColors.primary : Colors.white,
            foregroundColor: _showHeatmap ? Colors.white : AppColors.primary,
            tooltip: _showHeatmap ? 'Hide heatmap' : 'Show heatmap',
            onPressed: () {
              setState(() => _showHeatmap = !_showHeatmap);
              _drawCrimeMarkers();
            },
            child: const Icon(Icons.layers_rounded),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // TOP BAR
  // =====================================================

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(200),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SafeGuard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  'Crime Heatmap',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            // Crime count badge
            if (_crimes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.orangeAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_filteredCrimes.length} incidents',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            // Refresh
            GestureDetector(
              onTap: () {
                if (_currentPosition != null) {
                  _fetchAndDrawCrimes(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FILTER PILLS
  // =====================================================

  Widget _buildFilterPills() {
    final filters = [
      ('all', 'All', Colors.white),
      ('high', 'High', AppColors.danger),
      ('medium', 'Medium', AppColors.warning),
      ('low', 'Low', AppColors.success),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: filters.map((f) {
        final isActive = _activeFilter == f.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() => _activeFilter = f.$1);
              _drawCrimeMarkers();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? f.$3 : Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? f.$3 : Colors.white30,
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: f.$3.withAlpha(100), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: Text(
                f.$2,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =====================================================
  // LOADING BADGE
  // =====================================================

  Widget _buildLoadingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 8),
          Text('Loading crimes...', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // =====================================================
  // SAFETY SCORE CARD
  // =====================================================

  Widget _buildSafetyScoreCard() {
    final report = _safetyReport!;

    Color scoreColor;
    Color scoreBg;
    IconData scoreIcon;

    switch (report.color) {
      case SafetyColor.safe:
        scoreColor = AppColors.success;
        scoreBg = const Color(0xFF0D2818);
        scoreIcon = Icons.check_circle_rounded;
      case SafetyColor.moderate:
        scoreColor = AppColors.warning;
        scoreBg = const Color(0xFF2A1E05);
        scoreIcon = Icons.warning_rounded;
      case SafetyColor.danger:
        scoreColor = AppColors.danger;
        scoreBg = const Color(0xFF2A0808);
        scoreIcon = Icons.dangerous_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: scoreBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Score row
            Row(
              children: [
                // Animated score circle
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (_, __) {
                    final displayScore = (report.score * _scoreAnimation.value).toInt();
                    return SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: _scoreAnimation.value * report.score / 100,
                              strokeWidth: 6,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$displayScore',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              Text(
                                '/100',
                                style: TextStyle(color: scoreColor.withAlpha(180), fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(scoreIcon, color: scoreColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            report.rating,
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.crimeCount} incidents near you',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Top: ${report.topCategory}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Severity breakdown bar
            const SizedBox(height: 14),
            _buildSeverityBar(),

            // Tap hint
            const SizedBox(height: 10),
            const Text(
              '📍 Tap any marker to see crime details',
              style: TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBar() {
    final high = _crimes.where((c) => c.severity == 'high').length;
    final medium = _crimes.where((c) => c.severity == 'medium').length;
    final low = _crimes.where((c) => c.severity == 'low').length;
    final total = _crimes.length;

    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: high == 0 ? 0 : high,
              child: Container(
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
            ),
            if (medium > 0)
              Expanded(
                flex: medium,
                child: Container(
                  height: 6,
                  color: AppColors.warning,
                ),
              ),
            if (low > 0)
              Expanded(
                flex: low,
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(AppColors.danger, 'High', high),
            _buildLegendItem(AppColors.warning, 'Medium', medium),
            _buildLegendItem(AppColors.success, 'Low', low),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  // =====================================================
  // CRIME DETAIL BOTTOM SHEET
  // =====================================================

  Widget _buildCrimeDetailSheet(CrimeIncident crime) {
    Color severityColor;
    IconData severityIcon;
    String severityLabel;

    switch (crime.severity) {
      case 'high':
        severityColor = AppColors.danger;
        severityIcon = Icons.dangerous_rounded;
        severityLabel = 'High Risk';
      case 'medium':
        severityColor = AppColors.warning;
        severityIcon = Icons.warning_rounded;
        severityLabel = 'Medium Risk';
      default:
        severityColor = AppColors.success;
        severityIcon = Icons.info_rounded;
        severityLabel = 'Low Risk';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 30),
        ],
        border: Border.all(color: severityColor.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: severityColor.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(severityIcon, color: severityColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crime.categoryLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: severityColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              severityLabel,
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: _dismissDetail,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details grid
                _buildDetailRow(Icons.location_on_rounded, 'Location', crime.location ?? 'Unknown'),
                _buildDetailRow(Icons.calendar_month_rounded, 'Date',
                    '${crime.date.day}/${crime.date.month}/${crime.date.year}'),
                _buildDetailRow(Icons.gavel_rounded, 'Outcome', crime.outcomeStatus ?? 'Under investigation'),
                if (crime.isMock)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Demo data — real data available in UK regions',
                          style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
