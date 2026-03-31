import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/attendance.dart';
import '../../core/models/employee.dart';

// ─── Date range presets ────────────────────────────────

enum DatePreset { today, thisWeek, fifteenDays, thisMonth, custom }

class DateRangeValue {
  final DateTime from;
  final DateTime to;
  const DateRangeValue({required this.from, required this.to});
}

// ─── Per-worker computed stats ─────────────────────────

class WorkerAttendanceSummary {
  final Employee employee;
  final List<Attendance> records;
  final int daysPresent;
  final int daysAbsent;
  final int daysLate;
  final double salary;

  const WorkerAttendanceSummary({
    required this.employee,
    required this.records,
    required this.daysPresent,
    required this.daysAbsent,
    required this.daysLate,
    required this.salary,
  });

  int get daysWorked => daysPresent + daysLate;
}

// ─── Provider ──────────────────────────────────────────

class AttendanceProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  DatePreset _preset = DatePreset.today;
  DatePreset get preset => _preset;

  late DateRangeValue _range;
  DateRangeValue get range => _range;

  bool isLoading = true;

  // Aggregates
  int totalPresent = 0;
  int totalAbsent = 0;
  int totalLate = 0;

  List<WorkerAttendanceSummary> workers = [];

  StreamSubscription? _attendanceSub;

  AttendanceProvider() {
    _range = _rangeFor(DatePreset.today);
    _init();
  }

  // ── public API ──────────────────────────────────────

  void selectPreset(DatePreset p) {
    _preset = p;
    _range = _rangeFor(p);
    _fetch();
  }

  void selectCustomRange(DateTime from, DateTime to) {
    _preset = DatePreset.custom;
    _range = DateRangeValue(from: from, to: to);
    _fetch();
  }

  Future<void> refresh() => _fetch();

  // ── lifecycle ───────────────────────────────────────

  Future<void> _init() async {
    await _fetch();
    _subscribe();
  }

  void _subscribe() {
    _attendanceSub = _client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .listen((_) => _fetch());
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    super.dispose();
  }

  // ── fetch & compute ─────────────────────────────────

  Future<void> _fetch() async {
    isLoading = true;
    notifyListeners();

    final fromStr = _range.from.toIso8601String().split('T').first;
    final toStr = _range.to.toIso8601String().split('T').first;

    final results = await Future.wait([
      _client.from('employees').select(),
      _client
          .from('attendance')
          .select()
          .gte('date', fromStr)
          .lte('date', toStr),
    ]);

    final employeesList = (results[0] as List)
        .map((j) => Employee.fromJson(j as Map<String, dynamic>))
        .toList();

    final attendanceList = (results[1] as List)
        .map((j) => Attendance.fromJson(j as Map<String, dynamic>))
        .toList();

    // group attendance by employee id
    final Map<String, List<Attendance>> grouped = {};
    for (final a in attendanceList) {
      grouped.putIfAbsent(a.employeeId, () => []).add(a);
    }

    totalPresent = 0;
    totalAbsent = 0;
    totalLate = 0;

    final List<WorkerAttendanceSummary> built = [];

    for (final emp in employeesList) {
      final records = grouped[emp.id] ?? [];

      int p = 0, a = 0, l = 0;
      for (final r in records) {
        switch (r.status) {
          case AttendanceStatus.present:
            p++;
          case AttendanceStatus.absent:
            a++;
          case AttendanceStatus.late_:
            l++;
        }
      }

      totalPresent += p;
      totalAbsent += a;
      totalLate += l;

      final daysWorked = p + l;
      final salary = daysWorked * emp.dailyRate;

      built.add(WorkerAttendanceSummary(
        employee: emp,
        records: records..sort((a, b) => b.date.compareTo(a.date)),
        daysPresent: p,
        daysAbsent: a,
        daysLate: l,
        salary: salary,
      ));
    }

    // sort: most days worked first
    built.sort((a, b) => b.daysWorked.compareTo(a.daysWorked));

    workers = built;
    isLoading = false;
    notifyListeners();
  }

  // ── helpers ─────────────────────────────────────────

  static DateRangeValue _rangeFor(DatePreset p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (p) {
      case DatePreset.today:
        return DateRangeValue(from: today, to: today);
      case DatePreset.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return DateRangeValue(from: weekStart, to: today);
      case DatePreset.fifteenDays:
        return DateRangeValue(
          from: today.subtract(const Duration(days: 14)),
          to: today,
        );
      case DatePreset.thisMonth:
        return DateRangeValue(
          from: DateTime(today.year, today.month, 1),
          to: today,
        );
      case DatePreset.custom:
        return DateRangeValue(from: today, to: today);
    }
  }
}
