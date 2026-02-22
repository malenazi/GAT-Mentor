/// Models for questions fetched from the API.
///
/// [QuestionModel] is the lightweight version returned by `/questions/next`
/// (no correct answer or explanations -- prevents cheating via network
/// inspection). [QuestionDetail] extends it with the solution data returned
/// after an attempt is submitted or when viewing the solution screen.

class QuestionModel {
  final int id;
  final int conceptId;
  final String conceptName;
  final String topicName;
  final String text;
  final int difficulty; // 1-5
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int expectedTimeSeconds;
  final List<String> tags;

  const QuestionModel({
    required this.id,
    required this.conceptId,
    required this.conceptName,
    required this.topicName,
    required this.text,
    required this.difficulty,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.expectedTimeSeconds,
    required this.tags,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      conceptId: json['concept_id'] as int,
      conceptName: json['concept_name'] as String? ?? '',
      topicName: json['topic_name'] as String? ?? '',
      text: json['text'] as String,
      difficulty: json['difficulty'] as int? ?? 3,
      optionA: json['option_a'] as String,
      optionB: json['option_b'] as String,
      optionC: json['option_c'] as String,
      optionD: json['option_d'] as String,
      expectedTimeSeconds: json['expected_time_seconds'] as int? ?? 90,
      tags: _parseTags(json['tags']),
    );
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) return raw.isNotEmpty ? raw.split(',').map((e) => e.trim()).toList() : const [];
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'concept_id': conceptId,
      'concept_name': conceptName,
      'topic_name': topicName,
      'text': text,
      'difficulty': difficulty,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'expected_time_seconds': expectedTimeSeconds,
      'tags': tags,
    };
  }

  /// Convenience: get option text by letter.
  String optionText(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return optionA;
      case 'B':
        return optionB;
      case 'C':
        return optionC;
      case 'D':
        return optionD;
      default:
        return '';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'QuestionModel(id: $id, concept: $conceptName, difficulty: $difficulty)';
}

/// Extended model that includes the solution -- only available after the
/// student has submitted their answer or explicitly requests the solution.
class QuestionDetail extends QuestionModel {
  final String correctOption; // 'A', 'B', 'C', or 'D'
  final String explanation; // Markdown-formatted step-by-step solution
  final String? hint;
  final String? whyWrongA;
  final String? whyWrongB;
  final String? whyWrongC;
  final String? whyWrongD;

  const QuestionDetail({
    required super.id,
    required super.conceptId,
    required super.conceptName,
    required super.topicName,
    required super.text,
    required super.difficulty,
    required super.optionA,
    required super.optionB,
    required super.optionC,
    required super.optionD,
    required super.expectedTimeSeconds,
    required super.tags,
    required this.correctOption,
    required this.explanation,
    this.hint,
    this.whyWrongA,
    this.whyWrongB,
    this.whyWrongC,
    this.whyWrongD,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) {
    return QuestionDetail(
      id: json['id'] as int,
      conceptId: json['concept_id'] as int,
      conceptName: json['concept_name'] as String? ?? '',
      topicName: json['topic_name'] as String? ?? '',
      text: json['text'] as String,
      difficulty: json['difficulty'] as int? ?? 3,
      optionA: json['option_a'] as String,
      optionB: json['option_b'] as String,
      optionC: json['option_c'] as String,
      optionD: json['option_d'] as String,
      expectedTimeSeconds: json['expected_time_seconds'] as int? ?? 90,
      tags: QuestionModel._parseTags(json['tags']),
      correctOption: json['correct_option'] as String,
      explanation: json['explanation'] as String? ?? '',
      hint: json['hint'] as String?,
      whyWrongA: json['why_wrong_a'] as String?,
      whyWrongB: json['why_wrong_b'] as String?,
      whyWrongC: json['why_wrong_c'] as String?,
      whyWrongD: json['why_wrong_d'] as String?,
    );
  }

  /// Get the "why wrong" explanation for a specific option letter.
  String? whyWrong(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return whyWrongA;
      case 'B':
        return whyWrongB;
      case 'C':
        return whyWrongC;
      case 'D':
        return whyWrongD;
      default:
        return null;
    }
  }

  @override
  String toString() =>
      'QuestionDetail(id: $id, correct: $correctOption, concept: $conceptName)';
}
