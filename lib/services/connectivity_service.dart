import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStatusController.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void initialize() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _checkStatus(results);
    });
    // Check initial state
    checkConnection();
  }

  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = await _checkStatus(results);
      return hasConnection;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      _updateStatus(false);
      return false;
    }
  }

  Future<bool> _checkStatus(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _updateStatus(false);
      return false;
    }

    // On Web, InternetAddress.lookup is not supported directly; connectivity result is sufficient
    if (kIsWeb) {
      _updateStatus(true);
      return true;
    }

    // On mobile / desktop platforms, verify actual internet reachability
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        _updateStatus(true);
        return true;
      }
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('firebase.google.com')
            .timeout(const Duration(seconds: 4));
        if (fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty) {
          _updateStatus(true);
          return true;
        }
      } catch (_) {
        // Both failed -> No active internet
      }
    }

    _updateStatus(false);
    return false;
  }

  void _updateStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionStatusController.add(_isOnline);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
