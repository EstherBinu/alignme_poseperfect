// lib/main.dart (Simplified)

import 'package:flutter/material.dart';
import 'pose_data.dart';
import 'pose_detail_screen.dart'; // We will create this next

void main() => runApp(const YogaApp());

class YogaApp extends StatelessWidget {
  const YogaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yoga Correction App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const PoseListScreen(),
    );
  }
}

class PoseListScreen extends StatelessWidget {
  const PoseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yoga Pose Library')),
      body: ListView.builder(
        itemCount: yogaPoses.length,
        itemBuilder: (context, index) {
          final pose = yogaPoses[index];
          return ListTile(
            title: Text(pose.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PoseDetailScreen(pose: pose),
                ),
              );
            },
          );
        },
      ),
    );
  }
}