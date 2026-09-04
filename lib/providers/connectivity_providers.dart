import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Live online/offline status for the whole app. Backed by
/// [ConnectivityService] -- yields the current status immediately on
/// first listen (so cold-start-with-no-internet is caught), then one
/// value per confirmed change after that. Watched by
/// [ConnectivityBanner] and by anything that wants to react to
/// reconnects (see main.dart).
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final service = ConnectivityService.instance;
  await service.init();
  yield service.isOnline;
  yield* service.onStatusChanged;
});
