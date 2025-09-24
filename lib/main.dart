import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TodoProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const TodoPage(),
    );
  }
}

// Model
class Todo {
  final String id;
  String title;
  bool isDone;

  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });
}

// Provider
class TodoProvider extends ChangeNotifier {
  final List<Todo> _todos = [];
  String _filter = 'All';

  List<Todo> get todos {
    switch (_filter) {
      case 'Active':
        return _todos.where((t) => !t.isDone).toList();
      case 'Done':
        return _todos.where((t) => t.isDone).toList();
      default:
        return List<Todo>.from(_todos);
    }
  }

  int get activeCount => _todos.where((t) => !t.isDone).length;

  void add(String title) {
    if (title.trim().length >= 3) {
      _todos.add(Todo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
      ));
      notifyListeners();
    }
  }

  void toggle(String id) {
    final i = _todos.indexWhere((t) => t.id == id);
    if (i != -1) {
      _todos[i].isDone = !_todos[i].isDone;
      notifyListeners();
    }
  }

  Map<String, dynamic>? remove(String id) {
    final i = _todos.indexWhere((t) => t.id == id);
    if (i != -1) {
      final removed = _todos.removeAt(i);
      notifyListeners();
      return {"todo": removed, "index": i};
    }
    return null;
  }

  void insertAt(int index, Todo todo) {
    if (index < 0 || index > _todos.length) {
      _todos.add(todo);
    } else {
      _todos.insert(index, todo);
    }
    notifyListeners();
  }

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }
}

// UI
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("To-Do List"),
          centerTitle: true,
          bottom: TabBar(
            onTap: (i) {
              if (i == 0) provider.setFilter("All");
              if (i == 1) provider.setFilter("Active");
              if (i == 2) provider.setFilter("Done");
            },
            tabs: const [
              Tab(text: "All"),
              Tab(text: "Active"),
              Tab(text: "Done"),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "Aktif: ${provider.activeCount}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: provider.todos.isEmpty
                  ? const Center(
                child: Text(
                  "Belum ada tugas ✨",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.todos.length,
                itemBuilder: (context, i) {
                  final todo = provider.todos[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          todo.isDone
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: todo.isDone
                              ? Colors.green
                              : Colors.grey,
                        ),
                        onPressed: () => provider.toggle(todo.id),
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16,
                          decoration: todo.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          final removed = provider.remove(todo.id);
                          if (removed != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Item dihapus"),
                                action: SnackBarAction(
                                  label: "Undo",
                                  onPressed: () {
                                    provider.insertAt(
                                      removed["index"] as int,
                                      removed["todo"] as Todo,
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // Input bar di bawah
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: const Border(
                  top: BorderSide(color: Colors.black12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Tambah tugas...",
                        border: OutlineInputBorder(),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _add(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _add(provider),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Add"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add(TodoProvider provider) {
    if (_controller.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul minimal 3 karakter")),
      );
      return;
    }
    provider.add(_controller.text);
    _controller.clear();
  }
}