// Vaccination Coverage Service for BeforeDoctor
// Generated from CDC vaccination coverage dataset

import 'dart:convert';
import 'package:logger/logger.dart';

class VaccinationCoverageService {
  static final Logger _logger = Logger();
  
  // Vaccination schedule for children 19-35 months
  static const Map<String, List<String>> _vaccinationSchedule = {
    "19-35_months": [
      "DTaP (Diphtheria, Tetanus, Pertussis)",
      "MMR (Measles, Mumps, Rubella)",
      "Varicella (Chickenpox)",
      "Hepatitis A",
      "Hepatitis B",
      "Hib (Haemophilus influenzae type b)",
      "PCV13 (Pneumococcal)",
      "IPV (Polio)",
      "Rotavirus",
      "Influenza (Annual)"
    ]
  };
  
  // Coverage statistics from CDC dataset
  static const Map<String, Map<String, double>> _coverageStats = {
    "DTaP": {"coverage_rate": 85.2, "recommended_doses": 4},
    "MMR": {"coverage_rate": 91.9, "recommended_doses": 1},
    "Varicella": {"coverage_rate": 91.2, "recommended_doses": 1},
    "Hepatitis_A": {"coverage_rate": 60.6, "recommended_doses": 1},
    "Hepatitis_B": {"coverage_rate": 92.1, "recommended_doses": 3},
    "Hib": {"coverage_rate": 92.7, "recommended_doses": 3},
    "PCV13": {"coverage_rate": 92.3, "recommended_doses": 4},
    "IPV": {"coverage_rate": 92.7, "recommended_doses": 3},
    "Rotavirus": {"coverage_rate": 74.8, "recommended_doses": 2},
    "Influenza": {"coverage_rate": 58.6, "recommended_doses": 1}
  };
  
  /// Check vaccination status for a child
  static Map<String, dynamic> checkVaccinationStatus({
    required String childId,
    required int ageInMonths,
    required Map<String, List<Map<String, dynamic>>> vaccinationHistory,
  }) {
    try {
      if (ageInMonths < 19 || ageInMonths > 35) {
        return {
          "status": "outside_age_range",
          "message": "Vaccination tracking optimized for children 19-35 months",
          "recommendations": []
        };
      }
      
      List<Map<String, dynamic>> missingVaccines = [];
      List<Map<String, dynamic>> upcomingVaccines = [];
      List<Map<String, dynamic>> completedVaccines = [];
      
      // Check each required vaccine
      for (String vaccine in _vaccinationSchedule["19-35_months"]!) {
        String vaccineKey = _getVaccineKey(vaccine);
        var stats = _coverageStats[vaccineKey];
        
        if (stats == null) continue;
        
        int receivedDoses = _countReceivedDoses(vaccinationHistory, vaccineKey);
        int requiredDoses = stats["recommended_doses"]!.toInt();
        
        if (receivedDoses >= requiredDoses) {
          completedVaccines.add({
            "vaccine": vaccine,
            "doses_received": receivedDoses,
            "required_doses": requiredDoses,
            "status": "complete"
          });
        } else if (receivedDoses > 0) {
          missingVaccines.add({
            "vaccine": vaccine,
            "doses_received": receivedDoses,
            "required_doses": requiredDoses,
            "status": "incomplete",
            "missing_doses": requiredDoses - receivedDoses
          });
        } else {
          missingVaccines.add({
            "vaccine": vaccine,
            "doses_received": 0,
            "required_doses": requiredDoses,
            "status": "not_started",
            "missing_doses": requiredDoses
          });
        }
      }
      
      // Calculate coverage percentage
      double coveragePercentage = (completedVaccines.length / 
          _vaccinationSchedule["19-35_months"]!.length) * 100;
      
      return {
        "status": "success",
        "child_id": childId,
        "age_months": ageInMonths,
        "coverage_percentage": coveragePercentage.roundToDouble(),
        "completed_vaccines": completedVaccines,
        "missing_vaccines": missingVaccines,
        "upcoming_vaccines": upcomingVaccines,
        "recommendations": _generateRecommendations(missingVaccines),
        "last_updated": DateTime.now().toIso8601String()
      };
      
    } catch (e) {
      _logger.e("Error checking vaccination status: $e");
      return {
        "status": "error",
        "message": "Failed to check vaccination status",
        "error": e.toString()
      };
    }
  }
  
