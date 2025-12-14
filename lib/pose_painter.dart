// lib/pose_painter.dart - FINAL FIX FOR SKELETON MIRRORING AND ROTATION

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size absoluteImageSize; // The original size of the image frame (e.g., 640x480)

  PosePainter(this.pose, this.absoluteImageSize);

  // Define the joints and connections for the skeleton (unchanged)
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
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    // Helper function to convert normalized landmark coordinates to screen coordinates
    Offset offsetForLandmark(PoseLandmark landmark) {
      
      // Calculate scaling factors:
      // Screen Width (size.width) maps to Image Height (absoluteImageSize.height)
      final double scaleX = size.width / absoluteImageSize.height;
      // Screen Height (size.height) maps to Image Width (absoluteImageSize.width)
      final double scaleY = size.height / absoluteImageSize.width;
      
      // 1. ROTATION FIX: Swap X and Y for the 90-degree correction.
      final double landmarkY = landmark.y;
      final double landmarkX = landmark.x;

      // 2. MIRRORING FIX: Apply the horizontal flip (1.0 - coordinate) to the
      // coordinate that controls the final horizontal screen position.
      // After the swap, the X-axis of the screen is controlled by the original Y-coordinate.
      // The Y-axis of the screen is controlled by the original X-coordinate.
      // This is complicated! Let's simplify the final result:

      // Corrected X (Horizontal Screen Position): Uses the scaled landmark Y coordinate.
      // We do NOT mirror this axis.
      final double finalX = landmarkY * scaleX; 

      // Corrected Y (Vertical Screen Position): Uses the scaled and mirrored landmark X coordinate.
      // We MUST mirror this axis to achieve the selfie effect.
      // We flip the X-axis coordinate relative to the image width.
      final double finalY = (absoluteImageSize.width - landmarkX) * scaleY; 

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