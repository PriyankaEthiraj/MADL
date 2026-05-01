import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import 'feedback_screen.dart';

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  String? _videoError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic>? _extractResolutionProof() {
    final logs = (data?['statusLogs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final log in logs.reversed) {
      final remark = '${log['remark'] ?? ''}';
      if (!remark.startsWith('RESOLUTION_PROOF:')) continue;
      final jsonPart = remark.substring('RESOLUTION_PROOF:'.length);
      try {
        final decoded = jsonDecode(jsonPart);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _extractResolutionProofs() {
    final proof = _extractResolutionProof();
    if (proof == null) return [];

    final proofs = proof['proofs'];
    if (proofs is List) {
      final mapped = proofs.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      return _dedupeProofEntries(mapped);
    }

    final proofUrl = '${proof['proof_url'] ?? ''}';
    final proofType = '${proof['proof_type'] ?? ''}';
    if (proofUrl.isEmpty) return [];
    return _dedupeProofEntries([
      {
        'type': proofType,
        'url': proofUrl,
      }
    ]);
  }

  List<Map<String, dynamic>> _dedupeProofEntries(List<Map<String, dynamic>> items) {
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];

    for (final item in items) {
      final key = '${item['url'] ?? ''}'.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      deduped.add(item);
    }

    return deduped;
  }

  String _absoluteMediaUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    final parsed = Uri.tryParse(rawUrl);
    if (parsed != null && parsed.hasScheme) return rawUrl;

    final base = '${data?['serverBaseUrl'] ?? ''}'.trim();
    if (base.isEmpty) return rawUrl;
    return '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
  }

  bool _canReviewProof() {
    final role = context.read<AuthService>().user?['role']?.toString().toLowerCase();
    final status = (data?['status']?.toString().toLowerCase() ?? '');
    return role == 'citizen' &&
        (status == 'pending citizen verification' || status == 'resolving verification');
  }

  bool _canLeaveFeedback() {
    final role = context.read<AuthService>().user?['role']?.toString().toLowerCase();
    final status = (data?['status']?.toString().toLowerCase() ?? '');
    return role == 'citizen' &&
        (status == 'solved' || status == 'resolved' || status == 'closed');
  }

  Widget _buildImagePreview(String imageUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.grey[500], size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image preview',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
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
                    'Image preview',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImagePreviewDialog(String imageUrl) async {
    if (imageUrl.isEmpty || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 320,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text('Failed to load image preview'),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
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
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: IconButton(
                          iconSize: 56,
                          color: Colors.white,
                          onPressed: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
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
                        color: Colors.black.withValues(alpha: 0.55),
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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _load();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _setupVideoPreview(String? videoUrl) async {
    _videoController?.dispose();
    _videoController = null;
    _videoReady = false;
    _videoError = null;

    if (videoUrl == null || videoUrl.isEmpty) return;

    try {
      final uri = Uri.parse(videoUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode >= 400) {
        throw Exception('Video download failed: HTTP ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'complaint_${widget.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final controller = VideoPlayerController.file(file);
      await controller.initialize().timeout(const Duration(seconds: 12));
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _videoReady = true;
        _videoError = null;
      });
    } catch (err) {
      _videoController?.dispose();
      if (!mounted) return;
      setState(() {
        _videoController = null;
        _videoReady = false;
        _videoError = err.toString();
      });
    }
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) return 'N/A';
    final dateTime = DateTime.tryParse(value.toString());
    if (dateTime == null) return value.toString();
    final local = dateTime.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min:$ss';
  }

  LatLng? _parseLatLng(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(',');
    if (parts.length < 2) return null;

    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Widget _buildLocationMap(String? locationText) {
    final point = _parseLatLng(locationText);
    if (point == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 220,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartcity.mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final res = await context.read<ComplaintService>().getComplaint(widget.id);
      await _setupVideoPreview(res['videoUrl']?.toString());
      setState(() {
        data = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return const Color(0xFF9CA3AF);
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in progress':
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'pending citizen verification':
      case 'resolving verification':
        return const Color(0xFFEA580C);
      case 'solved':
      case 'resolved':
      case 'closed':
        return const Color(0xFF10B981);
      case 'reopened':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null || status.isEmpty) return Icons.info_outline;
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'in progress':
      case 'in_progress':
        return Icons.work_outline;
      case 'pending citizen verification':
      case 'resolving verification':
        return Icons.verified_outlined;
      case 'solved':
      case 'resolved':
      case 'closed':
        return Icons.check_circle_outline;
      case 'reopened':
        return Icons.replay_circle_filled_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _statusLabel(String? status) {
    final value = '${status ?? ''}'.toLowerCase();
    if (value == 'resolved' || value == 'solved' || value == 'closed') return 'Solved';
    if (value == 'in progress' || value == 'in_progress') return 'In Progress';
    if (value == 'pending citizen verification' || value == 'resolving verification') return 'Resolving Verification';
    if (value == 'pending') return 'Pending';
    if (value == 'reopened') return 'Reopened';
    return status?.toString() ?? 'Unknown';
  }

  Widget _buildInfoSection(String title, String? content, {IconData? icon}) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveProof() async {
    try {
      await context.read<ComplaintService>().reviewProof(widget.id, approve: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof approved successfully')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectProof() async {
    try {
      await context.read<ComplaintService>().reviewProof(widget.id, approve: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof rejected. Complaint reopened.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Complaint Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('Failed to load complaint'))
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Status Card with Icon
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getStatusColor(data!['status'] as String?),
                                _getStatusColor(data!['status'] as String?).withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                color: _getStatusColor(data!['status'] as String?).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                            child: Column(
                              children: [
                                Icon(
                                  _getStatusIcon(data!['status'] as String?),
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Status: ${_statusLabel(data!['status']?.toString())}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Main Content Card
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Complaint ID
                                    Text(
                                      'Complaint #${data!['id']?.toString() ?? 'N/A'}',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Info Sections
                                    _buildInfoSection(
                                      'Type',
                                      data!['type']?.toString(),
                                      icon: Icons.category_outlined,
                                    ),
                                    _buildInfoSection(
                                      'Description',
                                      data!['description']?.toString(),
                                      icon: Icons.description_outlined,
                                    ),
                                    _buildInfoSection(
                                      'Location',
                                      data!['location']?.toString(),
                                      icon: Icons.location_on_outlined,
                                    ),
                                    _buildLocationMap(data!['location']?.toString()),
                                    
                                    // Assigned To (if available)
                                    if (data!['assignedDepartmentName'] != null)
                                      _buildInfoSection(
                                        'Assigned To',
                                        data!['assignedDepartmentName']?.toString(),
                                        icon: Icons.business_outlined,
                                      ),

                                    if (_extractResolutionProof() != null)
                                      Builder(
                                        builder: (context) {
                                          final proof = _extractResolutionProof()!;
                                          final proofs = _extractResolutionProofs();

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 16),
                                              Text(
                                                'Resolution Verification',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              _buildInfoSection(
                                                'Resolution Description',
                                                proof['resolution_description']?.toString(),
                                                icon: Icons.checklist,
                                              ),
                                              _buildInfoSection(
                                                'Geo Location',
                                                'Lat: ${proof['geo_location']?['lat'] ?? '-'}, Lng: ${proof['geo_location']?['lng'] ?? '-'}',
                                                icon: Icons.location_on,
                                              ),
                                              _buildInfoSection(
                                                'Geo Address',
                                                proof['geo_location']?['address']?.toString(),
                                                icon: Icons.place,
                                              ),
                                              _buildInfoSection(
                                                'Captured At',
                                                proof['geo_location']?['captured_at'] == null
                                                    ? null
                                                    : _formatTimestamp(proof['geo_location']?['captured_at']),
                                                icon: Icons.access_time,
                                              ),
                                              _buildInfoSection(
                                                'Verification Date',
                                                proof['date']?.toString(),
                                                icon: Icons.calendar_today,
                                              ),
                                              if (proofs.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                ...proofs.map((item) {
                                                  final proofType = '${item['type'] ?? ''}'.toLowerCase();
                                                  final proofUrl = _absoluteMediaUrl('${item['url'] ?? ''}');
                                                  final isImage = proofType.contains('image');
                                                  final isVideo = proofType.contains('video');

                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 12),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '${item['type'] ?? 'proof'} proof',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        if (proofUrl.isNotEmpty && isImage)
                                                          InkWell(
                                                            borderRadius: BorderRadius.circular(12),
                                                            onTap: () => _showImagePreviewDialog(proofUrl),
                                                            child: _buildImagePreview(proofUrl),
                                                          )
                                                        else if (proofUrl.isNotEmpty && isVideo)
                                                          _NetworkVideoProofPreview(url: proofUrl)
                                                        else if (proofUrl.isNotEmpty)
                                                          Container(
                                                            height: 120,
                                                            width: double.infinity,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey[200],
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            alignment: Alignment.center,
                                                            child: const Text('Unsupported proof type'),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    
                                    // Photo (if available)
                                    if (data!['photoUrl'] != null && data!['photoUrl'] != '') ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        'Photo',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => _showImagePreviewDialog(data!['photoUrl']?.toString() ?? ''),
                                        child: _buildImagePreview(data!['photoUrl']?.toString() ?? ''),
                                      ),
                                      // Photo Geotag Info
                                      if (data!['photoLatitude'] != null || data!['photoLongitude'] != null || data!['photoTimestamp'] != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (data!['photoLatitude'] != null)
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Lat: ${data!['photoLatitude']}, Lon: ${data!['photoLongitude']}',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (data!['photoLocationName'] != null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.place, size: 16, color: Theme.of(context).colorScheme.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        data!['photoLocationName']?.toString() ?? 'N/A',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              if (data!['photoTimestamp'] != null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.primary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _formatTimestamp(data!['photoTimestamp']),
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                    
                                    // Video (if available)
                                    if (data!['videoUrl'] != null && data!['videoUrl'] != '') ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        'Video',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: _videoController != null && _videoReady ? _showVideoPreviewDialog : null,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: _videoController != null && _videoReady
                                                ? AspectRatio(
                                                    aspectRatio: _videoController!.value.aspectRatio,
                                                    child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        VideoPlayer(_videoController!),
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
                                                        Center(
                                                          child: IconButton(
                                                            iconSize: 48,
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
                                                              _videoController!.value.isPlaying
                                                                  ? Icons.pause_circle
                                                                  : Icons.play_circle,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : SizedBox(
                                                    height: 200,
                                                    child: Center(
                                                      child: _videoError == null
                                                          ? const CircularProgressIndicator()
                                                          : Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                const Icon(Icons.error_outline, color: Colors.white70),
                                                                const SizedBox(height: 8),
                                                                const Text(
                                                                  'Unable to load video preview',
                                                                  style: TextStyle(color: Colors.white70),
                                                                ),
                                                                const SizedBox(height: 6),
                                                                Text(
                                                                  _videoError!,
                                                                  textAlign: TextAlign.center,
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                                ),
                                                                const SizedBox(height: 10),
                                                                OutlinedButton.icon(
                                                                  onPressed: () => _setupVideoPreview(data!['videoUrl']?.toString()),
                                                                  icon: const Icon(Icons.refresh),
                                                                  label: const Text('Retry'),
                                                                ),
                                                              ],
                                                            ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      // Video Geotag Info
                                      if (data!['videoLatitude'] != null || data!['videoLongitude'] != null || data!['videoTimestamp'] != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (data!['videoLatitude'] != null)
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.secondary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Lat: ${data!['videoLatitude']}, Lon: ${data!['videoLongitude']}',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (data!['videoLocationName'] != null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.place, size: 16, color: Theme.of(context).colorScheme.secondary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        data!['videoLocationName']?.toString() ?? 'N/A',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              if (data!['videoTimestamp'] != null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.secondary),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _formatTimestamp(data!['videoTimestamp']),
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Timeline Section
                          if (data!['statusLogs'] != null && (data!['statusLogs'] as List).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timeline,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Status Timeline',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      ...List.generate(
                                        (data!['statusLogs'] as List).length,
                                        (index) {
                                          final log = (data!['statusLogs'] as List)[index];
                                          final isLast = index == (data!['statusLogs'] as List).length - 1;
                                          final statusColor = _getStatusColor(log['status'] as String?);
                                          
                                          return IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Timeline indicator
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: statusColor,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 2,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                          color: statusColor.withValues(alpha: 0.3),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (!isLast)
                                                      Expanded(
                                                        child: Container(
                                                          width: 2,
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment.topCenter,
                                                              end: Alignment.bottomCenter,
                                                              colors: [
                                                                statusColor.withValues(alpha: 0.5),
                                                                statusColor.withValues(alpha: 0.1),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                // Content
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(bottom: 24.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                          color: statusColor.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: statusColor.withValues(alpha: 0.3),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            _statusLabel(log['status']?.toString()),
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: statusColor,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          _formatTimestamp(log['changedAt']),
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                color: Colors.grey[600],
                                                              ),
                                                        ),
                                                        if (log['changedBy'] != null) ...[
                                                          const SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.person_outline,
                                                                size: 14,
                                                                color: Colors.grey[600],
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                'by ${log['changedBy']}',
                                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                      color: Colors.grey[600],
                                                                      fontStyle: FontStyle.italic,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: data != null
          ? Builder(
              builder: (context) {
                if (_canReviewProof()) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'reject-proof',
                        onPressed: _rejectProof,
                        icon: const Icon(Icons.close_outlined),
                        label: const Text('Reject'),
                        backgroundColor: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      FloatingActionButton.extended(
                        heroTag: 'approve-proof',
                        onPressed: _approveProof,
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Approve'),
                        backgroundColor: Colors.orange,
                      ),
                    ],
                  );
                }
                if (_canLeaveFeedback()) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackScreen(id: widget.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Leave Feedback'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  );
                }
                return const SizedBox.shrink();
              },
            )
          : null,
    );
  }
}

class _NetworkVideoProofPreview extends StatefulWidget {
  const _NetworkVideoProofPreview({required this.url});

  final String url;

  @override
  State<_NetworkVideoProofPreview> createState() => _NetworkVideoProofPreviewState();
}

class _NetworkVideoProofPreviewState extends State<_NetworkVideoProofPreview> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize().timeout(const Duration(seconds: 20));
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isReady = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isReady = false;
      });
    }
  }

  Future<void> _openFullscreen() async {
    if (_controller == null || !_isReady || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              Positioned.fill(
                child: Center(
                  child: IconButton(
                    iconSize: 56,
                    color: Colors.white,
                    onPressed: () {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                      setState(() {});
                    },
                    icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
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
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isReady ? _openFullscreen : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _isReady && _controller != null
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(_controller!),
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
                      Center(
                        child: IconButton(
                          iconSize: 48,
                          color: Colors.white,
                          onPressed: () {
                            if (_controller!.value.isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                            setState(() {});
                          },
                          icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 180,
                  child: Center(
                    child: _error == null
                        ? const CircularProgressIndicator()
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white70),
                                const SizedBox(height: 8),
                                const Text(
                                  'Unable to load proof video',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
        ),
      ),
    );
  }
}
