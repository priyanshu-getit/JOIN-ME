import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text('Event not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final eventDate =
              (data['eventDateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
          final joinedUsers = List<String>.from(data['joinedUsers'] ?? []);
          final creatorId = data['creatorId'];
          final isCreator = currentUser?.uid == creatorId;
          final isJoined = joinedUsers.contains(currentUser?.uid);
          final isExpired = DateTime.now().isAfter(eventDate);

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Untitled Event',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data['description'] ?? 'No description provided',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${eventDate.toLocal()}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${joinedUsers.length}/${data['totalPeople']} joined',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                const Spacer(),
                if (isExpired)
                  const Text(
                    'Event Expired ⏰',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                else ...[
                  if (isCreator)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCDD2), // light pink
                        foregroundColor: const Color(0xFFC62828), // dark red
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Event?'),
                            content: const Text(
                              'This will permanently remove the event.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('events')
                              .doc(eventId)
                              .delete();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    )
                  else if (!isJoined)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.group_add),
                      label: const Text('Join Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8E6C9), // light green
                        foregroundColor: const Color(0xFF2E7D32), // deep green
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(eventId)
                            .update({
                              'joinedUsers': FieldValue.arrayUnion([
                                currentUser!.uid,
                              ]),
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully joined the event!'),
                          ),
                        );
                      },
                    )
                  else ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE0B2), // light peach
                        foregroundColor: const Color(
                          0xFFD84315,
                        ), // soft orange-red
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(eventId)
                            .update({
                              'joinedUsers': FieldValue.arrayRemove([
                                currentUser!.uid,
                              ]),
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You left the event successfully.'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Open Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBBDEFB), // light blue
                        foregroundColor: const Color(0xFF1565C0), // deep blue
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(eventId: eventId),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
