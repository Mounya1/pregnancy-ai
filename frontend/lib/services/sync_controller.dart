import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'auth_controller.dart';
import 'local_storage_service.dart';

enum SyncState { idle, syncing, done, failed, unavailable }

/// Keeps this device's data and the server copy in step - automatically.
///
/// The whole local store travels as one document. That mirrors how the app
/// already stores things and makes a sync one request instead of twenty, at
/// the cost of not being able to merge two devices that both changed at once:
/// the copy the server saw last wins. Syncing every few seconds keeps that
/// window small.
///
/// It used to run only from the Back up / Restore buttons in Account, so the
/// website and the phone quietly drifted apart - two profiles for one person.
/// Now it runs on sign-in, on app open and resume, shortly after any change,
/// and when the app goes to the background.
class SyncController extends ChangeNotifier with WidgetsBindingObserver {
  /// [dio] is for tests - a fake server. The app uses the API client's.
  SyncController(this._storage, this._auth, {this.onRestored, Dio? dio})
      : _dio = dio ?? ApiClient().rawDio {
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    _onAuthChanged();
  }

  final LocalStorageService _storage;
  final AuthController _auth;
  final Dio _dio;

  /// Called after data arrives from the server, so every screen's controller
  /// reloads it - no restart needed.
  final VoidCallback? onRestored;

  /// How often to look for local changes to send up. Only a local read unless
  /// something changed.
  static const pushInterval = Duration(seconds: 15);

  /// How often to look for changes made on another device while this one is
  /// open.
  static const pullInterval = Duration(seconds: 60);

  SyncState _state = SyncState.idle;
  String? _message;
  DateTime? _lastSynced;
  bool _wasAvailable = false;
  bool _running = false;
  Timer? _pushTimer;
  Timer? _pullTimer;

  SyncState get state => _state;
  String? get message => _message;
  DateTime? get lastSynced => _lastSynced;

  /// Sync needs an account to attach data to, so it is off on device-only
  /// builds - there is no identity to key a server copy on.
  bool get isAvailable => _auth.isCloud && _auth.isSignedIn;

  void _set(SyncState state, [String? message]) {
    _state = state;
    _message = message;
    notifyListeners();
  }

  // ---- Automatic ----

