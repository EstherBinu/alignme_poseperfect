// lib/pose_painter.dart

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size absoluteImageSize; // The actual dimensions of the camera frame

  PosePainter(this.pose, this.absoluteImageSize);

  // Define the joints and connections for the skeleton
  static const List<List<PoseLandmarkType>> POSE_SKELETON_CONNECTIONS = [
    // Torso and Hips
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],

    // Left Arm
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],

    // Right Arm
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],

    // Left Leg
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],

    // Right Leg
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the lines (bones)
    final linePaint = Paint()
      ..color = Colors
          .yellow // Bright color for visibility
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Paint for the points (joints)
    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    // Helper function to convert normalized landmark coordinates to screen coordinates
    Offset offsetForLandmark(PoseLandmark landmark) {
      // The landmarks' (x, y) coordinates are normalized to the image size (absoluteImageSize).
      // We need to scale them to the widget size (size).

      // Calculate scaling factors:
      final double scaleX = size.width / absoluteImageSize.width;
      final double scaleY = size.height / absoluteImageSize.height;

      // Because we are using the front camera, we must mirror the X coordinate (1.0 - x)
      // to ensure the skeleton is drawn correctly over the selfie feed.
      final double mirroredX = absoluteImageSize.width - landmark.x;

      return Offset(mirroredX * scaleX, landmark.y * scaleY);
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
    // Only repaint if the pose data has changed
    return oldDelegate.pose != pose;
  }
}
