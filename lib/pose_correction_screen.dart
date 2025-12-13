// lib/pose_correction_screen.dart (Partial Update)

import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Import the camera package
import 'package:permission_handler/permission_handler.dart'; // Import permission handler

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
    _initializeCamera(); // Call the initialization function
  }
  
  // 2. Camera Initialization Function
  Future<void> _initializeCamera() async {
    // A. Check and Request Permission
    var status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _feedbackMessage = "Camera permission denied. Cannot start correction.";
      });
      return; // Stop if permission is denied
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
        orElse: () => _cameras.first // Fallback to any camera
    );
    
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium, // Use medium resolution to save resources on your 6yr old laptop
      enableAudio: false, // We don't need audio
    );
    
    try {
      await _cameraController!.initialize();
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
    // 3. Dispose Controller on exit
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4. Build the UI based on initialization status
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.poseKey.toUpperCase())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_feedbackMessage), // Show status message
            ],
          ),
        ),
      );
    }
    
    // 5. Camera View (when initialized)
    return Scaffold(
      appBar: AppBar(title: Text(widget.poseKey.toUpperCase())),
      body: Stack(
        children: [
          // Display the camera feed, wrapped in AspectRatio to handle orientation
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
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