import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pet_connect_app/models/medical_note.dart';
import 'package:pet_connect_app/screens/add_edit_medical_note_screen.dart';
import 'package:pet_connect_app/models/calendar_event.dart';

class HealthDetailsScreen extends StatefulWidget {
  static const String routeName = '/health-details';

  // The petId is now required
  final String petId;

  const HealthDetailsScreen({super.key, required this.petId});

  @override
  State<HealthDetailsScreen> createState() => _HealthDetailsScreenState();
}

class _HealthDetailsScreenState extends State<HealthDetailsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late final Stream<List<CalendarEvent>> _eventsStream;
  Map<DateTime, List<CalendarEvent>> _events = {};

  late final Stream<List<MedicalNote>> _medicalNotesStream;
  List<MedicalNote> _medicalNotes = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventsStream = _getEventsStream();
    _medicalNotesStream = _getMedicalNotesStream();
  }

  Stream<List<MedicalNote>> _getMedicalNotesStream() {
    final supabase = Supabase.instance.client;
    return supabase
        .from('medical_notes')
        .stream(primaryKey: ['id'])
        .eq('pet_id', widget.petId)
        .map((maps) {
          final notes = maps.map((map) => MedicalNote(
            id: map['id'] as int,
            title: map['title'] as String,
            content: map['content'] as String,
            createdAt: DateTime.parse(map['created_at'] as String),
          )).toList();
          setState(() {
            _medicalNotes = notes;
          });
          return notes;
        });
  }

  Stream<List<CalendarEvent>> _getEventsStream() {
    final supabase = Supabase.instance.client;
    return supabase
        .from('calendar_events')
        .stream(primaryKey: ['id'])
        .eq('pet_id', widget.petId) // We now filter by the real petId
        .map((maps) {
          final events = <DateTime, List<CalendarEvent>>{};
          for (var map in maps) {
            final timeParts = (map['event_time'] as String).split(':');
            final event = CalendarEvent(
              id: map['id'] as int,
              title: map['title'] as String,
              description: map['description'] as String,
              date: DateTime.parse(map['event_date'] as String),
              time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
            );
            final date = DateTime.utc(event.date.year, event.date.month, event.date.day);
            if (events[date] == null) {
              events[date] = [];
            }
            events[date]!.add(event);
          }
          setState(() {
            _events = events;
          });
          return []; // The stream is just for triggering rebuilds, we use the state `_events`
        });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final date = DateTime.utc(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Calendar'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          StreamBuilder(
            stream: _eventsStream,
            builder: (context, snapshot) {
              return TableCalendar<CalendarEvent>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              );
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Text("Today's Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: ListTile(
                          leading: const Icon(Icons.event_note),
                          title: Text(event.title),
                          subtitle: Text(event.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(event.time.format(context)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(event),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 30, thickness: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AddEditMedicalNoteScreen.routeName,
                            arguments: {
                              'petId': widget.petId,
                              'note': null,
                            },
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Note'),
                      ),
                    ],
                  ),
                ),
                // Medical notes list
                Expanded(
                  child: StreamBuilder<List<MedicalNote>>(
                    stream: _medicalNotesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No medical notes yet.'));
                      }
                      final notes = snapshot.data!;
                      return ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                            child: ListTile(
                              title: Text(note.title),
                              subtitle: Text('Created on: ${note.createdAt.toLocal().toString().split(' ')[0]}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AddEditMedicalNoteScreen.routeName,
                                  arguments: {
                                    'petId': widget.petId,
                                    'note': note,
                                  },
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(),
        label: const Text('Add Event'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmationDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text('Are you sure you want to delete this event?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteEvent(event);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(CalendarEvent event) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('calendar_events').delete().eq('id', event.id);
    } catch (e) {
      // Handle error
      print("Error deleting event: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting event: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog state
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              setDialogState(() => selectedDate = pickedDate);
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Time: ${selectedTime.format(context)}"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setDialogState(() => selectedTime = pickedTime);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final supabase = Supabase.instance.client;
                    final userId = supabase.auth.currentUser?.id;

                    if (userId == null) return;

                    try {
                      await supabase.from('calendar_events').insert({
                        'pet_id': widget.petId,
                        'user_id': userId,
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'event_date': selectedDate.toIso8601String(),
                        'event_time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00',
                      });
                      Navigator.pop(context);
                    } catch (e) {
                      // Handle error
                      print("Error adding event: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error adding event: $e"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}