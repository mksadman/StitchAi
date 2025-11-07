class Fabric {
  final String fabricId;
  final String name;
  final String material;
  final String color;
  final String pattern;
  final double price;
  final int stock;
  final String supplierId;

  const Fabric({
    required this.fabricId,
    required this.name,
    required this.material,
    required this.color,
    required this.pattern,
    required this.price,
    required this.stock,
    required this.supplierId,
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
    );
  }

  String imageUrl({int width = 600, int height = 800}) {
    final seed = fabricId.replaceAll('-', '');
    return 'https://picsum.photos/seed/$seed/$width/$height';
  }
}