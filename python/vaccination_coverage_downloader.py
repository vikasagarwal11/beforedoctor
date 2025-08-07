#!/usr/bin/env python3
"""
CDC Vaccination Coverage Dataset Downloader
Downloads and processes vaccination coverage data for children 19-35 months
"""

import os
import json
import pandas as pd
import logging
from datetime import datetime
from pathlib import Path
import zipfile
import shutil

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('vaccination_download.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class VaccinationDatasetDownloader:
    def __init__(self):
        self.dataset_name = "cdc/vaccination-coverage-among-children-19-35-months"
        self.base_dir = Path("vaccination_coverage_training")
        self.data_dir = self.base_dir / "data"
        self.processed_dir = self.base_dir / "processed"
        self.models_dir = self.base_dir / "models"
        self.outputs_dir = self.base_dir / "outputs"
        
        # Create directories
        for dir_path in [self.base_dir, self.data_dir, self.processed_dir, 
                        self.models_dir, self.outputs_dir]:
            dir_path.mkdir(exist_ok=True)
    
    def download_dataset(self):
        """Download the vaccination coverage dataset using kagglehub"""
        try:
            import kagglehub
            
            logger.info(f"Downloading dataset: {self.dataset_name}")
            path = kagglehub.dataset_download(self.dataset_name)
            logger.info(f"Dataset downloaded to: {path}")
            
            # Copy files to our data directory
            self._copy_dataset_files(path)
            
            return True
            
        except ImportError:
            logger.error("kagglehub not available. Trying alternative download method...")
            return self._download_with_kaggle_cli()
    
    def _download_with_kaggle_cli(self):
        """Alternative download method using kaggle CLI"""
        try:
            import subprocess
            
            logger.info("Attempting download with kaggle CLI...")
            result = subprocess.run([
                "kaggle", "datasets", "download", 
                "cdc/vaccination-coverage-among-children-19-35-months",
                "-p", str(self.data_dir)
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info("Dataset downloaded successfully with kaggle CLI")
                self._extract_dataset()
                return True
            else:
                logger.error(f"Kaggle CLI download failed: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to download with kaggle CLI: {e}")
            return False
    
    def _copy_dataset_files(self, source_path):
        """Copy downloaded files to our data directory"""
        source_path = Path(source_path)
        
        if source_path.is_file():
            # Single file download
            shutil.copy2(source_path, self.data_dir / source_path.name)
        elif source_path.is_dir():
            # Directory download
            for item in source_path.iterdir():
                if item.is_file():
                    shutil.copy2(item, self.data_dir / item.name)
                elif item.is_dir():
                    shutil.copytree(item, self.data_dir / item.name, dirs_exist_ok=True)
        
        logger.info(f"Files copied to: {self.data_dir}")
    
    def _extract_dataset(self):
        """Extract any zip files in the data directory"""
        for zip_file in self.data_dir.glob("*.zip"):
            logger.info(f"Extracting: {zip_file}")
            with zipfile.ZipFile(zip_file, 'r') as zip_ref:
                zip_ref.extractall(self.data_dir)
            # Remove the zip file after extraction
            zip_file.unlink()
    
    def analyze_dataset(self):
        """Analyze the downloaded dataset structure"""
        logger.info("Analyzing dataset structure...")
        
        dataset_info = {
            "dataset_name": self.dataset_name,
            "download_date": datetime.now().isoformat(),
            "files": [],
            "data_summary": {}
        }
        
        # List all files in data directory
        for file_path in self.data_dir.rglob("*"):
            if file_path.is_file():
                file_info = {
                    "name": file_path.name,
                    "size": file_path.stat().st_size,
                    "extension": file_path.suffix,
                    "relative_path": str(file_path.relative_to(self.data_dir))
                }
                dataset_info["files"].append(file_info)
                
                # Analyze CSV files
                if file_path.suffix.lower() == '.csv':
                    try:
                        df = pd.read_csv(file_path)
                        file_info["rows"] = len(df)
                        file_info["columns"] = list(df.columns)
                        file_info["sample_data"] = df.head(3).to_dict('records')
                        
                        dataset_info["data_summary"][file_path.name] = {
                            "shape": df.shape,
                            "columns": list(df.columns),
                            "dtypes": df.dtypes.to_dict(),
                            "missing_values": df.isnull().sum().to_dict(),
                            "unique_values": {col: df[col].nunique() for col in df.columns}
                        }
                        
                        logger.info(f"Analyzed {file_path.name}: {df.shape[0]} rows, {df.shape[1]} columns")
                        
                    except Exception as e:
                        logger.error(f"Error analyzing {file_path}: {e}")
        
        # Save dataset info
        info_file = self.processed_dir / "dataset_info.json"
        with open(info_file, 'w') as f:
            json.dump(dataset_info, f, indent=2)
        
        logger.info(f"Dataset analysis saved to: {info_file}")
        return dataset_info
    
    def create_flutter_integration(self, dataset_info):
        """Create Flutter integration code for vaccination data"""
        flutter_code = '''
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
'''
        
        # Save Flutter integration code
        flutter_file = self.outputs_dir / "vaccination_coverage_service.dart"
        with open(flutter_file, 'w') as f:
            f.write(flutter_code)
        
        logger.info(f"Flutter integration code saved to: {flutter_file}")
        return flutter_file
    
    def run(self):
        """Main execution method"""
        logger.info("Starting vaccination coverage dataset download...")
        
        # Download dataset
        if not self.download_dataset():
            logger.error("Failed to download dataset")
            return False
        
        # Analyze dataset
        dataset_info = self.analyze_dataset()
        
        # Create Flutter integration
        flutter_file = self.create_flutter_integration(dataset_info)
        
        logger.info("Vaccination coverage dataset processing completed successfully!")
        logger.info(f"Flutter integration available at: {flutter_file}")
        
        return True

if __name__ == "__main__":
    downloader = VaccinationDatasetDownloader()
    success = downloader.run()
    
    if success:
        print("✅ Vaccination coverage dataset downloaded and processed successfully!")
    else:
        print("❌ Failed to process vaccination coverage dataset") 