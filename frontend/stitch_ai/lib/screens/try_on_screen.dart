import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try-On')),
      body: Column(
        children: [
          Expanded(child: _Viewer()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null, // Placeholder for future functionality
                icon: const Icon(Icons.checkroom),
                label: const Text('Try it on (coming soon)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Viewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(
        child: Text('3D model preview is available on Android. Web support coming soon.'),
      );
    }

    return Cube(
      onSceneCreated: (Scene scene) {
        scene.world.add(Object(fileName: 'assets/Sweater.obj'));
        scene.camera.zoom = 10;
      },
    );
  }
}