import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

/// Database Helper for BeforeDoctor
/// Manages SQLite database for local storage of symptoms, child profiles, and medical data
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._internal();
  DatabaseHelper._internal();

  // Database configuration
  static const String _databaseName = 'beforedoctor.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _tableSymptoms = 'symptoms';
  static const String _tableChildProfiles = 'child_profiles';
  static const String _tableMedicalHistory = 'medical_history';
  static const String _tableAllergies = 'allergies';
  static const String _tableMedications = 'medications';
  static const String _tableVaccinations = 'vaccinations';
  static const String _tableGrowthData = 'growth_data';
  static const String _tableInteractions = 'interactions';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Symptoms table
    await db.execute('''
      CREATE TABLE $_tableSymptoms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        symptom_type TEXT NOT NULL,
        severity TEXT,
        duration TEXT,
        temperature REAL,
        description TEXT,
        ai_analysis TEXT,
        risk_level TEXT,
        follow_up_questions TEXT,
        immediate_advice TEXT,
        seek_care_when TEXT,
        confidence REAL,
        api_used TEXT,
        uploaded INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Child profiles table
    await db.execute('''
      CREATE TABLE $_tableChildProfiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        gender TEXT,
        weight_kg REAL,
        height_cm REAL,
        blood_type TEXT,
        primary_caregiver TEXT,
        emergency_contact TEXT,
        insurance_info TEXT,
        medical_conditions TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Medical history table
    await db.execute('''
      CREATE TABLE $_tableMedicalHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        condition TEXT NOT NULL,
        diagnosis_date TEXT,
        severity TEXT,
        treatment TEXT,
        outcome TEXT,
        doctor_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Allergies table
    await db.execute('''
      CREATE TABLE $_tableAllergies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        allergen TEXT NOT NULL,
        reaction_type TEXT,
        severity TEXT,
        medication TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Medications table
    await db.execute('''
      CREATE TABLE $_tableMedications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        medication_name TEXT NOT NULL,
        dosage TEXT,
        frequency TEXT,
        start_date TEXT,
        end_date TEXT,
        prescribed_by TEXT,
        notes TEXT,
        active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Vaccinations table
    await db.execute('''
      CREATE TABLE $_tableVaccinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        vaccine_name TEXT NOT NULL,
        date_given TEXT NOT NULL,
        next_due_date TEXT,
        batch_number TEXT,
        given_by TEXT,
        location TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Growth data table
    await db.execute('''
      CREATE TABLE $_tableGrowthData (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        measurement_date TEXT NOT NULL,
        weight_kg REAL,
        height_cm REAL,
        head_circumference_cm REAL,
        bmi REAL,
        percentile_weight INTEGER,
        percentile_height INTEGER,
        percentile_head INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Interactions table (for learning pipeline)
    await db.execute('''
      CREATE TABLE $_tableInteractions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER,
        timestamp TEXT NOT NULL,
        user_input TEXT NOT NULL,
        ai_response TEXT,
        api_used TEXT,
        confidence REAL,
        response_time_ms INTEGER,
        success INTEGER DEFAULT 1,
        error_message TEXT,
        quality_score REAL,
        uploaded INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_symptoms_child_id ON $_tableSymptoms(child_id)');
    await db.execute('CREATE INDEX idx_symptoms_timestamp ON $_tableSymptoms(timestamp)');
    await db.execute('CREATE INDEX idx_symptoms_uploaded ON $_tableSymptoms(uploaded)');
    await db.execute('CREATE INDEX idx_interactions_timestamp ON $_tableInteractions(timestamp)');
    await db.execute('CREATE INDEX idx_interactions_uploaded ON $_tableInteractions(uploaded)');

    print('✅ Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
      print('🔄 Database upgraded from version $oldVersion to $newVersion');
    }
  }

  // ===== CHILD PROFILE OPERATIONS =====

  /// Create a new child profile
  Future<int> createChildProfile(Map<String, dynamic> profile) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...profile,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert(_tableChildProfiles, data);
  }

  /// Get all child profiles
  Future<List<Map<String, dynamic>>> getAllChildProfiles() async {
    final db = await database;
    return await db.query(_tableChildProfiles, orderBy: 'created_at DESC');
  }

  /// Get child profile by ID
  Future<Map<String, dynamic>?> getChildProfile(int id) async {
    final db = await database;
    final results = await db.query(
      _tableChildProfiles,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update child profile
  Future<int> updateChildProfile(int id, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableChildProfiles,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete child profile
  Future<int> deleteChildProfile(int id) async {
    final db = await database;
    return await db.delete(
      _tableChildProfiles,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== SYMPTOM OPERATIONS =====

  /// Save a new symptom
  Future<int> saveSymptom(Map<String, dynamic> symptom) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...symptom,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert(_tableSymptoms, data);
  }

  /// Get symptoms for a specific child
  Future<List<Map<String, dynamic>>> getSymptomsForChild(int childId, {int? limit}) async {
    final db = await database;
    return await db.query(
      _tableSymptoms,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Get all symptoms
  Future<List<Map<String, dynamic>>> getAllSymptoms({int? limit}) async {
    final db = await database;
    return await db.query(
      _tableSymptoms,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Get symptoms by type
  Future<List<Map<String, dynamic>>> getSymptomsByType(String symptomType, {int? limit}) async {
    final db = await database;
    return await db.query(
      _tableSymptoms,
      where: 'symptom_type = ?',
      whereArgs: [symptomType],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Update symptom
  Future<int> updateSymptom(int id, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableSymptoms,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark symptom as uploaded
  Future<int> markSymptomUploaded(int id) async {
    return await updateSymptom(id, {'uploaded': 1});
  }

  /// Get unuploaded symptoms
  Future<List<Map<String, dynamic>>> getUnuploadedSymptoms() async {
    final db = await database;
    return await db.query(
      _tableSymptoms,
      where: 'uploaded = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  // ===== MEDICAL HISTORY OPERATIONS =====

  /// Save medical history entry
  Future<int> saveMedicalHistory(Map<String, dynamic> history) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...history,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert(_tableMedicalHistory, data);
  }

  /// Get medical history for a child
  Future<List<Map<String, dynamic>>> getMedicalHistoryForChild(int childId) async {
    final db = await database;
    return await db.query(
      _tableMedicalHistory,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'diagnosis_date DESC',
    );
  }

  // ===== ALLERGY OPERATIONS =====

  /// Save allergy
  Future<int> saveAllergy(Map<String, dynamic> allergy) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...allergy,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert(_tableAllergies, data);
  }

  /// Get allergies for a child
  Future<List<Map<String, dynamic>>> getAllergiesForChild(int childId) async {
    final db = await database;
    return await db.query(
      _tableAllergies,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'created_at DESC',
    );
  }

  // ===== MEDICATION OPERATIONS =====

  /// Save medication
  Future<int> saveMedication(Map<String, dynamic> medication) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...medication,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert(_tableMedications, data);
  }

  /// Get active medications for a child
  Future<List<Map<String, dynamic>>> getActiveMedicationsForChild(int childId) async {
    final db = await database;
    return await db.query(
      _tableMedications,
      where: 'child_id = ? AND active = ?',
      whereArgs: [childId, 1],
      orderBy: 'start_date DESC',
    );
  }

  // ===== VACCINATION OPERATIONS =====

  /// Save vaccination
  Future<int> saveVaccination(Map<String, dynamic> vaccination) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...vaccination,
      'created_at': now,
      'updated_at': now,
    };

    return await db.insert(_tableVaccinations, data);
  }

  /// Get vaccinations for a child
  Future<List<Map<String, dynamic>>> getVaccinationsForChild(int childId) async {
    final db = await database;
    return await db.query(
      _tableVaccinations,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date_given DESC',
    );
  }

  // ===== GROWTH DATA OPERATIONS =====

  /// Save growth data
  Future<int> saveGrowthData(Map<String, dynamic> growthData) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...growthData,
      'created_at': now,
    };

    return await db.insert(_tableGrowthData, data);
  }

  /// Get growth data for a child
  Future<List<Map<String, dynamic>>> getGrowthDataForChild(int childId, {int? limit}) async {
    final db = await database;
    return await db.query(
      _tableGrowthData,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'measurement_date DESC',
      limit: limit,
    );
  }

  // ===== INTERACTION OPERATIONS =====

  /// Save interaction for learning pipeline
  Future<int> saveInteraction(Map<String, dynamic> interaction) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final data = {
      ...interaction,
      'created_at': now,
    };

    return await db.insert(_tableInteractions, data);
  }

  /// Get interactions for learning
  Future<List<Map<String, dynamic>>> getInteractionsForLearning({int? limit}) async {
    final db = await database;
    return await db.query(
      _tableInteractions,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Mark interaction as uploaded
  Future<int> markInteractionUploaded(int id) async {
    final db = await database;
    return await db.update(
      _tableInteractions,
      {'uploaded': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unuploaded interactions
  Future<List<Map<String, dynamic>>> getUnuploadedInteractions() async {
    final db = await database;
    return await db.query(
      _tableInteractions,
      where: 'uploaded = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  // ===== UTILITY OPERATIONS =====

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final symptomsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableSymptoms')
    ) ?? 0;
    
    final childrenCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableChildProfiles')
    ) ?? 0;
    
    final interactionsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableInteractions')
    ) ?? 0;

    return {
      'symptoms': symptomsCount,
      'children': childrenCount,
      'interactions': interactionsCount,
    };
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_tableSymptoms);
    await db.delete(_tableChildProfiles);
    await db.delete(_tableMedicalHistory);
    await db.delete(_tableAllergies);
    await db.delete(_tableMedications);
    await db.delete(_tableVaccinations);
    await db.delete(_tableGrowthData);
    await db.delete(_tableInteractions);
    print('🧹 All database data cleared');
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
