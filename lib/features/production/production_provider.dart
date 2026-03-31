import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/job_order.dart';
import '../../core/models/production_log.dart';

class ProductionJob {
  final JobOrder order;
  final int totalDone;

  const ProductionJob({required this.order, required this.totalDone});

  double get progress =>
      order.quantity > 0 ? (totalDone / order.quantity).clamp(0.0, 1.0) : 0;

  int get percent => (progress * 100).round();

  bool get isComplete => totalDone >= order.quantity;

  int get remaining => (order.quantity - totalDone).clamp(0, order.quantity);
}

class ProductionProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  String? _employeeUuid;
  String? _fullName;
  ProductionStage? _stage;

  List<ProductionJob> jobs = [];
  List<ProductionLog> myLogs = [];
  List<ProductionJob> completedJobs = [];
  bool isLoading = true;
  String? error;

  StreamSubscription? _ordersSub;
  StreamSubscription? _logsSub;

  String? get employeeUuid => _employeeUuid;
  String? get fullName => _fullName;
  ProductionStage? get stage => _stage;

  void update({
    required String? employeeUuid,
    required String? fullName,
    required ProductionStage? stage,
  }) {
    final changed = _employeeUuid != employeeUuid || _stage != stage;

    _employeeUuid = employeeUuid;
    _fullName = fullName;
    _stage = stage;

    if (changed) {
      _cancelStreams();
      if (_employeeUuid != null && _stage != null) {
        _init();
      } else {
        jobs = [];
        myLogs = [];
        completedJobs = [];
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _init() async {
    await _fetchAll();
    _subscribeToStreams();
  }

  // ── Fetch all data ─────────────────────────────────

  Future<void> _fetchAll() async {
    if (_employeeUuid == null || _stage == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchJobs(),
        _fetchMyLogs(),
        _fetchCompletedJobs(),
      ]);
    } catch (e) {
      error = 'Failed to load data. Pull to refresh.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchJobs() async {
    final stageValue = _stage!.toDbValue();

    final ordersData = await _client
        .from('job_orders')
        .select()
        .eq('status', stageValue)
        .order('created_at', ascending: true);

    final orders = (ordersData as List)
        .map((json) => JobOrder.fromJson(json as Map<String, dynamic>))
        .toList();

    if (orders.isEmpty) {
      jobs = [];
      return;
    }

    final orderIds = orders.map((o) => o.id).toList();

    final logsData = await _client
        .from('production_logs')
        .select('job_order_id, quantity_done')
        .inFilter('job_order_id', orderIds)
        .eq('stage', stageValue);

    final Map<String, int> doneMap = {};
    for (final row in (logsData as List)) {
      final orderId = row['job_order_id'] as String;
      final qty = (row['quantity_done'] as num).toInt();
      doneMap[orderId] = (doneMap[orderId] ?? 0) + qty;
    }

    final productionJobs = orders
        .map((o) => ProductionJob(order: o, totalDone: doneMap[o.id] ?? 0))
        .toList();

    // Sort: incomplete first (ascending progress), completed at bottom
    productionJobs.sort((a, b) {
      if (a.isComplete && !b.isComplete) return 1;
      if (!a.isComplete && b.isComplete) return -1;
      return a.progress.compareTo(b.progress);
    });

    jobs = productionJobs;
  }

  Future<void> _fetchMyLogs() async {
    final data = await _client
        .from('production_logs')
        .select('*, job_orders(customer_name, product_type)')
        .eq('employee_id', _employeeUuid!)
        .order('logged_at', ascending: false)
        .limit(100);

    myLogs = (data as List)
        .map((json) => ProductionLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _fetchCompletedJobs() async {
    // Get job IDs where this worker contributed
    final myLogData = await _client
        .from('production_logs')
        .select('job_order_id')
        .eq('employee_id', _employeeUuid!);

    final jobIds = (myLogData as List)
        .map((row) => row['job_order_id'] as String)
        .toSet()
        .toList();

    if (jobIds.isEmpty) {
      completedJobs = [];
      return;
    }

    final ordersData = await _client
        .from('job_orders')
        .select()
        .eq('status', 'done')
        .inFilter('id', jobIds)
        .order('created_at', ascending: false);

    final orders = (ordersData as List)
        .map((json) => JobOrder.fromJson(json as Map<String, dynamic>))
        .toList();

    if (orders.isEmpty) {
      completedJobs = [];
      return;
    }

    // Get this worker's contribution per job
    final contribData = await _client
        .from('production_logs')
        .select('job_order_id, quantity_done')
        .eq('employee_id', _employeeUuid!)
        .inFilter('job_order_id', orders.map((o) => o.id).toList());

    final Map<String, int> contribMap = {};
    for (final row in (contribData as List)) {
      final orderId = row['job_order_id'] as String;
      final qty = (row['quantity_done'] as num).toInt();
      contribMap[orderId] = (contribMap[orderId] ?? 0) + qty;
    }

    completedJobs = orders
        .map((o) =>
            ProductionJob(order: o, totalDone: contribMap[o.id] ?? 0))
        .toList();
  }

  // ── Submit update ──────────────────────────────────

  Future<void> submitUpdate({
    required String jobOrderId,
    required int quantity,
    required int currentTotal,
    required int orderQuantity,
  }) async {
    await _client.from('production_logs').insert({
      'job_order_id': jobOrderId,
      'employee_id': _employeeUuid!,
      'stage': _stage!.toDbValue(),
      'quantity_done': quantity,
    });

    final newTotal = currentTotal + quantity;

    // Stage transition when job reaches 100%
    if (newTotal >= orderQuantity) {
      final nextStatus = _stage == ProductionStage.cutting
          ? OrderStatus.printing
          : OrderStatus.done;

      await _client
          .from('job_orders')
          .update({'status': nextStatus.toDbValue()})
          .eq('id', jobOrderId);
    }
  }

  // ── Realtime streams ───────────────────────────────

  void _subscribeToStreams() {
    if (_stage == null) return;

    _ordersSub = _client
        .from('job_orders')
        .stream(primaryKey: ['id'])
        .listen((_) async {
      await _fetchJobs();
      await _fetchCompletedJobs();
      notifyListeners();
    });

    _logsSub = _client
        .from('production_logs')
        .stream(primaryKey: ['id'])
        .listen((_) async {
      await _fetchJobs();
      await _fetchMyLogs();
      await _fetchCompletedJobs();
      notifyListeners();
    });
  }

  void _cancelStreams() {
    _ordersSub?.cancel();
    _ordersSub = null;
    _logsSub?.cancel();
    _logsSub = null;
  }

  Future<void> refresh() => _fetchAll();

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }
}
