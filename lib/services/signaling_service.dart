import 'package:firebase_database/firebase_database.dart';

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Send call offer
  Future<void> sendCallOffer(String chatId, String callerId, String calleeId,
      Map<String, dynamic> offer) async {
    await _db.child('calls/$chatId/offer').set({
      'callerId': callerId,
      'calleeId': calleeId,
      'offer': offer,
      'timestamp': ServerValue.timestamp,
      'status': 'ringing',
    });
  }

  // Send call answer
  Future<void> sendCallAnswer(
      String chatId, Map<String, dynamic> answer) async {
    await _db.child('calls/$chatId/answer').set({
      'answer': answer,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Send ICE candidate
  Future<void> sendIceCandidate(
      String chatId, Map<String, dynamic> candidate) async {
    final ref = _db.child('calls/$chatId/candidates').push();
    await ref.set({
      'candidate': candidate,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Listen for call offer
  Stream<Map<String, dynamic>> listenForOffer(String chatId) {
    return _db.child('calls/$chatId/offer').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data;
    });
  }

  // Listen for call answer
  Stream<Map<String, dynamic>> listenForAnswer(String chatId) {
    return _db.child('calls/$chatId/answer').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data;
    });
  }

  // Listen for ICE candidates
  Stream<Map<String, dynamic>> listenForCandidates(String chatId) {
    return _db.child('calls/$chatId/candidates').onChildAdded.map((event) {
      if (event.snapshot.value == null) return {};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data;
    });
  }

  // End call
  Future<void> endCall(String chatId) async {
    await _db.child('calls/$chatId').remove();
  }

  // Check if call is active
  Future<bool> isCallActive(String chatId) async {
    final snapshot = await _db.child('calls/$chatId').get();
    return snapshot.exists;
  }
}
