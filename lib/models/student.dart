// lib/models/student.dart
class Student {
  int? id;
  String name;
  int age;
  String grade;
  String email;
  String phone;

  Student({
    this.id,
    required this.name,
    required this.age,
    required this.grade,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'grade': grade,
      'email': email,
      'phone': phone,
    };
  }

  factory Student.fromMap(Map<String, dynamic> m) {
    return Student(
      id: m['id'] as int?,
      name: m['name'] as String,
      age: m['age'] as int,
      grade: m['grade'] as String,
      email: m['email'] as String,
      phone: m['phone'] as String,
    );
  }
}
