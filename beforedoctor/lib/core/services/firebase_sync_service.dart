import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import 'logging_service.dart';

/// Firebase Sync Service
/// Handles real-time synchronization between local SQLite and Firebase cloud storage
class FirebaseSyncService {
  static FirebaseSyncService? _instance;
  static FirebaseSyncService get instance => _instance ??= FirebaseSyncService._internal();

  FirebaseSyncService._internal();

  // Firebase instances
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Services
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final LoggingService _loggingService = LoggingService();
  
  // Sync state
  bool _isInitialized = false;
  bool _isOnline = false;
  bool _isSyncing = false;
  Timer? _syncTimer;
  
  // Stream controllers
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  final StreamController<String> _syncProgressController = StreamController<String>.broadcast();
  
  // Streams
  Stream<bool> get syncStatusStream => _syncStatusController.stream;
  Stream<String> get syncProgressController => _syncProgressController.stream;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  /// Initialize Firebase sync service
  Future<bool> initialize() async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('⚠️ Firebase sync: User not authenticated');
        return false;
      }

      // Initialize connectivity monitoring
      await _initializeConnectivity();
      
      // Start periodic sync
      _startPeriodicSync();
      
      _isInitialized = true;
      print('✅ Firebase sync service initialized successfully');
      return true;
      
    } catch (e) {
      print('❌ Error initializing Firebase sync: $e');
      return false;
    }
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      
      if (_isOnline) {
        print('🌐 Internet connection restored - starting sync');
        _triggerSync();
      } else {
        print('📡 Internet connection lost - sync paused');
      }
    });

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
  }

  /// Start periodic sync (every 5 minutes when online)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && !_isSyncing) {
        _triggerSync();
      }
    });
  }

  /// Trigger manual sync
  Future<void> triggerManualSync() async {
    if (!_isInitialized) {
      print('⚠️ Firebase sync not initialized');
      return;
    }
    
    if (_isSyncing) {
      print('⚠️ Sync already in progress');
      return;
    }
    
    await _performSync();
  }

  /// Trigger sync (internal)
  Future<void> _triggerSync() async {
    if (!_isOnline || _isSyncing) return;
    
    await _performSync();
  }

  /// Perform the actual sync operation
  Future<void> _performSync() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      _syncStatusController.add(true);
      _syncProgressController.add('Starting sync...');
      
      print('🔄 Starting Firebase sync...');
      
      // Get user ID
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Upload unuploaded symptoms
      await _syncSymptoms(userId);
      
      // 2. Upload unuploaded interactions
      await _syncInteractions(userId);
      
      // 3. Download new data from Firebase
      await _downloadFromFirebase(userId);
      
      // 4. Update sync timestamps
      await _updateLastSyncTime(userId);
      
      print('✅ Firebase sync completed successfully');
      _syncProgressController.add('Sync completed successfully');
      
    } catch (e) {
      print('❌ Firebase sync failed: $e');
      _syncProgressController.add('Sync failed: $e');
      
      // Log error
      await _loggingService.logError(
        'firebase_sync_failed',
        errorMessage: e.toString(),
        stackTrace: StackTrace.current.toString(),
      );
      
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
    }
  }

  /// Sync symptoms to Firebase
  Future<void> _syncSymptoms(String userId) async {
    try {
      _syncProgressController.add('Syncing symptoms...');
      
      // Get unuploaded symptoms
      final unuploadedSymptoms = await _dbHelper.getUnuploadedSymptoms();
      
      if (unuploadedSymptoms.isEmpty) {
        print('📊 No symptoms to sync');
        return;
      }
      
      print('📤 Syncing ${unuploadedSymptoms.length} symptoms...');
      
      // Upload each symptom
      for (final symptom in unuploadedSymptoms) {
        try {
          // Create Firebase reference
          final symptomRef = _database
              .ref('users/$userId/children/${symptom['child_id']}/symptoms')
              .push();
          
          // Prepare symptom data for Firebase
          final firebaseData = {
            'id': symptom['id'],
            'timestamp': symptom['timestamp'],
            'symptom_type': symptom['symptom_type'],
            'severity': symptom['severity'],
            'duration': symptom['duration'],
            'temperature': symptom['temperature'],
            'description': symptom['description'],
            'ai_analysis': symptom['ai_analysis'],
            'risk_level': symptom['risk_level'],
            'follow_up_questions': symptom['follow_up_questions'],
            'immediate_advice': symptom['immediate_advice'],
            'seek_care_when': symptom['seek_care_when'],
            'confidence': symptom['confidence'],
            'api_used': symptom['api_used'],
            'created_at': symptom['created_at'],
            'updated_at': symptom['updated_at'],
            'synced_at': DateTime.now().toIso8601String(),
          };
          
          // Upload to Firebase
          await symptomRef.set(firebaseData);
          
          // Mark as uploaded in local database
          await _dbHelper.markSymptomUploaded(symptom['id']);
          
          print('✅ Symptom ${symptom['id']} synced to Firebase');
          
        } catch (e) {
          print('❌ Failed to sync symptom ${symptom['id']}: $e');
          // Continue with next symptom
        }
      }
      
      print('✅ Symptoms sync completed');
      
    } catch (e) {
      print('❌ Symptoms sync failed: $e');
      rethrow;
    }
  }

  /// Sync interactions to Firebase
  Future<void> _syncInteractions(String userId) async {
    try {
      _syncProgressController.add('Syncing interactions...');
      
      // Get unuploaded interactions
      final unuploadedInteractions = await _dbHelper.getUnuploadedInteractions();
      
      if (unuploadedInteractions.isEmpty) {
        print('📊 No interactions to sync');
        return;
      }
      
      print('📤 Syncing ${unuploadedInteractions.length} interactions...');
      
      // Upload each interaction
      for (final interaction in unuploadedInteractions) {
        try {
          // Create Firebase reference
          final interactionRef = _database
              .ref('users/$userId/interactions')
              .push();
          
          // Prepare interaction data for Firebase
          final firebaseData = {
            'id': interaction['id'],
            'child_id': interaction['child_id'],
            'timestamp': interaction['timestamp'],
            'user_input': interaction['user_input'],
            'ai_response': interaction['ai_response'],
            'api_used': interaction['api_used'],
            'confidence': interaction['confidence'],
            'response_time_ms': interaction['response_time_ms'],
            'success': interaction['success'],
            'error_message': interaction['error_message'],
            'quality_score': interaction['quality_score'],
            'created_at': interaction['created_at'],
            'synced_at': DateTime.now().toIso8601String(),
          };
          
          // Upload to Firebase
          await interactionRef.set(firebaseData);
          
          // Mark as uploaded in local database
          await _dbHelper.markInteractionUploaded(interaction['id']);
          
          print('✅ Interaction ${interaction['id']} synced to Firebase');
          
        } catch (e) {
          print('❌ Failed to sync interaction ${interaction['id']}: $e');
          // Continue with next interaction
        }
      }
      
      print('✅ Interactions sync completed');
      
    } catch (e) {
      print('❌ Interactions sync failed: $e');
      rethrow;
    }
  }

  /// Download data from Firebase
  Future<void> _downloadFromFirebase(String userId) async {
    try {
      _syncProgressController.add('Downloading from Firebase...');
      
      // Download child profiles
      await _downloadChildProfiles(userId);
      
      // Download medical history
      await _downloadMedicalHistory(userId);
      
      // Download allergies
      await _downloadAllergies(userId);
      
      // Download medications
      await _downloadMedications(userId);
      
      // Download vaccinations
      await _downloadVaccinations(userId);
      
      // Download growth data
      await _downloadGrowthData(userId);
      
      print('✅ Download from Firebase completed');
      
    } catch (e) {
      print('❌ Download from Firebase failed: $e');
      rethrow;
    }
  }

  /// Download child profiles from Firebase
  Future<void> _downloadChildProfiles(String userId) async {
    try {
      final profilesRef = _database.ref('users/$userId/children');
      final snapshot = await profilesRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        for (final entry in data.entries) {
          final profileData = entry.value as Map<dynamic, dynamic>;
          
          // Check if profile already exists locally
          final existingProfiles = await _dbHelper.getAllChildProfiles();
          final exists = existingProfiles.any((p) => p['name'] == profileData['name']);
          
          if (!exists) {
            // Create new profile locally
            await _dbHelper.createChildProfile({
              'name': profileData['name'],
              'date_of_birth': profileData['date_of_birth'],
              'gender': profileData['gender'],
              'weight_kg': profileData['weight_kg'],
              'height_cm': profileData['height_cm'],
              'blood_type': profileData['blood_type'],
              'primary_caregiver': profileData['primary_caregiver'],
              'emergency_contact': profileData['emergency_contact'],
              'insurance_info': profileData['insurance_info'],
              'medical_conditions': profileData['medical_conditions'],
            });
            
            print('✅ Downloaded child profile: ${profileData['name']}');
          }
        }
      }
      
    } catch (e) {
      print('❌ Failed to download child profiles: $e');
    }
  }

  /// Download medical history from Firebase
  Future<void> _downloadMedicalHistory(String userId) async {
    try {
      final children = await _dbHelper.getAllChildProfiles();
      
      for (final child in children) {
        final historyRef = _database.ref('users/$userId/children/${child['id']}/medical_history');
        final snapshot = await historyRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          for (final entry in data.entries) {
            final historyData = entry.value as Map<dynamic, dynamic>;
            
            // Check if already exists locally
            final existingHistory = await _dbHelper.getMedicalHistoryForChild(child['id']);
            final exists = existingHistory.any((h) => 
                h['condition'] == historyData['condition'] && 
                h['diagnosis_date'] == historyData['diagnosis_date']);
            
            if (!exists) {
              await _dbHelper.saveMedicalHistory({
                'child_id': child['id'],
                'condition': historyData['condition'],
                'diagnosis_date': historyData['diagnosis_date'],
                'severity': historyData['severity'],
                'treatment': historyData['treatment'],
                'outcome': historyData['outcome'],
                'doctor_notes': historyData['doctor_notes'],
              });
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Failed to download medical history: $e');
    }
  }

  /// Download allergies from Firebase
  Future<void> _downloadAllergies(String userId) async {
    try {
      final children = await _dbHelper.getAllChildProfiles();
      
      for (final child in children) {
        final allergiesRef = _database.ref('users/$userId/children/${child['id']}/allergies');
        final snapshot = await allergiesRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          for (final entry in data.entries) {
            final allergyData = entry.value as Map<dynamic, dynamic>;
            
            // Check if already exists locally
            final existingAllergies = await _dbHelper.getAllergiesForChild(child['id']);
            final exists = existingAllergies.any((a) => 
                a['allergen'] == allergyData['allergen']);
            
            if (!exists) {
              await _dbHelper.saveAllergy({
                'child_id': child['id'],
                'allergen': allergyData['allergen'],
                'reaction_type': allergyData['reaction_type'],
                'severity': allergyData['severity'],
                'medication': allergyData['medication'],
                'notes': allergyData['notes'],
              });
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Failed to download allergies: $e');
    }
  }

  /// Download medications from Firebase
  Future<void> _downloadMedications(String userId) async {
    try {
      final children = await _dbHelper.getAllChildProfiles();
      
      for (final child in children) {
        final medicationsRef = _database.ref('users/$userId/children/${child['id']}/medications');
        final snapshot = await medicationsRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          for (final entry in data.entries) {
            final medicationData = entry.value as Map<dynamic, dynamic>;
            
            // Check if already exists locally
            final existingMedications = await _dbHelper.getActiveMedicationsForChild(child['id']);
            final exists = existingMedications.any((m) => 
                m['medication_name'] == medicationData['medication_name'] &&
                m['start_date'] == medicationData['start_date']);
            
            if (!exists) {
              await _dbHelper.saveMedication({
                'child_id': child['id'],
                'medication_name': medicationData['medication_name'],
                'dosage': medicationData['dosage'],
                'frequency': medicationData['frequency'],
                'start_date': medicationData['start_date'],
                'end_date': medicationData['end_date'],
                'prescribed_by': medicationData['prescribed_by'],
                'notes': medicationData['notes'],
              });
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Failed to download medications: $e');
    }
  }

  /// Download vaccinations from Firebase
  Future<void> _downloadVaccinations(String userId) async {
    try {
      final children = await _dbHelper.getAllChildProfiles();
      
      for (final child in children) {
        final vaccinationsRef = _database.ref('users/$userId/children/${child['id']}/vaccinations');
        final snapshot = await vaccinationsRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          for (final entry in data.entries) {
            final vaccinationData = entry.value as Map<dynamic, dynamic>;
            
            // Check if already exists locally
            final existingVaccinations = await _dbHelper.getVaccinationsForChild(child['id']);
            final exists = existingVaccinations.any((v) => 
                v['vaccine_name'] == vaccinationData['vaccine_name'] &&
                v['date_given'] == vaccinationData['date_given']);
            
            if (!exists) {
              await _dbHelper.saveVaccination({
                'child_id': child['id'],
                'vaccine_name': vaccinationData['vaccine_name'],
                'date_given': vaccinationData['date_given'],
                'next_due_date': vaccinationData['next_due_date'],
                'batch_number': vaccinationData['batch_number'],
                'given_by': vaccinationData['given_by'],
                'location': vaccinationData['location'],
                'notes': vaccinationData['notes'],
              });
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Failed to download vaccinations: $e');
    }
  }

  /// Download growth data from Firebase
  Future<void> _downloadGrowthData(String userId) async {
    try {
      final children = await _dbHelper.getAllChildProfiles();
      
      for (final child in children) {
        final growthRef = _database.ref('users/$userId/children/${child['id']}/growth_data');
        final snapshot = await growthRef.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          
          for (final entry in data.entries) {
            final growthData = entry.value as Map<dynamic, dynamic>;
            
            // Check if already exists locally
            final existingGrowth = await _dbHelper.getGrowthDataForChild(child['id']);
            final exists = existingGrowth.any((g) => 
                g['measurement_date'] == growthData['measurement_date']);
            
            if (!exists) {
              await _dbHelper.saveGrowthData({
                'child_id': child['id'],
                'measurement_date': growthData['measurement_date'],
                'weight_kg': growthData['weight_kg'],
                'height_cm': growthData['height_cm'],
                'head_circumference_cm': growthData['head_circumference_cm'],
                'bmi': growthData['bmi'],
                'percentile_weight': growthData['percentile_weight'],
                'percentile_height': growthData['percentile_height'],
                'percentile_head': growthData['percentile_head'],
                'notes': growthData['notes'],
              });
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Failed to download growth data: $e');
    }
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime(String userId) async {
    try {
      final syncRef = _database.ref('users/$userId/sync_info');
      await syncRef.set({
        'last_sync': DateTime.now().toIso8601String(),
        'sync_status': 'completed',
        'device_id': 'flutter_app',
      });
    } catch (e) {
      print('❌ Failed to update sync time: $e');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {'status': 'not_authenticated'};
      
      final syncRef = _database.ref('users/$userId/sync_info');
      final snapshot = await syncRef.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return {
          'status': 'synced',
          'last_sync': data['last_sync'],
          'sync_status': data['sync_status'],
        };
      } else {
        return {'status': 'never_synced'};
      }
      
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
    _syncProgressController.close();
  }
}