  void _onAuthChanged() {
    final available = isAvailable;
    if (available && !_wasAvailable) {
      _pushTimer = Timer.periodic(pushInterval, (_) => _pushIfChanged());
      _pullTimer = Timer.periodic(pullInterval, (_) => syncNow());
      // Deferred: this can run inside the auth controller's notify.
      scheduleMicrotask(syncNow);
    } else if (!available && _wasAvailable) {
      _pushTimer?.cancel();
      _pullTimer?.cancel();
    }
    _wasAvailable = available;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        syncNow();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // Leaving the app (or the browser tab) - send anything pending now,
        // rather than trusting the timer to get another chance.
        _pushIfChanged();
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Order-independent fingerprint of the local data, so "has anything
  /// changed since the last sync?" is one comparison.
  static String fingerprint(Map<String, dynamic> data) {
    final keys = data.keys.toList()..sort();
    final canonical = jsonEncode({for (final k in keys) k: data[k]});
    return sha1.convert(utf8.encode(canonical)).toString();
  }

  /// Two-way sync: takes the server copy if another device saved since this
  /// one last synced, otherwise sends this device's changes up.
  Future<void> syncNow() async {
    if (!isAvailable || _running) return;
    _running = true;
    try {
      final local = await _storage.exportAll();
      final localHash = fingerprint(local);
      final (lastHash, lastAt) = await _storage.loadSyncState();

      final res = await _dio.get(
        '/sync',
        options: Options(headers: await _authHeader()),
      );
      final remote = res.data['data'];
      final remoteAt = DateTime.tryParse(res.data['updated_at'] as String? ?? '');

      if (remote == null) {
        // First device on this account: its data becomes the account's copy.
        await _upload(local, localHash);
        return;
      }

      // Server times on both sides, so device clocks never matter. A device
      // that has never synced takes the account's copy - that is what makes
      // a new phone or browser show the same profile as the old one.
      final remoteIsNewer =
          lastAt == null || (remoteAt != null && remoteAt.isAfter(lastAt));
      if (remoteIsNewer) {
        await _storage.importAll((remote as Map).cast<String, dynamic>());
        final merged = await _storage.exportAll();
        await _storage.saveSyncState(fingerprint(merged), remoteAt);
        _lastSynced = remoteAt;
        onRestored?.call();
        _set(SyncState.done, 'Up to date with your account.');
      } else if (localHash != lastHash) {
        await _upload(local, localHash);
      } else {
        _lastSynced = lastAt;
        if (_state != SyncState.done) _set(SyncState.done, 'Up to date with your account.');
      }
    } catch (e) {
      _set(SyncState.failed, _describe(e));
    } finally {
      _running = false;
    }
  }

  /// Sends local changes up without a round trip when nothing changed.
  Future<void> _pushIfChanged() async {
    if (!isAvailable || _running) return;
    final local = await _storage.exportAll();
    final (lastHash, _) = await _storage.loadSyncState();
    // Through syncNow, not a bare upload: another device may have saved in
    // the meantime, and blindly overwriting it would lose that.
    if (fingerprint(local) != lastHash) await syncNow();
  }

  Future<void> _upload(Map<String, dynamic> data, String hash) async {
    _set(SyncState.syncing);
    final res = await _dio.put(
      '/sync',
      data: {'data': data},
      options: Options(headers: await _authHeader()),
    );
    final at = DateTime.tryParse(res.data['updated_at'] as String? ?? '');
    await _storage.saveSyncState(hash, at);
    _lastSynced = at;
    _set(SyncState.done, 'Saved to your account.');
  }

  // ---- Manual (Account screen) ----

  /// Sends this device's data up, replacing the server copy.
  Future<void> push() async {
    if (!isAvailable) return _set(SyncState.unavailable, 'Sign in to sync.');
    if (_running) return;
    _running = true;
    try {
      final data = await _storage.exportAll();
      await _upload(data, fingerprint(data));
    } catch (e) {
      _set(SyncState.failed, _describe(e));
    } finally {
      _running = false;
    }
  }

  /// Brings the server copy down, replacing this device's data.
  ///
  /// Returns false when there is nothing stored yet. That case must not wipe
  /// the device: a brand new account has no server copy, and treating "never
  /// synced" as "synced and empty" would delete everything on first run.
  Future<bool> pull() async {
    if (!isAvailable) {
      _set(SyncState.unavailable, 'Sign in to sync.');
      return false;
    }
    if (_running) return false;
    _running = true;

    _set(SyncState.syncing);
    try {
      final res = await _dio.get(
        '/sync',
        options: Options(headers: await _authHeader()),
      );
      final data = res.data['data'];
      if (data == null) {
        _set(SyncState.done, 'Nothing saved to your account yet.');
        return false;
      }

      await _storage.importAll((data as Map).cast<String, dynamic>());
      _lastSynced = DateTime.tryParse(res.data['updated_at'] as String? ?? '');
      await _storage.saveSyncState(fingerprint(await _storage.exportAll()), _lastSynced);
      onRestored?.call();
      _set(SyncState.done, 'Restored from your account.');
      return true;
    } catch (e) {
      _set(SyncState.failed, _describe(e));
      return false;
    } finally {
      _running = false;
    }
  }

  /// Removes the server copy. The device keeps its own data.
  Future<void> deleteRemote() async {
    if (!isAvailable) return _set(SyncState.unavailable, 'Sign in to sync.');

    _set(SyncState.syncing);
    try {
      await _dio.delete('/sync', options: Options(headers: await _authHeader()));
      _lastSynced = null;
      _set(SyncState.done, 'Removed from your account. This device still has its copy.');
    } catch (e) {
      _set(SyncState.failed, _describe(e));
    }
  }

  Future<Map<String, String>> _authHeader() async {
    final token = await _auth.accessToken();
    return {'Authorization': 'Bearer $token'};
  }

  String _describe(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final detail = error.response?.data is Map
          ? (error.response!.data as Map)['detail']?.toString()
          : null;
      if (status == 401) return 'Your session expired. Sign in again.';
      if (status == 501) return 'Sync is not switched on for this server.';
      if (status == 413) {
        return detail ?? 'Your data is too large to sync.';
      }
      if (detail != null) return detail;
      return 'Sync failed${status == null ? '' : ' ($status)'}.';
    }
    return 'Sync failed. Check your connection.';
  }

  @override
  void dispose() {
    _pushTimer?.cancel();
    _pullTimer?.cancel();
    _auth.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
