// import 'package:cloud_firestore/cloud_firestore.dart';

// class ApiService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<String?> getUserRole(String uid) async {
//     try {
//       final doc = await _firestore.collection('users').doc(uid).get();
//       if (doc.exists) {
//         final data = doc.data();
//         return data?['role'];
//       }
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<void> createUser(Map<String, dynamic> userData) async {
//     final uid = userData['uid'] as String;
//     await _firestore.collection('users').doc(uid).set(userData);
//   }
// }
