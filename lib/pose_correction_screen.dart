import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

// NOTE: Add these two imports for the next step (MediaPipe)
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
// import 'package:image/image.dart' as imglib;

class PoseCorrectionScreen extends StatefulWidget {
  final String poseKey;

  const PoseCorrectionScreen({required this.poseKey, super.key});

  @override
  State<PoseCorrectionScreen> createState() => _PoseCorrectionScreenState();
}

class _PoseCorrectionScreenState extends State<PoseCorrectionScreen> {
  // 1. Declare Camera and Status Variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String _feedbackMessage = "Checking Camera Permissions...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // 2. Camera Initialization Function
  Future<void> _initializeCamera() async {
    // A. Check and Request Permission
    var status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _feedbackMessage = "Camera permission denied. Cannot start correction.";
      });
      return;
    }

    // B. Get Available Cameras
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() {
        _feedbackMessage = "No camera found on this device.";
      });
      return;
    }

    // C. Initialize Controller (Using the front camera for self-correction)
    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      // *** FIX 1: Resolution Preset ***
      // LOW is the best choice to reduce automatic cropping/scaling and save resources
      ResolutionPreset.low,
      enableAudio: false,
      // Explicitly using YUV420 for compatibility with ML Kit/MediaPipe core later
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      // Ensure camera settings are optimal
      if (_cameraController!.value.focusMode != null) {
        await _cameraController!.setFocusMode(FocusMode.auto);
      }

      setState(() {
        _isCameraInitialized = true;
        _feedbackMessage = "Camera Ready. Please assume the pose.";
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = "Error initializing camera: $e";
      });
    }
  }

  @override
  void dispose() {
    // Dispose Controller on exit
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4. Build the UI based on initialization status
    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.poseKey.toUpperCase())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_feedbackMessage),
            ],
          ),
        ),
      );
    }

    // 5. Camera View (when initialized)
    final Size size = MediaQuery.of(context).size;
    final double aspectRatio = _cameraController!.value.aspectRatio;

    return Scaffold(
      appBar: AppBar(title: Text(widget.poseKey.toUpperCase())),
      body: Stack(
        children: [
          // *** FIX 2: Correct Layout Transformation ***
          // This setup ensures the camera feed covers the entire screen,
          // handles the inherent 90-degree rotation of the stream, and
          // avoids the zoomed/bulged effect by respecting the full field of view.
          Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: FittedBox(
                fit: BoxFit.cover, // Ensure it fills the screen
                child: SizedBox(
                  // Swap width and height based on the controller's aspect ratio
                  // to correct the rotation and maintain the full portrait view.
                  width: size.width / aspectRatio,
                  height: size.height / aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          ),

          // ... (Overlay for Skeleton and Feedback will go here)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.6),
              child: Text(
                _feedbackMessage,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
