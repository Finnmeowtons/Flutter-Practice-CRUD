import 'package:flutter_api2/model/student_model.dart';
import 'package:flutter_api2/repositories/student_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentRepositoryImpl implements StudentRepository {
  @override
  Future<List<StudentModel>> fetchStudents() async {
    final response = await http.get(Uri.parse('http://localhost:3000/student'));
    print("await");
    if (response.statusCode == 200) {
      print("Success");
      // print("Id Decode: ${json.decode(response.body)['id']}");
      final List<dynamic> data = json.decode(response.body);
      // print("this is the data: ${data.map((json)=> StudentModel.fromJson(json)).toList()}");

      return data.map((json) => StudentModel.fromJson(json)).toList();
    } else {
      print("Failed");
      throw Exception('Failed to load students');
    }
  }

  @override
  Future<void> createStudent(StudentModel student) async {
    final response = await http.post(Uri.parse("http://localhost:3000/student/create"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(student.toJson()));

    if (response.statusCode != 201) {
      throw Exception('Failed to create student');
    }
  }

  @override
  Future<void> deleteStudent(String id) async {
    final response = await http.delete(Uri.parse("http://localhost:3000/student/$id"));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete student');
    }
  }

  @override
  Future<void> updateStudent(String id, StudentModel student) async {
    final response = await http.put(
      Uri.parse("http://localhost:3000/student/$id"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(student.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update student');
    }
  }
}
