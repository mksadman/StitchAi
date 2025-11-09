import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_cube/flutter_cube.dart';
import 'try_on_photo_screen.dart';

class TryOnScreen extends StatelessWidget {
  const TryOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try-On')),
      body: const _TryOnLayout(),
    );
  }
}

class _TryOnLayout extends StatefulWidget {
  const _TryOnLayout();

  @override
  State<_TryOnLayout> createState() => _TryOnLayoutState();
}

class _TryOnLayoutState extends State<_TryOnLayout> {
  final List<_ModelOption> _options = const [
    _ModelOption(
      title: 'Cloth 1',
      objPath: 'assets/cloths/cloth1model.obj',
      previewImage: 'assets/tryon/cloth1.png',
      outputImage: 'assets/tryon/output1.png',
    ),
    _ModelOption(
      title: 'Cloth 2',
      objPath: 'assets/cloths/cloth2model.obj',
      previewImage: 'assets/tryon/cloth2.png',
      outputImage: 'assets/tryon/output2.png',
    ),
    _ModelOption(
      title: 'Cloth 3',
      objPath: 'assets/cloths/cloth3model.obj',
      previewImage: 'assets/tryon/cloth3.png',
      outputImage: 'assets/tryon/output3.png',
    ),
  ];

  final List<String> _sizes = const ['S', 'M', 'L', 'XL'];
  final List<Map<String, dynamic>> _colors = const [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Red', 'color': Colors.red},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Green', 'color': Colors.green},
  ];

  String _selectedModel = 'assets/cloths/cloth1model.obj';
  String _selectedSize = 'M';
  String _selectedColor = 'Black';

  Object? _model;
  int _viewerKey = 0;

  void _applyTransforms() {
    if (_model == null) return;
    // Make the model larger by default, then apply size multiplier
    const baseScale = 2.5;
    final scaleMultiplier = switch (_selectedSize) {
      'S' => 0.9,
      'M' => 1.0,
      'L' => 1.1,
      'XL' => 1.2,
      _ => 1.0,
    };
    final scale = baseScale * scaleMultiplier;
    _model!.scale.setValues(scale, scale, scale);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Column(
      children: [
        // 3D Viewer
        Expanded(
          child: kIsWeb
              ? const Center(
                  child: Text(
                    '3D preview available on Android. Web support coming later.',
                  ),
                )
              : Cube(
                  key: ValueKey(_viewerKey),
                  onSceneCreated: (Scene scene) {
                    final obj = Object(fileName: _selectedModel);
                    scene.world.add(obj);
                    // Reduce zoom further so the model appears bigger
                    scene.camera.zoom = 11;
                    _model = obj;
                    _applyTransforms();
                  },
                ),
        ),

        // Model selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select model',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (ctx, i) {
                    final opt = _options[i];
                    final selected = _selectedModel == opt.objPath;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedModel = opt.objPath;
                          _viewerKey++; // rebuild Cube
                        });
                      },
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? color.primary
                                : color.outlineVariant,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  opt.previewImage,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(opt.title),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: _options.length,
                ),
              ),
            ],
          ),
        ),

        // Size chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Size', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _sizes.map((s) {
                  return ChoiceChip(
                    label: Text(s),
                    selected: _selectedSize == s,
                    onSelected: (_) {
                      setState(() {
                        _selectedSize = s;
                        _applyTransforms();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Color chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((c) {
                  final name = c['name'] as String;
                  final clr = c['color'] as Color;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: clr,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(name),
                      ],
                    ),
                    selected: _selectedColor == name,
                    onSelected: (_) {
                      setState(() {
                        _selectedColor = name;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Try On button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final selected = _options.firstWhere(
                  (o) => o.objPath == _selectedModel,
                );
                // Restrict to only "my image.jpg" per requirement
                final photos = <String>['assets/tryon/my image.jpg'];
                if (!mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TryOnPhotoScreen(
                      candidatePhotos: photos,
                      defaultPhotoLabel: 'my image.jpg',
                      outputImagePath: selected.outputImage,
                      size: _selectedSize,
                      color: _selectedColor,
                      modelTitle: selected.title,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.checkroom),
              label: const Text('Try On'),
            ),
          ),
        ),
      ],
    );
  }

  Future<List<String>> _loadTryOnPhotos() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final manifest = json.decode(manifestJson) as Map<String, dynamic>;
      final paths =
          manifest.keys.where((k) => k.startsWith('assets/tryon/')).toList()
            ..sort();
      return paths
          .where(
            (p) =>
                p.toLowerCase().endsWith('.png') ||
                p.toLowerCase().endsWith('.jpg') ||
                p.toLowerCase().endsWith('.jpeg'),
          )
          .toList();
    } catch (_) {
      return const [
        'assets/tryon/cloth1.png',
        'assets/tryon/cloth2.png',
        'assets/tryon/cloth3.png',
        'assets/tryon/my image.jpg',
      ];
    }
  }
}

class _ModelOption {
  final String title;
  final String objPath;
  final String previewImage;
  final String outputImage;

  const _ModelOption({
    required this.title,
    required this.objPath,
    required this.previewImage,
    required this.outputImage,
  });
}
