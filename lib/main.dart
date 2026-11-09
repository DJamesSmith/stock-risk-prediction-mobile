import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/live_socket.dart';
import 'core/token_storage.dart';
import 'state/session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final TokenStorage tokens = TokenStorage();
  final ApiClient api = ApiClient(tokens);
  final LiveSocket live = LiveSocket(api);
  final Session session = Session(api: api, live: live);

  runApp(StockRiskApp(api: api, live: live, session: session));
}