import 'package:south_style_app/core/models/production_log.dart';

enum EmployeeRole { admin, supervisor, dataEntry, production }

class Employee {
  final String id;
  final String? authId;
  final String employeeId;
  final String fullName;
  final EmployeeRole role;
  final ProductionStage? stage;
  final double dailyRate;
  final DateTime createdAt;

  const Employee({
    required this.id,
    this.authId,
    required this.employeeId,
    required this.fullName,
    required this.role,
    this.stage,
    required this.dailyRate,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      authId: json['auth_id'] as String?,
      employeeId: json['employee_id'] as String,
      fullName: json['full_name'] as String,
      role: _parseRole(json['role'] as String),
      stage: _parseStage(json['stage'] as String?),
      dailyRate: (json['daily_rate'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'full_name': fullName,
      'role': role.toDbValue(),
      'stage': stage?.toDbValue(),
      'daily_rate': dailyRate,
    };
  }

  static ProductionStage? _parseStage(String? value) {
    switch (value) {
      case 'cutter':
        return ProductionStage.cutting;
      case 'printer':
        return ProductionStage.printing;
      default:
        return null;
    }
  }

  static EmployeeRole _parseRole(String value) {
    switch (value) {
      case 'admin':
        return EmployeeRole.admin;
      case 'supervisor':
        return EmployeeRole.supervisor;
      case 'data_entry':
        return EmployeeRole.dataEntry;
      case 'production':
        return EmployeeRole.production;
      default:
        return EmployeeRole.production;
    }
  }
}

extension EmployeeRoleX on EmployeeRole {
  String toDbValue() {
    switch (this) {
      case EmployeeRole.admin:
        return 'admin';
      case EmployeeRole.supervisor:
        return 'supervisor';
      case EmployeeRole.dataEntry:
        return 'data_entry';
      case EmployeeRole.production:
        return 'production';
    }
  }

  String get label {
    switch (this) {
      case EmployeeRole.admin:
        return 'Admin';
      case EmployeeRole.supervisor:
        return 'Supervisor';
      case EmployeeRole.dataEntry:
        return 'Data Entry';
      case EmployeeRole.production:
        return 'Production';
    }
  }
}
