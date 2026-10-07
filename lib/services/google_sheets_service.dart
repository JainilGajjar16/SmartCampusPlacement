import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/app_strings.dart';
import '../models/application.dart';
import '../models/job.dart';
import '../models/notification_item.dart';
import '../models/recruiter_feedback.dart';
import '../models/student_profile.dart';

/// Single API service responsible for communicating with the existing
/// Google Apps Script Web App backend.
class GoogleSheetsService {
  /// Existing Google Apps Script Web App API endpoint URL.
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbw_8wTp2w8_TPM_fCDKfrgyDwQHKa-K8_aW8x7lM1EvX83EIrkmssb871ScxOi1dJGs/exec';

  /// Conservative chunk size (3 KB = 3000 bytes) chosen for query parameter safety
  /// and reliable execution within Apps Script URL limits.
  static const int resumeChunkSizeBytes = 3000;

  static const Duration _timeout = Duration(seconds: 20);

  /// Tests API connectivity to the Google Apps Script Web App.
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Connection timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': AppStrings.apiServerError};
    }
  }

  /// Authenticates user against the existing Apps Script backend.
  /// Expects action=login, userId, and password.
  Future<Map<String, dynamic>> loginUser({
    required String userId,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'login',
          'userId': userId.trim(),
          'password': password,
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during login.',
      };
    }
  }

  /// Registers a new user on the existing Google Apps Script & Google Sheet backend.
  /// Sends action=register, userId, name, email, mobile, password, role, github, linkedin.
  Future<Map<String, dynamic>> registerUser({
    required String userId,
    required String name,
    required String email,
    required String mobile,
    required String password,
    required String role,
    String github = '',
    String linkedin = '',
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'register',
          'userId': userId.trim(),
          'name': name.trim(),
          'email': email.trim(),
          'mobile': mobile.trim(),
          'password': password,
          'role': role.trim(),
          'github': github,
          'linkedin': linkedin,
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Registration timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during registration.',
      };
    }
  }

  /// Verifies User ID and registered Email against the Google Apps Script backend.
  /// Expects action=verify_reset_user, userId, and email.
  Future<Map<String, dynamic>> verifyResetUser({
    required String userId,
    required String email,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'verify_reset_user',
          'userId': userId.trim(),
          'email': email.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Account verification timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during account verification.',
      };
    }
  }

  /// Resets user password on the Google Apps Script backend.
  /// Expects action=reset_password, userId, email, and newPassword.
  Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String email,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'reset_password',
          'userId': userId.trim(),
          'email': email.trim(),
          'newPassword': newPassword,
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Password reset timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during password reset.',
      };
    }
  }

  /// Fetches a student profile from the existing Google Apps Script StudentProfiles sheet.
  /// Expects action=get_student_profile and userId.
  Future<Map<String, dynamic>> getStudentProfile({
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'get_student_profile',
          'userId': userId.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Profile fetch timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to retrieve profile data.'};
    }
  }

  /// Saves or updates a student profile on the existing Google Apps Script StudentProfiles sheet.
  /// Sends action=save_student_profile and profile parameters.
  Future<Map<String, dynamic>> saveStudentProfile(
    StudentProfile profile,
  ) async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: profile.toQueryParameters());

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Profile save timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to save profile changes.'};
    }
  }

  /// Uploads an individual web-safe base64 encoded chunk of a resume PDF.
  /// Sends action=upload_chunk, uploadId, userId, chunkIndex (1-indexed), totalChunks, fileName, chunk.
  Future<Map<String, dynamic>> uploadResumeChunk({
    required String uploadId,
    required String userId,
    required int chunkIndex,
    required int totalChunks,
    required String fileName,
    required String chunk,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'upload_chunk',
          'uploadId': uploadId,
          'userId': userId.trim(),
          'chunkIndex': chunkIndex.toString(),
          'totalChunks': totalChunks.toString(),
          'fileName': fileName,
          'chunk': chunk,
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Chunk $chunkIndex upload timed out.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to upload chunk $chunkIndex.',
      };
    }
  }

  /// Finalizes resume upload after all chunks have been received by the backend.
  /// Sends action=finish_upload, uploadId, userId, fileName, mimeType, totalChunks.
  Future<Map<String, dynamic>> finishResumeUpload({
    required String uploadId,
    required String userId,
    required String fileName,
    String mimeType = 'application/pdf',
    required int totalChunks,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'finish_upload',
          'uploadId': uploadId,
          'userId': userId.trim(),
          'fileName': fileName,
          'mimeType': mimeType,
          'totalChunks': totalChunks.toString(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Resume finalization timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to finalize resume upload.'};
    }
  }

  /// Fetches available jobs from the Google Apps Script backend.
  /// Defaults to active jobs only. Optionally includes inactive jobs or filters by company.
  /// Sends action=get_jobs.
  Future<Map<String, dynamic>> getJobs({
    bool includeInactive = false,
    String? companyId,
    String? company,
  }) async {
    try {
      final queryParams = <String, String>{'action': 'get_jobs'};
      if (includeInactive) {
        queryParams['includeInactive'] = 'true';
      }
      if (companyId != null && companyId.trim().isNotEmpty) {
        queryParams['companyId'] = companyId.trim();
      }
      if (company != null && company.trim().isNotEmpty) {
        queryParams['company'] = company.trim();
      }

      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(_timeout);

      final result = _parseResponse(response);
      if (result['success'] == true && result['jobs'] is List) {
        final List rawJobs = result['jobs'];
        final List<Job> jobs = rawJobs
            .map((j) => Job.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        return {'success': true, 'jobs': jobs};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to retrieve jobs.',
        'jobs': <Job>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'jobs': <Job>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Jobs fetch timed out. Please try again.',
        'jobs': <Job>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while loading jobs.',
        'jobs': <Job>[],
      };
    }
  }

  /// Fetches complete details of a specific job by jobId.
  /// Sends action=get_job_details and jobId.
  Future<Map<String, dynamic>> getJobDetails(String jobId) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {'action': 'get_job_details', 'jobId': jobId.trim()},
      );

      final response = await http.get(uri).timeout(_timeout);

      final result = _parseResponse(response);
      if (result['success'] == true && result['job'] is Map) {
        final Job job = Job.fromJson(Map<String, dynamic>.from(result['job']));
        return {'success': true, 'job': job};
      }
      return {
        'success': false,
        'message': result['message'] ?? AppStrings.jobNotFound,
      };
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Job details fetch timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while loading job details.',
      };
    }
  }

  /// Submits a job application for a given student userId and jobId.
  /// Sends action=apply_job, userId, and jobId.
  Future<Map<String, dynamic>> applyJob({
    required String userId,
    required String jobId,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'apply_job',
          'userId': userId.trim(),
          'jobId': jobId.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Application submission timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'An unexpected error occurred while submitting your application.',
      };
    }
  }

  /// Fetches list of applications submitted by a specific student userId.
  /// Sends action=get_my_applications and userId.
  Future<List<Application>> getMyApplications(String userId) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'get_my_applications',
          'userId': userId.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      final result = _parseResponse(response);
      if (result['success'] == true && result['applications'] is List) {
        final List rawApps = result['applications'];
        return rawApps
            .map((a) => Application.fromJson(Map<String, dynamic>.from(a)))
            .toList();
      }
      return <Application>[];
    } on SocketException {
      return <Application>[];
    } on TimeoutException {
      return <Application>[];
    } catch (e) {
      return <Application>[];
    }
  }

  /// Fetches list of notifications for a specific student userId.
  /// Sends action=get_notifications and userId.
  Future<Map<String, dynamic>> getNotifications(String userId) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'get_notifications',
          'userId': userId.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);

      if (result['success'] == true && result['notifications'] is List) {
        final List rawNotifs = result['notifications'];
        final List<NotificationItem> notifications = rawNotifs
            .map((n) => NotificationItem.fromJson(Map<String, dynamic>.from(n)))
            .toList();
        final int unreadCount = (result['unreadCount'] is int)
            ? result['unreadCount'] as int
            : int.tryParse(result['unreadCount']?.toString() ?? '0') ?? 0;
        return {
          'success': true,
          'notifications': notifications,
          'unreadCount': unreadCount,
        };
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load notifications.',
        'notifications': <NotificationItem>[],
        'unreadCount': 0,
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'notifications': <NotificationItem>[],
        'unreadCount': 0,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Notification fetch timed out. Please try again.',
        'notifications': <NotificationItem>[],
        'unreadCount': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while loading notifications.',
        'notifications': <NotificationItem>[],
        'unreadCount': 0,
      };
    }
  }

  /// Marks a specific notification (or all notifications if notificationId='all') as read.
  /// Sends action=mark_notification_read, notificationId, and userId.
  Future<Map<String, dynamic>> markNotificationAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'mark_notification_read',
          'notificationId': notificationId.trim(),
          'userId': userId.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update notification status.',
      };
    }
  }

  /// Marks all notifications as read for a given student userId.
  Future<Map<String, dynamic>> markAllNotificationsAsRead(String userId) async {
    return markNotificationAsRead(notificationId: 'all', userId: userId);
  }

  /// Posts a new job opening to the Google Sheets Jobs sheet.
  Future<Map<String, dynamic>> postJob({
    required String title,
    required String company,
    required String location,
    required String skills,
    required String salary,
    required String description,
    String jobType = 'Full-time',
    int? maxHiring,
  }) async {
    try {
      final queryParams = <String, String>{
        'action': 'post_job',
        'title': title.trim(),
        'jobTitle': title.trim(),
        'company': company.trim(),
        'companyName': company.trim(),
        'location': location.trim(),
        'skills': skills.trim(),
        'salary': salary.trim(),
        'description': description.trim(),
        'jobType': jobType.trim(),
      };

      if (maxHiring != null && maxHiring > 0) {
        queryParams['maxHiring'] = maxHiring.toString();
        queryParams['max_hiring'] = maxHiring.toString();
        queryParams['maxNoOfHiring'] = maxHiring.toString();
      }

      final uri = Uri.parse(baseUrl).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Job posting timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to post job opening.'};
    }
  }

  /// Fetches applications submitted for a specific company's jobs from Google Sheets backend.
  Future<Map<String, dynamic>> getCompanyApplications({
    required String companyId,
    String? companyName,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'get_company_applications',
          'companyId': companyId.trim(),
          if (companyName != null && companyName.isNotEmpty)
            'companyName': companyName.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);

      if (result['success'] == true && result['applications'] is List) {
        final List rawApps = result['applications'];
        final List<Map<String, dynamic>> apps = rawApps
            .map((a) => Map<String, dynamic>.from(a))
            .toList();
        return {'success': true, 'applications': apps};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load company applications.',
        'applications': <Map<String, dynamic>>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'applications': <Map<String, dynamic>>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Company applications fetch timed out.',
        'applications': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while loading applications.',
        'applications': <Map<String, dynamic>>[],
      };
    }
  }

  /// Updates an application status in Google Sheets backend.
  Future<Map<String, dynamic>> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'update_application_status',
          'applicationId': applicationId.trim(),
          'status': status.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Status update timed out.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update application status.',
      };
    }
  }

  /// Submits recruiter feedback and rating to Google Sheets backend (Phase 13).
  Future<Map<String, dynamic>> submitRecruiterFeedback({
    required RecruiterFeedback feedback,
  }) async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: feedback.toQueryParameters());

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Feedback submission timed out.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit recruiter feedback.',
      };
    }
  }

  /// Fetches recruiter feedback items from Google Sheets backend (Phase 13).
  Future<Map<String, dynamic>> getRecruiterFeedback({
    String? companyId,
    String? jobId,
    String? studentId,
    String? applicationId,
  }) async {
    try {
      final queryParams = <String, String>{'action': 'get_recruiter_feedback'};
      if (companyId != null && companyId.isNotEmpty) {
        queryParams['companyId'] = companyId.trim();
      }
      if (jobId != null && jobId.isNotEmpty) {
        queryParams['jobId'] = jobId.trim();
      }
      if (studentId != null && studentId.isNotEmpty) {
        queryParams['studentId'] = studentId.trim();
      }
      if (applicationId != null && applicationId.isNotEmpty) {
        queryParams['applicationId'] = applicationId.trim();
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(_timeout);
      final res = _parseResponse(response);

      if (res['success'] == true && res['feedbackList'] is List) {
        final rawList = res['feedbackList'] as List;
        final feedbackItems = rawList
            .map(
              (item) => RecruiterFeedback.fromJson(
                item is Map<String, dynamic> ? item : {},
              ),
            )
            .where((item) => item.applicationId.isNotEmpty)
            .toList();
        return {'success': true, 'feedbackList': feedbackItems};
      } else if (res['feedback'] is List) {
        final rawList = res['feedback'] as List;
        final feedbackItems = rawList
            .map(
              (item) => RecruiterFeedback.fromJson(
                item is Map<String, dynamic> ? item : {},
              ),
            )
            .where((item) => item.applicationId.isNotEmpty)
            .toList();
        return {'success': true, 'feedbackList': feedbackItems};
      }

      return res;
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'feedbackList': <RecruiterFeedback>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Fetching feedback timed out.',
        'feedbackList': <RecruiterFeedback>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch recruiter feedback.',
        'feedbackList': <RecruiterFeedback>[],
      };
    }
  }

  /// Fetches real campus & placement statistics for the Admin Dashboard (Phase 14).
  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_admin_statistics'});

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Fetching statistics timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load admin statistics.'};
    }
  }

  /// Fetches registered company user accounts for the Admin Dashboard (Phase 14B).
  Future<Map<String, dynamic>> getAdminCompanies() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_admin_companies'});

      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);
      if (result['success'] == true && result['companies'] is List) {
        final rawList = result['companies'] as List;
        final companies = rawList
            .map((c) => Map<String, dynamic>.from(c is Map ? c : {}))
            .toList();
        return {'success': true, 'companies': companies};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load company accounts.',
        'companies': <Map<String, dynamic>>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'companies': <Map<String, dynamic>>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Fetching company list timed out.',
        'companies': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load company accounts.',
        'companies': <Map<String, dynamic>>[],
      };
    }
  }

  /// Fetches registered student users and profile records for Admin Dashboard.
  Future<Map<String, dynamic>> getAdminStudents() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_admin_students'});
      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);
      if (result['success'] == true && result['students'] is List) {
        final List rawStudents = result['students'];
        final List<Map<String, dynamic>> students = rawStudents
            .map((s) => Map<String, dynamic>.from(s is Map ? s : {}))
            .toList();
        return {'success': true, 'students': students};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load student records.',
        'students': <Map<String, dynamic>>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'students': <Map<String, dynamic>>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Student records fetch timed out.',
        'students': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load student records.',
        'students': <Map<String, dynamic>>[],
      };
    }
  }

  /// Updates a company user account status (Approve / Revoke) in Google Sheets (Phase 14B).
  Future<Map<String, dynamic>> updateCompanyStatus({
    required String userId,
    required String status,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'update_company_status',
          'userId': userId.trim(),
          'status': status.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Updating status timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update company status.'};
    }
  }

  /// Updates a job status (Active / Inactive) in Google Sheets Jobs sheet.
  /// Sends action=update_job_status, jobId, and status.
  Future<Map<String, dynamic>> updateJobStatus({
    required String jobId,
    required String status,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'update_job_status',
          'jobId': jobId.trim(),
          'status': status.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Updating job status timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update job status.'};
    }
  }

  /// Fetches all jobs for a specific company (including both Active and Inactive).
  Future<Map<String, dynamic>> getCompanyJobs({
    required String companyId,
    String? companyName,
  }) async {
    return getJobs(
      includeInactive: true,
      companyId: companyId,
      company: companyName,
    );
  }

  /// Fetches most demanded skills statistics for Admin Analytics (Phase 15).
  Future<Map<String, dynamic>> getMostDemandedSkills() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_most_demanded_skills'});
      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);
      if (result['success'] == true && result['skills'] is List) {
        final rawList = result['skills'] as List;
        final skills = rawList
            .map((s) => Map<String, dynamic>.from(s is Map ? s : {}))
            .toList();
        return {'success': true, 'skills': skills};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load demanded skills.',
        'skills': <Map<String, dynamic>>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'skills': <Map<String, dynamic>>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out.',
        'skills': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load demanded skills.',
        'skills': <Map<String, dynamic>>[],
      };
    }
  }

  /// Fetches student readiness distribution statistics for Admin Analytics (Phase 15).
  Future<Map<String, dynamic>> getReadinessDistribution() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_readiness_distribution'});
      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);
      return result;
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load readiness distribution.',
      };
    }
  }

  /// Fetches top recommended jobs statistics for Admin Analytics (Phase 15).
  Future<Map<String, dynamic>> getTopRecommendedJobs() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_top_recommended_jobs'});
      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);
      final listData = result['recommendedJobs'] ?? result['jobs'];
      if (result['success'] == true && listData is List) {
        final jobs = listData
            .map((j) => Map<String, dynamic>.from(j is Map ? j : {}))
            .toList();
        return {'success': true, 'recommendedJobs': jobs, 'jobs': jobs};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load recommended jobs.',
        'recommendedJobs': <Map<String, dynamic>>[],
        'jobs': <Map<String, dynamic>>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'recommendedJobs': <Map<String, dynamic>>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out.',
        'recommendedJobs': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load recommended jobs.',
        'recommendedJobs': <Map<String, dynamic>>[],
      };
    }
  }

  /// Fetches placement trends over time for Admin Analytics (Phase 15).
  Future<Map<String, dynamic>> getPlacementTrends() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_placement_trends'});
      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);
      if (result['success'] == true && result['trends'] is List) {
        final rawList = result['trends'] as List;
        final trends = rawList
            .map((t) => Map<String, dynamic>.from(t is Map ? t : {}))
            .toList();
        return {'success': true, 'trends': trends};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load placement trends.',
        'trends': <Map<String, dynamic>>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'trends': <Map<String, dynamic>>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out.',
        'trends': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load placement trends.',
        'trends': <Map<String, dynamic>>[],
      };
    }
  }

  /// Sends a system broadcast announcement to target audience (Phase 16).
  /// Sends action=send_broadcast, title, message, audience, and createdBy.
  Future<Map<String, dynamic>> sendBroadcast({
    required String title,
    required String message,
    String audience = 'all',
    String createdBy = 'Admin',
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'send_broadcast',
          'title': title.trim(),
          'message': message.trim(),
          'audience': audience.trim(),
          'createdBy': createdBy.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Broadcast request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while sending broadcast.',
      };
    }
  }

  /// Fetches list of system broadcast announcements (Phase 16).
  /// Sends action=get_broadcasts.
  Future<Map<String, dynamic>> getBroadcasts() async {
    try {
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'action': 'get_broadcasts'});

      final response = await http.get(uri).timeout(_timeout);
      final result = _parseResponse(response);
      if (result['success'] == true && result['broadcasts'] is List) {
        final List raw = result['broadcasts'];
        final List<Map<String, dynamic>> broadcasts =
            raw.map((b) => Map<String, dynamic>.from(b is Map ? b : {})).toList();
        return {'success': true, 'broadcasts': broadcasts};
      }
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Failed to load announcements.',
        'broadcasts': <Map<String, dynamic>>[],
      };
    } on SocketException {
      return {
        'success': false,
        'message': AppStrings.networkError,
        'broadcasts': <Map<String, dynamic>>[],
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Fetching announcements timed out.',
        'broadcasts': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while loading announcements.',
        'broadcasts': <Map<String, dynamic>>[],
      };
    }
  }

  /// Deletes a student record from the Google Sheets backend (Phase 16).
  Future<Map<String, dynamic>> deleteStudent(String userId) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'delete_student',
          'userId': userId.trim(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Delete student request timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete student record.'};
    }
  }

  /// Updates student record details in Google Sheets backend (Phase 16).
  Future<Map<String, dynamic>> updateStudent({
    required String userId,
    String? name,
    String? email,
    String? mobile,
    String? status,
    String? education,
    String? semester,
    String? skills,
  }) async {
    try {
      final query = <String, String>{
        'action': 'update_student',
        'userId': userId.trim(),
      };
      if (name != null) query['name'] = name.trim();
      if (email != null) query['email'] = email.trim();
      if (mobile != null) query['mobile'] = mobile.trim();
      if (status != null) query['status'] = status.trim();
      if (education != null) query['education'] = education.trim();
      if (semester != null) query['semester'] = semester.trim();
      if (skills != null) query['skills'] = skills.trim();

      final uri = Uri.parse(baseUrl).replace(queryParameters: query);
      final response = await http.get(uri).timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      return {'success': false, 'message': AppStrings.networkError};
    } on TimeoutException {
      return {'success': false, 'message': 'Update student request timed out.'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update student record.'};
    }
  }

  /// Safely parses HTTP response and handles JSON format conversion.
  Map<String, dynamic> _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 400) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {
          'success': false,
          'message': 'Invalid server response structure.',
        };
      } on FormatException {
        return {
          'success': false,
          'message': 'Failed to parse server response.',
        };
      }
    } else {
      return {
        'success': false,
        'message':
            'Server error (${response.statusCode}). Please try again later.',
      };
    }
  }
}
