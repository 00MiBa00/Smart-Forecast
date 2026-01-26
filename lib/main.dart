import 'package:flutter/cupertino.dart';
import 'app/clear_app.dart';
import 'data/database/database.dart';
import 'data/repositories/document_repository.dart';
import 'data/repositories/section_repository.dart';
import 'data/repositories/card_repository.dart';
import 'core/services/demo_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final db = AppDatabase();
  await db.select(db.documents).get(); // Ensure database is created
  
  // Initialize demo data if first launch
  final demoDataService = DemoDataService(
    documentRepo: DocumentRepository(db),
    sectionRepo: SectionRepository(db),
    cardRepo: CardRepository(db),
  );
  
  await demoDataService.initializeDemoData();
  
  runApp(const DocTrainerApp());
}
