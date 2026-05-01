import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';

class ComplaintService with ChangeNotifier {
  ComplaintService(this.api);

  final ApiService api;
  List<Map<String, dynamic>> complaints = [];

  Future<void> loadComplaints() async {
    final res = await api.get('/complaints');
    final items = List<Map<String, dynamic>>.from(res['data']['items']);
    
    // Convert relative photo and video URLs to absolute URLs
    final serverUrl = api.baseUrl.replaceAll('/api', '');
    complaints = items.map((complaint) {
      if (complaint['photo_url'] != null && complaint['photo_url'] != '') {
        complaint['photo_url'] = '$serverUrl${complaint['photo_url']}';
      }
      if (complaint['video_url'] != null && complaint['video_url'] != '') {
        complaint['video_url'] = '$serverUrl${complaint['video_url']}';
      }
      return complaint;
    }).toList();
    
    notifyListeners();
  }

  Future<void> submitComplaint({
    required String category,
    String? subCategory,
    required String description,
    required String location,
    String? photoPath,
    String? videoPath,
    double? photoLatitude,
    double? photoLongitude,
    DateTime? photoTimestamp,
    String? photoLocationName,
    double? videoLatitude,
    double? videoLongitude,
    DateTime? videoTimestamp,
    String? videoLocationName,
  }) async {
    try {
      // Combine category and subcategory into type field
      String type = category;
      if (subCategory != null && subCategory.isNotEmpty) {
        type = '$category - $subCategory';
      }

      final usesTunnel = api.baseUrl.contains('tunnelmole') ||
          api.baseUrl.contains('loca.lt') ||
          api.baseUrl.contains('trycloudflare.com');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${api.baseUrl}/complaints'),
      );
      request.headers['Authorization'] = 'Bearer ${api.token}';
      request.fields['type'] = type;
      request.fields['description'] = description;
      request.fields['location'] = location;
      
      // Add photo file with geotag data (optional)
      if (photoPath != null && photoPath.isNotEmpty) {
        final photoExtension = photoPath.toLowerCase().split('.').last;
        String photoMimeType = 'image/jpeg';

        if (photoExtension == 'png') {
          photoMimeType = 'image/png';
        } else if (photoExtension == 'gif') {
          photoMimeType = 'image/gif';
        } else if (photoExtension == 'webp') {
          photoMimeType = 'image/webp';
        }

        final photoFile = await http.MultipartFile.fromPath(
          'photo',
          photoPath,
          contentType: MediaType.parse(photoMimeType),
        );
        request.files.add(photoFile);

        // Add photo geotag data only when photo exists
        if (photoLatitude != null) {
          request.fields['photo_latitude'] = photoLatitude.toString();
        }
        if (photoLongitude != null) {
          request.fields['photo_longitude'] = photoLongitude.toString();
        }
        if (photoTimestamp != null) {
          request.fields['photo_timestamp'] = photoTimestamp.toUtc().toIso8601String();
        }
        if (photoLocationName != null) {
          request.fields['photo_location_name'] = photoLocationName;
        }
      }
      
      // Public tunnels have strict body limits; skip video upload there.
      // The complaint can still be submitted with the photo attachment.
      if (!usesTunnel && videoPath != null && videoPath.isNotEmpty) {
        final videoExtension = videoPath.toLowerCase().split('.').last;
        String videoMimeType = 'video/mp4';
        
        if (videoExtension == 'webm') {
          videoMimeType = 'video/webm';
        } else if (videoExtension == 'mov') {
          videoMimeType = 'video/quicktime';
        } else if (videoExtension == 'avi') {
          videoMimeType = 'video/x-msvideo';
        }
        
        final videoFile = await http.MultipartFile.fromPath(
          'video',
          videoPath,
          contentType: MediaType.parse(videoMimeType),
        );
        request.files.add(videoFile);
        
        // Add video geotag data
        if (videoLatitude != null) {
          request.fields['video_latitude'] = videoLatitude.toString();
        }
        if (videoLongitude != null) {
          request.fields['video_longitude'] = videoLongitude.toString();
        }
        if (videoTimestamp != null) {
          request.fields['video_timestamp'] = videoTimestamp.toUtc().toIso8601String();
        }
        if (videoLocationName != null) {
          request.fields['video_location_name'] = videoLocationName;
        }
      } else if (usesTunnel && videoPath != null && videoPath.isNotEmpty) {
        request.fields['video_skipped'] = 'true';
      }
      
      final response = await request.send();
      if (response.statusCode >= 400) {
        final responseBody = await response.stream.bytesToString();
        // Try to parse JSON error
        try {
          final jsonError = jsonDecode(responseBody);
          throw Exception(jsonError['message'] ?? 'Failed to submit complaint');
        } catch (_) {
          throw Exception('Failed to submit complaint: $responseBody');
        }
      }
      
      await loadComplaints();
    } catch (e) {
      throw Exception('Failed to submit complaint: $e');
    }
  }

  Future<Map<String, dynamic>> getComplaint(int id) async {
    final res = await api.get('/complaints/$id');
    final data = res['data'];
    final serverUrl = api.baseUrl.replaceAll('/api', '');
    
    // Backend returns { complaint: {...}, logs: [...] }
    final complaint = data['complaint'] ?? {};
    final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
    
    // Map status logs to expected format
    final mappedLogs = logs.map((log) => {
      'status': log['status'],
      'changedAt': log['updated_at'],
      'changedBy': log['updated_by_name'],
      'remark': log['remark'],
    }).toList();
    
    // Map complaint fields to UI-expected format
    // Convert relative photo URL to absolute URL
    String? photoUrl;
    if (complaint['photo_url'] != null && complaint['photo_url'] != '') {
      photoUrl = '$serverUrl${complaint['photo_url']}';
    }
    
    // Convert relative video URL to absolute URL
    String? videoUrl;
    if (complaint['video_url'] != null && complaint['video_url'] != '') {
      videoUrl = '$serverUrl${complaint['video_url']}';
    }
    
    return {
      'id': complaint['id'],
      'type': complaint['type'],
      'description': complaint['description'],
      'location': complaint['location'],
      'status': complaint['status'],
      'photoUrl': photoUrl,
      'photoLatitude': complaint['photo_latitude'],
      'photoLongitude': complaint['photo_longitude'],
      'photoTimestamp': complaint['photo_timestamp'],
      'photoLocationName': complaint['photo_location_name'],
      'videoUrl': videoUrl,
      'videoLatitude': complaint['video_latitude'],
      'videoLongitude': complaint['video_longitude'],
      'videoTimestamp': complaint['video_timestamp'],
      'videoLocationName': complaint['video_location_name'],
      'citizenName': complaint['citizen_name'],
      'assignedDepartmentName': complaint['department_name'],
      'createdAt': complaint['created_at'],
      'updatedAt': complaint['updated_at'],
      'statusLogs': mappedLogs,
      'serverBaseUrl': serverUrl,
    };
  }

  Future<void> submitFeedback(int complaintId, int rating, String comment) async {
    await api.post('/complaints/$complaintId/feedback', {
      'rating': rating,
      'comment': comment
    });
  }

  Future<void> reviewProof(int complaintId, {required bool approve}) async {
    await api.post('/complaints/$complaintId/approve-proof', {
      'action': approve ? 'approve' : 'reject',
    });
  }

  Future<void> approveProof(int complaintId) async {
    await reviewProof(complaintId, approve: true);
  }
}
