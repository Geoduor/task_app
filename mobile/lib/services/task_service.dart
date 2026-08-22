import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import 'api_config.dart';

/// Thrown for any non-2xx response so the UI layer can show a message
/// without knowing about HTTP status codes.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin HTTP client wrapping the Task API. Keeping this separate from the
/// provider makes it trivial to unit test or swap out later.
class TaskService {
  final http.Client _client;
  TaskService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<List<Task>> fetchTasks() async {
    final response = await _get('/tasks');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask(String title) async {
    final response = await _client.post(
      _uri('/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
    _throwIfError(response);
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Task> completeTask(String id) async {
    final response = await _client.patch(_uri('/tasks/$id/complete'));
    _throwIfError(response);
    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _get(String path) async {
    final response = await _client.get(_uri(path));
    _throwIfError(response);
    return response;
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = 'Request failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        final m = body['message'];
        message = m is List ? m.join(', ') : m.toString();
      }
    } catch (_) {
      // Response wasn't JSON (e.g. server unreachable proxy error) — keep
      // the generic message rather than crashing on parse.
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
