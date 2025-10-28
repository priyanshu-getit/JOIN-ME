import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';
import 'hosted_events_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Near You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            onPressed: () {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HostedEventsScreen(creatorUID: currentUser.uid),
                  ),
                );
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('eventDateTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No events available.'));
          }

          final now = DateTime.now();
          final events = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final eventDate = (data['eventDateTime'] as Timestamp).toDate();
            return eventDate.isAfter(now);
          }).toList();

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data = events[index].data() as Map<String, dynamic>;
              final eventId = events[index].id;
              final joinedUsers = List<String>.from(data['joinedUsers'] ?? []);
              final isJoined = joinedUsers.contains(currentUser?.uid);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(data['title'] ?? 'Untitled'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        'Joined: ${joinedUsers.length}/${data['totalPeople']}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${(data['eventDateTime'] as Timestamp).toDate()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: isJoined
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EventDetailScreen(eventId: eventId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
