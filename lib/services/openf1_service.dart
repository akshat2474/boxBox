import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../models/driver.dart';
import '../models/race_message.dart';

class OpenF1Service {
  static const String baseUrl = 'https://api.openf1.org/v1';

  // Races officially cancelled in 2026 (Bahrain GP + Saudi Arabian GP, cancelled Mar 14 2026
  // due to Middle East conflict). Remove when OpenF1 API reflects this.
  static const Set<int> _cancelledMeetingKeys = {1282, 1283};

  Future<List<Session>> getSessions({int? year}) async {
    final targetYear = year ?? DateTime.now().year;
    final url = Uri.parse('$baseUrl/sessions?year=$targetYear');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => Session.fromJson(json))
          .where((s) => !_cancelledMeetingKeys.contains(s.meetingKey))
          .toList();
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  Future<List<Driver>> getDriversForSession(int sessionKey) async {
    final url = Uri.parse('$baseUrl/drivers?session_key=$sessionKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Driver.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load drivers');
    }
  }

  Future<List<RaceMessage>> getRaceControlMessages(int sessionKey) async {
    final url = Uri.parse('$baseUrl/race_control?session_key=$sessionKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RaceMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load race control');
    }
  }
}

final openF1ServiceProvider = Provider((ref) => OpenF1Service());

final currentSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final service = ref.watch(openF1ServiceProvider);
  return await service.getSessions();
});

/// Combined hub data: drivers map + race control messages, polled every 10s
class SessionHubData {
  final Map<int, Driver> driversMap;
  final List<RaceMessage> messages;
  SessionHubData({required this.driversMap, required this.messages});
}

final sessionHubProvider = StreamProvider.autoDispose.family<SessionHubData, int>((ref, sessionKey) async* {
  final service = ref.watch(openF1ServiceProvider);

  Future<SessionHubData> fetch() async {
    final results = await Future.wait([
      service.getDriversForSession(sessionKey),
      service.getRaceControlMessages(sessionKey),
    ]);
    final drivers = results[0] as List<Driver>;
    final messages = (results[1] as List<RaceMessage>).reversed.toList();
    final driversMap = {for (final d in drivers) d.driverNumber: d};
    return SessionHubData(driversMap: driversMap, messages: messages);
  }

  yield await fetch();

  await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
    yield await fetch();
  }
});
