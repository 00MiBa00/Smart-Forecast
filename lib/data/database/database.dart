import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/document_type.dart';
import '../models/card_type.dart';
import '../models/card_status.dart';
import '../models/srs_grade.dart';
import '../models/study_scope.dart';

part 'database.g.dart';

// Documents table
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get type => intEnum<DocumentType>()();
  TextColumn get localFilePath => text()();
  DateTimeColumn get importedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  TextColumn get lastPosition => text().nullable()();
  IntColumn get pagesCount => integer().nullable()();
  IntColumn get sectionsCount => integer().withDefault(const Constant(0))();
  IntColumn get cardsCount => integer().withDefault(const Constant(0))();
  TextColumn get language => text().nullable()();
  RealColumn get codeFontScale => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {id};
}

// Sections table
class Sections extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get tags => text()(); // JSON array
  IntColumn get difficulty => integer().withDefault(const Constant(0))();
  TextColumn get anchorStart => text()();
  TextColumn get anchorEnd => text().nullable()();
  TextColumn get extractedText => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Cards table
class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get sectionId => text().references(Sections, #id, onDelete: KeyAction.setNull).nullable()();
  IntColumn get type => intEnum<CardType>()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get tags => text()(); // JSON array
  IntColumn get status => intEnum<CardStatus>()();
  TextColumn get sourceSnippet => text().nullable()();
  TextColumn get sourceAnchor => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// SRS Records table
class SRSRecords extends Table {
  TextColumn get cardId => text().references(Cards, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dueAt => dateTime()();
  RealColumn get intervalDays => real()();
  RealColumn get easeFactor => real()();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get lastGrade => intEnum<SRSGrade>().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cardId};
}

// Study Sessions table
class StudySessions extends Table {
  TextColumn get id => text()();
  IntColumn get scope => intEnum<StudyScope>()();
  TextColumn get scopeId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get reviewedCount => integer().withDefault(const Constant(0))();
  IntColumn get againCount => integer().withDefault(const Constant(0))();
  IntColumn get hardCount => integer().withDefault(const Constant(0))();
  IntColumn get goodCount => integer().withDefault(const Constant(0))();
  IntColumn get easyCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Documents, Sections, Cards, SRSRecords, StudySessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'doc_trainer.sqlite'));
      return NativeDatabase(file);
    });
  }
}
