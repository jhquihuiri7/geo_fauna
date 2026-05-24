import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart'; // generado por: flutterfire configure
import 'services/app_navigation_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Modo inmersivo: oculta la barra de navegación del sistema. El usuario la
  // revela deslizando desde el borde y se vuelve a ocultar automáticamente.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  runApp(const EcoGuiaApp());
}

class EcoGuiaApp extends StatelessWidget {
  const EcoGuiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'EcoGuía Galápagos',
          navigatorKey: AppNavigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Pantalla de carga mientras se resuelve el estado de sesión/perfil.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Escucha el estado de autenticación y redirige automáticamente.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        NotificationService.instance.syncDeviceToken(user);

        // Autenticado: decidir según si el perfil ya está completo en Firestore.
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: auth.userDoc(user.uid),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting &&
                !docSnap.hasData) {
              return const _Loading();
            }
            final complete = auth.isProfileComplete(docSnap.data?.data());
            return complete
                ? const AppShell()
                : CompleteProfileScreen(user: user);
          },
        );
      },
    );
  }
}
