class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String level;
  final String? examDate;
  final int dailyMinutes;
  final int targetScore;
  final String studyFocus;
  final bool isAdmin;
  final bool onboardingComplete;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.level,
    this.examDate,
    required this.dailyMinutes,
    required this.targetScore,
    required this.studyFocus,
    required this.isAdmin,
    required this.onboardingComplete,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      level: json['level'] as String? ?? 'average',
      examDate: json['exam_date'] as String?,
      dailyMinutes: json['daily_minutes'] as int? ?? 45,
      targetScore: json['target_score'] as int? ?? 70,
      studyFocus: json['study_focus'] as String? ?? 'both',
      isAdmin: json['is_admin'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'level': level,
      'exam_date': examDate,
      'daily_minutes': dailyMinutes,
      'target_score': targetScore,
      'study_focus': studyFocus,
      'is_admin': isAdmin,
      'onboarding_complete': onboardingComplete,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? fullName,
    String? level,
    String? examDate,
    int? dailyMinutes,
    int? targetScore,
    String? studyFocus,
    bool? isAdmin,
    bool? onboardingComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      level: level ?? this.level,
      examDate: examDate ?? this.examDate,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      targetScore: targetScore ?? this.targetScore,
      studyFocus: studyFocus ?? this.studyFocus,
      isAdmin: isAdmin ?? this.isAdmin,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          level == other.level &&
          examDate == other.examDate &&
          dailyMinutes == other.dailyMinutes &&
          targetScore == other.targetScore &&
          studyFocus == other.studyFocus &&
          isAdmin == other.isAdmin &&
          onboardingComplete == other.onboardingComplete;

  @override
  int get hashCode => Object.hash(
        id,
        email,
        fullName,
        level,
        examDate,
        dailyMinutes,
        targetScore,
        studyFocus,
        isAdmin,
        onboardingComplete,
      );

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, '
        'level: $level, onboardingComplete: $onboardingComplete)';
  }
}
