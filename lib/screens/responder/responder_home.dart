import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/dispatch_model.dart';
import '../../models/incident_model.dart';
import '../../services/auth_service.dart';
import '../../services/dispatch_service.dart';
import '../../services/incident_service.dart';
import '../../services/routing_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';

class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  final AuthService _authService = AuthService();
  final DispatchService _dispatchService = DispatchService();
  final IncidentService _incidentService = IncidentService();
  final RoutingService _routingService = RoutingService();
  UserModel? _currentUser;
  GoogleMapController? _mapController;
  Position? _currentPosition;

  int _selectedIndex = 0;
  RouteModel? _currentRoute;
  IncidentModel? _assignedIncident;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUserProfile();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() => _currentPosition = position);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error getting location: $e');
      }
    }
  }

  Future<void> _computeRouteToIncident(IncidentModel incident) async {
    if (_currentPosition == null) return;

    setState(() {
      _assignedIncident = incident;
      _currentRoute = null;
    });

    // Try A* route via Edge Function
    final route = await _routingService.computeRoute(
      startLat: _currentPosition!.latitude,
      startLng: _currentPosition!.longitude,
      endLat: incident.latitude,
      endLng: incident.longitude,
    );

    if (mounted) {
      setState(() {
        _currentRoute = route;
        _updateMapRoute();
      });
    }
  }

  void _updateMapRoute() {
    if (_currentRoute == null || _currentPosition == null) return;

    final polylinePoints = _currentRoute!.path
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: AppColors.info,
          width: 5,
          points: polylinePoints,
        ),
      };

      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
        if (_assignedIncident != null)
          Marker(
            markerId: const MarkerId('incident'),
            position: LatLng(
              _assignedIncident!.latitude,
              _assignedIncident!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: _assignedIncident!.type.label,
              snippet: _assignedIncident!.address ?? 'Incident Location',
            ),
          ),
      };
    });

    // Fit map to show both points
    if (_assignedIncident != null && _mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(_currentPosition!.latitude, _assignedIncident!.latitude),
          min(_currentPosition!.longitude, _assignedIncident!.longitude),
        ),
        northeast: LatLng(
          max(_currentPosition!.latitude, _assignedIncident!.latitude),
          max(_currentPosition!.longitude, _assignedIncident!.longitude),
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_assignedIncident == null || _currentPosition == null) return;

    final url = RoutingService.googleMapsUrl(
      originLat: _currentPosition!.latitude,
      originLng: _currentPosition!.longitude,
      destLat: _assignedIncident!.latitude,
      destLng: _assignedIncident!.longitude,
    );

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _updateStatus(ResponderStatus status) async {
    try {
      await _authService.updateResponderStatus(status);
      if (mounted) {
        showSnackBar(context, 'Status updated to ${status.name}');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating status: $e');
      }
    }
  }

  Future<void> _updateDispatchStatus(
      String dispatchId, DispatchStatus status) async {
    try {
      await _dispatchService.updateDispatchStatus(dispatchId, status);
      setState(() {});
      if (mounted) {
        showSnackBar(context, 'Dispatch status updated');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e');
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.updateResponderStatus(ResponderStatus.offline);
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Responder: ${_currentUser?.fullName ?? 'Loading...'}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<ResponderStatus>(
            icon: const Icon(Icons.circle, color: AppColors.success),
            onSelected: _updateStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ResponderStatus.available,
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 12),
                    SizedBox(width: 8),
                    Text('Available'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ResponderStatus.busy,
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.orange, size: 12),
                    SizedBox(width: 8),
                    Text('Busy'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ResponderStatus.offline,
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.grey, size: 12),
                    SizedBox(width: 8),
                    Text('Offline'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildMapSection() : _buildDispatchesSection(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.primaryDark,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Dispatches',
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null
                ? LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(
                    AppConstants.defaultLat, AppConstants.defaultLng),
            zoom: AppConstants.defaultZoom,
          ),
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          polylines: _polylines,
          markers: _markers,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: StreamBuilder<DispatchModel?>(
              stream: _authService.currentUserId != null
                  ? _dispatchService
                      .subscribeToResponderDispatches(_authService.currentUserId!)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final activeDispatch = snapshot.data;

                if (activeDispatch == null) {
                  return const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No active dispatch. Waiting for assignments...',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: activeDispatch.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activeDispatch.status.label,
                            style: TextStyle(
                              color: activeDispatch.status.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Active Dispatch',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Route info card (when route is computed)
                    if (_currentRoute != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions,
                                color: AppColors.info, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _currentRoute!.distanceText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time,
                                color: AppColors.info, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _currentRoute!.etaText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                            if (_currentRoute!.isFallback) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.warning,
                                  color: AppColors.warning, size: 14),
                            ],
                          ],
                        ),
                      ),
                      // Open in Google Maps button
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Open in Google Maps'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (activeDispatch.status == DispatchStatus.pending)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _updateDispatchStatus(
                                activeDispatch.id, DispatchStatus.accepted);
                            // Fetch incident details and compute route
                            _incidentService
                                .getIncident(activeDispatch.incidentId)
                                .then((incident) {
                              if (incident != null) {
                                _computeRouteToIncident(incident);
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept Dispatch'),
                        ),
                      )
                    else if (activeDispatch.status == DispatchStatus.accepted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _updateDispatchStatus(
                              activeDispatch.id, DispatchStatus.enRoute),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Mark En Route'),
                        ),
                      )
                    else if (activeDispatch.status == DispatchStatus.enRoute)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _updateDispatchStatus(
                              activeDispatch.id, DispatchStatus.onScene),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Arrived at Scene'),
                        ),
                      )
                    else if (activeDispatch.status == DispatchStatus.onScene)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _updateDispatchStatus(
                              activeDispatch.id, DispatchStatus.resolved),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Mark Resolved'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDispatchesSection() {
    if (_authService.currentUserId == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<DispatchModel?>(
      stream: _dispatchService.subscribeToResponderDispatches(
          _authService.currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final dispatch = snapshot.data;

        if (dispatch == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No dispatches',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'New dispatch assignments will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Dispatch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: dispatch.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dispatch.status.label,
                            style: TextStyle(
                              color: dispatch.status.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Dispatch ID', dispatch.id.substring(0, 8)),
                    _buildInfoRow('Incident ID',
                        dispatch.incidentId.substring(0, 8)),
                    _buildInfoRow('Dispatched At', dispatch.dispatchedAt.toString()),
                    if (dispatch.acceptedAt != null)
                      _buildInfoRow('Accepted At', dispatch.acceptedAt.toString()),
                    if (dispatch.enRouteAt != null)
                      _buildInfoRow('En Route At', dispatch.enRouteAt.toString()),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
