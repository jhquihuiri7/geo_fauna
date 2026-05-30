import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart'; // generado por: flutterfire configure
import 'services/app_navigation_service.dart';
import 'services/auth_service.dart';
import 'services/field_data_service.dart';
import 'services/notification_service.dart';
import 'services/offline_sync_service.dart';
import 'services/tracking_service.dart';
import 'theme/app_theme.dart';
import 'app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Modo inmersivo: oculta la barra de navegación del sistema. El usuario la
  // revela deslizando desde el borde y se vuelve a ocultar automáticamente.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Solo Firebase es crítico antes del primer frame (el stream de auth lo
  // necesita). Lo demás se inicializa en segundo plano para que la app pinte de
  // inmediato y no dispare un ANR ("esperar o cerrar app") en el arranque.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EcoGuiaApp());
  _initBackgroundServices();
}

/// Inicializa los servicios no críticos tras `runApp`, en paralelo y sin
/// bloquear el arranque. Cada uno se aísla para que un fallo no tumbe a los
/// demás ni se vuelva una excepción asíncrona sin capturar.
void _initBackgroundServices() {
  Future<void> guard(String name, Future<void> Function() task) async {
    try {
      await task();
    } catch (error, stack) {
      debugPrint('Fallo al inicializar $name: $error\n$stack');
    }
  }

  unawaited(guard('OfflineSync', OfflineSyncService.instance.initialize));
  unawaited(guard('Tracking', TrackingService.instance.initialize));
  unawaited(guard('Notificaciones', NotificationService.instance.initialize));
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
        FieldDataService();
        unawaited(OfflineSyncService.instance.retryNow());

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
