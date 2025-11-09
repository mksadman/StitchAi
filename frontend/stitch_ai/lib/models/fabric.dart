class Fabric {
  final String fabricId;
  final String name;
  final String material;
  final String color;
  final String pattern;
  final double price;
  final int stock;
  final String supplierId;
  final String imageUrlStr;

  const Fabric({
    required this.fabricId,
    required this.name,
    required this.material,
    required this.color,
    required this.pattern,
    required this.price,
    required this.stock,
    required this.supplierId,
    required this.imageUrlStr,
  });

  factory Fabric.fromJson(Map<String, dynamic> json) {
    return Fabric(
      fabricId: json['fabric_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      material: json['material']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      pattern: json['pattern']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse('${json['price']}') ?? 0.0,
      stock: (json['stock'] is num) ? (json['stock'] as num).toInt() : int.tryParse('${json['stock']}') ?? 0,
      supplierId: json['supplier_id']?.toString() ?? '',
      imageUrlStr: json['image_url']?.toString() ?? '',
    );
  }

  String imageUrl({int width = 600, int height = 800}) {
    // Prefer backend-provided absolute media URL when available
    final url = imageUrlStr.trim();
    if (url.isNotEmpty) return url;
    // Fallback: cloth-focused images from Unsplash Source without API keys
    final parts = [
      'fabric', 'textile', 'cloth', 'garment',
      material.trim(),
      pattern.trim(),
      color.trim(),
    ]
        .where((p) => p.isNotEmpty)
        .map((p) => p.toLowerCase().replaceAll(RegExp(r'\s+'), '-'))
        .toList();
    final query = parts.join(',');
    return 'https://source.unsplash.com/${width}x${height}/?${query}';
  }
}