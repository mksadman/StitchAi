import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/fabric.dart';
import '../services/api.dart';
import 'try_on_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _materialCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _patternCtrl = TextEditingController();

  List<Fabric> _items = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fabrics = await APIService.recommendFabrics(
        material: _materialCtrl.text,
        color: _colorCtrl.text,
        pattern: _patternCtrl.text,
      );
      setState(() {
        _items = fabrics;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _materialCtrl.dispose();
    _colorCtrl.dispose();
    _patternCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.primaryContainer,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.style, color: color.primary),
            const SizedBox(width: 8),
            const Text('Stitch Ai'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Filters(
                materialCtrl: _materialCtrl,
                colorCtrl: _colorCtrl,
                patternCtrl: _patternCtrl,
                onApply: _fetch,
              ),
              const SizedBox(height: 8),
              _MarketplaceGrid(
                items: _items,
                loading: _loading,
                error: _error,
                onRetry: _fetch,
              ),
              const SizedBox(height: 24),
              const _TryOnSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController materialCtrl;
  final TextEditingController colorCtrl;
  final TextEditingController patternCtrl;
  final VoidCallback onApply;

  const _Filters({
    required this.materialCtrl,
    required this.colorCtrl,
    required this.patternCtrl,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marketplace',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: materialCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Material (e.g., cotton)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: colorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Color (e.g., navy blue)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: patternCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pattern (e.g., plain)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Get Suggestions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceGrid extends StatelessWidget {
  final List<Fabric> items;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _MarketplaceGrid({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _ShimmerGrid();
    }
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      );
    }
    if (items.isEmpty) {
      return const Text('No suggestions yet. Try adjusting filters and refresh.');
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _FabricCard(item: item);
      },
    );
  }
}

class _FabricCard extends StatelessWidget {
  final Fabric item;
  const _FabricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: item.imageUrl(width: 600, height: 800),
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (ctx, url) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(color: Colors.grey.shade300),
              ),
              errorWidget: (ctx, url, err) => const Center(child: Icon(Icons.broken_image)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('${item.material} • ${item.color}${item.pattern.isNotEmpty ? ' • ${item.pattern}' : ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('৳${item.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color.primary)),
                    _StockBadge(stock: item.stock),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    final label = inStock ? 'In stock' : 'Out of stock';
    final color = inStock ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Expanded(child: Container(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(height: 14, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TryOnSection extends StatelessWidget {
  const _TryOnSection();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.vrpano, size: 44, color: color.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Virtual Try-On',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Tap below to preview the 3D model. "Try it on" will be added later.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TryOnScreen()),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Launch Try-On'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}