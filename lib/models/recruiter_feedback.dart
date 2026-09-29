/// Model representing recruiter feedback and rating for a candidate application.
class RecruiterFeedback {
  final String feedbackId;
  final String applicationId;
  final String jobId;
  final String studentId;
  final String companyId;
  final double rating;
  final String feedback;
  final String createdAt;

  const RecruiterFeedback({
    required this.feedbackId,
    required this.applicationId,
    required this.jobId,
    required this.studentId,
    required this.companyId,
    required this.rating,
    required this.feedback,
    required this.createdAt,
  });

  /// Factory constructor to parse JSON returned from Apps Script API.
  factory RecruiterFeedback.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['feedback'] is Map<String, dynamic>)
            ? json['feedback'] as Map<String, dynamic>
            : json;

    double parseRating(dynamic raw) {
      if (raw == null) return 0.0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0.0;
    }

    return RecruiterFeedback(
      feedbackId: data['feedbackId']?.toString() ?? data['id']?.toString() ?? '',
      applicationId: data['applicationId']?.toString() ?? data['application_id']?.toString() ?? '',
      jobId: data['jobId']?.toString() ?? data['job_id']?.toString() ?? '',
      studentId: data['studentId']?.toString() ?? data['userId']?.toString() ?? data['user_id']?.toString() ?? '',
      companyId: data['companyId']?.toString() ?? data['company_id']?.toString() ?? '',
      rating: parseRating(data['rating']),
      feedback: data['feedback']?.toString() ?? data['comment']?.toString() ?? '',
      createdAt: data['createdAt']?.toString() ?? data['created_at']?.toString() ?? '',
    );
  }

  /// Serializes model to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'feedbackId': feedbackId,
      'applicationId': applicationId,
      'jobId': jobId,
      'studentId': studentId,
      'companyId': companyId,
      'rating': rating,
      'feedback': feedback,
      'createdAt': createdAt,
    };
  }

  /// Converts model parameters to query parameter map for GET/POST API requests.
  Map<String, String> toQueryParameters() {
    return {
      'action': 'submit_recruiter_feedback',
      'feedbackId': feedbackId.trim(),
      'applicationId': applicationId.trim(),
      'jobId': jobId.trim(),
      'studentId': studentId.trim(),
      'companyId': companyId.trim(),
      'rating': rating.toStringAsFixed(1),
      'feedback': feedback.trim(),
      'createdAt': createdAt.trim(),
    };
  }
}
