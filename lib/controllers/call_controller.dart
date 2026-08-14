import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import '../models/call_model.dart';
import '../services/encryption_service.dart';
import '../services/signaling_service.dart';

class CallController extends GetxController {
  static CallController get to => Get.isRegistered<CallController>()
      ? Get.find<CallController>()
      : Get.put(CallController(), permanent: true);

  // Services
  final EncryptionService _encryption = EncryptionService();
  final SignalingService _signaling = SignalingService();
  final Connectivity _connectivity = Connectivity();

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Reactive state
  final Rx<CallModel?> currentCall = Rx<CallModel?>(null);
  final Rx<CallState> callState = CallState.ringing.obs;
  final RxBool isCallActive = false.obs;
  final RxBool isMuted = false.obs;
  final RxBool isSpeakerOn = false.obs;
  final RxBool isCameraOn = true.obs;
  final RxBool isReconnecting = false.obs;
  final RxString networkStatus = 'connected'.obs;
  final RxInt durationSeconds = 0.obs;

  Timer? _durationTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;

  // WebRTC Configuration (Free STUN/TURN)
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
    ],
    'iceTransportPolicy': 'all',
    'rtcpMuxPolicy': 'require',
  };

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    _connectivity.onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _handleNetworkChange(result);
    });

    _encryption.generateKeyPair();
  }

  // ============ CALL INITIATION ============

  Future<void> startCall(String chatId, String calleeId, bool isVideo) async {
    try {
      final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      final startTime = DateTime.now();

      currentCall.value = CallModel(
        id: callId,
        chatId: chatId,
        callerId: _getCurrentUserId(),
        calleeId: calleeId,
        type: isVideo ? CallType.video : CallType.audio,
        state: CallState.ringing,
        direction: CallDirection.outgoing,
        startTime: startTime,
        isEncrypted: true,
        encryptionKey: _encryption.getPublicKeyBase64(),
      );

      callState.value = CallState.ringing;
      await _initializeLocalStream(isVideo);

      _peerConnection = await createPeerConnection(_configuration);
      _setupPeerConnectionListeners();

      _localStream?.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await _signaling.sendCallOffer(chatId, currentCall.value!.callerId, calleeId, {
        'sdp': offer.toMap(),
        'encryptionKey': _encryption.getPublicKeyBase64(),
        'callType': isVideo ? 'video' : 'audio',
      });

      _signaling.listenForAnswer(chatId).listen((data) async {
        if (data.isNotEmpty) {
          await _handleAnswer(data['answer']);
        }
      });

      _signaling.listenForCandidates(chatId).listen((data) {
        if (data.isNotEmpty) {
          _handleRemoteCandidate(data['candidate']);
        }
      });

      isCallActive.value = true;
    } catch (e) {
      Get.snackbar('Call Error', 'Start call failed: $e');
    }
  }

  // ============ ANSWER CALL ============

  Future<void> answerCall(String chatId, bool isVideo) async {
    try {
      final offerData = await _signaling.listenForOffer(chatId).first;
      if (offerData.isEmpty) {
        throw Exception('No call offer found');
      }

      currentCall.value = CallModel(
        id: 'call_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        callerId: offerData['callerId'] ?? '',
        calleeId: _getCurrentUserId(),
        type: isVideo ? CallType.video : CallType.audio,
        state: CallState.connecting,
        direction: CallDirection.incoming,
        startTime: DateTime.now(),
        isEncrypted: true,
        encryptionKey: offerData['offer']?['encryptionKey'],
      );

      if (offerData['offer']?['encryptionKey'] != null) {
        _encryption.setPeerPublicKey(offerData['offer']['encryptionKey']);
      }

      await _initializeLocalStream(isVideo);

      _peerConnection = await createPeerConnection(_configuration);
      _setupPeerConnectionListeners();

      _localStream?.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      final offerSdp = offerData['offer']?['sdp'];
      if (offerSdp != null) {
        await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(offerSdp['sdp'], offerSdp['type']));
      }

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _signaling.sendCallAnswer(chatId, answer.toMap());

      _signaling.listenForCandidates(chatId).listen((data) {
        if (data.isNotEmpty) {
          _handleRemoteCandidate(data['candidate']);
        }
      });

      isCallActive.value = true;
      callState.value = CallState.active;
      _startDurationTimer();
    } catch (e) {
      Get.snackbar('Call Error', 'Answer call failed: $e');
    }
  }

  void _setupPeerConnectionListeners() {
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null && currentCall.value != null) {
        _signaling.sendIceCandidate(currentCall.value!.chatId, candidate.toMap());
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' || event.track.kind == 'audio') {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        callState.value = CallState.active;
        _startDurationTimer();
      }
    };

    _peerConnection!.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          callState.value = CallState.active;
          _startDurationTimer();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _handleDisconnect();
          break;
        default:
          break;
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      networkStatus.value = state.toString().split('.').last.toLowerCase();
    };
  }

  Future<void> _handleNetworkChange(ConnectivityResult result) async {
    if (!isCallActive.value) return;

    if (result == ConnectivityResult.none) {
      isReconnecting.value = true;
      networkStatus.value = 'disconnected';
      callState.value = CallState.connecting;
    } else {
      await _attemptReconnect();
    }
  }

  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      await endCall();
      return;
    }

    _reconnectAttempts++;
    isReconnecting.value = true;
    networkStatus.value = 'reconnecting...';

    try {
      await _peerConnection?.close();
      _peerConnection = await createPeerConnection(_configuration);
      _setupPeerConnectionListeners();

      _localStream?.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      if (currentCall.value?.direction == CallDirection.outgoing) {
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        await _signaling.sendCallOffer(
          currentCall.value!.chatId,
          currentCall.value!.callerId,
          currentCall.value!.calleeId,
          {'sdp': offer.toMap()},
        );
      } else {
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        await _signaling.sendCallAnswer(currentCall.value!.chatId, answer.toMap());
      }

      isReconnecting.value = false;
      _reconnectAttempts = 0;
      networkStatus.value = 'connected';
      callState.value = CallState.active;
    } catch (_) {
      _reconnectAttempts++;
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted.value;
    });
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
  }

  void toggleCamera() {
    isCameraOn.value = !isCameraOn.value;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isCameraOn.value;
    });
  }

  Future<void> endCall() async {
    _durationTimer?.cancel();
    _durationTimer = null;

    await _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    _remoteStream = null;

    if (currentCall.value != null) {
      await _signaling.endCall(currentCall.value!.chatId);
    }

    isCallActive.value = false;
    isReconnecting.value = false;
    _reconnectAttempts = 0;
    callState.value = CallState.ended;
    durationSeconds.value = 0;
    currentCall.value = null;
  }

  Future<void> _initializeLocalStream(bool isVideo) async {
    final constraints = {
      'audio': true,
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': 1280,
              'height': 720,
              'frameRate': 30,
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = _localStream;
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    final answer =
        RTCSessionDescription(answerData['sdp'], answerData['type']);
    await _peerConnection!.setRemoteDescription(answer);
    callState.value = CallState.active;
    _startDurationTimer();
  }

  Future<void> _handleRemoteCandidate(Map<String, dynamic> candidateData) async {
    await _peerConnection!.addCandidate(
      RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      ),
    );
  }

  void _handleDisconnect() {
    if (isCallActive.value) {
      _attemptReconnect();
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      durationSeconds.value++;
    });
  }

  String get formattedDuration {
    final minutes = (durationSeconds.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'current_user_id';
  }

  @override
  void onClose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    _durationTimer?.cancel();
    endCall();
    super.onClose();
  }
}
