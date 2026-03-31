import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee.dart';
import '../models/production_log.dart';

class AuthResult {
  final EmployeeRole role;
  final String employeeUuid;
  final String fullName;
  final ProductionStage? stage;

  const AuthResult({
    required this.role,
    required this.employeeUuid,
    required this.fullName,
    this.stage,
  });
}

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Signs in using employee_id as the email (employee_id@southstyle.app)
  /// and fetches the role + UUID from the "employees" table.
  Future<AuthResult> signIn({
    required String employeeId,
    required String password,
  }) async {
    final email = '$employeeId@southstyle.app';

    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = _client.auth.currentUser!.id;

    final data = await _client
        .from('employees')
        .select('id, role, full_name, stage')
        .eq('auth_id', userId)
        .single();

    return AuthResult(
      role: _parseRole(data['role'] as String),
      employeeUuid: data['id'] as String,
      fullName: data['full_name'] as String,
      stage: _parseStage(data['stage'] as String?),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  ProductionStage? _parseStage(String? value) {
    switch (value) {
      case 'cutter':
        return ProductionStage.cutting;
      case 'printer':
        return ProductionStage.printing;
      default:
        return null;
    }
  }

  EmployeeRole _parseRole(String role) {
    switch (role) {
      case 'admin':
        return EmployeeRole.admin;
      case 'supervisor':
        return EmployeeRole.supervisor;
      case 'data_entry':
        return EmployeeRole.dataEntry;
      case 'production':
        return EmployeeRole.production;
      default:
        return EmployeeRole.dataEntry;
    }
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  EmployeeRole? _role;
  EmployeeRole? get role => _role;

  String? _employeeUuid;
  String? get employeeUuid => _employeeUuid;

  String? _fullName;
  String? get fullName => _fullName;

  ProductionStage? _stage;
  ProductionStage? get stage => _stage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isAuthenticated => _role != null;

  /// Sign in and fetch role. Returns the route to navigate to.
  Future<String> signIn({
    required String employeeId,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(
        employeeId: employeeId,
        password: password,
      );
      _role = result.role;
      _employeeUuid = result.employeeUuid;
      _fullName = result.fullName;
      _stage = result.stage;
      _isLoading = false;
      notifyListeners();
      return routeForRole(_role!);
    } catch (e) {
      _isLoading = false;
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _role = null;
    _employeeUuid = null;
    _fullName = null;
    _stage = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Maps a role to its landing route.
  static String routeForRole(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.admin:
      case EmployeeRole.supervisor:
        return '/dashboard';
      case EmployeeRole.dataEntry:
        return '/orders';
      case EmployeeRole.production:
        return '/production';
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid_credentials')) {
      return 'Invalid employee ID or password.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Check your connection.';
    }
    return 'Sign in failed. Please try again.';
  }
}
