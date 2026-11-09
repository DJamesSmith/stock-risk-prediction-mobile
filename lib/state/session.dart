import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/live_socket.dart';
import '../models/live_event.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum SessionStatus { unknown, signedOut, signedIn }

class Session extends ChangeNotifier {
  Session({required this.api, required this.live}) : auth = AuthService(api) {
    api.onSessionExpired = _expire;
    live.onSessionExpired = _expire;
    _liveEvents = live.events.listen(_onLiveEvent);
  }

  final ApiClient api;
  final LiveSocket live;
  final AuthService auth;
  late final StreamSubscription<LiveEvent> _liveEvents;

  SessionStatus status = SessionStatus.unknown;
  AppUser? user;
  String? restoreError;
  String? notice;
  bool restoring = false;

  Future<void> restore() async {
    if (restoring) {
      return;
    }

    restoring = true;
    restoreError = null;
    notifyListeners();

    await api.tokens.load();

    if (!api.tokens.hasTokens) {
      restoring = false;
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }

    try {
      user = await auth.me();
      status = SessionStatus.signedIn;
      live.start();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await api.tokens.clear();
        status = SessionStatus.signedOut;
      } else {
        restoreError = error.message;
      }
    }

    restoring = false;
    notifyListeners();
  }

  Future<void> login(String usernameOrEmail, String password) async {
    user = await auth.login(usernameOrEmail, password);
    notice = null;
    status = SessionStatus.signedIn;
    live.start();
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await auth.register(
      username: username,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await login(username, password);
  }

  Future<void> reloadUser() async {
    user = await auth.me();
    notifyListeners();
  }

  void updateUser(AppUser updated) {
    user = updated;
    notifyListeners();
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final String message = await auth.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );
    live.restart();
    return message;
  }

  Future<void> logout() async {
    try {
      await auth.logout();
    } on ApiException catch (_) {}

    await _signOut(null);
  }

  Future<void> forgetStoredLogin() async {
    await _signOut(null);
  }

  void _expire() {
    if (status != SessionStatus.signedIn) {
      return;
    }

    _signOut('Your session expired. Please log in again.');
  }

  Future<void> _signOut(String? message) async {
    live.stop();
    await api.tokens.clear();
    user = null;
    notice = message;
    restoreError = null;
    status = SessionStatus.signedOut;
    notifyListeners();
  }

  void _onLiveEvent(LiveEvent event) {
    final AppUser? current = user;

    if (event.type != 'connection.ready' || current == null) {
      return;
    }

    if (event.data['role'] != current.role) {
      reloadUser().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    _liveEvents.cancel();
    super.dispose();
  }
}
