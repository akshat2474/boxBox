class RaceMessage {
  final int sessionKey;
  final DateTime date;
  final String category;
  final String? flag;
  final String? scope;
  final int? sector;
  final int? driverNumber;
  final int? lapNumber;
  final String message;

  RaceMessage({
    required this.sessionKey,
    required this.date,
    required this.category,
    this.flag,
    this.scope,
    this.sector,
    this.driverNumber,
    this.lapNumber,
    required this.message,
  });

  factory RaceMessage.fromJson(Map<String, dynamic> json) {
    return RaceMessage(
      sessionKey: json['session_key'] ?? 0,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? 'Unknown',
      flag: json['flag'],
      scope: json['scope'],
      sector: json['sector'],
      driverNumber: json['driver_number'],
      lapNumber: json['lap_number'],
      message: json['message'] ?? '',
    );
  }
}
