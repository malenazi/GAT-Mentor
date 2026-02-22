class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator
  static const String webBaseUrl = '/api/v1'; // Relative URL — works in production and local

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Onboarding
  static const String onboardingProfile = '/onboarding/profile';
  static const String diagnosticQuestions = '/onboarding/diagnostic';
  static const String diagnosticSubmit = '/onboarding/diagnostic/submit';

  // Questions
  static const String nextQuestion = '/questions/next';
  static String questionDetail(int id) => '/questions/$id';
  static String questionHint(int id) => '/questions/$id/hint';
  static const String questionBatch = '/questions/batch';

  // Attempts
  static const String createAttempt = '/attempts/';
  static const String attemptHistory = '/attempts/history';
  static const String recentAttempts = '/attempts/recent';

  // Stats
  static const String dashboard = '/stats/dashboard';
  static const String masteryMap = '/stats/mastery';
  static const String trends = '/stats/trends';
  static const String weakest = '/stats/weakest';

  // Plan
  static const String todayPlan = '/plan/today';
  static const String generatePlan = '/plan/generate';
  static const String planSettings = '/plan/settings';
  static String completePlanItem(int id) => '/plan/items/$id/complete';

  // Review
  static const String reviewQueue = '/review/queue';
  static const String reviewCount = '/review/queue/count';
  static String classifyMistake(int id) => '/review/$id/classify';
  static String markReviewed(int id) => '/review/$id/reviewed';

  // Sessions
  static const String startSession = '/sessions/start';
  static String getSession(int id) => '/sessions/$id';
  static String submitSession(int id) => '/sessions/$id/submit';
  static const String sessionHistory = '/sessions/history/list';

  // Streaks
  static const String currentStreak = '/streaks/current';
  static const String streakCheckin = '/streaks/checkin';

  // Admin
  static const String adminQuestions = '/admin/questions/';
  static const String adminBulkUpload = '/admin/questions/bulk';
  static const String adminOverview = '/admin/stats/overview';
}
