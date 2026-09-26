/// App string constants to prevent hardcoded literals.
abstract class AppStrings {
  static const String appName = 'Smart Campus Placement';
  static const String appSubtitle =
      'Your Campus Placement & Career Preparation Platform';
  static const String welcomeTitle = 'Empowering Student Careers';
  static const String welcomeDescription =
      'Connect with top recruiters, showcase your skills, view placement opportunities, and jumpstart your career right from campus.';
  static const String getStarted = 'Get Started';
  static const String feature1 = 'Placement Opportunities';
  static const String feature2 = 'Resume Management';
  static const String feature3 = 'Career Tracking';

  // Login Screen Strings
  static const String welcomeBack = 'Welcome Back';
  static const String loginSubtitle = 'Login to continue your placement journey';
  static const String userIdLabel = 'User ID';
  static const String userIdHint = 'enter your user ID (e.g. john123)';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'enter your password';
  static const String forgotPassword = 'Forgot Password?';
  static const String forgotPasswordNotice =
      'Password reset feature will be enabled in future phases.';
  static const String login = 'Login';
  static const String createAccountPrompt = "Don't have an account? ";
  static const String createNewAccount = 'Create New Account';
  static const String loginSuccess = 'Login successful! Welcome back.';

  // Forgot & Reset Password Screen Strings
  static const String forgotPasswordTitle = 'Forgot Password?';
  static const String forgotPasswordSubtitle =
      'Verify your account to reset your password.';
  static const String verifyAccount = 'Verify Account';
  static const String verifySuccess = 'Account verified successfully.';
  static const String resetPasswordTitle = 'Reset Password';
  static const String resetPasswordSubtitle =
      'Enter a new password for your account.';
  static const String newPasswordLabel = 'New Password';
  static const String newPasswordHint = 'enter your new password';
  static const String confirmNewPasswordLabel = 'Confirm New Password';
  static const String confirmNewPasswordHint = 're-enter your new password';
  static const String resetPassword = 'Reset Password';
  static const String passwordResetSuccess =
      'Password reset successfully! Please login with your new password.';
  static const String verifiedUserId = 'Verified User ID';
  static const String verifiedEmail = 'Verified Email';


  // Registration Screen Strings
  static const String createAccount = 'Create Account';
  static const String registerSubtitle =
      'Register to start your placement & career journey';
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'enter your full name';
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'enter your email (e.g. john@college.edu)';
  static const String mobileLabel = 'Mobile Number';
  static const String mobileHint = 'enter your 10-digit mobile number';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String confirmPasswordHint = 're-enter your password';
  static const String roleLabel = 'Select Role';
  static const String studentRole = 'Student';
  static const String hrRole = 'HR';
  static const String register = 'Register';
  static const String alreadyHaveAccountPrompt = 'Already have an account? ';
  static const String loginLink = 'Login';
  static const String registerSuccess =
      'Registration successful! You can now log in.';

  // Dashboard Strings
  static const String dashboardTitle = 'Campus Dashboard';
  static const String logout = 'Logout';
  static const String menuMyProfile = 'My Profile';
  static const String menuMyProfileSubtitle = 'Manage & update your student placement profile';
  static const String menuResume = 'My Resume';
  static const String menuResumeSubtitle = 'Upload & manage your campus resume PDF';
  static const String menuJobs = 'Jobs';
  static const String menuJobsSubtitle = 'View campus placement job listings';
  static const String menuApplications = 'Applications';
  static const String menuApplicationsSubtitle = 'Track your submitted job applications';
  static const String comingSoon = 'Coming Soon';
  static const String jobsComingSoon = 'Campus Job Placement listings will arrive in future phases!';
  static const String applicationsComingSoon = 'Job Applications tracking will arrive in future phases!';

  // Profile Screen Strings
  static const String profileTitle = 'Student Profile';
  static const String profileSubtitle = 'Keep your placement details accurate for recruiters';
  static const String sectionPersonalInfo = 'Personal Information';
  static const String sectionProfessionalLinks = 'Professional Links';
  static const String sectionEducation = 'Education';
  static const String sectionSkills = 'Skills & Competencies';
  static const String sectionProjects = 'Key Projects';
  static const String sectionCertifications = 'Certifications & Achievements';

