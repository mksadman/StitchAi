import 'package:flutter/material.dart';

class TryOnResultScreen extends StatelessWidget {
  final String outputImagePath;
  final String selectedPhotoPath;
  final String size;
  final String color;
  final String modelTitle;

  const TryOnResultScreen({
    super.key,
    required this.outputImagePath,
    required this.selectedPhotoPath,
    required this.size,
    required this.color,
    required this.modelTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Try-On Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Model: $modelTitle',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('Size: $size'),
                      Text('Color: $color'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Input photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(selectedPhotoPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Generated output',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(outputImagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