  /// Log a vaccination event via voice command
  static Map<String, dynamic> logVaccination({
    required String childId,
    required String vaccineName,
    required DateTime vaccinationDate,
    String? batchNumber,
    String? provider,
    String? notes,
  }) {
    try {
      String vaccineKey = _getVaccineKey(vaccineName);
      
      if (vaccineKey.isEmpty) {
        return {
          "status": "error",
          "message": "Unknown vaccine: $vaccineName"
        };
      }
      
      Map<String, dynamic> vaccinationRecord = {
        "child_id": childId,
        "vaccine_key": vaccineKey,
        "vaccine_name": vaccineName,
        "vaccination_date": vaccinationDate.toIso8601String(),
        "batch_number": batchNumber,
        "provider": provider,
        "notes": notes,
        "logged_at": DateTime.now().toIso8601String()
      };
      
      _logger.i("Vaccination logged: $vaccineName for child $childId");
      
      return {
        "status": "success",
        "message": "Vaccination logged successfully",
        "record": vaccinationRecord
      };
      
    } catch (e) {
      _logger.e("Error logging vaccination: $e");
      return {
        "status": "error",
        "message": "Failed to log vaccination",
        "error": e.toString()
      };
    }
  }
  
  /// Generate vaccination reminders
  static List<Map<String, dynamic>> generateReminders({
    required String childId,
    required int ageInMonths,
    required Map<String, List<Map<String, dynamic>>> vaccinationHistory,
  }) {
    try {
      var status = checkVaccinationStatus(
        childId: childId,
        ageInMonths: ageInMonths,
        vaccinationHistory: vaccinationHistory,
      );
      
      if (status["status"] != "success") {
        return [];
      }
      
      List<Map<String, dynamic>> reminders = [];
      
      for (var missingVaccine in status["missing_vaccines"]) {
        reminders.add({
          "type": "vaccination_reminder",
          "priority": missingVaccine["status"] == "not_started" ? "high" : "medium",
          "vaccine": missingVaccine["vaccine"],
          "message": "Schedule ${missingVaccine["vaccine"]} vaccination",
          "missing_doses": missingVaccine["missing_doses"],
          "recommended_timing": _getRecommendedTiming(missingVaccine["vaccine"], ageInMonths)
        });
      }
      
      return reminders;
      
    } catch (e) {
      _logger.e("Error generating reminders: $e");
      return [];
    }
  }
  
  /// Extract vaccination information from voice input
  static Map<String, dynamic> extractVaccinationFromVoice(String voiceInput) {
    try {
      voiceInput = voiceInput.toLowerCase();
      
      // Common vaccination keywords
      List<String> vaccineKeywords = [
        "dtap", "diphtheria", "tetanus", "pertussis",
        "mmr", "measles", "mumps", "rubella",
        "varicella", "chickenpox",
        "hepatitis", "hep a", "hep b",
        "hib", "haemophilus",
        "pcv", "pneumococcal",
        "ipv", "polio",
        "rotavirus",
        "flu", "influenza",
        "vaccine", "vaccination", "shot", "immunization"
      ];
      
      // Check if voice input contains vaccination-related content
      bool isVaccinationRelated = vaccineKeywords.any((keyword) => 
          voiceInput.contains(keyword));
      
      if (!isVaccinationRelated) {
        return {
          "is_vaccination": false,
          "message": "No vaccination-related content detected"
        };
      }
      
      // Extract vaccine name
      String? detectedVaccine;
      for (String keyword in vaccineKeywords) {
        if (voiceInput.contains(keyword)) {
          detectedVaccine = _mapKeywordToVaccine(keyword);
          break;
        }
      }
      
      // Extract date information
      DateTime? vaccinationDate = _extractDateFromVoice(voiceInput);
      
      return {
        "is_vaccination": true,
        "detected_vaccine": detectedVaccine,
        "vaccination_date": vaccinationDate?.toIso8601String(),
        "voice_input": voiceInput,
        "confidence": 0.85 // High confidence for vaccination detection
      };
      
    } catch (e) {
      _logger.e("Error extracting vaccination from voice: $e");
      return {
        "is_vaccination": false,
        "error": e.toString()
      };
    }
  }
  
