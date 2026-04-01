import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/standing.dart';

class StandingsService {
  static const String baseUrl = 'https://api.jolpi.ca/ergast/f1';

  Future<List<Standing>> getDriverStandings({int? year}) async {
    final targetYear = year ?? DateTime.now().year;
    final url = Uri.parse('$baseUrl/$targetYear/driverStandings.json');
    
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> dataList = responseData['MRData']['StandingsTable']
          ['StandingsLists'][0]['DriverStandings'];
      return dataList.map((json) => Standing.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load standings');
    }
  }
}

final standingsServiceProvider = Provider((ref) => StandingsService());

final currentStandingsProvider = FutureProvider<List<Standing>>((ref) async {
  final service = ref.watch(standingsServiceProvider);
  return await service.getDriverStandings();
});
