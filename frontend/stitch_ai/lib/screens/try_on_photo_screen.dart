import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'try_on_result_screen.dart';

class TryOnPhotoScreen extends StatefulWidget {
  final List<String> candidatePhotos;
  final String defaultPhotoLabel;
  final String outputImagePath;
  final String size;
  final String color;
  final String modelTitle;

  const TryOnPhotoScreen({
    super.key,
    required this.candidatePhotos,
    required this.defaultPhotoLabel,
    required this.outputImagePath,
    required this.size,
    required this.color,
    required this.modelTitle,
  });

  @override
  State<TryOnPhotoScreen> createState() => _TryOnPhotoScreenState();
}

class _TryOnPhotoScreenState extends State<TryOnPhotoScreen> {
  String? _selectedPhoto;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Preselect "my image.jpg" if present; else first photo; else null
    String defaultMatch = '';
    try {
      defaultMatch = widget.candidatePhotos.firstWhere(
        (p) => p.toLowerCase().endsWith('/${widget.defaultPhotoLabel.toLowerCase()}'),
      );
    } catch (_) {}
    if (defaultMatch.isNotEmpty) {
      _selectedPhoto = defaultMatch;
    } else if (widget.candidatePhotos.isNotEmpty) {
      _selectedPhoto = widget.candidatePhotos.first;
    } else {
      _selectedPhoto = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Photo')),
      body: Column(
        children: [
          if (widget.candidatePhotos.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No photos found in assets/tryon'),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.candidatePhotos.length,
                itemBuilder: (ctx, i) {
                  final path = widget.candidatePhotos[i];
                  final selected = path == _selectedPhoto;
                  return InkWell(
                    onTap: () => setState(() => _selectedPhoto = path),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(path, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedPhoto == null || _isGenerating
                    ? null
                    : () async {
                        if (!mounted) return;
                        setState(() => _isGenerating = true);
                        // Show generating dialog but do not await it,
                        // so the following delay and navigation can proceed.
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const _GeneratingDialog(),
                        );
                        // Wait 10 seconds then close dialog and navigate.
                        await Future.delayed(const Duration(seconds: 10));
                        if (mounted) {
                          // Close the dialog
                          Navigator.of(context).pop();
                        }
                        if (!mounted) return;
                        setState(() => _isGenerating = false);
                        if (!mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TryOnResultScreen(
                              outputImagePath: widget.outputImagePath,
                              selectedPhotoPath: _selectedPhoto!,
                              size: widget.size,
                              color: widget.color,
                              modelTitle: widget.modelTitle,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate (10s)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratingDialog extends StatelessWidget {
  const _GeneratingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generating try-on'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 8),
          LinearProgressIndicator(),
          SizedBox(height: 12),
          Text('Please wait ~10 seconds...'),
        ],
      ),
    );
  }
}