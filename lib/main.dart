import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const TaskManagerApp());

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TaskHomeScreen(),
    );
  }
}

class Task {
  String title;
  bool isDone;
  Task({required this.title, this.isDone = false});

  Map<String, dynamic> toMap() => {'title': title, 'isDone': isDone};
  factory Task.fromMap(Map<String, dynamic> map) =>
      Task(title: map['title'], isDone: map['isDone']);
}

class TaskHomeScreen extends StatefulWidget {
  const TaskHomeScreen({super.key});

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  final List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _tasks.addAll(decoded.map((e) => Task.fromMap(e)).toList());
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tasks',
      jsonEncode(_tasks.map((e) => e.toMap()).toList()),
    );
  }

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _tasks.add(Task(title: title.trim()));
      _controller.clear();
    });
    _saveTasks();
    Navigator.pop(context);
  }

  void _toggleTask(int index) {
    setState(() => _tasks[index].isDone = !_tasks[index].isDone);
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() => _tasks.removeAt(index));
    _saveTasks();
  }

  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter new task',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _addTask,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _addTask(_controller.text),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showAddTaskModal,
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('No tasks yet. Tap + to add one.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  leading: IconButton(
                    icon: Icon(
                      task.isDone ? Icons.check_circle : Icons.circle_outlined,
                      color: task.isDone ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleTask(index),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTask(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskModal,
        label: const Text('New Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
