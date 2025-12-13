// lib/pose_data.dart

class Pose {
  final String name;
  final String description;
  final String poseKey; // Unique ID for correction logic

  Pose({required this.name, required this.description, required this.poseKey});
}

// Store the list of all poses
final List<Pose> yogaPoses = [
  Pose(
    name: "Mountain Pose (Tadasana)",
    description: "Stand tall with feet hip-width apart, arms by your sides. Ground down through all four corners of your feet. Engage your core and draw your shoulders back and down.",
    poseKey: "mountain_pose",
  ),
  Pose(
    name: "Tree Pose (Vrksasana)",
    description: "Shift your weight to one foot. Bend your opposite knee and place the sole of your foot on your inner thigh or calf. Bring your hands to prayer at your chest.",
    poseKey: "tree_pose",
  ),
  // Add more poses here...
];