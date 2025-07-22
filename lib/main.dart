import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Task model to hold task data
class Task {
  String title;
  bool isCompleted;
  DateTime createdAt;

  Task({
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}

void main() {
  runApp(const CuteTodoApp());
}


class AnimatedSplashScreen extends StatefulWidget {
  final Widget child;

  const AnimatedSplashScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _iconController.forward();
    await _textController.forward();

    // Wait a bit more then navigate to main app
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9C27B0), // Purple
              Color(0xFF673AB7), // Deep Purple
              Color(0xFF3F51B5), // Indigo
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              AnimatedBuilder(
                animation: _iconAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Animated Text
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _textAnimation.value)),
                      child: Column(
                        children: [
                          const Text(
                            'Cute Todo',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Organize your tasks beautifully',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),

              // Loading indicator
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CuteTodoApp extends StatelessWidget {
  const CuteTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cute Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AnimatedSplashScreen(
        child: TodoListScreen(), // ✅ Use the main screen after splash
      ),
    );
  }
}


class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> with TickerProviderStateMixin {
  // This will hold our tasks
  List<Task> tasks = [];

  // Controller for the text input
  final TextEditingController _taskController = TextEditingController();

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _deleteAnimationController;
  late AnimationController _checkboxAnimationController;

  // Animation tracking
  int _lastAddedIndex = -1;
  int _deletingIndex = -1;
  int _lastCheckedIndex = -1;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _deleteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _checkboxAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Load tasks when the app starts
    _loadTasks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _deleteAnimationController.dispose();
    _checkboxAnimationController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];

      final loadedTasks = tasksJson.map((taskJson) {
        final taskMap = json.decode(taskJson);
        return Task.fromJson(taskMap);
      }).toList();

      setState(() {
        tasks = loadedTasks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = tasks.map((task) => json.encode(task.toJson())).toList();
      await prefs.setStringList('tasks', tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  // Function to add a new task
  void _addTask(String taskTitle) async {
    if (taskTitle.trim().isNotEmpty) {
      setState(() {
        tasks.add(Task(title: taskTitle.trim()));
        _lastAddedIndex = tasks.length - 1;
      });

      _taskController.clear();

      // Save tasks to storage
      await _saveTasks();

      // Use post frame callback to ensure animation happens after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.reset();
          _animationController.forward();
        }
      });
    }
  }

  // Function to toggle task completion
  void _toggleTask(int index) async {
    if (index < 0 || index >= tasks.length || !mounted) return;

    final wasCompleted = tasks[index].isCompleted;

    setState(() {
      tasks[index].isCompleted = !tasks[index].isCompleted;
      if (tasks[index].isCompleted && !wasCompleted) {
        _lastCheckedIndex = index;
      } else {
        _lastCheckedIndex = -1;
      }
    });

    // Save tasks to storage
    await _saveTasks();

    // Use post frame callback for animation
    if (tasks[index].isCompleted && !wasCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkboxAnimationController.reset();
          _checkboxAnimationController.forward();
        }
      });
    }
  }

  // Function to delete a task with animation
  void _deleteTask(int index) async {
    if (index < 0 || index >= tasks.length || !mounted) return;

    setState(() {
      _deletingIndex = index;
    });

    try {
      await _deleteAnimationController.forward();
    } catch (e) {
      debugPrint('Animation error: $e');
    }

    if (mounted) {
      setState(() {
        if (index < tasks.length) {
          tasks.removeAt(index);
        }
        _deletingIndex = -1;
        if (_lastAddedIndex >= tasks.length) {
          _lastAddedIndex = -1;
        }
        if (_lastCheckedIndex >= tasks.length) {
          _lastCheckedIndex = -1;
        }
      });

      _deleteAnimationController.reset();

      // Save tasks to storage
      await _saveTasks();
    }
  }

  // Function to show dialog for adding new task
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: _taskController,
            decoration: const InputDecoration(
              hintText: 'Enter your task...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              _addTask(value);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _taskController.clear();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _addTask(_taskController.text);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  // Function to clear all completed tasks
  void _clearCompletedTasks() async {
    final completedCount = tasks.where((task) => task.isCompleted).length;

    if (completedCount == 0) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Completed Tasks'),
          content: Text('Are you sure you want to remove $completedCount completed task${completedCount == 1 ? '' : 's'}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      setState(() {
        tasks.removeWhere((task) => task.isCompleted);
        _lastAddedIndex = -1;
        _lastCheckedIndex = -1;
      });
      await _saveTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while tasks are being loaded
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.purple, Colors.purpleAccent],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    final completedCount = tasks.where((task) => task.isCompleted).length;
    final totalCount = tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Cute To-Do List'),
            if (totalCount > 0)
              Text(
                '$completedCount of $totalCount completed',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (completedCount > 0)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearCompletedTasks,
              tooltip: 'Clear completed tasks',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple, Colors.purpleAccent],
          ),
        ),
        child: tasks.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 64,
                color: Colors.white70,
              ),
              SizedBox(height: 16),
              Text(
                'No tasks yet!\nTap the + button to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            if (index >= tasks.length) return const SizedBox.shrink();

            final task = tasks[index];
            return TaskCard(
              key: ValueKey('${task.title}_${task.createdAt.millisecondsSinceEpoch}'),
              task: task,
              index: index,
              isLastAdded: index == _lastAddedIndex,
              isDeleting: index == _deletingIndex,
              isLastChecked: index == _lastCheckedIndex,
              animationController: _animationController,
              deleteAnimationController: _deleteAnimationController,
              checkboxAnimationController: _checkboxAnimationController,
              onToggle: () => _toggleTask(index),
              onDelete: () => _deleteTask(index),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.purple, size: 32),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final int index;
  final bool isLastAdded;
  final bool isDeleting;
  final bool isLastChecked;
  final AnimationController animationController;
  final AnimationController deleteAnimationController;
  final AnimationController checkboxAnimationController;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.index,
    required this.isLastAdded,
    required this.isDeleting,
    required this.isLastChecked,
    required this.animationController,
    required this.deleteAnimationController,
    required this.checkboxAnimationController,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget taskCard = Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted ? Colors.green : Colors.transparent,
              border: Border.all(
                color: task.isCompleted ? Colors.green : Colors.purple,
                width: 2,
              ),
            ),
            child: task.isCompleted
                ? const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            )
                : null,
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: task.isCompleted ? Colors.grey : Colors.black,
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          child: Text(task.title),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );

    // Apply animations based on state
    if (isDeleting) {
      return AnimatedBuilder(
        animation: deleteAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(-300 * deleteAnimationController.value, 0),
            child: Opacity(
              opacity: 1 - deleteAnimationController.value,
              child: taskCard,
            ),
          );
        },
      );
    }

    if (isLastAdded) {
      return AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: animationController.value,
            child: taskCard,
          );
        },
      );
    }

    if (isLastChecked && task.isCompleted) {
      return AnimatedBuilder(
        animation: checkboxAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (0.1 * checkboxAnimationController.value),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3 * checkboxAnimationController.value),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: taskCard,
            ),
          );
        },
      );
    }

    return taskCard;
  }
}