/// The result returned by the server after submitting an attempt.
///
/// Contains the correctness verdict, the correct answer, explanations,
/// and the student's updated mastery score for the associated concept.

class AttemptResult {
  final int id;
  final int questionId;
  final String selectedOption; // 'A', 'B', 'C', or 'D'
  final bool isCorrect;
  final int timeTakenSeconds;
  final bool wasGuessed;
  final bool hintUsed;
  final String correctOption;
  final String explanation;
  final String? whyWrong; // Why the *selected* option is wrong (null if correct)
  final double masteryChange; // e.g. +0.04 or -0.06
  final double newMastery; // Updated mastery after this attempt (0.0 - 1.0)

  const AttemptResult({
    required this.id,
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.timeTakenSeconds,
    required this.wasGuessed,
    required this.hintUsed,
    required this.correctOption,
    required this.explanation,
    this.whyWrong,
    required this.masteryChange,
    required this.newMastery,
  });

  factory AttemptResult.fromJson(Map<String, dynamic> json) {
    return AttemptResult(
      id: json['id'] as int,
      questionId: json['question_id'] as int,
      selectedOption: json['selected_option'] as String,
      isCorrect: json['is_correct'] as bool,
      timeTakenSeconds: json['time_taken_seconds'] as int,
      wasGuessed: json['was_guessed'] as bool? ?? false,
      hintUsed: json['hint_used'] as bool? ?? false,
      correctOption: json['correct_option'] as String,
      explanation: json['explanation'] as String? ?? '',
      whyWrong: json['why_wrong'] as String?,
      masteryChange: (json['mastery_change'] as num?)?.toDouble() ?? 0.0,
      newMastery: (json['new_mastery'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'selected_option': selectedOption,
      'is_correct': isCorrect,
      'time_taken_seconds': timeTakenSeconds,
      'was_guessed': wasGuessed,
      'hint_used': hintUsed,
      'correct_option': correctOption,
      'explanation': explanation,
      'why_wrong': whyWrong,
      'mastery_change': masteryChange,
      'new_mastery': newMastery,
    };
  }

  /// Formatted mastery change string with sign prefix.
  String get masteryChangeFormatted {
    final sign = masteryChange >= 0 ? '+' : '';
    return '$sign${masteryChange.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttemptResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AttemptResult(id: $id, questionId: $questionId, '
      'correct: $isCorrect, mastery: $masteryChangeFormatted)';
}
