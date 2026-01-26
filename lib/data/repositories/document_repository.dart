import 'dart:convert';
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;

class DocumentRepository {
  final AppDatabase _database;

  DocumentRepository(this._database);

  /// Create a new document
  Future<void> createDocument(DocumentsCompanion document) async {
    await _database.into(_database.documents).insert(document);
  }

  /// Get a document by ID
  Future<Document?> getDocumentById(String id) async {
    return await (_database.select(_database.documents)
          ..where((doc) => doc.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update the last position for a document
  Future<void> updateLastPosition(
    String documentId,
    Map<String, dynamic> positionJson,
  ) async {
    final jsonString = jsonEncode(positionJson);
    await (_database.update(_database.documents)
          ..where((doc) => doc.id.equals(documentId)))
        .write(
      DocumentsCompanion(
        lastPosition: drift.Value(jsonString),
        lastOpenedAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Update last opened time
  Future<void> updateLastOpened(String documentId) async {
    await (_database.update(_database.documents)
          ..where((doc) => doc.id.equals(documentId)))
        .write(
      DocumentsCompanion(
        lastOpenedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Get all documents
  Future<List<Document>> getAllDocuments() async {
    return await (_database.select(_database.documents)
          ..orderBy([(doc) => drift.OrderingTerm.desc(doc.lastOpenedAt)]))
        .get();
  }

  /// Watch all documents (stream)
  Stream<List<Document>> watchAllDocuments() {
    return (_database.select(_database.documents)
          ..orderBy([(doc) => drift.OrderingTerm.desc(doc.lastOpenedAt)]))
        .watch();
  }

  /// Delete a document and all its related data
  Future<void> deleteDocument(String documentId) async {
    await _database.transaction(() async {
      // Delete the document (sections and cards will be cascade deleted)
      await (_database.delete(_database.documents)
            ..where((doc) => doc.id.equals(documentId)))
          .go();
    });
  }
}
