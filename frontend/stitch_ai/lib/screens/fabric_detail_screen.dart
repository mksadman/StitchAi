import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/fabric.dart';

class FabricDetailScreen extends StatelessWidget {
  final Fabric item;

  const FabricDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name.isNotEmpty ? item.name : 'Fabric Details'),
        backgroundColor: color.primaryContainer,
      ),
      body: ListView(
        children: [
          // Header image
          AspectRatio(
            aspectRatio: 3 / 4,
            child: CachedNetworkImage(
              imageUrl: item.imageUrl(width: 900, height: 1200),
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(color: Colors.grey.shade300),
              errorWidget: (ctx, url, err) => const Center(child: Icon(Icons.broken_image)),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Name', value: item.name),
                _DetailRow(label: 'Material', value: item.material),
                _DetailRow(label: 'Color', value: item.color),
                if (item.pattern.isNotEmpty)
                  _DetailRow(label: 'Pattern', value: item.pattern),
                _DetailRow(label: 'Price', value: '৳${item.price.toStringAsFixed(2)}'),
                _DetailRow(label: 'Stock', value: item.stock.toString()),
                if (item.supplierId.isNotEmpty)
                  _DetailRow(label: 'Supplier ID', value: item.supplierId),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}