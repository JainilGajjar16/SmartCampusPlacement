/// Data model representing a student profile.
class StudentProfile {
  final String userId;
  final String name;
  final String email;
  final String mobile;
  final String github;
  final String linkedin;
  final String education;
  final String skills;
  final String projects;
  final String certifications;

  const StudentProfile({
    required this.userId,
    this.name = '',
    this.email = '',
    this.mobile = '',
    this.github = '',
    this.linkedin = '',
    this.education = '',
    this.skills = '',
    this.projects = '',
    this.certifications = '',
  });

  /// Factory constructor to parse JSON returned from Google Apps Script API.
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['profile'] is Map<String, dynamic>)
        ? json['profile'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic>)
            ? json['data'] as Map<String, dynamic>
            : json;

    String parseSkills(dynamic rawSkills) {
      if (rawSkills == null) return '';
      if (rawSkills is List) {
        return rawSkills
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .join(', ');
      }
      return rawSkills.toString();
    }

    final rawSkills =
        data['skills'] ?? data['skill'] ?? data['skillsAndCompetencies'];

    return StudentProfile(
      userId: data['userId']?.toString() ?? data['user_id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      mobile: data['mobile']?.toString() ?? '',
      github: data['github']?.toString() ?? '',
      linkedin: data['linkedin']?.toString() ?? '',
      education: data['education']?.toString() ?? '',
      skills: parseSkills(rawSkills),
      projects: data['projects']?.toString() ?? '',
      certifications: data['certifications']?.toString() ?? '',
    );
  }

  /// Converts model parameters to query parameters map for API request.
  Map<String, String> toQueryParameters() {
    return {
      'action': 'save_student_profile',
      'userId': userId.trim(),
      'name': name.trim(),
      'email': email.trim(),
      'mobile': mobile.trim(),
      'github': github.trim(),
      'linkedin': linkedin.trim(),
      'education': education.trim(),
      'skills': skills.trim(),
      'projects': projects.trim(),
      'certifications': certifications.trim(),
    };
  }

  /// Creates a copy of StudentProfile with updated values.
  StudentProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? mobile,
    String? github,
    String? linkedin,
    String? education,
    String? skills,
    String? projects,
    String? certifications,
  }) {
    return StudentProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      github: github ?? this.github,
      linkedin: linkedin ?? this.linkedin,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      projects: projects ?? this.projects,
      certifications: certifications ?? this.certifications,
    );
  }
}