  static const String githubLabel = 'GitHub Profile URL';
  static const String githubHint = 'https://github.com/yourusername';
  static const String linkedinLabel = 'LinkedIn Profile URL';
  static const String linkedinHint = 'https://linkedin.com/in/yourusername';
  static const String educationLabel = 'Education Details';
  static const String educationHint = 'e.g. B.Tech Computer Science (2022-2026), XYZ Institute';
  static const String skillsLabel = 'Skills';
  static const String skillsHint = 'e.g. Flutter, Dart, Java, Python, SQL, REST APIs';
  static const String projectsLabel = 'Projects';
  static const String projectsHint = 'e.g. Smart Campus Placement App, E-Commerce Portal';
  static const String certificationsLabel = 'Certifications';
  static const String certificationsHint = 'e.g. Google Cloud Certified, AWS Cloud Practitioner';

  static const String saveProfile = 'Save Profile';
  static const String profileSavedSuccess = 'Profile saved successfully!';
  static const String newProfileNotice = 'Welcome! Fill in your placement profile details below and tap Save.';

  // Resume Screen Strings
  static const String resumeTitle = 'My Resume';
  static const String resumeSubtitle = 'Upload your latest resume PDF for campus placement.';
  static const String noResumeUploaded = 'No resume uploaded yet';
  static const String selectResume = 'Select Resume PDF';
  static const String changeFile = 'Select Different PDF';
  static const String uploadResume = 'Upload Resume';
  static const String retryUpload = 'Retry Upload';
  static const String openInDrive = 'Open Resume in Google Drive';
  static const String resumeUploadSuccess = 'Resume uploaded successfully!';
  static const String errInvalidFileType = 'Only PDF (.pdf) files are allowed for resume upload.';
  static const String errFileTooLarge = 'Resume file must be 5 MB or smaller.';
  static const String errFilePickerFailed = 'Failed to select file or selection was cancelled.';
  static const String errSessionRequired = 'You must be logged in to upload a resume.';

  // Validation Error Strings
  static const String errUserIdRequired = 'Please enter your User ID';
  static const String errUserIdMinLength =
      'User ID must be at least 3 characters long';
  static const String errEmailRequired = 'Please enter your email address';
  static const String errEmailInvalid = 'Please enter a valid email address';
  static const String errPasswordRequired = 'Please enter a password';
  static const String errPasswordMinLength =
      'Password must be at least 6 characters long';
  static const String errFullNameRequired = 'Please enter your full name';
  static const String errMobileRequired = 'Please enter your mobile number';
  static const String errMobileInvalid =
      'Please enter a valid 10-digit mobile number';
  static const String errConfirmPasswordRequired =
      'Please confirm your password';
  static const String errPasswordsDoNotMatch = 'Passwords do not match';
  static const String errRoleRequired = 'Please select a role';

  // API & Network Error Strings
  static const String networkError =
      'Network error. Please check your connection and try again.';
  static const String apiServerError =
      'Unable to connect to Smart Campus placement server.';
  static const String retry = 'Retry';

  // Job Listings & Job Details Strings
  static const String availableJobs = 'Available Jobs';
  static const String availableJobsSubtitle =
      'Explore current placement and internship opportunities';
  static const String noJobsAvailable = 'No jobs available right now.';
  static const String jobDetailsTitle = 'Job Details';
  static const String companyLabel = 'Company';
  static const String locationLabel = 'Location';
  static const String jobTypeLabel = 'Job Type';
  static const String skillsRequired = 'Skills Required';
  static const String salaryOrStipend = 'Salary / Stipend';
  static const String jobDescription = 'Job Description';
  static const String postedDateLabel = 'Posted Date';
  static const String applyForJob = 'Apply for this Job';
  static const String jobApplicationsComingSoon =
      'Job applications will be available in the next phase.';
  static const String jobNotFound = 'Job not found';

  // Job Search & Filter Strings (Phase 9)
  static const String searchJobsHint =
      'Search by title, company, location, skills...';
  static const String filterJobs = 'Filter Jobs';
  static const String resetFilters = 'Reset Filters';
  static const String clearSearch = 'Clear Search';
  static const String allLocations = 'All Locations';
  static const String allJobTypes = 'All Types';
  static const String allSkills = 'All Skills';
  static const String sortBy = 'Sort By';
  static const String sortNewest = 'Newest First';
  static const String sortSalaryHighToLow = 'Salary: High to Low';
  static const String sortSalaryLowToHigh = 'Salary: Low to High';
  static const String sortTitleAZ = 'Title: A to Z';
  static const String noJobsMatchTitle = 'No matching jobs found';
  static const String noJobsMatchSubtitle =
      'Try refining your search terms or clearing active filters.';

