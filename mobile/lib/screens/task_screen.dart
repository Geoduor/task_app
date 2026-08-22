import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget initial load; errors surface via provider.status.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final error = await context.read<TaskProvider>().addTask(
          _titleController.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _titleController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _toggle(Task task) async {
    final error = await context.read<TaskProvider>().toggleComplete(task);
    if (!mounted) return;
    if (error != null) _showSnackBar(error, isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Add a new task',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _submitting
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton.filled(
                            onPressed: _submit,
                            icon: const Icon(Icons.add),
                            tooltip: 'Add task',
                          ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        switch (provider.status) {
          case TaskLoadStatus.initial:
          case TaskLoadStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case TaskLoadStatus.error:
            return _buildError(provider.errorMessage, provider);
          case TaskLoadStatus.loaded:
            if (provider.tasks.isEmpty) {
              return const Center(child: Text('No tasks yet — add one above.'));
            }
            return RefreshIndicator(
              onRefresh: provider.loadTasks,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.tasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = provider.tasks[index];
                  return CheckboxListTile(
                    value: task.completed,
                    // Once completed, the API has no "un-complete" endpoint,
                    // so the checkbox becomes inert to match server truth.
                    onChanged: task.completed ? null : (_) => _toggle(task),
                    title: Text(
                      task.title,
                      style: task.completed
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            );
        }
      },
    );
  }

  Widget _buildError(String? message, TaskProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.loadTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
