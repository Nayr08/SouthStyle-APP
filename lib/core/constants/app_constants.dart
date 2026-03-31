class AppConstants {
  AppConstants._();

  static const String appName = 'South Style';
  static const String appVersion = '1.0.0';

  // Supabase (replace with your actual credentials)
  static const String supabaseUrl = 'https://lqbwtjtklgeddobsdzmp.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxYnd0anRrbGdlZGRvYnNkem1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5MjQ4MTUsImV4cCI6MjA5MDUwMDgxNX0.FtlQc_hufhUcrHObZOgjDv4Zy-n5ybrjfPftZHb8Q9I';

  // Route names
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String attendanceRoute = '/attendance';
  static const String ordersRoute = '/orders';
  static const String createOrderRoute = '/orders/create';
  static const String productionRoute = '/production';
}
