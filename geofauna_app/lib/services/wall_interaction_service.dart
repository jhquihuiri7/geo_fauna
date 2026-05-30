import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WallInteractionTarget {
  const WallInteractionTarget({required this.collection, required this.id});

  final String collection;
  final String id;

  static WallInteractionTarget fromFeedItem({
    required String id,
    required String sourceKey,
  }) {
    final parts = sourceKey.split('/');
    if (parts.length >= 2 && parts[0] == 'fieldRecords') {
      return WallInteractionTarget(collection: 'fieldRecords', id: parts[1]);
    }
    if (parts.length >= 2 && parts[0] == 'publicFeed') {
      return WallInteractionTarget(collection: 'publicFeed', id: parts[1]);
    }
    return WallInteractionTarget(collection: 'publicFeed', id: id);
  }
}

class WallComment {
  const WallComment({
    required this.id,
    required this.authorName,
    required this.body,
    this.authorPhotoUrl,
    this.createdAt,
    this.isPending = false,
  });

  final String id;
  final String authorName;
  final String? authorPhotoUrl;
  final String body;
  final DateTime? createdAt;
  final bool isPending;

  factory WallComment.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final author = data['authorSnapshot'] is Map
        ? data['authorSnapshot'] as Map
        : null;
    return WallComment(
      id: doc.id,
      authorName:
          _firstNonEmpty([
            _stringValue(author?['name']),
            _stringValue(data['authorName']),
          ]) ??
          'Usuario sin nombre',
      authorPhotoUrl: _firstNonEmpty([
        _stringValue(author?['photoUrl']),
        _stringValue(data['authorPhotoUrl']),
      ]),
      body: _stringValue(data['body']) ?? '',
      createdAt: _toDate(data['createdAt']),
    );
  }
}

class WallReaction {
  const WallReaction({
    required this.id,
    required this.type,
    required this.authorName,
    this.authorPhotoUrl,
    this.createdAt,
  });

  final String id;
  final String type;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime? createdAt;

  factory WallReaction.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final author = data['authorSnapshot'] is Map
        ? data['authorSnapshot'] as Map
        : null;
    return WallReaction(
      id: doc.id,
      type: _normalizeReactionType(_stringValue(data['type'])),
      authorName:
          _firstNonEmpty([
            _stringValue(author?['name']),
            _stringValue(data['authorName']),
          ]) ??
          'Usuario sin nombre',
      authorPhotoUrl: _firstNonEmpty([
        _stringValue(author?['photoUrl']),
        _stringValue(data['authorPhotoUrl']),
      ]),
      createdAt: _toDate(data['createdAt']),
    );
  }
}

class QueuedWallComment {
  const QueuedWallComment({required this.comment, required this.commit});

  final WallComment comment;
  final Future<void> commit;
}

class WallInteractionService {
  WallInteractionService._();

