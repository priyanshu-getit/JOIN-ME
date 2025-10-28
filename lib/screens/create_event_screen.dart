import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  int _peopleNeeded = 1;
  DateTime? _eventDateTime;
  bool _loading = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate() || _eventDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final username = userDoc.data()?['username'] ?? 'Unknown';
      final profilePhotoUrl =
          userDoc.data()?['profilePhotoUrl'] ??
          'assets/default_avatar.png'; // ✅ fallback

      await FirebaseFirestore.instance.collection('events').add({
        'title': _title,
        'description': _description,
        'totalPeople': _peopleNeeded, // ✅ standardized field
        'creatorUsername': username,
        'creatorUID': user.uid,
        'creatorPhotoUrl': profilePhotoUrl, // ✅ consistent naming
        'eventDateTime': Timestamp.fromDate(_eventDateTime!),
        'createdAt': Timestamp.now(),
        'joinedCount': 0, // ✅ initialize
        'joinedUsers': [], // ✅ initialize
        'lat': 0.0,
        'lng': 0.0,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Event Created")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Event")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                      ),
                      onSaved: (value) => _title = value!.trim(),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter title" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                      onSaved: (value) => _description = value!.trim(),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter description"
                          : null,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Total People Needed",
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _peopleNeeded = int.parse(value!),
                      validator: (value) =>
                          value == null || int.tryParse(value) == null
                          ? "Enter valid number"
                          : null,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _pickDateTime,
                      child: Text(
                        _eventDateTime == null
                            ? "Pick Event Date & Time"
                            : "Event Time: ${_eventDateTime!.toLocal()}",
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text("Create Event"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
