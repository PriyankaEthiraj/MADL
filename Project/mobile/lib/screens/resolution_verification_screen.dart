import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../services/auth_service.dart';
import 'geo_camera_screen.dart';

class ResolutionVerificationScreen extends StatefulWidget {
  const ResolutionVerificationScreen({
    super.key,
    required this.complaint,
  });

  final Map<String, dynamic> complaint;

  @override
  State<ResolutionVerificationScreen> createState() => _ResolutionVerificationScreenState();
}

class _ResolutionVerificationScreenState extends State<ResolutionVerificationScreen> {
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  bool _uploading = false;

  String? _imageProofUrl;
  File? _imageProofFile;
  String? _videoProofUrl;
  File? _videoProofFile;
  double? _lat;
  double? _lng;
  String? _geoAddress;
  DateTime? _geoTimestamp;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  String? _videoError;

  String _formatDateDdMmYyyy(DateTime date) {
    final dd = '${date.day}'.padLeft(2, '0');
    final mm = '${date.month}'.padLeft(2, '0');
    final yyyy = '${date.year}';
    return '$dd-$mm-$yyyy';
  }

  String get _dateDisplay => _formatDateDdMmYyyy(DateTime.now());
  String get _dateIso => DateTime.now().toIso8601String();

  int get _complaintId => (widget.complaint['id'] as int?) ?? 0;

  String get _departmentName {
    final auth = context.read<AuthService>();
    return '${widget.complaint['department_name'] ?? auth.user?['department_name'] ?? auth.user?['name'] ?? 'Department'}';
  }

  String get _originalDescription => '${widget.complaint['description'] ?? ''}';

  String _formatGeoTimestamp(DateTime date) {
    final dd = '${date.day}'.padLeft(2, '0');
    final mm = '${date.month}'.padLeft(2, '0');
    final yyyy = '${date.year}';
    final hh = '${date.hour}'.padLeft(2, '0');
    final min = '${date.minute}'.padLeft(2, '0');
    final ss = '${date.second}'.padLeft(2, '0');
    return '$dd-$mm-$yyyy $hh:$min:$ss';
  }

