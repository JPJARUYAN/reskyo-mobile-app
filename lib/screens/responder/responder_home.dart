import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/dispatch_model.dart';
import '../../services/auth_service.dart';
import '../../services/dispatch_service.dart';
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
  UserModel? _currentUser;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  DispatchStatus _currentStatus = DispatchStatus.pending; // ignore: unused_field
  int _selectedIndex = 0;

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
      setState(() => _currentStatus = status);
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
                    const SizedBox(height: 8),
                    if (activeDispatch.status == DispatchStatus.pending)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _updateDispatchStatus(
                              activeDispatch.id, DispatchStatus.accepted),
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
