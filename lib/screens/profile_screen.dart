import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'hosted_events_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  List<DocumentSnapshot> hostedEvents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final eventsQuery = await FirebaseFirestore.instance
        .collection('events')
        .where('creatorUID', isEqualTo: user.uid)
        .get();

    setState(() {
      userData = userDoc.data();
      hostedEvents = eventsQuery.docs;
      loading = false;
    });
  }

  Future<double> _getAverageRating(String eventId) async {
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('ratings')
        .get();

    if (ratingsSnapshot.docs.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var doc in ratingsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }
    return totalRating / ratingsSnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FutureBuilder<String?>(
                    future: _getProfilePhotoUrl(
                      FirebaseAuth.instance.currentUser!.uid,
                    ),
                    builder: (context, photoSnapshot) {
                      if (!photoSnapshot.hasData) {
                        return const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person, size: 30),
                        );
                      }
                      final String? profilePhotoUrl = photoSnapshot.data;
                      return CircleAvatar(
                        radius: 30,
                        backgroundImage: profilePhotoUrl != null
                            ? NetworkImage(profilePhotoUrl)
                            : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                        child: profilePhotoUrl == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Username: ${userData?['username'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        "Phone: ${userData?['phone'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        "DOB: ${userData?['dob'] != null ? DateFormat('dd/MM/yyyy').format((userData!['dob'] as Timestamp).toDate()) : 'N/A'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text(
                "Hosted Events:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...hostedEvents.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return FutureBuilder<double>(
                  future: _getAverageRating(doc.id),
                  builder: (context, ratingSnapshot) {
                    if (!ratingSnapshot.hasData) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    final double averageRating = ratingSnapshot.data!;
                    return ListTile(
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Text(
                        'Rating: ${averageRating.toStringAsFixed(1)}',
                      ),
                      trailing: Text(
                        "${data['joined'] ?? 0} / ${data['peopleNeeded'] ?? 0}",
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _getProfilePhotoUrl(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userDoc.data()?['profilePhotoUrl'];
  }
}