  Widget _buildGeotagOverlay() {
    if (_lat == null || _lng == null) return const SizedBox.shrink();

    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF10B981), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_geoAddress != null && _geoAddress!.trim().isNotEmpty)
                    Text(
                      _geoAddress!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    'GPS: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_geoTimestamp != null)
                    Text(
                      _formatGeoTimestamp(_geoTimestamp!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImagePreviewDialog() async {
    if (_imageProofFile == null || !mounted) return;

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
                    _imageProofFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                _buildGeotagOverlay(),
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

  Future<void> _showVideoPreviewDialog() async {
    if (_videoController == null || !_videoReady || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video preview is not ready yet')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    _buildGeotagOverlay(),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: IconButton(
                          iconSize: 56,
                          color: Colors.white,
                          onPressed: () {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                            setState(() {});
                            setDialogState(() {});
                          },
                          icon: Icon(
                            _videoController!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                          ),
                        ),
                      ),
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
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _uploadProofFile(String filePath, {required String label}) async {
    final auth = context.read<AuthService>();
    setState(() => _uploading = true);

    try {
      final response = await auth.api.uploadFile(
        path: '/complaints/upload-proof',
        filePath: filePath,
        fieldName: 'proof',
      );

      final data = Map<String, dynamic>.from(response['data'] ?? response);
      final url = (data['url'] ?? '').toString();
      if (url.isEmpty) {
        throw Exception('Upload did not return a URL');
      }

      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label uploaded')),
      );
      return url;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proof upload failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _captureImage() async {
    final result = await Navigator.push<GeoCameraResult>(
      context,
      MaterialPageRoute(builder: (_) => const GeoCameraScreen()),
    );
    if (result == null) return;

    final uploaded = await _uploadProofFile(result.imagePath, label: 'Photo proof');
    if (uploaded == null || uploaded.isEmpty) return;

    setState(() {
      _imageProofUrl = uploaded;
      _imageProofFile = File(result.imagePath);
      _lat = result.latitude;
      _lng = result.longitude;
      _geoAddress = result.address;
      _geoTimestamp = result.timestamp;
    });
  }

  Future<void> _captureVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.camera);
    if (video == null) return;

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final uploaded = await _uploadProofFile(video.path, label: 'Video proof');
    if (uploaded == null || uploaded.isEmpty) return;

    final controller = VideoPlayerController.file(File(video.path));
    try {
      await controller.initialize();
      await controller.setLooping(true);
    } catch (err) {
      _videoError = err.toString();
    }

    setState(() {
      _videoProofUrl = uploaded;
      _videoProofFile = File(video.path);
      _lat = position.latitude;
      _lng = position.longitude;
      _geoAddress = null;
      _geoTimestamp = DateTime.now();
      _videoController?.dispose();
      _videoController = controller;
      _videoReady = _videoError == null;
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final resolutionDescription = _descriptionController.text.trim();

    if (resolutionDescription.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resolution description must be at least 10 characters')),
      );
      return;
    }
    final hasImage = _imageProofUrl != null && _imageProofUrl!.isNotEmpty;
    final hasVideo = _videoProofUrl != null && _videoProofUrl!.isNotEmpty;
    if (!hasImage && !hasVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture image or video proof using camera to continue')),
      );
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geo-location missing. Please retry capture.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final verificationResponse = await auth.api.post('/complaints/verify-resolution', {
        'complaintId': _complaintId,
        'originalDescription': _originalDescription,
        'resolutionDescription': resolutionDescription,
        'departmentName': _departmentName,
        'resolutionDate': _dateIso,
        'proofType': hasImage ? 'image' : 'video',
        'proofUrl': hasImage ? _imageProofUrl : _videoProofUrl,
        'imageUrl': _imageProofUrl,
        'videoUrl': _videoProofUrl,
        'geoLocation': {
          'lat': _lat,
          'lng': _lng,
          'address': _geoAddress,
          'captured_at': _geoTimestamp?.toIso8601String(),
        },
      });

      final verification = Map<String, dynamic>.from(
        verificationResponse['complaint_id'] != null ? verificationResponse : verificationResponse['data'] ?? verificationResponse,
      );

      if ('${verification['status']}' == 'Pending Citizen Verification') {
        final proofJson = {
          'complaint_id': verification['complaint_id'],
          'department': verification['department'],
          'resolution_description': resolutionDescription,
          'proof_type': verification['proof_type'],
          'proof_url': verification['proof_url'],
          'proofs': verification['proofs'],
          'geo_location': verification['geo_location'],
          'date': verification['date'],
          'status': verification['status'],
        };

        await auth.api.post('/complaints/$_complaintId/status', {
          'status': 'Pending Citizen Verification',
          'remark': 'RESOLUTION_PROOF:${jsonEncode(proofJson)}',
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted for citizen approval')),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${verification['remarks'] ?? 'Pending verification'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resolution failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _readonlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resolution Verification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _readonlyField('Complaint ID', '$_complaintId'),
                    const SizedBox(height: 14),
                    _readonlyField('Department Name', _departmentName),
                    const SizedBox(height: 14),
                    _readonlyField('Date', _dateDisplay),
                    const SizedBox(height: 14),
                    _readonlyField('Original Complaint Description', _originalDescription),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resolution Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'At least 10 characters',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Proof Capture (camera only)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _uploading || _submitting ? null : _captureImage,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Capture Image'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _uploading || _submitting ? null : _captureVideo,
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('Record Video'),
                        ),
                      ],
                    ),
                    if (_uploading) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(),
                    ],
                    if (_imageProofFile != null || _videoProofFile != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_imageProofFile != null) ...[
                        Text('Image proof', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showImagePreviewDialog,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.file(
                                  _imageProofFile!,
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  left: 10,
                                  top: 10,
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
                                _buildGeotagOverlay(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_videoProofFile != null)
                        GestureDetector(
                          onTap: _showVideoPreviewDialog,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _videoController != null && _videoReady
                                ? AspectRatio(
                                    aspectRatio: _videoController!.value.aspectRatio,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        VideoPlayer(_videoController!),
                                        Positioned(
                                          left: 10,
                                          top: 10,
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
                                        _buildGeotagOverlay(),
                                        Center(
                                          child: IconButton(
                                            iconSize: 52,
                                            color: Colors.white,
                                            onPressed: () {
                                              if (_videoController!.value.isPlaying) {
                                                _videoController!.pause();
                                              } else {
                                                _videoController!.play();
                                              }
                                              setState(() {});
                                            },
                                            icon: Icon(
                                              _videoController!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(
                                    height: 240,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Center(
                                          child: _videoError == null
                                              ? const CircularProgressIndicator()
                                              : Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Text(
                                                    'Video preview unavailable',
                                                    style: const TextStyle(color: Colors.white),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                        ),
                                        _buildGeotagOverlay(),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      const SizedBox(height: 8),
                        Text('Proof captured: ${[_imageProofUrl != null ? "image" : null, _videoProofUrl != null ? "video" : null].whereType<String>().join(", ")}'),
                      const SizedBox(height: 4),
                      Text('Geo: ${_lat?.toStringAsFixed(6)}, ${_lng?.toStringAsFixed(6)}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submitting || _uploading ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_submitting ? 'Submitting...' : 'Submit for Citizen Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}