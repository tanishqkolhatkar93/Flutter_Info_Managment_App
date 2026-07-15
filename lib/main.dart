// lib/main.dart
import 'package:flutter/material.dart';
import 'models/student.dart';
import 'services/db_service.dart';
import 'screens/add_edit_student_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Info Management (SQLite)',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DBService _db = DBService();
  final TextEditingController _searchController = TextEditingController();
  List<Student> _suggestions = [];
  Student? _selected;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Initially no suggestions
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final q = _searchController.text;
    if (q.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    setState(() => _loading = true);
    final res = await _db.searchStudentsByName(q);
    setState(() {
      _suggestions = res;
      _loading = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _selected = null;
    });
  }

  Future<void> _selectSuggestion(Student s) async {
    setState(() {
      _searchController.text = s.name;
      _suggestions = [];
      _selected = s;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected == null || _selected!.id == null) return;
    final id = _selected!.id!;
    await _db.deleteStudent(id);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Student deleted')));
    setState(() {
      _selected = null;
      _suggestions = [];
      _searchController.clear();
    });
  }



  Future<void> _editSelected() async {
    if (_selected == null) return;
    final updated = await Navigator.of(context).push<Student?>(
      MaterialPageRoute(builder: (_) => AddEditStudentScreen(student: _selected)),
    );
    if (updated != null && updated.id != null) {
      // Save to DB
      await _db.updateStudent(updated);

      // Reload from DB to be 100% sure we have latest data
      final fresh = await _db.getStudentById(updated.id!);

      setState(() {
        _selected = fresh;
        _suggestions = [];
        _searchController.text = fresh?.name ?? '';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Student updated')));
    }
  }


  Future<void> _addNewStudent() async {
    final created = await Navigator.of(context).push<Student?>(
      MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
    );
    if (created != null) {
      // 1) Insert into DB and get the new ID
      final newId = await _db.insertStudent(created);

      // 2) Fetch the fresh row from DB (with ID)
      final fresh = await _db.getStudentById(newId);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Student added')));

      // 3) Use the DB-backed object with ID
      setState(() {
        _searchController.text = fresh?.name ?? created.name;
        _selected = fresh;
        _suggestions = [];
      });
    }
  }


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search students by name...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_loading) return const Padding(
      padding: EdgeInsets.symmetric(horizontal:16.0),
      child: LinearProgressIndicator(),
    );
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return ListTile(
            title: Text(s.name),
            subtitle: Text('${s.grade} · Age ${s.age}'),
            onTap: () => _selectSuggestion(s),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCard() {
    if (_selected == null) return const SizedBox.shrink();
    final s = _selected!;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Age: ${s.age}'),
              Text('Class: ${s.grade}'),
              Text('Email: ${s.email}'),
              Text('Phone: ${s.phone}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: _editSelected,
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text('Are you sure you want to delete this student?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _deleteSelected();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllStudentsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.list),
        label: const Text('Show All Students'),
        onPressed: () async {
          final arr = await _db.getAllStudents();
          showModalBottomSheet(
            context: context,
            builder: (_) => ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: arr.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, idx) {
                final e = arr[idx];
                return ListTile(
                  title: Text(e.name),
                  subtitle: Text('${e.grade} · Age ${e.age}'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectSuggestion(e);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Information Management (SQLite)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(),
            _buildSuggestions(),
            const SizedBox(height: 8),
            _buildSelectedCard(),
            _buildAllStudentsButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewStudent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
