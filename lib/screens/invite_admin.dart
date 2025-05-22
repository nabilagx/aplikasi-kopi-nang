// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class InviteAdminPage extends StatelessWidget {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Fungsi untuk update status undangan (accept atau reject)
//   Future<void> _updateInvitationStatus(String docId, String newStatus) async {
//     await _firestore.collection('adminInvitations').doc(docId).update({
//       'status': newStatus,
//       if (newStatus == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userEmail = _auth.currentUser?.email ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Daftar Undangan Admin'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('adminInvitations')
//             .where('email', isEqualTo: userEmail)
//             .orderBy('sentAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
//           }
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           final invites = snapshot.data?.docs ?? [];

//           if (invites.isEmpty) {
//             return Center(child: Text('Tidak ada undangan admin.'));
//           }

//           return ListView.builder(
//             itemCount: invites.length,
//             itemBuilder: (context, index) {
//               final doc = invites[index];
//               final data = doc.data() as Map<String, dynamic>;
//               final status = data['status'] ?? 'pending';
//               final sentAt = data['sentAt'] as Timestamp?;
//               final sentAtStr = sentAt != null
//                   ? DateTime.fromMillisecondsSinceEpoch(sentAt.seconds * 1000).toLocal().toString()
//                   : 'Waktu tidak diketahui';

//               return Card(
//                 margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 child: ListTile(
//                   title: Text('Undangan Admin'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Email: ${data['email']}'),
//                       Text('Status: $status'),
//                       Text('Dikirim pada: $sentAtStr'),
//                     ],
//                   ),
//                   trailing: status == 'pending'
//                       ? Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.check, color: Colors.green),
//                               tooltip: 'Terima',
//                               onPressed: () async {
//                                 await _updateInvitationStatus(doc.id, 'accepted');
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(content: Text('Undangan diterima. Anda sekarang admin.')),
//                                 );
//                               },
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.close, color: Colors.red),
//                               tooltip: 'Tolak',
//                               onPressed: () async {
//                                 await _updateInvitationStatus(doc.id, 'rejected');
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(content: Text('Undangan ditolak.')),
//                                 );
//                               },
//                             ),
//                           ],
//                         )
//                       : Icon(
//                           status == 'accepted' ? Icons.check_circle : Icons.cancel,
//                           color: status == 'accepted' ? Colors.green : Colors.red,
//                         ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
