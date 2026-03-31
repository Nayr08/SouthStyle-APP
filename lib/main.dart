import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/admin_dashboard.dart';
import 'features/dashboard/dashboard_provider.dart';
import 'features/attendance/attendance_provider.dart';
import 'features/orders/orders_screen.dart';
import 'features/orders/create_order_screen.dart';
import 'features/production/production_screen.dart';
import 'features/production/production_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProductionProvider>(
          create: (_) => ProductionProvider(),
          update: (_, auth, previous) {
            final provider = previous ?? ProductionProvider();
            provider.update(
              employeeUuid: auth.employeeUuid,
              fullName: auth.fullName,
              stage: auth.stage,
            );
            return provider;
          },
        ),
      ],
      child: const SouthStyleApp(),
    ),
  );
}

class SouthStyleApp extends StatelessWidget {
  const SouthStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppConstants.loginRoute,
      routes: {
        AppConstants.loginRoute: (_) => const LoginScreen(),
        AppConstants.dashboardRoute: (_) => const AdminDashboard(),
        AppConstants.ordersRoute: (_) => const OrdersScreen(),
        AppConstants.createOrderRoute: (_) => const CreateOrderScreen(),
        AppConstants.productionRoute: (_) => const ProductionScreen(),
      },
    );
  }
}
