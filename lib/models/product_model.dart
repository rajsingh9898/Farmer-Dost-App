class ProductModel {
  final String code;
  final String name;
  final String batch;
  final String manufacturer;
  final String status; // 'genuine', 'fake', or 'unrecognized'

  ProductModel({
    required this.code,
    required this.name,
    required this.batch,
    required this.manufacturer,
    required this.status,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductModel(
      code: map['code'] as String? ?? documentId,
      name: map['name'] as String? ?? 'Unknown Product',
      batch: map['batch'] as String? ?? 'N/A',
      manufacturer: map['manufacturer'] as String? ?? 'Unknown Manufacturer',
      status: map['status'] as String? ?? 'unrecognized',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'batch': batch,
      'manufacturer': manufacturer,
      'status': status,
    };
  }
}
