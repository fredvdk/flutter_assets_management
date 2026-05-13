import 'update.dart';

class Asset {
  final String id;
  final String? name;
  final String? type;
  final String? bank;
  final String? createdBy;
  final DateTime? created;
  final String? notes;
  final List<Update> updates;

  Asset({
    required this.id,
    this.name,
    this.type,
    this.bank,
    this.createdBy,
    this.created,
    this.notes,
    required this.updates,
  });

  @override
  String toString() {
    return 'Asset{id: $id, name: $name, type: $type, bank: $bank, createdBy: $createdBy, created: $created, notes: $notes, updates: $updates.map((update) => update.toString())}';
  }

  // Convert Asset object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'bank': bank,
      'created_by': createdBy,
      'created': created?.toIso8601String(),
      'notes': notes,
      'updates': updates.map((update) => update.toJson()).toList()
    };
  }

  // Create Asset object from JSON
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] ?? '',
      name: json['name'],
      type: json['type'],
      bank: json['bank'],
      createdBy: json['created_by'],
      created: json['created'] != null ? DateTime.parse(json['created']) : null,
      notes: json['notes'],
      updates: json['updates'] != null
          ? List<Update>.from(json['updates'].map((updateJson) => Update.fromJson(updateJson)))
          : [],
    );
  }

  // Function to calculate totals per type
  static Map<String, int> getTotalsPerType(List<Asset> assets) {
    Map<String, int> totals = {};
    for (var asset in assets) {
      if (asset.type != null && asset.updates.isNotEmpty) {
        totals[asset.type!] = (totals[asset.type!] ?? 0) + asset.getLastValue();
      }
    }
    totals['Total'] = totals.values.fold(0, (sum, value) => sum + value);
    return totals;
  }

  int getLastValue(){
    return updates.isNotEmpty ? updates.last.value : 0;
  }

  String getLastUpdatedBy(){
    return updates.isNotEmpty ? updates.last.updated_by ?? 'N/A' : 'N/A';
    }

  DateTime getLastUpdatedAt(){
    return updates.isNotEmpty ? updates.last.updated_at ?? DateTime(1970) : DateTime(1970); 
  }
}
