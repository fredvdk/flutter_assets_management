// ignore_for_file: non_constant_identifier_names

class Update {
  final String id;
  final DateTime date;
  final int value;
  final String assetId;
  final DateTime? updated_at;
  final String? updated_by;

  Update({
    required this.id,
    required this.date,
    required this.value,
    required this.assetId,
    this.updated_at,
    this.updated_by,
  });

  @override
  String toString() {
    return 'Update{id: $id, date: $date, value: $value, assetId: $assetId, updated_by: $updated_by, updated_at: $updated_at}';
  }

  // Convert Update object to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'asset_id': assetId,
      'updated_by': updated_by,
      'updated_at': updated_at?.toIso8601String()
    };
  }

  // Create Update object from JSON
  factory Update.fromJson(Map<String, dynamic> json) {
    return Update(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      value: json['value'] ?? 0,
      assetId: json['asset_id'] ?? '',
      updated_at: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      updated_by: json['updated_by'],
    );
  }
}
