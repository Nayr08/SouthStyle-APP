class OrderItem {
  final String id;
  final String jobOrderId;
  final String name;
  final String? size;
  final int quantity;

  const OrderItem({
    required this.id,
    required this.jobOrderId,
    required this.name,
    this.size,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      jobOrderId: json['job_order_id'] as String,
      name: json['name'] as String,
      size: json['size'] as String?,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_order_id': jobOrderId,
      'name': name,
      'size': size,
      'quantity': quantity,
    };
  }
}
