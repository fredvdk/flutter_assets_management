import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_assets_management/models/asset.dart';
import 'package:flutter_assets_management/models/update.dart';

void main() {
  group('Asset', () {
    group('Constructor', () {
      test('creates an Asset with all parameters', () {
        final now = DateTime.now();
        final updates = [
          Update(
            id: '1',
            assetId: 'asset1',
            value: 100,
            date: DateTime.parse('2024-01-01'),
            updated_by: 'John',
            updated_at: now,
          )
        ];

        final asset = Asset(
          id: 'asset1',
          name: 'Laptop',
          type: 'Electronics',
          bank: 'Bank A',
          createdBy: 'John',
          created: now,
          notes: 'Company laptop',
          updates: updates,
        );

        expect(asset.id, 'asset1');
        expect(asset.name, 'Laptop');
        expect(asset.type, 'Electronics');
        expect(asset.bank, 'Bank A');
        expect(asset.createdBy, 'John');
        expect(asset.created, now);
        expect(asset.notes, 'Company laptop');
        expect(asset.updates, updates);
      });

      test('creates an Asset with default values', () {
        final asset = Asset(id: '', updates: []);

        expect(asset.id, '');
        expect(asset.name, isNull);
        expect(asset.type, isNull);
        expect(asset.bank, isNull);
        expect(asset.createdBy, isNull);
        expect(asset.created, isNull);
        expect(asset.notes, isNull);
        expect(asset.updates, isEmpty);
      });

      test('creates an Asset with partial parameters', () {
        final updates = [
          Update(
            id: '1',
            assetId: 'asset1',
            date: DateTime.parse('2024-01-01'),
            value: 100,
          )
        ];

        final asset = Asset(
          id: 'asset1',
          name: 'Phone',
          updates: updates,
        );

        expect(asset.id, 'asset1');
        expect(asset.name, 'Phone');
        expect(asset.type, isNull);
        expect(asset.updates.length, 1);
      });
    });

    group('toJson', () {
      test('converts Asset to JSON correctly', () {
        final now = DateTime.now();
        final updates = [
          Update(
            id: 'update1',
            assetId: 'asset1',
            value: 100,
            date: DateTime.parse('2024-01-01'),
            updated_by: 'John',
            updated_at: now,
          )
        ];

        final asset = Asset(
          id: 'asset1',
          name: 'Laptop',
          type: 'Electronics',
          bank: 'Bank A',
          createdBy: 'John',
          created: now,
          notes: 'Company laptop',
          updates: updates,
        );

        final json = asset.toJson();

        expect(json['id'], 'asset1');
        expect(json['name'], 'Laptop');
        expect(json['type'], 'Electronics');
        expect(json['bank'], 'Bank A');
        expect(json['created_by'], 'John');
        expect(json['created'], now.toIso8601String());
        expect(json['notes'], 'Company laptop');
        expect(json['updates'], isA<List>());
        expect(json['updates'].length, 1);
      });

      test('converts Asset with null dates to JSON', () {
        final asset = Asset(
          id: 'asset1',
          name: 'Laptop',
          updates: [],
        );

        final json = asset.toJson();

        expect(json['created'], isNull);
      });

      test('converts Asset with empty updates to JSON', () {
        final asset = Asset(
          id: 'asset1',
          updates: [],
        );

        final json = asset.toJson();

        expect(json['updates'], isEmpty);
      });
    });

    group('fromJson', () {
      test('creates Asset from JSON correctly', () {
        final now = DateTime.now();
        final json = {
          'id': 'asset1',
          'name': 'Laptop',
          'type': 'Electronics',
          'bank': 'Bank A',
          'created_by': 'John',
          'created': now.toIso8601String(),
          'notes': 'Company laptop',
          'updates': [
            {
              'id': 'update1',
              'assetId': 'asset1',
              'value': 100,
              'updated_by': 'John',
              'updated_at': now.toIso8601String(),
            }
          ]
        };

        final asset = Asset.fromJson(json);

        expect(asset.id, 'asset1');
        expect(asset.name, 'Laptop');
        expect(asset.type, 'Electronics');
        expect(asset.bank, 'Bank A');
        expect(asset.createdBy, 'John');
        expect(asset.created, isNotNull);
        expect(asset.notes, 'Company laptop');
        expect(asset.updates.length, 1);
        expect(asset.updates[0].value, 100);
      });

      test('creates Asset from JSON with missing optional fields', () {
        final json = {
          'id': 'asset1',
          'updates': []
        };

        final asset = Asset.fromJson(json);

        expect(asset.id, 'asset1');
        expect(asset.name, isNull);
        expect(asset.type, isNull);
        expect(asset.created, isNull);
        expect(asset.updates, isEmpty);
      });

      test('creates Asset from JSON with null updates', () {
        final json = {
          'id': 'asset1',
          'name': 'Laptop',
          'updates': null
        };

        final asset = Asset.fromJson(json);

        expect(asset.id, 'asset1');
        expect(asset.name, 'Laptop');
        expect(asset.updates, isEmpty);
      });
    });

    group('Serialization round-trip', () {
      test('Asset survives toJson/fromJson round-trip', () {
        final now = DateTime.now();
        final updates = [
          Update(
            id: 'update1',
            assetId: 'asset1',
            value: 100,
            date: DateTime.parse('2024-01-01'),
            updated_by: 'John',
            updated_at: now,
          ),
          Update(
            id: 'update2',
            assetId: 'asset1',
            value: 150,
            date: DateTime.parse('2024-01-02'),
            updated_by: 'Jane',
            updated_at: now.add(const Duration(days: 1)),
          )
        ];

        final original = Asset(
          id: 'asset1',
          name: 'Laptop',
          type: 'Electronics',
          bank: 'Bank A',
          createdBy: 'John',
          created: now,
          notes: 'Company laptop',
          updates: updates,
        );

        final json = original.toJson();
        final restored = Asset.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.type, original.type);
        expect(restored.bank, original.bank);
        expect(restored.createdBy, original.createdBy);
        expect(restored.notes, original.notes);
        expect(restored.updates.length, original.updates.length);
      });
    });

    group('toString', () {
      test('generates a non-empty string representation', () {
        final asset = Asset(
          id: 'asset1',
          name: 'Laptop',
          type: 'Electronics',
          updates: [],
        );

        final str = asset.toString();

        expect(str, isNotEmpty);
        expect(str, contains('Asset'));
        expect(str, contains('asset1'));
        expect(str, contains('Laptop'));
      });
    });

    group('getTotalsPerType', () {
      test('calculates totals per asset type correctly', () {
        final assets = [
          Asset(
            id: 'asset1',
            type: 'Electronics',
            updates: [
              Update(
                id: 'update1',
                assetId: 'asset1',
                date: DateTime.parse('2024-01-01'),
                value: 100,
              ),
              Update(
                id: 'update2',
                assetId: 'asset1',
                date: DateTime.parse('2024-01-02'),
                value: 50,
              )
            ],
          ),
          Asset(
            id: 'asset2',
            type: 'Furniture',
            updates: [
              Update(
                id: 'update3',
                assetId: 'asset2',
                date: DateTime.parse('2024-01-01'),
                value: 200,
              )
            ],
          ),
          Asset(
            id: 'asset3',
            type: 'Electronics',
            updates: [
              Update(
                id: 'update4',
                assetId: 'asset3',
                date: DateTime.parse('2024-01-01'),
                value: 150,
              )
            ],
          ),
        ];

        final totals = Asset.getTotalsPerType(assets);

        expect(totals['Electronics'], 200); // 50 + 150
        expect(totals['Furniture'], 200);
        expect(totals['Total'], 400);
      });

      test('returns empty map for empty assets list', () {
        final totals = Asset.getTotalsPerType([]);

        expect(totals, {'Total': 0});
      });

      test('ignores assets without updates', () {
        final assets = [
          Asset(
            id: 'asset1',
            type: 'Electronics',
            updates: [],
          ),
          Asset(
            id: 'asset2',
            type: 'Furniture',
            updates: [
              Update(
                id: 'update1',
                assetId: 'asset2',
                date: DateTime.parse('2024-01-01'),
                value: 100,
              )
            ],
          ),
        ];

        final totals = Asset.getTotalsPerType(assets);

        expect(totals['Electronics'], isNull);
        expect(totals['Furniture'], 100);
        expect(totals['Total'], 100);
      });

      test('ignores assets without type', () {
        final assets = [
          Asset(
            id: 'asset1',
            type: null,
            updates: [
              Update(
                id: 'update1',
                assetId: 'asset1',
                date: DateTime.parse('2024-01-01'),
                value: 100,
              )
            ],
          ),
          Asset(
            id: 'asset2',
            type: 'Electronics',
            updates: [
              Update(
                id: 'update2',
                assetId: 'asset2',
                date: DateTime.parse('2024-01-01'),
                value: 150,
              )
            ],
          ),
        ];

        final totals = Asset.getTotalsPerType(assets);

        expect(totals['Electronics'], 150);
        expect(totals[null], isNull);
        expect(totals['Total'], 150);
      });

      test('handles multiple assets of same type', () {
        final assets = [
          Asset(
            id: 'asset1',
            type: 'Electronics',
            updates: [
              Update(
                id: 'update1',
                assetId: 'asset1',
                date: DateTime.parse('2024-01-01'),
                value: 100,
              )
            ],
          ),
          Asset(
            id: 'asset2',
            type: 'Electronics',
            updates: [
              Update(
                id: 'update2',
                assetId: 'asset2',
                date: DateTime.parse('2024-01-01'),
                value: 50,
              )
            ],
          ),
        ];

        final totals = Asset.getTotalsPerType(assets);

        expect(totals['Electronics'], 150); // 100 + 50
        expect(totals['Total'], 150);
      });
    });
  });
}
