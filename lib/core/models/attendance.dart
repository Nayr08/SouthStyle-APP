enum AttendanceStatus { present, absent, late_ }

class Attendance {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final AttendanceStatus status;
  final DateTime createdAt;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.status,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      date: DateTime.parse(json['date'] as String),
      timeIn: json['time_in'] != null
          ? DateTime.parse(json['time_in'] as String)
          : null,
      timeOut: json['time_out'] != null
          ? DateTime.parse(json['time_out'] as String)
          : null,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'date': date.toIso8601String().split('T').first,
      'time_in': timeIn?.toIso8601String(),
      'time_out': timeOut?.toIso8601String(),
      'status': status.toDbValue(),
    };
  }

  static AttendanceStatus _parseStatus(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late_;
      default:
        return AttendanceStatus.absent;
    }
  }
}

extension AttendanceStatusX on AttendanceStatus {
  String toDbValue() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late_:
        return 'late';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late_:
        return 'Late';
    }
  }
}
