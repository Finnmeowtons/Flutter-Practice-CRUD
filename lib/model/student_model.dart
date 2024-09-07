class StudentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String course;
  final String year;
  final String enrolled;

  StudentModel({
      required this.id,
      required this.firstName,
      required this.lastName,
      required this.course,
      required this.year,
      required this.enrolled
  });

  factory StudentModel.fromJson(Map<String, dynamic> json){
    return StudentModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      course: json['course'],
      year: json['year'],
      enrolled: json['enrolled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'first_name': firstName,
      'last_name': lastName,
      'course': course,
      'year': year,
      'enrolled': enrolled,
    };
  }
  
  List<Object> get props => [id, firstName, lastName, course, year, enrolled];
}
