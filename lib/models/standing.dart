class Standing {
  final int position;
  final int points;
  final String givenName;
  final String familyName;
  final String constructorName;

  Standing({
    required this.position,
    required this.points,
    required this.givenName,
    required this.familyName,
    required this.constructorName,
  });

  factory Standing.fromJson(Map<String, dynamic> json) {
    return Standing(
      position: int.tryParse(json['position'].toString()) ?? 0,
      points: int.tryParse(json['points'].toString()) ?? 0,
      givenName: json['Driver']['givenName'] ?? '',
      familyName: json['Driver']['familyName'] ?? '',
      constructorName: (json['Constructors'] as List).isNotEmpty ? json['Constructors'][0]['name'] : '',
    );
  }
}
