// lib/pose_painter.dart - FINAL, ROBUST GEOMETRIC FIX

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size absoluteImageSize; // Raw size of the camera image frame (e.g., 480x640)

  PosePainter(this.pose, this.absoluteImageSize);

  static const List<List<PoseLandmarkType>> POSE_SKELETON_CONNECTIONS = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) { // 'size' here is the size of the 75% Expanded area
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    // Helper function to convert landmark coordinates to screen coordinates
    Offset offsetForLandmark(PoseLandmark landmark) {
      
      // Calculate scaling factors:
      // Final Screen Width (size.width) maps to Image Height (absoluteImageSize.height)
      final double scaleFactorX = size.width / absoluteImageSize.height;
      // Final Screen Height (size.height) maps to Image Width (absoluteImageSize.width)
      final double scaleFactorY = size.height / absoluteImageSize.width;
      
      // *** THE FINAL GEOMETRY FIX ***
      
      // 1. Corrected X (Horizontal Screen Position): 
      //    Determined by landmark Y, and flipped for selfie mirror. (Corrected)
      final double finalX = (absoluteImageSize.height - landmark.y) * scaleFactorX; 
      
      // 2. Corrected Y (Vertical Screen Position): 
      //    Determined by landmark X. *** FIX: Invert the Y-axis by flipping the X-coordinate ***
      //    This makes the head (low X value) go to the top of the screen (low Y value), and vice-versa.
      final double finalY = (absoluteImageSize.width - landmark.x) * scaleFactorY; 

      return Offset(finalX, finalY);
    }
    
    // 1. Draw connections (bones)
    for (var connection in POSE_SKELETON_CONNECTIONS) {
      final startLandmark = pose.landmarks[connection.first];
      final endLandmark = pose.landmarks[connection.last];

      if (startLandmark != null && endLandmark != null) {
        final startOffset = offsetForLandmark(startLandmark);
        final endOffset = offsetForLandmark(endLandmark);
        canvas.drawLine(startOffset, endOffset, linePaint);
      }
    }

    // 2. Draw points (joints)
    pose.landmarks.forEach((type, landmark) {
      final center = offsetForLandmark(landmark);
      canvas.drawCircle(center, 4.0, pointPaint);
    });
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}