  // Helper methods
  static String _getVaccineKey(String vaccineName) {
    Map<String, String> vaccineMapping = {
      "DTaP": "DTaP",
      "MMR": "MMR", 
      "Varicella": "Varicella",
      "Hepatitis A": "Hepatitis_A",
      "Hepatitis B": "Hepatitis_B",
      "Hib": "Hib",
      "PCV13": "PCV13",
      "IPV": "IPV",
      "Rotavirus": "Rotavirus",
      "Influenza": "Influenza"
    };
    
    for (String key in vaccineMapping.keys) {
      if (vaccineName.contains(key)) {
        return vaccineMapping[key]!;
      }
    }
    return "";
  }
  
  static String _mapKeywordToVaccine(String keyword) {
    Map<String, String> keywordMapping = {
      "dtap": "DTaP (Diphtheria, Tetanus, Pertussis)",
      "diphtheria": "DTaP (Diphtheria, Tetanus, Pertussis)",
      "tetanus": "DTaP (Diphtheria, Tetanus, Pertussis)",
      "pertussis": "DTaP (Diphtheria, Tetanus, Pertussis)",
      "mmr": "MMR (Measles, Mumps, Rubella)",
      "measles": "MMR (Measles, Mumps, Rubella)",
      "mumps": "MMR (Measles, Mumps, Rubella)",
      "rubella": "MMR (Measles, Mumps, Rubella)",
      "varicella": "Varicella (Chickenpox)",
      "chickenpox": "Varicella (Chickenpox)",
      "hepatitis": "Hepatitis B",
      "hep a": "Hepatitis A",
      "hep b": "Hepatitis B",
      "hib": "Hib (Haemophilus influenzae type b)",
      "haemophilus": "Hib (Haemophilus influenzae type b)",
      "pcv": "PCV13 (Pneumococcal)",
      "pneumococcal": "PCV13 (Pneumococcal)",
      "ipv": "IPV (Polio)",
      "polio": "IPV (Polio)",
      "rotavirus": "Rotavirus",
      "flu": "Influenza (Annual)",
      "influenza": "Influenza (Annual)"
    };
    
    return keywordMapping[keyword] ?? "Unknown Vaccine";
  }
  
  static DateTime? _extractDateFromVoice(String voiceInput) {
    // Simple date extraction - in practice, this would use NLP
    if (voiceInput.contains("today")) {
      return DateTime.now();
    } else if (voiceInput.contains("yesterday")) {
      return DateTime.now().subtract(Duration(days: 1));
    } else if (voiceInput.contains("last week")) {
      return DateTime.now().subtract(Duration(days: 7));
    }
    
    // Default to today if no specific date mentioned
    return DateTime.now();
  }
  
  static int _countReceivedDoses(Map<String, List<Map<String, dynamic>>> history, String vaccineKey) {
    if (!history.containsKey(vaccineKey)) return 0;
    return history[vaccineKey]!.length;
  }
  
  static List<String> _generateRecommendations(List<Map<String, dynamic>> missingVaccines) {
    List<String> recommendations = [];
    
    for (var vaccine in missingVaccines) {
      if (vaccine["status"] == "not_started") {
        recommendations.add("Start ${vaccine["vaccine"]} vaccination series");
      } else {
        recommendations.add("Complete ${vaccine["vaccine"]} vaccination series");
      }
    }
    
    return recommendations;
  }
  
  static String _getRecommendedTiming(String vaccine, int ageInMonths) {
    // Simplified timing logic - in practice, this would be more sophisticated
    return "Schedule within next 30 days";
  }
} 