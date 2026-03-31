enum ProductionStage { cutting, printing }

class ProductionLog {
  final String id;
  final String jobOrderId;
  final String employeeId;
  final ProductionStage stage;
  final int quantityDone;
  final DateTime loggedAt;
  final Map<String, dynamic>? rawJobData;

  const ProductionLog({
    required this.id,
    required this.jobOrderId,
    required this.employeeId,
    required this.stage,
    required this.quantityDone,
    required this.loggedAt,
    this.rawJobData,
  });

  factory ProductionLog.fromJson(Map<String, dynamic> json) {
    return ProductionLog(
      id: json['id'] as String,
      jobOrderId: json['job_order_id'] as String,
      employeeId: json['employee_id'] as String,
      stage: _parseStage(json['stage'] as String),
      quantityDone: json['quantity_done'] as int,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      rawJobData: json['job_orders'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_order_id': jobOrderId,
      'employee_id': employeeId,
      'stage': stage.toDbValue(),
      'quantity_done': quantityDone,
    };
  }

  static ProductionStage _parseStage(String value) {
    switch (value) {
      case 'cutting':
        return ProductionStage.cutting;
      case 'printing':
        return ProductionStage.printing;
      default:
        return ProductionStage.cutting;
    }
  }
}

extension ProductionStageX on ProductionStage {
  String toDbValue() {
    switch (this) {
      case ProductionStage.cutting:
        return 'cutting';
      case ProductionStage.printing:
        return 'printing';
    }
  }

  String get label {
    switch (this) {
      case ProductionStage.cutting:
        return 'Cutting';
      case ProductionStage.printing:
        return 'Printing';
    }
  }
}
