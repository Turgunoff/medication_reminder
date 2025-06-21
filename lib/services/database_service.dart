import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import 'notification_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final NotificationService _notificationService = NotificationService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medication_reminder.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency INTEGER NOT NULL,
        times TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        takenAt TEXT NOT NULL,
        FOREIGN KEY (medicationId) REFERENCES medications (id)
      )
    ''');
  }

  // Insert new medication
  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    final id = await db.insert('medications', medication.toMap());

    // Schedule notifications for the new medication
    if (id > 0) {
      final medicationWithId = Medication(
        id: id,
        name: medication.name,
        dosage: medication.dosage,
        frequency: medication.frequency,
        times: medication.times,
        notes: medication.notes,
        createdAt: medication.createdAt,
        isActive: medication.isActive,
      );
      await _notificationService.scheduleMedicationReminder(medicationWithId);
      print('Scheduled notifications for medication: ${medication.name}');
    }

    return id;
  }

  // Get all medications
  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  // Get medication by ID
  Future<Medication?> getMedicationById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    }
    return null;
  }

  // Update medication
  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    final result = await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );

    // Reschedule notifications for the updated medication
    if (result > 0) {
      await _notificationService.cancelMedicationReminders(medication.id!);
      await _notificationService.scheduleMedicationReminder(medication);
      print('Rescheduled notifications for medication: ${medication.name}');
    }

    return result;
  }

  // Delete medication (soft delete)
  Future<int> deleteMedication(int id) async {
    final db = await database;
    final result = await db.update(
      'medications',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Cancel notifications for the deleted medication
    if (result > 0) {
      await _notificationService.cancelMedicationReminders(id);
      print('Cancelled notifications for deleted medication ID: $id');
    }

    return result;
  }

  // Log medication taken
  Future<int> logMedicationTaken(int medicationId) async {
    final db = await database;
    return await db.insert('medication_logs', {
      'medicationId': medicationId,
      'takenAt': DateTime.now().toIso8601String(),
    });
  }

  // Get medication logs for today
  Future<List<Map<String, dynamic>>> getTodayLogs() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await db.rawQuery(
      '''
      SELECT ml.*, m.name, m.dosage
      FROM medication_logs ml
      JOIN medications m ON ml.medicationId = m.id
      WHERE ml.takenAt >= ? AND ml.takenAt < ?
      ORDER BY ml.takenAt DESC
    ''',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
  }

  // Get medication logs for a specific medication
  Future<List<Map<String, dynamic>>> getMedicationLogs(int medicationId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT ml.*, m.name, m.dosage
      FROM medication_logs ml
      JOIN medications m ON ml.medicationId = m.id
      WHERE ml.medicationId = ?
      ORDER BY ml.takenAt DESC
    ''',
      [medicationId],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