  static final instance = WallInteractionService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Indica si el usuario actual ya dio "me gusta" a la publicacion.
  Stream<bool> userLikeStream(WallInteractionTarget target) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return _postRef(target)
        .collection('reactions')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> userConfirmationStream(WallInteractionTarget target) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return _postRef(target)
        .collection('confirmations')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<WallComment>> commentsStream(WallInteractionTarget target) {
    return _postRef(target)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => WallComment.fromSnapshot(doc))
              .where((comment) => comment.body.isNotEmpty)
              .toList(),
        );
  }

  Stream<List<WallReaction>> reactionsStream(WallInteractionTarget target) {
    return _postRef(target)
        .collection('reactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WallReaction.fromSnapshot).toList());
  }

  /// Alterna el "me gusta" del usuario actual sobre la publicacion. Si ya
  /// reacciono (con cualquier tipo, incluido un tipo legado), se elimina la
  /// marca y se descuenta del contador correspondiente; si no, se agrega un
  /// "me gusta".
  Future<void> toggleLike(WallInteractionTarget target) async {
    final user = _requireUser();
    final author = await _authorSnapshot(user);
    final postRef = _postRef(target);
    final reactionRef = postRef.collection('reactions').doc(user.uid);

    await _firestore.runTransaction((tx) async {
      final reaction = await tx.get(reactionRef);
      final post = await tx.get(postRef);
      if (!post.exists) throw Exception('La publicacion ya no existe.');

      final updates = <String, Object>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reaction.exists) {
        // Descuenta del contador al que contribuyo esta marca; puede ser un
        // tipo legado ('foto', 'proteger', etc.) de cuando habia varias
        // reacciones.
        final storedType = _rawReactionType(
          _stringValue(reaction.data()?['type']),
        );
        updates['reactionCounts.$storedType'] = FieldValue.increment(-1);
        tx.delete(reactionRef);
      } else {
        updates['reactionCounts.like'] = FieldValue.increment(1);
        tx.set(reactionRef, {
          'authorId': user.uid,
          'authorName': author.name,
          'authorPhotoUrl': author.photoUrl,
          'authorSnapshot': author.toMap(),
          'type': 'like',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _updateCounters(tx, target, updates);
    });
  }

  Future<void> toggleConfirmation(WallInteractionTarget target) async {
    final user = _requireUser();
    final postRef = _postRef(target);
    final confirmationRef = postRef.collection('confirmations').doc(user.uid);

    await _firestore.runTransaction((tx) async {
      final confirmation = await tx.get(confirmationRef);
      final post = await tx.get(postRef);
      if (!post.exists) throw Exception('La publicacion ya no existe.');

      final delta = confirmation.exists ? -1 : 1;
      if (confirmation.exists) {
        tx.delete(confirmationRef);
      } else {
        tx.set(confirmationRef, {
          'authorId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _updateCounters(tx, target, {
        'validationSummary.confirmations': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addComment(WallInteractionTarget target, String body) async {
    final queued = queueComment(target, body);
    await queued.commit;
  }

  QueuedWallComment queueComment(WallInteractionTarget target, String body) {
    final user = _requireUser();
    final text = body.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(body, 'body', 'El comentario esta vacio.');
    }

    final postRef = _postRef(target);
    final commentRef = postRef.collection('comments').doc();
    final localAuthor = _localAuthorSnapshot(user);

    return QueuedWallComment(
      comment: WallComment(
        id: commentRef.id,
        authorName: localAuthor.name,
        authorPhotoUrl: localAuthor.photoUrl,
        body: text,
        createdAt: DateTime.now(),
        isPending: true,
      ),
      commit: _commitComment(target, text, postRef, commentRef, user),
    );
  }

  Future<void> _commitComment(
    WallInteractionTarget target,
    String text,
    DocumentReference<Map<String, dynamic>> postRef,
    DocumentReference<Map<String, dynamic>> commentRef,
    User user,
  ) async {
    final author = await _authorSnapshot(user);

    await _firestore.runTransaction((tx) async {
      final post = await tx.get(postRef);
      if (!post.exists) throw Exception('La publicacion ya no existe.');

      tx.set(commentRef, {
        'authorId': user.uid,
        'authorName': author.name,
        'authorPhotoUrl': author.photoUrl,
        'authorSnapshot': author.toMap(),
        'body': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _updateCounters(tx, target, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Debes iniciar sesion para interactuar.',
      );
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> _postRef(
    WallInteractionTarget target,
  ) {
    return _firestore.collection(target.collection).doc(target.id);
  }

  void _updateCounters(
    Transaction tx,
    WallInteractionTarget target,
    Map<String, Object> updates,
  ) {
    tx.update(_postRef(target), updates);
  }

  Future<_AuthorSnapshot> _authorSnapshot(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    return _AuthorSnapshot(
      uid: user.uid,
      name:
          _firstNonEmpty([
            _stringValue(data['name']),
            user.displayName,
            user.email,
          ]) ??
          'Usuario sin nombre',
      photoUrl: _firstNonEmpty([
        _stringValue(data['photoUrl']),
        _stringValue(data['photoURL']),
        user.photoURL,
      ]),
    );
  }

  _AuthorSnapshot _localAuthorSnapshot(User user) {
    return _AuthorSnapshot(
      uid: user.uid,
      name:
          _firstNonEmpty([user.displayName, user.email]) ??
          'Usuario sin nombre',
      photoUrl: user.photoURL,
    );
  }
}

class _AuthorSnapshot {
  const _AuthorSnapshot({required this.uid, required this.name, this.photoUrl});

  final String uid;
  final String name;
  final String? photoUrl;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final text = _stringValue(value);
    if (text != null) return text;
  }
  return null;
}

String _normalizeReactionType(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'visto' => 'visto',
    'confirmo' || 'confirmó' || 'confirm' => 'confirmo',
    'proteger' || 'protect' => 'proteger',
    'foto' || 'photo' || 'like' || 'heart' || 'love' => 'foto',
    _ => 'foto',
  };
}

String _rawReactionType(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? 'like' : text;
}
