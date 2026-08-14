import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../controllers/call_controller.dart';
import '../models/call_model.dart';

class CallScreen extends StatefulWidget {
  final String chatId;
  final bool isVideo;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.chatId,
    required this.isVideo,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallController _callController = CallController.to;

  @override
  void initState() {
    super.initState();
    _setupCall();
  }

  Future<void> _setupCall() async {
    if (widget.isCaller) {
      await _callController.startCall(
        widget.chatId,
        'callee_id',
        widget.isVideo,
      );
    } else {
      await _callController.answerCall(widget.chatId, widget.isVideo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final callState = _callController.callState.value;
          final networkStatus = _callController.networkStatus.value;

          return Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[900]!,
                      Colors.black,
                    ],
                  ),
                ),
              ),

              // Main content
              Column(
                children: [
                  // Header
                  _buildHeader(callState),

                  const Spacer(),

                  // Remote video or avatar
                  if (widget.isVideo && callState == CallState.active)
                    _buildVideoView()
                  else
                    _buildAvatarView(callState),

                  const Spacer(),

                  // Call controls
                  _buildCallControls(),

                  const SizedBox(height: 20),
                ],
              ),

              // Network status badge
              Positioned(
                top: 80,
                right: 16,
                child: _buildNetworkStatus(networkStatus),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(CallState callState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          const Spacer(),
          if (callState == CallState.ringing)
            const Text(
              'Calling...',
              style: TextStyle(color: Colors.white70),
            ),
          if (callState == CallState.connecting)
            const Text(
              'Connecting...',
              style: TextStyle(color: Colors.white70),
            ),
          if (callState == CallState.active)
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.greenAccent),
                      SizedBox(width: 4),
                      Text(
                        'Encrypted',
                        style:
                            TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _callController.formattedDuration,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarView(CallState callState) {
    return Column(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.person, size: 70, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Caller Name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          callState == CallState.ringing ? 'Ringing...' : 'Connected',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildVideoView() {
    return Stack(
      children: [
        // Remote video
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.6,
          color: Colors.black,
          child: RTCVideoView(_callController.remoteRenderer),
        ),

        // Local video (PIP)
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RTCVideoView(_callController.localRenderer),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallControls() {
    final isMuted = _callController.isMuted.value;
    final isSpeakerOn = _callController.isSpeakerOn.value;
    final isCameraOn = _callController.isCameraOn.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute
          _buildControlButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            onTap: () => _callController.toggleMute(),
          ),

          // End Call
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            size: 60,
            onTap: () {
              _callController.endCall();
              Get.back();
            },
          ),

          // Speaker
          _buildControlButton(
            icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            onTap: () => _callController.toggleSpeaker(),
          ),

          // Camera (for video calls)
          if (widget.isVideo)
            _buildControlButton(
              icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
              onTap: () => _callController.toggleCamera(),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color color = Colors.white,
    double size = 50,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: color == Colors.red
            ? Colors.red
            : Colors.white.withAlpha(51),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  Widget _buildNetworkStatus(String networkStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            networkStatus == 'connected'
                ? Icons.signal_cellular_4_bar
                : networkStatus == 'reconnecting...'
                    ? Icons.signal_cellular_connected_no_internet_4_bar
                    : Icons.signal_cellular_off,
            color: networkStatus == 'connected'
                ? Colors.green
                : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            networkStatus,
            style: TextStyle(
              color: networkStatus == 'connected'
                  ? Colors.green
                  : Colors.orange,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
