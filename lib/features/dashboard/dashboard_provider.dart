import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/job_order.dart';

class LiveOrder {
  final JobOrder order;
  final int piecesDone;

  const LiveOrder({required this.order, required this.piecesDone});

  double get progress =>
      order.quantity > 0 ? (piecesDone / order.quantity).clamp(0.0, 1.0) : 0;

  int get percent => (progress * 100).round();
}

class DashboardProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  int presentToday = 0;
  int activeOrders = 0;
  int piecesPrintedToday = 0;
  int completedThisWeek = 0;
  List<LiveOrder> liveOrders = [];
  bool isLoading = true;

  StreamSubscription? _attendanceSub;
  StreamSubscription? _ordersSub;
  StreamSubscription? _productionSub;

  DashboardProvider() {
    _init();
  }

  Future<void> _init() async {
    await _fetchAll();
    _subscribeToStreams();
  }

  // ── Fetch all stats in one pass ─────────────────────

  Future<void> _fetchAll() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchPresentToday(),
      _fetchActiveOrders(),
      _fetchPiecesPrintedToday(),
      _fetchCompletedThisWeek(),
      _fetchLiveOrders(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchPresentToday() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('attendance')
        .select('id')
        .eq('date', today)
        .inFilter('status', ['present', 'late']);
    presentToday = (data as List).length;
  }

  Future<void> _fetchActiveOrders() async {
    final data = await _client
        .from('job_orders')
        .select('id')
        .inFilter('status', ['pending', 'cutting', 'printing']);
    activeOrders = (data as List).length;
  }

  Future<void> _fetchPiecesPrintedToday() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('production_logs')
        .select('quantity_done')
        .eq('stage', 'printing')
        .gte('logged_at', '${today}T00:00:00');
    int total = 0;
    for (final row in (data as List)) {
      total += (row['quantity_done'] as num).toInt();
    }
    piecesPrintedToday = total;
  }

  Future<void> _fetchCompletedThisWeek() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().split('T').first;
    final data = await _client
        .from('job_orders')
        .select('id')
        .eq('status', 'done')
        .gte('created_at', '${weekStartStr}T00:00:00');
    completedThisWeek = (data as List).length;
  }

  Future<void> _fetchLiveOrders() async {
    final ordersData = await _client
        .from('job_orders')
        .select()
        .inFilter('status', ['pending', 'cutting', 'printing'])
        .order('created_at', ascending: false)
        .limit(20);

    final orders = (ordersData as List)
        .map((json) => JobOrder.fromJson(json as Map<String, dynamic>))
        .toList();

    if (orders.isEmpty) {
      liveOrders = [];
      return;
    }

    final orderIds = orders.map((o) => o.id).toList();

    final logsData = await _client
        .from('production_logs')
        .select('job_order_id, quantity_done')
        .inFilter('job_order_id', orderIds);

    final Map<String, int> doneMap = {};
    for (final row in (logsData as List)) {
      final orderId = row['job_order_id'] as String;
      final qty = (row['quantity_done'] as num).toInt();
      doneMap[orderId] = (doneMap[orderId] ?? 0) + qty;
    }

    liveOrders = orders
        .map((o) => LiveOrder(order: o, piecesDone: doneMap[o.id] ?? 0))
        .toList();
  }

  // ── Realtime subscriptions ──────────────────────────

  void _subscribeToStreams() {
    _attendanceSub = _client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .listen((_) => _refreshStat(_fetchPresentToday));

    _ordersSub = _client
        .from('job_orders')
        .stream(primaryKey: ['id'])
        .listen((_) async {
      await _fetchActiveOrders();
      await _fetchCompletedThisWeek();
      await _fetchLiveOrders();
      notifyListeners();
    });

    _productionSub = _client
        .from('production_logs')
        .stream(primaryKey: ['id'])
        .listen((_) async {
      await _fetchPiecesPrintedToday();
      await _fetchLiveOrders();
      notifyListeners();
    });
  }

  Future<void> _refreshStat(Future<void> Function() fetcher) async {
    await fetcher();
    notifyListeners();
  }

  Future<void> refresh() => _fetchAll();

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _ordersSub?.cancel();
    _productionSub?.cancel();
    super.dispose();
  }
}
