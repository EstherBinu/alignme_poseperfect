// lib/pose_detail_screen.dart

import 'package:flutter/material.dart';
import 'pose_data.dart';
import 'pose_correction_screen.dart'; // We will create this next

class PoseDetailScreen extends StatelessWidget {
  final Pose pose;

  const PoseDetailScreen({required this.pose, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pose.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How to Perform the Pose:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(pose.description, style: const TextStyle(fontSize: 16)),
            const Spacer(), // Pushes the button to the bottom
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('POSE CORRECTION', style: TextStyle(fontSize: 18)),
                onPressed: () {
                  // Navigate to the camera page, passing the pose details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoseCorrectionScreen(poseKey: pose.poseKey),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}