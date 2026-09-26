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
  });

  /// Factory constructor to deserialize a [Job] from API JSON response.
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: (json['jobId'] ?? json['id'] ?? '').toString().trim(),
      title: (json['title'] ?? json['jobTitle'] ?? '').toString().trim(),
      company: (json['company'] ?? json['companyName'] ?? '').toString().trim(),
      location: (json['location'] ?? '').toString().trim(),
      jobType: (json['jobType'] ?? json['type'] ?? '').toString().trim(),
      skills: (json['skills'] ?? json['requiredSkills'] ?? '').toString().trim(),
      salary: (json['salary'] ?? json['stipend'] ?? '').toString().trim(),
      description: (json['description'] ?? json['jobDescription'] ?? '').toString().trim(),
      status: (json['status'] ?? json['jobStatus'] ?? 'Active').toString().trim(),
      postedDate: (json['postedDate'] ?? json['date'] ?? '').toString().trim(),
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
    };
  }
}
