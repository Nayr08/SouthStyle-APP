import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/job_order.dart';

class OrdersProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<JobOrder> _allOrders = [];
  List<JobOrder> get orders => _filteredOrders;
  
  OrderStatus? _selectedFilter;
  OrderStatus? get selectedFilter => _selectedFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<JobOrder> get _filteredOrders {
    if (_selectedFilter == null) {
      return _allOrders;
    }
    return _allOrders.where((order) => order.status == _selectedFilter).toList();
  }

  OrdersProvider() {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('job_orders')
          .select('''
            id,
            display_order_id,
            customer_name,
            product_type,
            quantity,
            notes,
            status,
            created_at,
            created_by,
            employees(full_name)
          ''')
          .order('created_at', ascending: false);

      _allOrders = (response as List).map((json) {
        final employee = json['employees'] as Map<String, dynamic>?;
        final createdByName = employee?['full_name'] as String? ?? 'Unknown User';
        return JobOrder.fromJson({
          ...json as Map<String, dynamic>,
          'created_by': createdByName,
        });
      }).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch orders: $e';
      _allOrders = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(OrderStatus? status) {
    _selectedFilter = status;
    notifyListeners();
  }

  void clearFilter() {
    _selectedFilter = null;
    notifyListeners();
  }
}
