import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class NetworkProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _subscription;

  bool _isOnline = true;
  bool _isChecking = false;
  bool _showBackOnlineBanner = false;
  Timer? _backOnlineTimer;

  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;
  bool get showBackOnlineBanner => _showBackOnlineBanner;

  NetworkProvider(this._connectivityService) {
    _isOnline = _connectivityService.isOnline;
    _connectivityService.initialize();
    _subscription = _connectivityService.connectionStream.listen((online) {
      final wasOffline = !_isOnline;
      _isOnline = online;

      if (wasOffline && online) {
        _showBackOnlineBanner = true;
        _backOnlineTimer?.cancel();
        _backOnlineTimer = Timer(const Duration(seconds: 3), () {
          _showBackOnlineBanner = false;
          notifyListeners();
        });
      }

      notifyListeners();
    });
  }

  Future<bool> retryConnection() async {
    _isChecking = true;
    notifyListeners();

    final result = await _connectivityService.checkConnection();
    _isChecking = false;
    _isOnline = result;
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _backOnlineTimer?.cancel();
    super.dispose();
  }
}
