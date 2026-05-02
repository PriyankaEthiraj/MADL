import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../services/complaint_service.dart';
import 'geo_camera_screen.dart';

class ComplaintCreateScreen extends StatefulWidget {
  final String? category;
  
  const ComplaintCreateScreen({super.key, this.category});

  @override
  State<ComplaintCreateScreen> createState() => _ComplaintCreateScreenState();
}

class _ComplaintCreateScreenState extends State<ComplaintCreateScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _customSubCategoryController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _error;
  XFile? _photo;
  double? _photoLatitude;
  double? _photoLongitude;
  DateTime? _photoTimestamp;
  String? _photoAddress;
  XFile? _video;
  VideoPlayerController? _videoController;
  bool _videoPreviewReady = false;
  double? _videoLatitude;
  double? _videoLongitude;
  DateTime? _videoTimestamp;
  String? _videoAddress;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, List<String>> _subCategoryMap = {
    'Road Maintenance': [
      'Potholes',
      'Road cracks',
      'Waterlogging',
      'Damaged speed breakers',
      'Broken footpaths',
      'Missing manhole covers',
      'Road accidents due to damage',
      'Unauthorized road digging',
      'Other',
    ],
    'Public Toilet & Sanitation': [
      'Toilet cleanliness issue',
      'Water not available',
      'Toilet locked',
      'Bad odor',
      'Broken taps / flush',
      'No lighting',
      'Lack of maintenance staff',
      'Other',
    ],
    'Public Transport – Bus': [
      'Bus delay',
      'Overcrowding',
      'Bus not stopping',
      'Driver rash driving',
      'Bus breakdown',
      'Dirty buses',
      'Route change without notice',
      'Lack of buses',
      'Other',
    ],
    'Street Light': [
      'Not working',
      'Flickering',
      'Broken pole',
      'Daytime light on',
      'Damaged wiring',
      'Area blackout',
      'Other',
    ],
    'Water Supply': [
      'No water supply',
      'Low pressure',
      'Leakage',
      'Dirty water',
      'Irregular timing',
      'Burst pipeline',
      'Overflow tank',
      'Other',
    ],
    'Garbage & Waste Management': [
      'Garbage not collected',
      'Overflowing dustbin',
      'No dustbin',
      'Irregular pickup',
      'Open dumping',
      'Bad smell',
      'Dead animal disposal',
      'Other',
    ],
    'Others': [],
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _customSubCategoryController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPreview(String videoPath) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(videoPath));

    try {
      await _videoController!.initialize();
      if (!mounted) return;
      setState(() {
        _videoPreviewReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videoPreviewReady = false;
      });
    }
  }

  Future<String?> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[];

      if (place.name != null && place.name!.isNotEmpty) parts.add(place.name!);
      if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
      if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
      if (place.country != null && place.country!.isNotEmpty) parts.add(place.country!);

      if (parts.isEmpty) {
        return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      return parts.join(', ');
    } catch (e) {
      debugPrint('Failed to get video address: $e');
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  Widget _buildGeotagOverlay({
    required Color accentColor,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) {
    final hasLocation = address != null && address.trim().isNotEmpty;
    final hasCoordinates = latitude != null && longitude != null;
    final hasTimestamp = timestamp != null;

    if (!hasLocation && !hasCoordinates && !hasTimestamp) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: accentColor, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasLocation ? address!.trim() : 'Geotag captured',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (hasCoordinates) ...[
              const SizedBox(height: 4),
              Text(
                'GPS: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (hasTimestamp) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPhotoPreviewDialog() async {
    if (_photo == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.file(
                    File(_photo!.path),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                _buildGeotagOverlay(
                  accentColor: const Color(0xFF10B981),
                  address: _photoAddress,
                  latitude: _photoLatitude,
                  longitude: _photoLongitude,
                  timestamp: _photoTimestamp,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      setState(() => _error = 'Please select a complaint category');
      return;
    }

    // Validate subcategory for non-Others categories
    if (_selectedCategory != 'Others' && _selectedSubCategory == null) {
      setState(() => _error = 'Please select a sub-category');
      return;
    }

    // Validate custom subcategory when "Other" is selected
    if (_selectedSubCategory == 'Other' && _customSubCategoryController.text.trim().isEmpty) {
      setState(() => _error = 'Please specify the subcategory');
      return;
    }

    // Validate at least one media attachment is required
    if (_photo == null && _video == null) {
      setState(() => _error = 'Attach at least one media: photo or geo video');
      return;
    }

    // Validate description length
    if (_descriptionController.text.trim().length < 20) {
      setState(() => _error = 'Description must be at least 20 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use custom subcategory if "Other" is selected
      String? finalSubCategory = _selectedSubCategory;
      if (_selectedSubCategory == 'Other') {
        finalSubCategory = _customSubCategoryController.text.trim();
      }
      
      await context.read<ComplaintService>().submitComplaint(
            category: _selectedCategory!,
            subCategory: finalSubCategory,
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
        photoPath: _photo?.path,
            videoPath: _video?.path,
            photoLatitude: _photoLatitude,
            photoLongitude: _photoLongitude,
            photoTimestamp: _photoTimestamp,
            photoLocationName: _photoAddress,
            videoLatitude: _videoLatitude,
            videoLongitude: _videoLongitude,
            videoTimestamp: _videoTimestamp,
            videoLocationName: _videoAddress,
          );
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Complaint submitted successfully!')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      // Navigate back to home (pop twice - once for this screen, once for category screen)
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openGeoCamera() async {
    try {
      final result = await Navigator.push<GeoCameraResult>(
        context,
        MaterialPageRoute(builder: (_) => const GeoCameraScreen()),
      );
      
      if (result != null) {
        setState(() {
          _photo = XFile(result.imagePath);
          _photoLatitude = result.latitude;
          _photoLongitude = result.longitude;
          _photoTimestamp = result.timestamp;
          _photoAddress = result.address;
          _error = null;
        });
        
        // Show success message with coordinates
        if (mounted) {
          final message = result.address != null
              ? 'Photo captured at: ${result.address}'
              : 'Photo captured with GPS: ${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(message),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (err) {
      setState(() => _error = 'Failed to capture photo: ${err.toString()}');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Capture Photo with GPS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For complaint verification, photos must be captured with GPS location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Open Geo Camera'),
              subtitle: const Text('Capture with GPS coordinates'),
              onTap: () {
                Navigator.pop(context);
                _openGeoCamera();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _useGps() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied. Please enable in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _error = null;
        _isLoadingLocation = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Location captured successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (err) {
      setState(() {
        _error = 'Failed to get location: ${err.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _captureVideoWithGeo() async {
    // For now, we'll capture video with current location
    // In a production app, you might want to integrate with a GeoVideo capture screen
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await _getAddressFromCoordinates(position.latitude, position.longitude);

      // Now open video picker and tag with location
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.camera);
      
      if (video != null) {
        setState(() {
          _video = video;
          _videoPreviewReady = false;
          _videoLatitude = position.latitude;
          _videoLongitude = position.longitude;
          _videoTimestamp = DateTime.now();
          _videoAddress = address;
          _error = null;
        });
        await _initializeVideoPreview(video.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Video captured at: ${_videoAddress!}'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (err) {
      setState(() => _error = 'Failed to capture video: ${err.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Complaint',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Report an Issue',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),

                  // Category (read-only, auto-filled)
                  TextFormField(
                    initialValue: _selectedCategory,
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Color(0xFFF9FAFB),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sub-category dropdown (if not Others)
                  if (_selectedCategory != 'Others') ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubCategory,
                      decoration: const InputDecoration(
                        labelText: 'Sub Category',
                        hintText: 'Select sub-category',
                        prefixIcon: Icon(Icons.list_alt_outlined),
                      ),
                      items: (_subCategoryMap[_selectedCategory] ?? []).map((subCategory) {
                        return DropdownMenuItem(
                          value: subCategory,
                          child: Text(subCategory),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubCategory = value;
                          _customSubCategoryController.clear();
                          _error = null;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a sub-category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Custom subcategory field (if "Other" is selected)
                  if (_selectedSubCategory == 'Other') ...[
                    TextFormField(
                      controller: _customSubCategoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Specify Subcategory *',
                        hintText: 'Enter custom subcategory',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please specify the subcategory';
                        }
                        if (value.trim().length < 3) {
                          return 'Subcategory must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    maxLength: 500,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Provide detailed description of the issue (min 20 characters)...',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (value.trim().length < 20) {
                        return 'Description must be at least 20 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Location *',
                      hintText: 'Enter location or use GPS',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: _isLoadingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.my_location),
                              tooltip: 'Use current location',
                              onPressed: _useGps,
                            ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Location is required';
                      }
                      if (value.trim().length < 5) {
                        return 'Please enter a valid location';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Attachment (Required) *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (_photo != null) ...[
                    GestureDetector(
                      onTap: _showPhotoPreviewDialog,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(_photo!.path),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Tap to preview',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            _buildGeotagOverlay(
                              accentColor: const Color(0xFF10B981),
                              address: _photoAddress,
                              latitude: _photoLatitude,
                              longitude: _photoLongitude,
                              timestamp: _photoTimestamp,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => setState(() {
                                    _photo = null;
                                    _photoLatitude = null;
                                    _photoLongitude = null;
                                    _photoTimestamp = null;
                                    _photoAddress = null;
                                  }),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Show GPS coordinates if available
                    if (_photoLatitude != null && _photoLongitude != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_photoAddress != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF10B981),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _photoAddress!,
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.gps_fixed,
                                  color: Color(0xFF10B981),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'GPS: ${_photoLatitude!.toStringAsFixed(6)}, ${_photoLongitude!.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_photoTimestamp != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF10B981),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatTimestamp(_photoTimestamp!),
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],

                  OutlinedButton.icon(
                    onPressed: _showPhotoOptions,
                    icon: Icon(_photo == null ? Icons.add_a_photo : Icons.edit),
                    label: Text(_photo == null ? 'Add Photo' : 'Change Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Geo Video (Camera Only)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (_video != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35),
                        ),
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.06),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.videocam, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _video!.path.split(Platform.pathSeparator).last,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Remove video',
                                onPressed: () => setState(() {
                                  _videoController?.dispose();
                                  _videoController = null;
                                  _videoPreviewReady = false;
                                  _video = null;
                                  _videoLatitude = null;
                                  _videoLongitude = null;
                                  _videoTimestamp = null;
                                  _videoAddress = null;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_videoController != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                color: Colors.black,
                                child: _videoPreviewReady
                                    ? AspectRatio(
                                        aspectRatio: _videoController!.value.aspectRatio,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            VideoPlayer(_videoController!),
                                            _buildGeotagOverlay(
                                              accentColor: const Color(0xFF00BCD4),
                                              address: _videoAddress,
                                              latitude: _videoLatitude,
                                              longitude: _videoLongitude,
                                              timestamp: _videoTimestamp,
                                            ),
                                            Align(
                                              alignment: Alignment.center,
                                              child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (_videoController!.value.isPlaying) {
                                                      _videoController!.pause();
                                                    } else {
                                                      _videoController!.play();
                                                    }
                                                  });
                                                },
                                                iconSize: 44,
                                                color: Colors.white,
                                                icon: Icon(
                                                  _videoController!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : SizedBox(
                                        height: 180,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            const Center(child: CircularProgressIndicator()),
                                            _buildGeotagOverlay(
                                              accentColor: const Color(0xFF00BCD4),
                                              address: _videoAddress,
                                              latitude: _videoLatitude,
                                              longitude: _videoLongitude,
                                              timestamp: _videoTimestamp,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          if (_videoLatitude != null && _videoLongitude != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'GPS: ${_videoLatitude!.toStringAsFixed(6)}, ${_videoLongitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          if (_videoAddress != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _videoAddress!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          if (_videoTimestamp != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(_videoTimestamp!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  OutlinedButton.icon(
                    onPressed: _captureVideoWithGeo,
                    icon: const Icon(Icons.videocam),
                    label: Text(_video == null ? 'Capture Geo Video' : 'Recapture Geo Video'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Complaint'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
