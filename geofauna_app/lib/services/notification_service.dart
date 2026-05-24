import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

    if (_supportsRemotePush) {
      try {
        await AwesomeNotificationsFcm().initialize(
          onFcmTokenHandle: onFcmTokenHandle,
          onFcmSilentDataHandle: onFcmSilentDataHandle,
          onNativeTokenHandle: onNativeTokenHandle,
          debug: kDebugMode,
        );
      } catch (error) {
        debugPrint('No se pudo inicializar Awesome FCM: $error');
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

      final fcm = AwesomeNotificationsFcm();
      if (!await fcm.isFirebaseAvailable) return;

      final token = await fcm.requestFirebaseAppToken();
      if (token.isEmpty) return;

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
      final fcm = AwesomeNotificationsFcm();
      if (!await fcm.isFirebaseAvailable) return;

      final token = await fcm.requestFirebaseAppToken();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || token.isEmpty) return;

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

  @pragma('vm:entry-point')
  static Future<void> onFcmTokenHandle(String token) async {
    await instance.saveTokenForCurrentUser(token);
  }

  @pragma('vm:entry-point')
  static Future<void> onNativeTokenHandle(String token) async {
    debugPrint('Native push token recibido: $token');
  }

  @pragma('vm:entry-point')
  static Future<void> onFcmSilentDataHandle(FcmSilentData silentData) async {
    debugPrint('Silent push recibido: ${silentData.data}');
  }

  static Future<void> _handleNotificationAction(
    ReceivedAction receivedAction,
  ) async {
    final payload = receivedAction.payload ?? const <String, String?>{};
    if (payload['route'] != 'wall_post') return;

    final sourceKey = payload['sourceKey'];
    if (sourceKey == null || sourceKey.isEmpty) return;

    AppNavigationService.openWallPost(
      sourceKey: sourceKey,
      postId: payload['postId'],
    );
  }
}
