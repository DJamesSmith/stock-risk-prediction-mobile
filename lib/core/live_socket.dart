import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_endpoints.dart';
import '../models/live_event.dart';
import '../models/live_quote.dart';
import 'api_client.dart';

enum LiveStatus { offline, connecting, connected, reconnecting }

class LiveSocket extends ChangeNotifier {
  LiveSocket(this.api);

  static const int closeUnauthorized = 4401;
  static const int maxTickersPerMessage = 20;
  static const int maxAlerts = 50;
  static const int maxUnauthorizedInRow = 3;
  static const Duration pingInterval = Duration(seconds: 30);
  static const Duration silenceLimit = Duration(seconds: 75);
  static const List<int> retryDelaySeconds = [1, 2, 4, 8, 16, 30];

  final ApiClient api;
  VoidCallback? onSessionExpired;

  final StreamController<LiveEvent> _events = StreamController<LiveEvent>.broadcast();
  final Map<String, LiveQuote> quotes = {};
  final List<RiskAlert> alerts = [];
  final Set<String> pinnedTickers = {};
  final Map<String, int> _followers = {};

  LiveStatus status = LiveStatus.offline;
  String? lastError;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _retryTimer;
  DateTime _lastMessageAt = DateTime.now();
  bool _wanted = false;
  int _attempt = 0;
  int _unauthorizedInRow = 0;

  Stream<LiveEvent> get events => _events.stream;

  bool get isConnected => status == LiveStatus.connected;

  List<String> get followedTickers {
    final List<String> tickers = _followers.keys.toList();
    tickers.sort();
    return tickers;
  }

  LiveQuote? quoteFor(String ticker) => quotes[ticker.toUpperCase()];

  void start() {
    _wanted = true;
    _attempt = 0;
    _unauthorizedInRow = 0;
    _closeChannel();
    _open();
  }

  void restart() {
    if (!_wanted) {
      return;
    }

    start();
  }

  void stop() {
    _wanted = false;
    _closeChannel();
    quotes.clear();
    alerts.clear();
    pinnedTickers.clear();
    _followers.clear();
    lastError = null;
    _setStatus(LiveStatus.offline);
  }

  void follow(Iterable<String> tickers) {
    final List<String> added = [];

    for (final String ticker in tickers.map((ticker) => ticker.toUpperCase()).toSet()) {
      final int count = _followers[ticker] ?? 0;
      _followers[ticker] = count + 1;

      if (count == 0) {
        added.add(ticker);
      }
    }

    _sendTickers('subscribe', added);
  }

  void unfollow(Iterable<String> tickers) {
    final List<String> removed = [];

    for (final String ticker in tickers.map((ticker) => ticker.toUpperCase()).toSet()) {
      final int? count = _followers[ticker];

      if (count == null) {
        continue;
      }

      if (count <= 1) {
        _followers.remove(ticker);
        removed.add(ticker);
      } else {
        _followers[ticker] = count - 1;
      }
    }

    _sendTickers('unsubscribe', removed);
  }

  bool isPinned(String ticker) => pinnedTickers.contains(ticker.toUpperCase());

  void togglePin(String ticker) {
    final String upper = ticker.toUpperCase();

    if (pinnedTickers.remove(upper)) {
      unfollow([upper]);
    } else {
      pinnedTickers.add(upper);
      follow([upper]);
    }

    notifyListeners();
  }

  void dismissAlert(RiskAlert alert) {
    alerts.remove(alert);
    notifyListeners();
  }

  void clearAlerts() {
    alerts.clear();
    notifyListeners();
  }

  Future<void> _open() async {
    _retryTimer?.cancel();
    final String? token = api.tokens.access;

    if (!_wanted || token == null) {
      return;
    }

    _setStatus(_attempt == 0 ? LiveStatus.connecting : LiveStatus.reconnecting);

    final WebSocketChannel channel = WebSocketChannel.connect(ApiEndpoints.liveSocketUri(token));
    _channel = channel;

    try {
      await channel.ready;
    } catch (_) {
      if (_channel == channel) {
        _channel = null;
        _scheduleRetry();
      }
      return;
    }

    if (_channel != channel) {
      channel.sink.close();
      return;
    }

    _lastMessageAt = DateTime.now();
    _subscription = channel.stream.listen(
      _onMessage,
      onDone: () => _onClosed(channel),
      onError: (Object error) {},
    );
  }

  void _onMessage(dynamic raw) {
    _lastMessageAt = DateTime.now();
    LiveEvent event;

    try {
      event = LiveEvent.fromJson(Map<String, dynamic>.from(jsonDecode(raw.toString()) as Map));
    } catch (_) {
      return;
    }

    if (event.type == 'connection.ready') {
      _attempt = 0;
      _unauthorizedInRow = 0;
      lastError = null;
      _setStatus(LiveStatus.connected);
      _startPing();
      _sendTickers('subscribe', _followers.keys.toList());
    } else if (event.type == 'price.update') {
      final LiveQuote quote = LiveQuote.fromJson(event.data);
      quotes[quote.ticker] = quote;
      notifyListeners();
    } else if (event.type == 'risk.changed') {
      alerts.insert(0, RiskAlert.fromJson(event.data));

      if (alerts.length > maxAlerts) {
        alerts.removeLast();
      }

      notifyListeners();
    } else if (event.type == 'error') {
      lastError = event.message;
      notifyListeners();
    }

    _events.add(event);
  }

  Future<void> _onClosed(WebSocketChannel channel) async {
    if (_channel != channel) {
      return;
    }

    final int? code = channel.closeCode;
    _channel = null;
    _subscription = null;
    _pingTimer?.cancel();

    if (!_wanted) {
      _setStatus(LiveStatus.offline);
      return;
    }

    if (code == closeUnauthorized && _unauthorizedInRow < maxUnauthorizedInRow) {
      _unauthorizedInRow++;
      final bool? refreshed = await api.refreshAccessToken();

      if (!_wanted) {
        return;
      }

      if (refreshed == true) {
        _open();
        return;
      }

      if (refreshed == false) {
        onSessionExpired?.call();
        return;
      }
    }

    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!_wanted) {
      return;
    }

    final int index = min(_attempt, retryDelaySeconds.length - 1);
    final Duration delay = Duration(seconds: retryDelaySeconds[index]);
    _attempt++;
    _setStatus(_attempt > 3 ? LiveStatus.offline : LiveStatus.reconnecting);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, _open);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      final Duration silence = DateTime.now().difference(_lastMessageAt);

      if (silence > silenceLimit) {
        _closeChannel();
        _scheduleRetry();
        return;
      }

      _send({'action': 'ping'});
    });
  }

  void _sendTickers(String action, List<String> tickers) {
    for (int start = 0; start < tickers.length; start += maxTickersPerMessage) {
      final int end = min(start + maxTickersPerMessage, tickers.length);
      _send({'action': action, 'tickers': tickers.sublist(start, end)});
    }
  }

  void _send(Map<String, dynamic> message) {
    final WebSocketChannel? channel = _channel;

    if (channel == null || status != LiveStatus.connected) {
      return;
    }

    channel.sink.add(jsonEncode(message));
  }

  void _closeChannel() {
    _pingTimer?.cancel();
    _retryTimer?.cancel();
    final WebSocketChannel? channel = _channel;
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    channel?.sink.close();
  }

  void _setStatus(LiveStatus value) {
    if (status == value) {
      return;
    }

    status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _wanted = false;
    _closeChannel();
    _events.close();
    super.dispose();
  }
}
