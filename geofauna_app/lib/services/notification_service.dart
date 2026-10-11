import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'app_navigation_service.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const wallChannelKey = 'wall_channel';

  bool _initialized = false;
  bool _syncing = false;
  String? _lastSyncedUid;
  String? _lastSyncedToken;

  Future<void> initialize() async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: wallChannelKey,
        channelName: 'Muro',
        channelDescription: 'Publicaciones nuevas del muro de GeoFauna',
        defaultColor: const Color(0xFF006948),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ], debug: kDebugMode);

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );

    // Los push se reciben con firebase_messaging (oficial y gratuito). El
    // add-on awesome_notifications_fcm pedía una licencia de pago y, sin ella,
    // anteponía "[DEMO]" al título de cada push en release.
    if (_supportsRemotePush) {
      try {
        await _ensureFirebaseInitialized();
        // Con la app abierta FCM no muestra nada: lo pintamos como
        // notificación local de Awesome, que sigue siendo gratuita.
        FirebaseMessaging.onMessage.listen(_showForegroundMessage);
        // Toque en un push que mostró el sistema (app en segundo plano).
        FirebaseMessaging.onMessageOpenedApp.listen(_openRemoteMessage);
        FirebaseMessaging.instance.onTokenRefresh.listen(
          (token) => unawaited(saveTokenForCurrentUser(token)),
        );
        // Toque en un push que abrió la app desde cerrada.
        final initialMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (initialMessage != null) _openRemoteMessage(initialMessage);
      } catch (error) {
        debugPrint('No se pudo inicializar Firebase Messaging: $error');
      }
    }

    final initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
    if (initialAction != null) {
      await _handleNotificationAction(initialAction);
    }

    _initialized = true;
  }

  Future<void> syncDeviceToken(User user) async {
    if (!_supportsRemotePush || _syncing) return;
    if (_lastSyncedUid == user.uid && _lastSyncedToken != null) return;

    _syncing = true;
    try {
      final allowed = await _ensurePermission();
      if (!allowed) return;

      await _ensureFirebaseInitialized();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await saveTokenForCurrentUser(token);
      _lastSyncedUid = user.uid;
      _lastSyncedToken = token;
    } catch (error) {
      debugPrint('No se pudo registrar el token push: $error');
    } finally {
      _syncing = false;
    }
  }

  Future<void> saveTokenForCurrentUser(String token) async {
    await _ensureFirebaseInitialized();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token.isEmpty) return;

    final tokenId = _tokenDocumentId(token);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notificationTokens')
        .doc(tokenId)
        .set({
          'token': token,
          'userId': user.uid,
          'platform': _platformLabel,
          'enabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> unregisterCurrentDevice() async {
    if (!_supportsRemotePush) return;

    try {
      await _ensureFirebaseInitialized();
      final token = await FirebaseMessaging.instance.getToken();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || token == null || token.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notificationTokens')
          .doc(_tokenDocumentId(token))
          .set({
            'enabled': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('No se pudo desregistrar el token push: $error');
    }
  }

  Future<bool> _ensurePermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (allowed) return true;
    return AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: wallChannelKey,
    );
  }

  static Future<void> _ensureFirebaseInitialized() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  static bool get _supportsRemotePush {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String get _platformLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  static String _tokenDocumentId(String token) {
    return base64Url.encode(utf8.encode(token)).replaceAll('=', '');
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    await _handleNotificationAction(receivedAction);
  }

  static Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final data = message.data;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: (data['postId'] ?? message.messageId ?? '').hashCode & 0x7fffffff,
        channelKey: wallChannelKey,
        title: notification.title,
        body: notification.body,
        payload: {
          for (final key in const ['route', 'postId', 'sourceKey'])
            key: data[key]?.toString(),
        },
      ),
    );
  }

  static void _openRemoteMessage(RemoteMessage message) {
    _openWallPost(message.data);
  }

  static Future<void> _handleNotificationAction(
    ReceivedAction receivedAction,
  ) async {
    _openWallPost(receivedAction.payload ?? const <String, String?>{});
  }

  static void _openWallPost(Map<String, dynamic> data) {
    if (data['route'] != 'wall_post') return;

    final sourceKey = data['sourceKey'];
    if (sourceKey is! String || sourceKey.isEmpty) return;

    final postId = data['postId'];
    AppNavigationService.openWallPost(
      sourceKey: sourceKey,
      postId: postId is String ? postId : null,
    );
  }
}