  // Job Applications Strings (Phase 11 Enhanced)
  static const String myApplications = 'My Applications';
  static const String myApplicationsSubtitle =
      'Track the status of your campus placement applications';
  static const String applicationSubmittedSuccess =
      'Application submitted successfully';
  static const String alreadyAppliedForJob =
      'You have already applied for this job';
  static const String noApplicationsSubmitted =
      'You haven\'t applied for any jobs yet.';
  static const String loadingApplications = 'Loading applications...';
  static const String applicationStatusLabel = 'Status';
  static const String appliedDateLabel = 'Applied Date';
  static const String applicationIdLabel = 'Application ID';
  static const String searchApplicationsHint =
      'Search by job title, company, location...';
  static const String applicationDetailsTitle = 'Application Details';
  static const String viewJobDetailsButton = 'View Full Job Details';
  static const String progressTimelineTitle = 'Application Progress Timeline';
  static const String noMatchingApplicationsTitle = 'No matching applications';
  static const String noMatchingApplicationsSubtitle =
      'Try refining your search text or clearing the status filter.';
  static const String statusApplied = 'Applied';
  static const String statusUnderReview = 'Under Review';
  static const String statusShortlisted = 'Shortlisted';
  static const String statusSelected = 'Selected';
  static const String statusRejected = 'Rejected';
  static const String statusActive = 'Active';

  // Notifications Strings (Phase 8)
  static const String notificationsTitle = 'Notifications';
  static const String notificationsSubtitle =
      'Stay updated with your job applications and placement alerts';
  static const String markAllAsRead = 'Mark all read';
  static const String noNotifications = 'No notifications yet';
  static const String noNotificationsSubtitle =
      'You are all caught up! New placement alerts will appear here.';
  static const String loadingNotifications = 'Loading notifications...';
  static const String allNotificationsRead = 'All notifications marked as read.';
  static const String notificationMarkedRead = 'Notification marked as read.';
  static const String filterAll = 'All';
  static const String filterUnread = 'Unread';
  static const String filterApplications = 'Applications';

  // Skill Gap Analysis Strings (Phase 10)
  static const String skillGapAnalysisTitle = 'Job Skill Gap Analysis';
  static const String skillGapAnalysisSubtitle =
      'Compare your profile skills against target job requirements';
  static const String analyzeSkillGap = 'Analyze Skill Gap';
  static const String jobReadinessScore = 'Job Readiness Score';
  static const String matchedSkillsLabel = 'Matched Required Skills';
  static const String missingSkillsLabel = 'Missing Target Skills';
  static const String extraSkillsLabel = 'Additional Profile Competencies';
  static const String recommendedLearningPath =
      'Recommended Learning Roadmaps';
  static const String noSkillsInProfileTitle = 'No Skills Listed in Profile';
  static const String noSkillsInProfileSubtitle =
      'Add skills to your student profile to run a skill gap analysis for this job.';
  static const String updateProfileSkills = 'Update Profile Skills';

  // Placement Readiness & Recommendation Strings (Phase 12)
  static const String placementReadinessTitle = 'Placement Readiness & Insights';
  static const String placementReadinessSubtitle =
      'Track your readiness score and explore skill-matched campus jobs';
  static const String overallReadinessLabel = 'Overall Readiness';
  static const String profileCompletenessLabel = 'Profile Completeness';
  static const String marketAlignmentLabel = 'Market Skill Alignment';
  static const String placementInsightsHeader = 'Placement Insights';
  static const String strongMatchesLabel = 'Strong Matches';
  static const String goodMatchesLabel = 'Good Matches';
  static const String needsImprovementLabel = 'Needs Improvement';
  static const String topSkillsToImproveHeader = 'Top Skills to Improve';
  static const String recommendedJobsHeader = 'Recommended Jobs for You';
  static const String filterAllMatches = 'All Matches';
  static const String filterStrongMatch = 'Strong (80%+)';
  static const String filterGoodMatch = 'Good (50-79%)';
  static const String filterNeedsImprovement = 'Improve (<50%)';
  static const String skillMatchPercentageLabel = 'Skill Match';
  static const String viewSkillGapAndApply = 'Analyze Skill Gap & Apply';
}

