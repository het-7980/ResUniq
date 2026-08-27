/// ---------------------------------------------------------------------------
/// ResUniq - suggestion_service.dart
/// ---------------------------------------------------------------------------
/// Central suggestion catalog for resume form fields.
///
/// Suggestions are intentionally attached only to fields where a known value is
/// useful. Personal values such as a user's name, email, phone number, project
/// name and reference name return no suggestions.
/// ---------------------------------------------------------------------------
library;

class SuggestionService {
  SuggestionService._();

  static const Map<String, List<String>> _byFieldId = {
    'personal.jobRole': _jobTitles,
    'experience.role': _jobTitles,
    'personal.location': _locations,
    'education.school': _institutions,
    'education.degree': _degrees,
    'experience.company': _companies,
    'skills': _skills,
    'certifications.name': _certifications,
    'certifications.issuer': _issuers,
    'languages': _languages,
    'interests': _interests,
  };

  /// Returns ranked matches for [fieldId]. Matching starts with prefix matches
  /// (for example, "flu" -> "Flutter") and then includes word matches.
  static List<String> suggestionsFor(
    String fieldId,
    String query, {
    int limit = 8,
  }) {
    final source = _byFieldId[fieldId];
    if (source == null) return const [];

    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final prefix = <String>[];
    final contains = <String>[];

    for (final value in source) {
      final candidate = value.toLowerCase();
      if (candidate.startsWith(normalized)) {
        prefix.add(value);
      } else if (candidate.contains(normalized)) {
        contains.add(value);
      }
    }

    final result = [...prefix, ...contains];
    return result.length <= limit ? result : result.take(limit).toList();
  }

  static const _jobTitles = <String>[
    'Software Engineer',
    'Software Developer',
    'Flutter Developer',
    'Mobile App Developer',
    'Android Developer',
    'iOS Developer',
    'Frontend Developer',
    'Backend Developer',
    'Full Stack Developer',
    'Web Developer',
    'UI/UX Designer',
    'Graphic Designer',
    'Data Analyst',
    'Data Scientist',
    'Machine Learning Engineer',
    'AI Engineer',
    'DevOps Engineer',
    'Cloud Engineer',
    'Cybersecurity Analyst',
    'QA Engineer',
    'Business Analyst',
    'Product Manager',
    'Project Manager',
    'Digital Marketing Specialist',
    'Accountant',
    'Human Resources Executive',
  ];

  static const _degrees = <String>[
    'Bachelor of Technology (B.Tech)',
    'Bachelor of Engineering (B.E.)',
    'Bachelor of Computer Applications (BCA)',
    'Bachelor of Science (B.Sc)',
    'Bachelor of Commerce (B.Com)',
    'Bachelor of Business Administration (BBA)',
    'Master of Technology (M.Tech)',
    'Master of Computer Applications (MCA)',
    'Master of Science (M.Sc)',
    'Master of Business Administration (MBA)',
    'Diploma in Engineering',
    'Diploma in Computer Engineering',
    'Higher Secondary Certificate (HSC)',
    'Secondary School Certificate (SSC)',
  ];

  static const _skills = <String>[
    'Flutter', 'Dart', 'Firebase', 'FlutterFlow', 'Android', 'Kotlin',
    'Java', 'Python', 'C', 'C++', 'C#', 'JavaScript', 'TypeScript',
    'HTML', 'CSS', 'React', 'Node.js', 'Express.js', 'Next.js', 'Angular',
    'PHP', 'Laravel', 'SQL', 'MySQL', 'PostgreSQL', 'MongoDB', 'Git',
    'GitHub', 'REST API', 'GraphQL', 'AWS', 'Google Cloud', 'Docker',
    'Figma', 'UI/UX Design', 'Machine Learning', 'Data Analysis',
    'Problem Solving', 'Communication', 'Teamwork', 'Leadership',
  ];

  static const _languages = <String>[
    'English', 'Hindi', 'Gujarati', 'Marathi', 'Punjabi', 'Bengali',
    'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Urdu', 'French', 'German',
    'Spanish', 'Japanese', 'Korean', 'Chinese', 'Arabic',
  ];

  static const _interests = <String>[
    'Coding', 'Reading', 'Photography', 'Traveling', 'Music', 'Drawing',
    'Gaming', 'Sports', 'Cricket', 'Football', 'Cycling', 'Fitness',
    'Cooking', 'Writing', 'Volunteering', 'Open Source', 'Technology',
  ];

  static const _locations = <String>[
    'Ahmedabad, Gujarat', 'Surat, Gujarat', 'Vadodara, Gujarat',
    'Rajkot, Gujarat', 'Gandhinagar, Gujarat', 'Mumbai, Maharashtra',
    'Pune, Maharashtra', 'Bengaluru, Karnataka', 'Hyderabad, Telangana',
    'Chennai, Tamil Nadu', 'New Delhi, Delhi', 'Noida, Uttar Pradesh',
    'Gurugram, Haryana', 'Kolkata, West Bengal', 'Remote',
  ];

  static const _institutions = <String>[
    'Gujarat Technological University',
    'Gujarat University',
    'Nirma University',
    'Pandit Deendayal Energy University',
    'Indian Institute of Technology Bombay',
    'Indian Institute of Technology Delhi',
    'Indian Institute of Technology Madras',
    'Indian Institute of Technology Gandhinagar',
    'National Institute of Technology Surat',
    'University of Mumbai',
    'Savitribai Phule Pune University',
    'Anna University',
    'Visvesvaraya Technological University',
  ];

  static const _companies = <String>[
    'Google', 'Microsoft', 'Amazon', 'Apple', 'Meta', 'IBM', 'Oracle',
    'Infosys', 'Tata Consultancy Services', 'Wipro', 'HCLTech', 'Accenture',
    'Deloitte', 'Cognizant', 'Capgemini', 'Zoho', 'Reliance Industries',
  ];

  static const _certifications = <String>[
    'AWS Certified Cloud Practitioner',
    'AWS Certified Solutions Architect',
    'Google Associate Cloud Engineer',
    'Google Data Analytics Professional Certificate',
    'Microsoft Azure Fundamentals',
    'Microsoft Certified: Azure Developer Associate',
    'Oracle Java Certification',
    'Flutter & Dart Certification',
    'Certified ScrumMaster (CSM)',
    'CompTIA Security+',
  ];

  static const _issuers = <String>[
    'Google', 'Microsoft', 'Amazon Web Services', 'Oracle', 'Meta',
    'IBM', 'Cisco', 'Coursera', 'Udemy', 'LinkedIn Learning', 'CompTIA',
    'Scrum Alliance',
  ];
}
