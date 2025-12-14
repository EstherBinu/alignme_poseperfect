import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_painter.dart';
import 'dart:math';
import 'dart:typed_data'; // NEW: Required for Uint8List
import 'package:flutter/foundation.dart'; // NEW: Required for WriteBuffer

class PoseCorrectionScreen extends StatefulWidget {
  final String poseKey;

  const PoseCorrectionScreen({required this.poseKey, super.key});

  @override
  State<PoseCorrectionScreen> createState() => _PoseCorrectionScreenState();
}

class _PoseCorrectionScreenState extends State<PoseCorrectionScreen> {
  // ... (State variables and initialization remain the same) ...
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String _feedbackMessage = "Checking Camera Permissions...";
  late PoseDetector _poseDetector;
  Pose? _detectedPose;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
    _initializeCamera();
  }

  void _initializeDetector() {
    final options = PoseDetectorOptions();
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    // ... (Camera initialization remains the same) ...
    var status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _feedbackMessage = "Camera permission denied. Cannot start correction.";
      });
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() {
        _feedbackMessage = "No camera found on this device.";
      });
      return;
    }

    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      if (_cameraController!.value.focusMode != null) {
        await _cameraController!.setFocusMode(FocusMode.auto);
      }

      _cameraController!.startImageStream(_processCameraImage);

      setState(() {
        _isCameraInitialized = true;
        _feedbackMessage = "Detector Initialized. Stand in position.";
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = "Error initializing camera: $e";
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isCameraInitialized || _isDetecting || _poseDetector == null) return;
    _isDetecting = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }

    try {
      final List<Pose> detectedPoses = await _poseDetector.processImage(
        inputImage,
      );

      if (detectedPoses.isNotEmpty) {
        final firstPose = detectedPoses.first;
        final feedback = _getCorrectionFeedback(firstPose, widget.poseKey);

        setState(() {
          _detectedPose = firstPose;
          _feedbackMessage = feedback;
        });
      } else {
        setState(() {
          _detectedPose = null;
          _feedbackMessage =
              "Stand further back and ensure full body is visible.";
        });
      }
    } catch (e) {
      print("Error processing pose: $e");
    } finally {
      _isDetecting = false;
    }
  }

  // *** FIXED: Helper to convert CameraImage to InputImage (New ML Kit API) ***
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null ||
        _cameraController!.value.previewSize == null)
      return null;

    // 1. Combine all image planes into a single buffer (required for YUV format)
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 2. Create the Metadata object (Renamed from InputImageData)
    final metadata = InputImageMetadata(
      // *** FIX: Class RENAMED to InputImageMetadata ***
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation0deg, // Rotation is handled in UI
      format: InputImageFormat.yuv420, // Must match the camera setting
      bytesPerRow:
          image.planes[0].bytesPerRow, // Critical for ML Kit processing
    );

    // 3. Create the InputImage from the combined bytes and metadata
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata, // *** FIX: Parameter RENAMED to metadata ***
    );
  }

  // Helper function to calculate angle (in degrees) between three landmarks
  double _getAngle(PoseLandmark p1, PoseLandmark v1, PoseLandmark p2) {
    // This uses the Law of Cosines to calculate the angle at vertex v1.
    final a = sqrt(pow(v1.x - p2.x, 2) + pow(v1.y - p2.y, 2));
    final b = sqrt(pow(v1.x - p1.x, 2) + pow(v1.y - p1.y, 2));
    final c = sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));

    if (a == 0.0 || b == 0.0) return 0.0;

    final cosTheta = (b * b + a * a - c * c) / (2 * b * a);
    final safeCosTheta = cosTheta.clamp(-1.0, 1.0);

    return acos(safeCosTheta) * (180 / pi);
  }

  // *** NEW: The CORE CORRECTION LOGIC FUNCTION ***
  String _getCorrectionFeedback(Pose pose, String poseKey) {
    PoseLandmark? getLandmark(PoseLandmarkType type) => pose.landmarks[type];

    if (poseKey == 'mountain_pose') {
      final leftShoulder = getLandmark(PoseLandmarkType.leftShoulder);
      final rightShoulder = getLandmark(PoseLandmarkType.rightShoulder);
      final leftAnkle = getLandmark(PoseLandmarkType.leftAnkle);
      final rightAnkle = getLandmark(PoseLandmarkType.rightAnkle);
      final leftHip = getLandmark(PoseLandmarkType.leftHip);
      final leftKnee = getLandmark(PoseLandmarkType.leftKnee);

      if (leftShoulder == null ||
          rightShoulder == null ||
          leftAnkle == null ||
          rightAnkle == null ||
          leftHip == null ||
          leftKnee == null) {
        return "Please ensure full body is visible for analysis.";
      }

      // 1. Torso Alignment Check (Should be ~180 degrees)
      final leftTorsoAngle = _getAngle(leftShoulder, leftHip, leftKnee);
      if (leftTorsoAngle < 170) {
        return "Torso Check: Tuck your tailbone and align your back to be perfectly straight.";
      }

      // 2. Shoulder Level Check
      final shoulderHeightDiff = (leftShoulder.y - rightShoulder.y).abs();
      if (shoulderHeightDiff > 0.04) {
        return "Shoulder Check: Drop your high shoulder and relax your neck.";
      }

      return "Perfect Mountain Pose! Hold steady and breathe.";
    }

    // Add logic for 'tree_pose' here

    return "Analyzing Pose...";
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI code remains the same) ...
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

    final Size size = MediaQuery.of(context).size;
    final double aspectRatio = _cameraController!.value.aspectRatio;

    return Scaffold(
      appBar: AppBar(title: Text(widget.poseKey.toUpperCase())),
      body: Stack(
        children: [
          // Camera Feed with Zoom Fix
          Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: size.width / aspectRatio,
                  height: size.height / aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          ),

          // Overlay for Drawing Skeleton (Visual Feedback)
          if (_detectedPose != null &&
              _cameraController!.value.previewSize != null)
            Positioned.fill(
              child: CustomPaint(
                painter: PosePainter(
                  _detectedPose!,
                  _cameraController!.value.previewSize!,
                ),
              ),
            ),

          // Feedback Message
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
