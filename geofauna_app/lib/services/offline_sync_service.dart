import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

typedef OfflineSyncProcessor =
    Future<void> Function(OfflineSyncOperation operation);

enum OfflineSyncStatus { pending, syncing, failed }

class OfflineSyncOperation {
  const OfflineSyncOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final OfflineSyncStatus status;
  final int createdAtMs;
  final int updatedAtMs;
  final int retryCount;
  final String? lastError;

  OfflineSyncOperation copyWith({
    OfflineSyncStatus? status,
    int? updatedAtMs,
    int? retryCount,
    String? lastError,
    bool clearLastError = false,
  }) {
    return OfflineSyncOperation(
      id: id,
      type: type,
      payload: payload,
      status: status ?? this.status,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      retryCount: retryCount ?? this.retryCount,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'status': status.name,
      'createdAtMs': createdAtMs,
      'updatedAtMs': updatedAtMs,
      'retryCount': retryCount,
      if (lastError != null) 'lastError': lastError,
    };
  }

  static OfflineSyncOperation fromJson(Map<String, dynamic> json) {
    return OfflineSyncOperation(
      id: _stringValue(json['id']) ?? _newId('op'),
      type: _stringValue(json['type']) ?? 'unknown',
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
      status: OfflineSyncStatus.values.firstWhere(
        (value) => value.name == _stringValue(json['status']),
        orElse: () => OfflineSyncStatus.pending,
      ),
      createdAtMs: _intValue(json['createdAtMs']) ?? _nowMs(),
      updatedAtMs: _intValue(json['updatedAtMs']) ?? _nowMs(),
      retryCount: _intValue(json['retryCount']) ?? 0,
      lastError: _stringValue(json['lastError']),
    );
  }
}

class OfflineSyncService {
  OfflineSyncService._();

  static final instance = OfflineSyncService._();

  final operations = ValueNotifier<List<OfflineSyncOperation>>(const []);

  OfflineSyncProcessor? _processor;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _retryTimer;
  File? _queueFile;
  Directory? _mediaDir;
  bool _initialized = false;
  bool _processing = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final appDir = await getApplicationDocumentsDirectory();
    _queueFile = File(
      '${appDir.path}${Platform.pathSeparator}offline_queue.json',
    );
    _mediaDir = Directory(
      '${appDir.path}${Platform.pathSeparator}offline_media',
    );
    if (!await _mediaDir!.exists()) {
      await _mediaDir!.create(recursive: true);
    }
    await _load();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        unawaited(processPending());
      }
    });
    _retryTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      unawaited(processPending());
    });
    _initialized = true;
  }

  void registerProcessor(OfflineSyncProcessor processor) {
    _processor = processor;
    unawaited(processPending());
  }

  Future<String> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? id,
  }) async {
    await initialize();
    final now = _nowMs();
    final operation = OfflineSyncOperation(
      id: id ?? _newId(type),
      type: type,
      payload: payload,
      status: OfflineSyncStatus.pending,
      createdAtMs: now,
      updatedAtMs: now,
    );
    operations.value = [...operations.value, operation];
    await _save();
    unawaited(processPending());
    return operation.id;
  }

  Future<List<Map<String, dynamic>>> persistEvidenceDrafts(
    List<OfflineEvidenceDraft> drafts,
  ) async {
    await initialize();
    final mediaDir = _mediaDir!;
    final persisted = <Map<String, dynamic>>[];
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final source = File(draft.path);
      if (!await source.exists()) continue;
      final extension = _extension(source.path);
      final fileName = '${_newId('media')}_$i$extension';
      final target = File('${mediaDir.path}${Platform.pathSeparator}$fileName');
      await source.copy(target.path);
      persisted.add({
        'type': draft.type,
        'path': target.path,
        'name': draft.name ?? fileName,
      });
    }
    return persisted;
  }

  Future<void> processPending() async {
    await initialize();
    final processor = _processor;
    if (processor == null || _processing || operations.value.isEmpty) return;

    _processing = true;
    try {
      for (final operation in List<OfflineSyncOperation>.of(operations.value)) {
        if (!operations.value.any((item) => item.id == operation.id)) continue;
        final current = _operationById(operation.id);
        if (current == null || current.status == OfflineSyncStatus.syncing) {
          continue;
        }
        await _replace(
          current.copyWith(
            status: OfflineSyncStatus.syncing,
            updatedAtMs: _nowMs(),
            clearLastError: true,
          ),
        );
        try {
          await processor(current);
          await _remove(current.id);
        } catch (error) {
          await _replace(
            current.copyWith(
              status: OfflineSyncStatus.failed,
              retryCount: current.retryCount + 1,
              updatedAtMs: _nowMs(),
              lastError: error.toString(),
            ),
          );
        }
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> retryNow() => processPending();

  OfflineSyncOperation? _operationById(String id) {
    for (final operation in operations.value) {
      if (operation.id == id) return operation;
    }
    return null;
  }

  Future<void> _replace(OfflineSyncOperation operation) async {
    operations.value = [
      for (final item in operations.value)
        if (item.id == operation.id) operation else item,
    ];
    await _save();
  }

  Future<void> _remove(String id) async {
    operations.value = [
      for (final item in operations.value)
        if (item.id != id) item,
    ];
    await _save();
  }

  Future<void> _load() async {
    final file = _queueFile!;
    if (!await file.exists()) {
      operations.value = const [];
      return;
    }
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        operations.value = const [];
        return;
      }
      operations.value = [
        for (final item in decoded)
          if (item is Map)
            OfflineSyncOperation.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      operations.value = const [];
    }
  }

  Future<void> _save() async {
    final file = _queueFile!;
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode([
        for (final operation in operations.value) operation.toJson(),
      ]),
      flush: true,
    );
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _retryTimer?.cancel();
  }
}

class OfflineEvidenceDraft {
  const OfflineEvidenceDraft({
    required this.type,
    required this.path,
    this.name,
  });

  final String type;
  final String path;
  final String? name;
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

String _newId(String prefix) => '${prefix}_${_nowMs()}_${_nonce()}';

String _nonce() {
  final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return micros.substring(micros.length > 8 ? micros.length - 8 : 0);
}

String _extension(String path) {
  final name = path.split(Platform.pathSeparator).last;
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '.bin';
  return name.substring(dot).toLowerCase();
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _intValue(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}
