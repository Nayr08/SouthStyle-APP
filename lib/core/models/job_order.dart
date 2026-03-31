enum ProductType { tshirt, tarpaulin, sticker, mug, other }

enum OrderStatus { pending, cutting, printing, done }

class JobOrder {
  final String id;
  final String customerName;
  final ProductType productType;
  final int quantity;
  final String? notes;
  final OrderStatus status;
  final String createdBy;
  final DateTime createdAt;

  const JobOrder({
    required this.id,
    required this.customerName,
    required this.productType,
    required this.quantity,
    this.notes,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory JobOrder.fromJson(Map<String, dynamic> json) {
    return JobOrder(
      id: json['id'] as String,
      customerName: json['customer_name'] as String,
      productType: _parseProductType(json['product_type'] as String),
      quantity: json['quantity'] as int,
      notes: json['notes'] as String?,
      status: _parseStatus(json['status'] as String),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'product_type': productType.toDbValue(),
      'quantity': quantity,
      'notes': notes,
      'status': status.toDbValue(),
      'created_by': createdBy,
    };
  }

  static ProductType _parseProductType(String value) {
    switch (value) {
      case 'tshirt':
        return ProductType.tshirt;
      case 'tarpaulin':
        return ProductType.tarpaulin;
      case 'sticker':
        return ProductType.sticker;
      case 'mug':
        return ProductType.mug;
      default:
        return ProductType.other;
    }
  }

  static OrderStatus _parseStatus(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'cutting':
        return OrderStatus.cutting;
      case 'printing':
        return OrderStatus.printing;
      case 'done':
        return OrderStatus.done;
      default:
        return OrderStatus.pending;
    }
  }
}

extension ProductTypeX on ProductType {
  String toDbValue() {
    switch (this) {
      case ProductType.tshirt:
        return 'tshirt';
      case ProductType.tarpaulin:
        return 'tarpaulin';
      case ProductType.sticker:
        return 'sticker';
      case ProductType.mug:
        return 'mug';
      case ProductType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ProductType.tshirt:
        return 'T-Shirt';
      case ProductType.tarpaulin:
        return 'Tarpaulin';
      case ProductType.sticker:
        return 'Sticker';
      case ProductType.mug:
        return 'Mug';
      case ProductType.other:
        return 'Other';
    }
  }
}

extension OrderStatusX on OrderStatus {
  String toDbValue() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.cutting:
        return 'cutting';
      case OrderStatus.printing:
        return 'printing';
      case OrderStatus.done:
        return 'done';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.cutting:
        return 'Cutting';
      case OrderStatus.printing:
        return 'Printing';
      case OrderStatus.done:
        return 'Done';
    }
  }
}
