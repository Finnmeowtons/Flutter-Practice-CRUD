import 'package:flutter_api2/model/student_model.dart';

abstract class StudentRepository{
  Future<List<StudentModel>> fetchStudents();
  Future<void> createStudent(StudentModel student);
  Future<void> deleteStudent(String id);
  Future<void> updateStudent(String id, StudentModel student);
}