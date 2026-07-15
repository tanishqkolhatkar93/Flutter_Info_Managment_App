// lib/screens/add_edit_student_screen.dart
import 'package:flutter/material.dart';
import '../models/student.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student; // null -> create new

  const AddEditStudentScreen({Key? key, this.student}) : super(key: key);

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameC;
  late TextEditingController _ageC;
  late TextEditingController _gradeC;
  late TextEditingController _emailC;
  late TextEditingController _phoneC;


  // inside initState()

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.student?.name ?? '');
    _ageC = TextEditingController(
        text: widget.student != null ? widget.student!.age.toString() : '');
    _gradeC = TextEditingController(text: widget.student?.grade ?? '');
    _emailC = TextEditingController(text: widget.student?.email ?? '');
    _phoneC = TextEditingController(text: widget.student?.phone ?? '');
  }


  @override
  void dispose() {
    _nameC.dispose();
    _ageC.dispose();
    _gradeC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final s = Student(
      id: widget.student?.id,
      name: _nameC.text.trim(),
      age: int.tryParse(_ageC.text.trim()) ?? 0,
      grade: _gradeC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
    );
    Navigator.of(context).pop(s);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add Student'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _ageC,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter age';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter valid age';
                  return null;
                },
              ),
              TextFormField(
                controller: _gradeC,
                decoration: const InputDecoration(labelText: 'Grade / Class'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter grade' : null,
              ),
              TextFormField(
                controller: _emailC,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: _phoneC,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save Changes' : 'Add Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
