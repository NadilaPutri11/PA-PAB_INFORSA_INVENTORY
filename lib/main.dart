import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/approval_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/dashboard_provider.dart';
import 'pages/auth/login_page.dart';
import 'pages/admin/main_admin_page.dart';
import 'pages/user/main_user_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id', null);

  await dotenv.load(fileName: 'assets/.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ApprovalProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INFORSA Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF000080)),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // ← diganti ke SplashScreen
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.checkSession();

    if (!mounted) return;

    if (auth.isLoggedIn) {
      if (auth.isAdmin) {
<<<<<<< HEAD
       
=======
        // Prefetch data admin saat splash agar dashboard langsung terisi.
>>>>>>> 190e2f40caab643be0b09682bd87d23eac3662a1
        try {
          await Future.wait([
            context.read<DashboardProvider>().fetchDashboardData(silent: true),
            context.read<InventoryProvider>().fetchItems(),
          ]);
        } catch (_) {
<<<<<<< HEAD
          
=======
          // Jika prefetch gagal, tetap lanjut ke halaman admin.
>>>>>>> 190e2f40caab643be0b09682bd87d23eac3662a1
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              auth.isAdmin ? const MainAdminPage() : const MainUserPage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000080),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Image.asset(
                  'assets/logo_inforsa.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'INFORSA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
