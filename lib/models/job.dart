/// Data model representing a job posting fetched from Google Sheets backend.
class Job {
  final String jobId;
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String skills;
  final String salary;
  final String description;
  final String status;
  final String postedDate;
  final int? maxHiring;
  final int applicationCount;

  const Job({
    required this.jobId,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.skills,
    required this.salary,
    required this.description,
    this.status = 'Active',
    this.postedDate = '',
    this.maxHiring,
    this.applicationCount = 0,
  });

  /// Returns true if the job is closed or has reached its hiring limit.
  bool get isClosed {
    final s = status.trim().toLowerCase();
    if (s == 'closed') return true;
    if (maxHiring != null && maxHiring! > 0 && applicationCount >= maxHiring!) {
      return true;
    }
    return false;
  }

  /// Returns true if hiring limit is reached.
  bool get isHiringLimitReached =>
      maxHiring != null && maxHiring! > 0 && applicationCount >= maxHiring!;

  /// Factory constructor to deserialize a [Job] from API JSON response.
  factory Job.fromJson(Map<String, dynamic> json) {
    int? parsedMaxHiring;
    final rawMax = json['maxHiring'] ??
        json['max_hiring'] ??
        json['maxNoOfHiring'] ??
        json['maxHirings'];
    if (rawMax != null) {
      final parsed = int.tryParse(rawMax.toString().trim());
      if (parsed != null && parsed > 0) {
        parsedMaxHiring = parsed;
      }
    }

    int parsedAppCount = 0;
    final rawCount = json['applicationCount'] ??
        json['applications'] ??
        json['application_count'] ??
        json['applicants'];
    if (rawCount != null) {
      final parsed = int.tryParse(rawCount.toString().trim());
      if (parsed != null && parsed >= 0) {
        parsedAppCount = parsed;
      }
    }

    String rawStatus =
        (json['status'] ?? json['jobStatus'] ?? 'Active').toString().trim();
    if (rawStatus.isEmpty) rawStatus = 'Active';

    // If max hiring is set and application count has reached or exceeded max hiring,
    // the effective status is Closed unless explicitly Inactive.
    if (parsedMaxHiring != null &&
        parsedMaxHiring > 0 &&
        parsedAppCount >= parsedMaxHiring) {
      if (rawStatus.toLowerCase() == 'active') {
        rawStatus = 'Closed';
      }
    }

    return Job(
      jobId: (json['jobId'] ?? json['id'] ?? '').toString().trim(),
      title: (json['title'] ?? json['jobTitle'] ?? '').toString().trim(),
      company: (json['company'] ?? json['companyName'] ?? '').toString().trim(),
      location: (json['location'] ?? '').toString().trim(),
      jobType: (json['jobType'] ?? json['type'] ?? '').toString().trim(),
      skills: (json['skills'] ?? json['requiredSkills'] ?? '').toString().trim(),
      salary: (json['salary'] ?? json['stipend'] ?? '').toString().trim(),
      description:
          (json['description'] ?? json['jobDescription'] ?? '').toString().trim(),
      status: rawStatus,
      postedDate: (json['postedDate'] ?? json['date'] ?? '').toString().trim(),
      maxHiring: parsedMaxHiring,
      applicationCount: parsedAppCount,
    );
  }

  /// Converts this [Job] instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'title': title,
      'company': company,
      'location': location,
      'jobType': jobType,
      'skills': skills,
      'salary': salary,
      'description': description,
      'status': status,
      'postedDate': postedDate,
      'maxHiring': maxHiring,
      'applicationCount': applicationCount,
    };
  }
}
