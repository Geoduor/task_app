import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

enum TaskLoadStatus { initial, loading, loaded, error }

/// ChangeNotifier-based state holder for the task screen.
///
/// Chosen over a heavier state-management package (Riverpod/Bloc) because
/// the screen owns a single, simple list of tasks — `provider` keeps the
/// widget tree declarative without extra boilerplate for a scope this small.
class TaskProvider extends ChangeNotifier {
  final TaskService _service;
  TaskProvider({TaskService? service}) : _service = service ?? TaskService();

  List<Task> _tasks = [];
  TaskLoadStatus _status = TaskLoadStatus.initial;
  String? _errorMessage;

  List<Task> get tasks => List.unmodifiable(_tasks);
  TaskLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> loadTasks() async {
    _status = TaskLoadStatus.loading;
    notifyListeners();
    try {
      _tasks = await _service.fetchTasks();
      _status = TaskLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = TaskLoadStatus.error;
    }
    notifyListeners();
  }

  Future<String?> addTask(String rawTitle) async {
    final title = rawTitle.trim();
    if (title.isEmpty) {
      return 'Task title cannot be empty';
    }
    try {
      final created = await _service.createTask(title);
      _tasks = [created, ..._tasks];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not reach the server. Please try again.';
    }
  }

  Future<String?> toggleComplete(Task task) async {
    if (task.completed) return null; // API only supports marking complete.

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return null;

    // Optimistic update for a responsive UI, rolled back on failure.
    final previous = _tasks[index];
    _tasks[index] = task.copyWith(completed: true);
    notifyListeners();

    try {
      final updated = await _service.completeTask(task.id);
      _tasks[index] = updated;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _tasks[index] = previous;
      notifyListeners();
      return e.message;
    } catch (e) {
      _tasks[index] = previous;
      notifyListeners();
      return 'Could not reach the server. Please try again.';
    }
  }
}
