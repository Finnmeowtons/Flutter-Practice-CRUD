import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_api2/repositories/student_repository_impl.dart';
import 'package:flutter_api2/model/student_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum Year {
  firstYear('First Year', 'First Year'),
  secondYear('Second Year', 'Second Year'),
  thirdYear('Third Year', 'Third Year'),
  fourthYear('Fourth Year', 'Fourth Year'),
  fifthYear('Fifth Year', 'Fifth Year');

  const Year(this.label, this.year);
  final String label;
  final String year;
}

extension YearExtension on String {
  Year? toYearEnum() {
    return Year.values.firstWhere(
      (year) =>
          year.year == this, // Compare with the 'year' property of the enum
    );
  }
}

class _MyAppState extends State<MyApp> {
  Year? selectedYear;
  var isEnrolled = '0';
  var cardValue = "Card";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black54),
        ),
        labelStyle: TextStyle(color: Colors.black),
      )),
      debugShowCheckedModeBanner: false,
      home: const Student(),
    );
  }
}

class Student extends StatefulWidget {
  const Student({super.key});

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  late Future<List<StudentModel>> futureStudent;
  @override
  void initState() {
    super.initState();
    futureStudent = StudentRepositoryImpl().fetchStudents(); // Initialize here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text("Student"),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (context) => const StudentInformation(
                        isCreatingStudent: true,
                      ))).then((_) => setState(() {
                futureStudent =
                    StudentRepositoryImpl()
                        .fetchStudents();
              }));
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureStudent = StudentRepositoryImpl().fetchStudents();
            });
          },
          child: FutureBuilder<List<StudentModel>>(
              future: futureStudent,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasData ) {
                  final students = snapshot.data!;
                  return Expanded(
                    child: ListView.builder(
                        itemCount: snapshot.data?.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentInformation(
                                        student: student,
                                      ),
                                    )).then((_) => setState(() {
                                      futureStudent =
                                          StudentRepositoryImpl()
                                              .fetchStudents();
                                    }));
                              },
                              child: Card.outlined(
                                child: SizedBox(
                                  width: 360,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${student.lastName}, ${student.firstName} ",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          "${student.year} - ${student.course}",
                                          style:
                                              const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          student.enrolled == "1"
                                              ? "Student is enrolled"
                                              : "Student is not enrolled",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: student.enrolled == "1"
                                                  ? Colors.green
                                                  : Colors.red),
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return Text('${snapshot.error}');
              }),
        ),
      ),
    );
  }
}

class StudentInformation extends StatefulWidget {
  final StudentModel? student;
  final bool isCreatingStudent;
  const StudentInformation(
      {super.key, this.student, this.isCreatingStudent = false});

  @override
  State<StudentInformation> createState() => _StudentInformationState();
}

class _StudentInformationState extends State<StudentInformation> {
  late bool isEnrolled;
  late Year? selectedYear;
  bool isEditing = false;
  late StudentModel student;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController courseController;

  @override
  void initState() {
    super.initState();
    student = widget.student ?? StudentModel(
        id: "",
        firstName: "",
        lastName: "",
        course: "",
        year: "",
        enrolled: "0"
    );
    isEnrolled = widget.student?.enrolled == "1";
    selectedYear = widget.student?.year.toYearEnum();
    firstNameController = TextEditingController(text: widget.student?.firstName);
    lastNameController = TextEditingController(text: widget.student?.lastName);
    courseController = TextEditingController(text: widget.student?.course);
  }

  @override
  Widget build(BuildContext context) {
    final alphabet = RegExp(r'^[a-zA-Z ]+$');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreatingStudent
            ? "Create Student"
            : "Student Information"),
        actions: <Widget>[
          if (isEditing || widget.isCreatingStudent)
            IconButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (widget.isCreatingStudent) {
                      _createStudent();
                    } else {
                      _updateStudent();
                    }
                    setState(() {
                      isEditing = false;
                    });
                  }
                },
                icon: const Icon(Icons.check))
          else
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit)),
                IconButton(
                    onPressed: () {
                      _deleteStudent();
                    },
                    icon: const Icon(Icons.delete))
              ],
            ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 48,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            enabled: isEditing || widget.isCreatingStudent,
                            controller: firstNameController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "First Name"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your first name";
                              } else if (!alphabet.hasMatch(value)) {
                                return "Alphabets only!";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          TextFormField(
                            enabled: isEditing || widget.isCreatingStudent,
                            controller: lastNameController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Last Name"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your last name";
                              } else if (!alphabet.hasMatch(value)) {
                                return "Alphabets only!";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          DropdownButtonFormField<Year>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Year",
                            ),
                            value: selectedYear,
                            items: Year.values.map((Year year) {
                              return DropdownMenuItem<Year>(
                                value: year,
                                child: Text(year.label),
                              );
                            }).toList(),
                            onChanged: isEditing || widget.isCreatingStudent
                                ? (Year? year) {
                                    setState(() {
                                      selectedYear = year;
                                    });
                                  }
                                : null,
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a year';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          TextFormField(
                            enabled: isEditing || widget.isCreatingStudent,
                            controller: courseController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Course"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your course";
                              } else if (!alphabet.hasMatch(value)) {
                                return "Alphabets only!";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text("Enrolled"),
                Switch(
                    value: isEnrolled,
                    onChanged: isEditing || widget.isCreatingStudent
                        ? (bool value) {
                            setState(() {
                              isEnrolled = value;
                            });
                          }
                        : null)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStudent() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to delete this student?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await StudentRepositoryImpl()
                        .deleteStudent(widget.student!.id);
                  } catch (error) {
                    print(error);
                  }
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        });
  }

  Future<void> _createStudent() async {
    final newStudent = StudentModel(
        id: "",
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        course: courseController.text,
        year: selectedYear!.label,
        enrolled: isEnrolled ? "1" : "0");

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Information'),
            content: const Text('Are you sure the information are correct?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await StudentRepositoryImpl().createStudent(newStudent);
                  } catch (error) {
                    print(error);
                  }
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        });
  }

  Future<void> _updateStudent() async {
    final updatedStudent = StudentModel(
        id: widget.student!.id,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        course: courseController.text,
        year: selectedYear!.label,
        enrolled: isEnrolled ? "1" : "0");

    try {
      await StudentRepositoryImpl()
          .updateStudent(widget.student!.id, updatedStudent);

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Success"),
              content: const Text("Student updated successfully"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"))
              ],
            );
          });
    } catch (error) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text("Error updating student: $error"),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"))
              ],
            );
          });
    }
  }
}
