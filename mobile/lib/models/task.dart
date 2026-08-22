/// Immutable model mirroring the API's TaskResponseDto.
class Task {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Returns a copy with [completed] overridden — used for optimistic UI
  /// updates before the server confirms the change.
  Task copyWith({bool? completed}) {
    return Task(
      id: id,
      title: title,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }
}
