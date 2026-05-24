import 'package:flutter/material.dart';

class WallPostTarget {
  const WallPostTarget({required this.sourceKey, this.postId});

  final String sourceKey;
  final String? postId;
}

class AppNavigationService {
  AppNavigationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final wallPostTarget = ValueNotifier<WallPostTarget?>(null);

  static void openWallPost({required String sourceKey, String? postId}) {
    wallPostTarget.value = WallPostTarget(sourceKey: sourceKey, postId: postId);
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
