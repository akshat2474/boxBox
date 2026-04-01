class Driver {
  final int driverNumber;
  final String fullName;
  final String nameAcronym;
  final String teamName;
  final String teamColour;
  final String? headshotUrl;

  Driver({
    required this.driverNumber,
    required this.fullName,
    required this.nameAcronym,
    required this.teamName,
    required this.teamColour,
    this.headshotUrl,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverNumber: json['driver_number'] ?? 0,
      fullName: json['full_name'] ?? 'Unknown Driver',
      nameAcronym: json['name_acronym'] ?? 'UNK',
      teamName: json['team_name'] ?? 'Unknown Team',
      teamColour: json['team_colour'] ?? 'FFFFFF',
      headshotUrl: json['headshot_url'],
    );
  }
}
