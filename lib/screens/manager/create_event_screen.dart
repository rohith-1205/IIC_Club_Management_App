import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _loading = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final reference = _referenceController.text.trim();
    final createdBy = FirebaseAuth.instance.currentUser!.uid;

    if (title.isEmpty ||
        description.isEmpty ||
        reference.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'description': description,
        'reference': reference,
        'eventDate': Timestamp.fromDate(_selectedDate!),
        'eventTime': _selectedTime!.format(context),
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'presentCount': 0,
        'absentCount': 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// EVENT TITLE
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// DESCRIPTION
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// REFERENCE
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference (link / note)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            /// DATE PICKER
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : _selectedDate!.toLocal().toString().split(' ')[0],
                ),
                onPressed: _pickDate,
              ),
            ),
            const SizedBox(height: 12),

            /// TIME PICKER
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime == null
                      ? 'Select Time'
                      : _selectedTime!.format(context),
                ),
                onPressed: _pickTime,
              ),
            ),
            const SizedBox(height: 24),

            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _createEvent,
                      child: const Text('Create Event'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}