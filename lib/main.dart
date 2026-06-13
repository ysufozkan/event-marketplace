import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/registration_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/staff/ticket_validator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('en_US', null);
  await _seedStaffUser();
  runApp(const MyApp());
}

Future<void> _seedStaffUser() async {
  try {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final snap = await db
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return;

    final credential = await auth.createUserWithEmailAndPassword(
      email: 'kapici@eventhub.com',
      password: 'kapici123',
    );

    await db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': 'Door Attendant',
      'email': 'kapici@eventhub.com',
      'role': 'staff',
      'avatarUrl': null,
      'createdAt': Timestamp.now(),
    });

    await auth.signOut();
  } catch (_) {
    // Account already exists or another error — silently ignore
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (_, auth, _) => MaterialApp(
          title: 'EventHub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forRole(auth.user?.role),
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/home': (_) => const HomeScreen(),
            '/staff': (_) => const TicketValidatorScreen(),
          },
        ),
      ),
    );
  }
}
