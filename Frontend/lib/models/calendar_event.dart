import 'package:flutter/material.dart';

class CalendarEvent {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
  });
}
