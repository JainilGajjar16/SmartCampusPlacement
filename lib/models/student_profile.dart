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

  /// Parses multiple education entries from raw string (separated by newline).
  static List<EducationItem> parseEducation(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => EducationItem.fromString(line))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Formats multiple education entries into a clean newline-delimited string.
  static String formatEducation(List<EducationItem> items) {
    return items
        .where((item) => item.isNotEmpty)
        .map((item) => item.toSerializedString())
        .join('\n');
  }

  /// Parses multiple certification entries from raw string (separated by newline).
  static List<CertificationItem> parseCertifications(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => CertificationItem.fromString(line))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Formats multiple certification entries into a clean newline-delimited string.
  static String formatCertifications(List<CertificationItem> items) {
    return items
        .where((item) => item.isNotEmpty)
        .map((item) => item.toSerializedString())
        .join('\n');
  }

  List<EducationItem> get educationItems => parseEducation(education);
  List<CertificationItem> get certificationItems =>
      parseCertifications(certifications);

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

/// Structured model representing a single education entry.
class EducationItem {
  final String degree;
  final String uniBoard;
  final String cgpaPercentage;
  final String year;

  const EducationItem({
    this.degree = '',
    this.uniBoard = '',
    this.cgpaPercentage = '',
    this.year = '',
  });

  bool get isEmpty =>
      degree.trim().isEmpty &&
      uniBoard.trim().isEmpty &&
      cgpaPercentage.trim().isEmpty &&
      year.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Serializes into a clean readable string.
  /// If year or cgpa is provided, preserves positional slots with ' | '.
  /// e.g. "Degree | Uni / Board | CGPA / Percentage | Year"
  String toSerializedString() {
    final d = degree.trim();
    final u = uniBoard.trim();
    final c = cgpaPercentage.trim();
    final y = year.trim();

    if (y.isNotEmpty || c.isNotEmpty) {
      return '$d | $u | $c | $y';
    } else if (u.isNotEmpty) {
      return '$d | $u';
    } else {
      return d;
    }
  }

  /// Parses a single line or raw string into an EducationItem.
  factory EducationItem.fromString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const EducationItem();

    if (trimmed.contains('|')) {
      final parts = trimmed.split('|').map((p) => p.trim()).toList();
      return EducationItem(
        degree: parts.isNotEmpty ? parts[0] : '',
        uniBoard: parts.length > 1 ? parts[1] : '',
        cgpaPercentage: parts.length > 2 ? parts[2] : '',
        year: parts.length > 3 ? parts[3] : '',
      );
    }

    // Backward compatibility for hyphen-separated "Degree - University"
    if (trimmed.contains(' - ')) {
      final parts = trimmed.split(' - ').map((p) => p.trim()).toList();
      return EducationItem(
        degree: parts.isNotEmpty ? parts[0] : '',
        uniBoard: parts.length > 1 ? parts[1] : '',
      );
    }

    // Default fallback: entire raw string belongs to degree
    return EducationItem(degree: trimmed);
  }

  EducationItem copyWith({
    String? degree,
    String? uniBoard,
    String? cgpaPercentage,
    String? year,
  }) {
    return EducationItem(
      degree: degree ?? this.degree,
      uniBoard: uniBoard ?? this.uniBoard,
      cgpaPercentage: cgpaPercentage ?? this.cgpaPercentage,
      year: year ?? this.year,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationItem &&
          runtimeType == other.runtimeType &&
          degree == other.degree &&
          uniBoard == other.uniBoard &&
          cgpaPercentage == other.cgpaPercentage &&
          year == other.year;

  @override
  int get hashCode =>
      degree.hashCode ^
      uniBoard.hashCode ^
      cgpaPercentage.hashCode ^
      year.hashCode;
}

/// Structured model representing a single certification or achievement entry.
class CertificationItem {
  final String courseCertificate;
  final String rankingPercentage;
  final String year;

  const CertificationItem({
    this.courseCertificate = '',
    this.rankingPercentage = '',
    this.year = '',
  });

  bool get isEmpty =>
      courseCertificate.trim().isEmpty &&
      rankingPercentage.trim().isEmpty &&
      year.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Serializes into a clean readable string:
  /// "Course / Certificate | Ranking / Percentage | Year"
  String toSerializedString() {
    final c = courseCertificate.trim();
    final r = rankingPercentage.trim();
    final y = year.trim();

    if (y.isNotEmpty) {
      return '$c | $r | $y';
    } else if (r.isNotEmpty) {
      return '$c | $r';
    } else {
      return c;
    }
  }

  /// Parses a single line into a CertificationItem.
  factory CertificationItem.fromString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const CertificationItem();

    if (trimmed.contains('|')) {
      final parts = trimmed.split('|').map((p) => p.trim()).toList();
      return CertificationItem(
        courseCertificate: parts.isNotEmpty ? parts[0] : '',
        rankingPercentage: parts.length > 1 ? parts[1] : '',
        year: parts.length > 2 ? parts[2] : '',
      );
    }

    // Default fallback: entire raw string belongs to courseCertificate
    return CertificationItem(courseCertificate: trimmed);
  }

  CertificationItem copyWith({
    String? courseCertificate,
    String? rankingPercentage,
    String? year,
  }) {
    return CertificationItem(
      courseCertificate: courseCertificate ?? this.courseCertificate,
      rankingPercentage: rankingPercentage ?? this.rankingPercentage,
      year: year ?? this.year,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificationItem &&
          runtimeType == other.runtimeType &&
          courseCertificate == other.courseCertificate &&
          rankingPercentage == other.rankingPercentage &&
          year == other.year;

  @override
  int get hashCode =>
      courseCertificate.hashCode ^
      rankingPercentage.hashCode ^
      year.hashCode;
}
