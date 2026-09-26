/// Data model representing a student's job application fetched from Google Sheets backend.
class Application {
  final String applicationId;
  final String jobId;
  final String userId;
  final String appliedDate;
  final String status;
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String salary;

  const Application({
    required this.applicationId,
    required this.jobId,
    required this.userId,
    required this.appliedDate,
    this.status = 'Applied',
    this.title = '',
    this.company = '',
    this.location = '',
    this.jobType = '',
    this.salary = '',
  });

  /// Factory constructor to deserialize an [Application] from API JSON response.
  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      applicationId: (json['applicationId'] ?? json['id'] ?? '').toString().trim(),
      jobId: (json['jobId'] ?? '').toString().trim(),
      userId: (json['userId'] ?? '').toString().trim(),
      appliedDate: (json['appliedDate'] ?? json['date'] ?? '').toString().trim(),
      status: (json['status'] ?? 'Applied').toString().trim(),
      title: (json['title'] ?? json['jobTitle'] ?? '').toString().trim(),
      company: (json['company'] ?? json['companyName'] ?? '').toString().trim(),
      location: (json['location'] ?? '').toString().trim(),
      jobType: (json['jobType'] ?? json['type'] ?? '').toString().trim(),
      salary: (json['salary'] ?? json['stipend'] ?? '').toString().trim(),
    );
  }

  /// Converts this [Application] instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'jobId': jobId,
      'userId': userId,
      'appliedDate': appliedDate,
      'status': status,
      'title': title,
      'company': company,
      'location': location,
      'jobType': jobType,
      'salary': salary,
    };
  }
}
