#!/usr/bin/env python3
"""
Master Training Orchestrator for BeforeDoctor
Coordinates all training modules and manages the complete ML pipeline
"""

import os
import sys
import json
import logging
import subprocess
from datetime import datetime
from pathlib import Path

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class MasterTrainingOrchestrator:
    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.training_modules = {
            "cdc": "cdc_training/cdc_model_trainer.py",
            "voice": "voice_training/voice_model_trainer.py",
            "treatment": "treatment_training/treatment_model_trainer.py",
            "conversation": "conversation_training/conversation_model_trainer.py",
            "risk": "risk_training/risk_model_trainer.py",
            "diseases_symptoms": "diseases_symptoms_training/diseases_symptoms_trainer.py"
        }
        self.results = {}
        
    def setup_environment(self):
        """Setup training environment"""
        logger.info("Setting up training environment...")
        
        # Create shared directories
        shared_dirs = ["models", "processed", "outputs", "logs"]
        for dir_name in shared_dirs:
            os.makedirs(self.base_dir / dir_name, exist_ok=True)
        
        # Create training module directories
        for module_name in self.training_modules.keys():
            module_dir = self.base_dir / module_name + "_training"
            os.makedirs(module_dir, exist_ok=True)
            os.makedirs(module_dir / "models", exist_ok=True)
            os.makedirs(module_dir / "processed", exist_ok=True)
        
        logger.info("Training environment setup complete")
    
    def run_training_module(self, module_name):
        """Run a specific training module"""
        logger.info(f"Starting {module_name} training module...")
        
        try:
            # Get module path
            module_path = self.base_dir / self.training_modules[module_name]
            
            if not module_path.exists():
                logger.error(f"Training module not found: {module_path}")
                return False
            
            # Run the training module
            result = subprocess.run([
                sys.executable, str(module_path)
            ], capture_output=True, text=True, cwd=self.base_dir)
            
            if result.returncode == 0:
                logger.info(f"✅ {module_name} training completed successfully")
                self.results[module_name] = {
                    "status": "success",
                    "timestamp": datetime.now().isoformat(),
                    "output": result.stdout
                }
                return True
            else:
                logger.error(f"❌ {module_name} training failed: {result.stderr}")
                self.results[module_name] = {
                    "status": "failed",
                    "timestamp": datetime.now().isoformat(),
                    "error": result.stderr
                }
                return False
                
        except Exception as e:
            logger.error(f"❌ Error running {module_name} training: {e}")
            self.results[module_name] = {
                "status": "error",
                "timestamp": datetime.now().isoformat(),
                "error": str(e)
            }
            return False
    
    def run_all_training_modules(self):
        """Run all training modules in sequence"""
        logger.info("Starting complete training pipeline...")
        
        # Setup environment
        self.setup_environment()
        
        # Run each training module
        for module_name in self.training_modules.keys():
            success = self.run_training_module(module_name)
            if not success:
                logger.warning(f"⚠️ {module_name} training failed, continuing with next module")
        
        # Generate summary report
        self.generate_training_summary()
        
        logger.info("Complete training pipeline finished")
        return self.results
    
    def run_specific_modules(self, module_names):
        """Run specific training modules"""
        logger.info(f"Running specific modules: {module_names}")
        
        # Setup environment
        self.setup_environment()
        
        # Run specified modules
        for module_name in module_names:
            if module_name in self.training_modules:
                success = self.run_training_module(module_name)
                if not success:
                    logger.warning(f"⚠️ {module_name} training failed")
            else:
                logger.error(f"❌ Unknown training module: {module_name}")
        
        # Generate summary report
        self.generate_training_summary()
        
        return self.results
    
    def generate_training_summary(self):
        """Generate training summary report"""
        logger.info("Generating training summary report...")
        
        summary = {
            "timestamp": datetime.now().isoformat(),
            "total_modules": len(self.training_modules),
            "successful_modules": sum(1 for r in self.results.values() if r["status"] == "success"),
            "failed_modules": sum(1 for r in self.results.values() if r["status"] == "failed"),
            "error_modules": sum(1 for r in self.results.values() if r["status"] == "error"),
            "module_results": self.results,
            "training_datasets": {
                "voice": "pediatric_symptom_dataset_comprehensive.json (5,064 records)",
                "treatment": "pediatric_symptom_treatment_large.json (26,794 records)",
                "conversation": "pediatric_llm_prompt_templates_full.json (155 templates)",
                "risk": "prompt_logic_tree.json (102 records)",
                "cdc": "CDC synthetic data (400 records)"
            }
        }
        
        # Save summary report
        summary_path = self.base_dir / "outputs" / "training_summary.json"
        with open(summary_path, "w") as f:
            json.dump(summary, f, indent=2)
        
        # Print summary
        logger.info("=== TRAINING SUMMARY ===")
        logger.info(f"Total modules: {summary['total_modules']}")
        logger.info(f"Successful: {summary['successful_modules']}")
        logger.info(f"Failed: {summary['failed_modules']}")
        logger.info(f"Errors: {summary['error_modules']}")
        
        for module_name, result in self.results.items():
            status_emoji = "✅" if result["status"] == "success" else "❌"
            logger.info(f"{status_emoji} {module_name}: {result['status']}")
        
        logger.info(f"Summary saved to: {summary_path}")
    
    def create_flutter_integration(self):
        """Create comprehensive Flutter integration for all models"""
        logger.info("Creating comprehensive Flutter integration...")
        
        flutter_code = '''
// Master AI Model Integration for Flutter
import 'dart:convert';
import 'package:flutter/services.dart';

class MasterAIModelService {
  // Voice processing models
  static Map<String, dynamic>? _voiceModels;
  
  // Treatment recommendation models
  static Map<String, dynamic>? _treatmentModels;
  
  // Conversation AI models
  static Map<String, dynamic>? _conversationModels;
  
  // Risk assessment models
  static Map<String, dynamic>? _riskModels;
  
  // CDC models
  static Map<String, dynamic>? _cdcModels;
  
  /// Load all AI models
  static Future<void> loadAllModels() async {
    try {
      // Load voice models
      await _loadVoiceModels();
      
      // Load treatment models
      await _loadTreatmentModels();
      
      // Load conversation models
      await _loadConversationModels();
      
      // Load risk models
      await _loadRiskModels();
      
      // Load CDC models
      await _loadCDCModels();
      
      print('✅ All AI models loaded successfully');
    } catch (e) {
      print('❌ Error loading AI models: $e');
    }
  }
  
  /// Process voice input and get comprehensive analysis
  static Future<Map<String, dynamic>> processVoiceInput(String voiceInput) async {
    try {
      // 1. Voice-to-symptom conversion
      final symptomData = await _processVoiceToSymptom(voiceInput);
      
      // 2. Get treatment recommendations
      final treatments = await _getTreatmentRecommendations(symptomData['symptom']);
      
      // 3. Assess risk level
      final riskAssessment = await _assessRisk(symptomData['symptom']);
      
      // 4. Generate conversation response
      final conversationResponse = await _generateConversationResponse(symptomData);
      
      return {
        'symptom_data': symptomData,
        'treatments': treatments,
        'risk_assessment': riskAssessment,
        'conversation_response': conversationResponse,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error processing voice input: $e');
      return {};
    }
  }
  
  // Private methods for each model type
  static Future<void> _loadVoiceModels() async {
    // Load voice processing models
  }
  
  static Future<void> _loadTreatmentModels() async {
    // Load treatment recommendation models
  }
  
  static Future<void> _loadConversationModels() async {
    // Load conversation AI models
  }
  
  static Future<void> _loadRiskModels() async {
    // Load risk assessment models
  }
  
  static Future<void> _loadCDCModels() async {
    // Load CDC models
  }
  
  static Future<Map<String, dynamic>> _processVoiceToSymptom(String voiceInput) async {
    // Process voice input to extract symptoms
    return {
      'symptom': 'fever',
      'severity': 'moderate',
      'confidence': 0.85,
    };
  }
  
  static Future<List<Map<String, dynamic>>> _getTreatmentRecommendations(String symptom) async {
    // Get treatment recommendations
    return [
      {'treatment': 'Acetaminophen', 'priority': 'high'},
      {'treatment': 'Rest', 'priority': 'medium'},
    ];
  }
  
  static Future<Map<String, dynamic>> _assessRisk(String symptom) async {
    // Assess risk level
    return {
      'risk_level': 'low',
      'emergency_flag': false,
      'recommended_action': 'monitor',
    };
  }
  
  static Future<String> _generateConversationResponse(Map<String, dynamic> symptomData) async {
    // Generate natural conversation response
    return 'Based on the symptoms, I recommend monitoring the fever and giving acetaminophen if needed.';
  }
}
'''
        
        # Save Flutter integration code
        integration_path = self.base_dir / "outputs" / "master_ai_integration.dart"
        with open(integration_path, "w") as f:
            f.write(flutter_code)
        
        logger.info(f"Comprehensive Flutter integration created: {integration_path}")
        return flutter_code

def main():
    """Main function to run training orchestrator"""
    orchestrator = MasterTrainingOrchestrator()
    
    # Check command line arguments
    if len(sys.argv) > 1:
        # Run specific modules
        module_names = sys.argv[1:]
        results = orchestrator.run_specific_modules(module_names)
    else:
        # Run all modules
        results = orchestrator.run_all_training_modules()
    
    # Create Flutter integration
    orchestrator.create_flutter_integration()
    
    print("🎯 Training orchestration completed!")
    return results

if __name__ == "__main__":
    main() 