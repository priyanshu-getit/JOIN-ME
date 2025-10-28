import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Commented out
// import 'package:image_picker/image_picker.dart'; // Commented out

class HostedEventsScreen extends StatefulWidget {
  final String creatorUID;

  const HostedEventsScreen({super.key, required this.creatorUID});

  @override
  _HostedEventsScreenState createState() => _HostedEventsScreenState();
}

class _HostedEventsScreenState extends State<HostedEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  // Commented out until billing is enabled
  // Future<void> _uploadPicture(String eventId) async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //
  //   if (pickedFile == null) return;
  //
  //   final file = File(pickedFile.path);
  //   final storageRef = FirebaseStorage.instance.ref().child(
  //     'event_pictures/$eventId/${DateTime.now().millisecondsSinceEpoch}.jpg',
  //   );
  //   await storageRef.putFile(file);
  //   final downloadURL = await storageRef.getDownloadURL();
  //
  //   await FirebaseFirestore.instance
  //       .collection('events')
  //       .doc(eventId)
  //       .collection('pictures')
  //       .add({'url': downloadURL});
  //
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Picture uploaded!')));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hosted Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Events'),
            Tab(text: 'Pictures'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Events Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('creatorUID', isEqualTo: widget.creatorUID)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data!.docs;

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final data = event.data() as Map<String, dynamic>;
                  final String title = data['title'] ?? 'No Title';

                  return FutureBuilder<double>(
                    future: _getAverageRating(event.id),
                    builder: (context, ratingSnapshot) {
                      if (!ratingSnapshot.hasData) {
                        return const ListTile(title: Text('Loading...'));
                      }

                      final double averageRating = ratingSnapshot.data!;
                      return ListTile(
                        title: Text(title),
                        subtitle: Text(
                          'Rating: ${averageRating.toStringAsFixed(1)}',
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Pictures Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('creatorUID', isEqualTo: widget.creatorUID)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data!.docs;
              final currentUser = FirebaseAuth.instance.currentUser;

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final data = event.data() as Map<String, dynamic>;
                  final String eventId = event.id;

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('events')
                        .doc(eventId)
                        .collection('pictures')
                        .get(),
                    builder: (context, pictureSnapshot) {
                      if (!pictureSnapshot.hasData) {
                        return const ListTile(
                          title: Text('Loading pictures...'),
                        );
                      }

                      final pictures = pictureSnapshot.data!.docs;
                      return Column(
                        children: pictures.map((pic) {
                          final url =
                              (pic.data() as Map<String, dynamic>?)?['url']
                                  as String?;
                          return ListTile(
                            leading: url != null
                                ? Image.network(
                                    url,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image),
                            title: Text('Picture ${pic.id}'),
                            trailing: currentUser?.uid == widget.creatorUID
                                ? IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Picture upload disabled until billing is enabled',
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
