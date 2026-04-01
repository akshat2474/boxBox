class Session {
  final int sessionKey;
  final int meetingKey;
  final String sessionName;
  final String sessionType;
  final String dateStart;
  final String dateEnd;
  final String countryName;
  final String circuitShortName;
  final String location;

  Session({
    required this.sessionKey,
    required this.meetingKey,
    required this.sessionName,
    required this.sessionType,
    required this.dateStart,
    required this.dateEnd,
    required this.countryName,
    required this.circuitShortName,
    required this.location,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionKey: json['session_key'] ?? 0,
      meetingKey: json['meeting_key'] ?? 0,
      sessionName: json['session_name'] ?? 'Unknown',
      sessionType: json['session_type'] ?? 'Unknown',
      dateStart: json['date_start'] ?? '',
      dateEnd: json['date_end'] ?? '',
      countryName: json['country_name'] ?? '',
      circuitShortName: json['circuit_short_name'] ?? '',
      location: json['location'] ?? '',
    );
  }
}
