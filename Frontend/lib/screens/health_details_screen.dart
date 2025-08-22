import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class HealthDetailsScreen extends StatefulWidget {
  static const String routeName = '/health-details';

  const HealthDetailsScreen({super.key});

  @override
  State<HealthDetailsScreen> createState() => _HealthDetailsScreenState();
}

class _HealthDetailsScreenState extends State<HealthDetailsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medicines:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Example: List of medicines
            const Text(' - Flea & Tick Prevention (Monthly)'),
            const Text(' - Heartworm Medication (Monthly)'),
            const Text(' - Allergy Medication (As needed)'),
            const SizedBox(height: 20),
            const Text(
              'Vaccination & Vet Checkup Calendar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Table Calendar
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 20),
            // Example: Upcoming Appointments (can be integrated with calendar events)
            const Text('Upcoming Appointments:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20),
                SizedBox(width: 10),
                Text('Sept 15, 2025: Annual Checkup (Dr. Smith)'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.vaccines, size: 20),
                SizedBox(width: 10),
                Text('Oct 1, 2025: Rabies Booster'),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement logic to add/update calendar events
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Update Calendar button pressed!')),
          );
        },
        label: const Text('Update Calendar'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
