import 'dart:convert';

class Event {
  int? id;
  String title;
  List<String>? imagePaths;
  DateTime date;
  String? description;

  Event({
    this.id,
    required this.title,
    this.imagePaths,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imagePaths': imagePaths != null ? jsonEncode(imagePaths) : null,
      'date': date.millisecondsSinceEpoch,
      'description': description,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      imagePaths: map['imagePaths'] != null 
          ? List<String>.from(jsonDecode(map['imagePaths']))
          : null,
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      description: map['description'],
    );
  }
}
