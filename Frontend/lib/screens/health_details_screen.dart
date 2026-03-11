import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pet_connect_app/models/medical_note.dart';
import 'package:pet_connect_app/screens/add_edit_medical_note_screen.dart';
import 'package:pet_connect_app/models/calendar_event.dart';

class HealthDetailsScreen extends StatefulWidget {
  static const String routeName = '/health-details';

  final String? petId;

  const HealthDetailsScreen({super.key, this.petId});

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

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) {
      _selectedDay = _focusedDay;
      _eventsStream = _getEventsStream();
      _medicalNotesStream = _getMedicalNotesStream();
    }
  }

  Stream<List<MedicalNote>> _getMedicalNotesStream() {
    final supabase = Supabase.instance.client;
    return supabase
        .from('medical_notes')
        .stream(primaryKey: ['id'])
        .eq('pet_id', widget.petId!)
        .map((maps) {
          final notes = maps.map((map) => MedicalNote(
            id: map['id'] as int,
            title: map['title'] as String,
            content: map['content'] as String,
            createdAt: DateTime.parse(map['created_at'] as String),
          )).toList();
          return notes;
        });
  }

  Stream<List<CalendarEvent>> _getEventsStream() {
    final supabase = Supabase.instance.client;
    return supabase
        .from('calendar_events')
        .stream(primaryKey: ['id'])
        .eq('pet_id', widget.petId!)
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
              userId: map['user_id'] as String,
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
          return [];
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

  void _deleteMedicalNote(MedicalNote note) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.from('medical_notes').delete().eq('id', note.id).select();
      if (response.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Cannot delete this note."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting note: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteNoteDialog(MedicalNote note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Note', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${note.title}"?', style: GoogleFonts.poppins()),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
            ElevatedButton(
              onPressed: () {
                _deleteMedicalNote(note);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteEventDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Event', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${event.title}"?', style: GoogleFonts.poppins()),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
            ElevatedButton(
              onPressed: () {
                _deleteEvent(event);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(CalendarEvent event) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.from('calendar_events').delete().eq('id', event.id).select();
      if (response.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: You may not have permission to delete this event."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.petId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Health Calendar', style: GoogleFonts.poppins())),
        body: Center(child: Text('No pet selected', style: GoogleFonts.poppins())),
      );
    }
    final selectedEvents = _getEventsForDay(_selectedDay!);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Health Calendar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Calendar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: StreamBuilder(
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
                    headerStyle: HeaderStyle(
                      titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      formatButtonVisible: false,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  );
                },
              ),
            ),
          ),
          
          // Events Header
          if (selectedEvents.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  "Events on ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
            ),
          
          // Events List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = selectedEvents[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.event_note, color: AppColors.primary),
                      ),
                      title: Text(event.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(event.description, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                            child: Text(event.time.format(context), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _showDeleteEventDialog(event),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: selectedEvents.length,
            ),
          ),

          // No Events Placeholder
          if (selectedEvents.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text("No events for this day", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(child: const SizedBox(height: 24)),

          // Medical History Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Medical History', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AddEditMedicalNoteScreen.routeName, arguments: {'petId': widget.petId, 'note': null}),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text('Add Note', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          // Medical Notes List
          StreamBuilder<List<MedicalNote>>(
            stream: _medicalNotesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text('No medical notes added yet.', style: GoogleFonts.poppins(color: Colors.grey[500])),
                    ),
                  ),
                );
              }
              final notes = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = notes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.medical_information, color: Colors.teal),
                          ),
                          title: Text(note.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Created: ${note.createdAt.toLocal().toString().split(' ')[0]}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                          ),
                          onTap: () => Navigator.pushNamed(context, AddEditMedicalNoteScreen.routeName, arguments: {'petId': widget.petId, 'note': note}),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _showDeleteNoteDialog(note),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: notes.length,
                ),
              );
            },
          ),
          
          // Bottom Padding so FAB doesn't cover last item
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Event', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Add New Event', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                      title: Text(selectedDate.toLocal().toString().split(' ')[0], style: GoogleFonts.poppins()),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                            child: child!,
                          ),
                        );
                        if (pickedDate != null) setDialogState(() => selectedDate = pickedDate);
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      leading: const Icon(Icons.access_time, color: AppColors.primary),
                      title: Text(selectedTime.format(context), style: GoogleFonts.poppins()),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                            child: child!,
                          ),
                        );
                        if (pickedTime != null) setDialogState(() => selectedTime = pickedTime);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;

                    final supabase = Supabase.instance.client;
                    final userId = supabase.auth.currentUser?.id;

                    if (userId == null) return;

                    try {
                      final eventData = {
                        'pet_id': widget.petId,
                        'user_id': userId,
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'event_date': selectedDate.toIso8601String(),
                        'event_time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00',
                      };

                      final newEvent = await supabase.from('calendar_events').insert(eventData).select().single();
                      await Supabase.instance.client.functions.invoke('send-notification', body: {'record': newEvent});

                      if (!mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error adding event: $e"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}