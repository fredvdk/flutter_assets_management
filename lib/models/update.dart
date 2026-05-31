class Update {
  final String id;
  final DateTime date;
  final int value;
  final String assetId;
  final DateTime? updatedAt;
  final String? updatedBy;

  Update({
    required this.id,
    required this.date,
    required this.value,
    required this.assetId,
    this.updatedAt,
    this.updatedBy,
  });

  @override
  String toString() {
    return 'Update{id: $id, date: $date, value: $value, assetId: $assetId, updatedBy: $updatedBy, updatedAt: $updatedAt}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'value': value,
      'asset_id': assetId,
      'updated_by': updatedBy,
      'updated_at': updatedAt?.toIso8601String()
    };
  }

  factory Update.fromJson(Map<String, dynamic> json) {
    return Update(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      value: json['value'] ?? 0,
      assetId: json['asset_id'] ?? '',
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      updatedBy: json['updated_by'],
    );
  }
}
