import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/incident_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class ReportIncidentScreen extends StatefulWidget {
  final Position? currentPosition;

  const ReportIncidentScreen({super.key, this.currentPosition});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _incidentService = IncidentService();
  final _imagePicker = ImagePicker();

  IncidentType _selectedType = IncidentType.other;
  File? _selectedPhoto;
  Position? _gpsPosition;
  String? _address;
  bool _isSubmitting = false;
  bool _isCapturingLocation = true;

  @override
  void initState() {
    super.initState();
    _gpsPosition = widget.currentPosition;
    _resolveAddress();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _resolveAddress() async {
    if (_gpsPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _gpsPosition!.latitude,
        _gpsPosition!.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;
        setState(() {
          _address =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      // Address resolution failed, that's okay
    }

    if (mounted) {
      setState(() => _isCapturingLocation = false);
    }
  }

  Future<void> _refreshLocation() async {
    setState(() => _isCapturingLocation = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() => _gpsPosition = position);
        await _resolveAddress();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error getting location: $e');
        setState(() => _isCapturingLocation = false);
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConstants.maxPhotoWidth.toDouble(),
        maxHeight: AppConstants.maxPhotoHeight.toDouble(),
        imageQuality: AppConstants.photoQuality,
      );

      if (image != null) {
        setState(() => _selectedPhoto = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error picking photo: $e');
      }
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_gpsPosition == null) {
      showSnackBar(context, 'Please wait for GPS location');
      return;
    }

    final user = await _authService.getCurrentUserProfile();
    if (user == null) {
      showSnackBar(context, 'Error: User not found');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final incident = await _incidentService.createIncident(
        type: _selectedType,
        description: _descriptionController.text.trim(),
        latitude: _gpsPosition!.latitude,
        longitude: _gpsPosition!.longitude,
        address: _address,
        reporterId: user.uid,
        barangay: user.barangay,
        photoFile: _selectedPhoto,
      );

      if (!mounted) return;

      if (incident != null) {
        showSnackBar(context, 'Emergency reported successfully!');

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            title: const Text('Report Submitted'),
            content: const Text(
              'Your emergency report has been received. '
              'CDRRMO and nearby volunteers will be notified.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showSnackBar(context, 'Failed to submit report. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Emergency'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your GPS location is captured automatically. '
                      'A photo of the incident is required.',
                      style: TextStyle(
                          color: AppColors.primaryDark, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Incident Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  avatar: Icon(
                    type.icon,
                    color: isSelected ? Colors.white : type.color,
                  ),
                  selected: isSelected,
                  selectedColor: type.color,
                  backgroundColor: type.color.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : type.color,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Describe what happened (e.g., number of vehicles, people involved, etc.)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide a description';
                }
                if (value.length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Incident Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedPhoto != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.file(
                      _selectedPhoto!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() => _selectedPhoto = null);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showPhotoSourceDialog,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                    _selectedPhoto != null ? 'Retake Photo' : 'Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isCapturingLocation) ...[
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Capturing GPS location...'),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _address ?? 'Location captured',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${_gpsPosition?.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_gpsPosition?.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCapturingLocation ? null : _refreshLocation,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh Location'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Emergency Report',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
