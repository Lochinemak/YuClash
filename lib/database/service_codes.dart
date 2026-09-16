part of 'database.dart';

@DataClassName('ServiceCodeRecord')
class V2boardServiceCodes extends Table {
  @override
  String get tableName => 'v2board_service_codes';

  TextColumn get code => text()();

  IntColumn get lastUsedAt => integer()();

  @override
  Set<Column> get primaryKey => {code};
}

@DriftAccessor(tables: [V2boardServiceCodes])
class V2boardServiceCodesDao extends DatabaseAccessor<Database>
    with _$V2boardServiceCodesDaoMixin {
  V2boardServiceCodesDao(super.attachedDatabase);

  final int maxCapacity = 20;

  Future<void> touch(String code) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await transaction(() async {
      await into(v2boardServiceCodes).insertOnConflictUpdate(
        V2boardServiceCodesCompanion.insert(code: code, lastUsedAt: now),
      );

      final count = await v2boardServiceCodes.count.getSingle() ?? 0;

      if (count > maxCapacity) {
        final oldestRecords =
            await (select(v2boardServiceCodes)
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.lastUsedAt,
                      mode: OrderingMode.asc,
                    ),
                  ])
                  ..limit(count - maxCapacity))
                .get();

        final oldestCodes = oldestRecords.map((e) => e.code).toList();
        await (delete(
          v2boardServiceCodes,
        )..where((t) => t.code.isIn(oldestCodes))).go();
      }
    });
  }

  Future<void> remove(String code) {
    return (delete(
      v2boardServiceCodes,
    )..where((t) => t.code.equals(code))).go();
  }

  Selectable<ServiceCodeRecord> query() {
    return select(v2boardServiceCodes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
      ]);
  }
}
