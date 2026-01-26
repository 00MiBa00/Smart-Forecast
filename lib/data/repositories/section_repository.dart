import 'dart:convert';
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

class SectionRepository {
  final AppDatabase _database;
  final _uuid = const Uuid();

  SectionRepository(this._database);

  /// Create a new section
  Future<String> createSection({
    required String documentId,
    required String title,
    required List<String> tags,
    required int difficulty,
    required String anchorStart,
    String? anchorEnd,
    required String extractedText,
  }) async {
    final now = DateTime.now();
    final sectionId = _uuid.v4();
    
    await _database.into(_database.sections).insert(
      SectionsCompanion(
        id: drift.Value(sectionId),
        documentId: drift.Value(documentId),
        title: drift.Value(title),
        tags: drift.Value(jsonEncode(tags)),
        difficulty: drift.Value(difficulty),
        anchorStart: drift.Value(anchorStart),
        anchorEnd: anchorEnd != null ? drift.Value(anchorEnd) : const drift.Value.absent(),
        extractedText: drift.Value(extractedText),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // Update document's section count
    await _incrementDocumentSectionCount(documentId);

    return sectionId;
  }

  /// Get sections by document ID
  Future<List<Section>> getSectionsByDocumentId(String documentId) async {
    return await (_database.select(_database.sections)
          ..where((section) => section.documentId.equals(documentId))
          ..orderBy([(section) => drift.OrderingTerm.desc(section.createdAt)]))
        .get();
  }

  /// Watch sections by document ID (stream)
  Stream<List<Section>> watchSectionsByDocumentId(String documentId) {
    return (_database.select(_database.sections)
          ..where((section) => section.documentId.equals(documentId))
          ..orderBy([(section) => drift.OrderingTerm.desc(section.createdAt)]))
        .watch();
  }

  /// Get a section by ID
  Future<Section?> getSectionById(String id) async {
    return await (_database.select(_database.sections)
          ..where((section) => section.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update a section
  Future<void> updateSection(Section section) async {
    await (_database.update(_database.sections)
          ..where((s) => s.id.equals(section.id)))
        .write(
      section.toCompanion(false).copyWith(
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Delete a section
  Future<void> deleteSection(String id) async {
    await (_database.delete(_database.sections)
          ..where((section) => section.id.equals(id)))
        .go();
  }

  /// Get all sections
  Future<List<Section>> getAllSections() async {
    return await (_database.select(_database.sections)
          ..orderBy([(section) => drift.OrderingTerm.desc(section.createdAt)]))
        .get();
  }

  /// Watch all sections (stream)
  Stream<List<Section>> watchAllSections() {
    return (_database.select(_database.sections)
          ..orderBy([(section) => drift.OrderingTerm.desc(section.createdAt)]))
        .watch();
  }

  /// Increment document's section count
  Future<void> _incrementDocumentSectionCount(String documentId) async {
    final doc = await (_database.select(_database.documents)
          ..where((d) => d.id.equals(documentId)))
        .getSingleOrNull();
    
    if (doc != null) {
      await (_database.update(_database.documents)
            ..where((d) => d.id.equals(documentId)))
          .write(
        DocumentsCompanion(
          sectionsCount: drift.Value(doc.sectionsCount + 1),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  }
}
