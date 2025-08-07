#!/usr/bin/env python3
"""
Voice-to-Symptom Model Trainer for BeforeDoctor
Trains models to convert voice input to structured symptom data
"""

import pandas as pd
import numpy as np
import json
import os
import logging
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score
import joblib
from datetime import datetime

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class VoiceModelTrainer:
    def __init__(self):
        self.models_dir = "models"
        self.data_dir = "data"
        self.processed_dir = "processed"
        self.models = {}
        self.vectorizer = None
        
    def load_comprehensive_dataset(self):
        """Load the comprehensive pediatric symptom dataset"""
        try:
            # Load from assets/data directory
            data_path = "../../../beforedoctor/assets/data/pediatric_symptom_dataset_comprehensive.json"
            with open(data_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            logger.info(f"Loaded comprehensive dataset with {len(data)} records")
            return data
        except Exception as e:
            logger.error(f"Error loading comprehensive dataset: {e}")
            return None
    
    def create_voice_training_data(self, dataset):
        """Create training data for voice-to-symptom conversion"""
        logger.info("Creating voice training data...")
        
        training_data = []
        
        # Generate synthetic voice inputs based on real symptoms
        voice_patterns = {
            "fever": [
                "My child has a fever",
                "Temperature is high",
                "Child is running a temperature",
                "Fever started yesterday",
                "High fever with chills"
            ],
            "cough": [
                "Child is coughing",
                "Dry cough at night",
                "Wet cough with phlegm",
                "Coughing a lot",
                "Persistent cough"
            ],
            "vomiting": [
                "Child is throwing up",
                "Vomiting after meals",
                "Projectile vomiting",
                "Nausea and vomiting",
                "Vomiting multiple times"
            ],
            "diarrhea": [
                "Loose stools",
                "Watery diarrhea",
                "Frequent bowel movements",
                "Diarrhea for days",
                "Stomach upset with diarrhea"
            ],
            "rash": [
                "Red rash on skin",
                "Itchy rash",
                "Rash spreading",
                "Bumpy rash",
                "Rash with fever"
            ],
            "ear_pain": [
                "Ear hurts",
                "Pulling at ear",
                "Ear infection",
                "Pain in ear",
                "Fluid in ear"
            ]
        }
        
        # Create training examples
        for symptom, voice_inputs in voice_patterns.items():
            for voice_input in voice_inputs:
                # Create multiple variations
                for age_group in ["infant", "toddler", "preschool", "school_age", "adolescent"]:
                    training_example = {
                        "voice_input": voice_input,
                        "symptom": symptom,
                        "age_group": age_group,
                        "confidence": np.random.uniform(0.7, 1.0),
                        "severity": np.random.choice(["mild", "moderate", "severe"]),
                        "duration": np.random.randint(1, 15)
                    }
                    training_data.append(training_example)
        
        logger.info(f"Created {len(training_data)} voice training examples")
        return training_data
    
    def prepare_features(self, training_data):
        """Prepare features for voice-to-symptom model"""
        logger.info("Preparing features for voice model...")
        
        # Convert to DataFrame
        df = pd.DataFrame(training_data)
        
        # Create text vectorizer
        self.vectorizer = TfidfVectorizer(
            max_features=1000,
            ngram_range=(1, 3),
            stop_words='english'
        )
        
        # Vectorize voice inputs
        X = self.vectorizer.fit_transform(df['voice_input'])
        
        # Create target variables
        y_symptom = df['symptom']
        y_severity = df['severity']
        y_age_group = df['age_group']
        
        logger.info(f"Prepared features: {X.shape}")
        return X, y_symptom, y_severity, y_age_group
    
    def train_symptom_classifier(self, X, y_symptom):
        """Train symptom classification model"""
        logger.info("Training symptom classification model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y_symptom, test_size=0.2, random_state=42
        )
        
        # Train Random Forest classifier
        symptom_model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        
        symptom_model.fit(X_train, y_train)
        
        # Evaluate model
        y_pred = symptom_model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        logger.info(f"Symptom classification accuracy: {accuracy:.3f}")
        
        # Save model
        model_path = f"{self.models_dir}/symptom_classifier.pkl"
        joblib.dump(symptom_model, model_path)
        
        return symptom_model, accuracy
    
    def train_severity_classifier(self, X, y_severity):
        """Train severity classification model"""
        logger.info("Training severity classification model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y_severity, test_size=0.2, random_state=42
        )
        
        # Train Random Forest classifier
        severity_model = RandomForestClassifier(
            n_estimators=100,
            max_depth=8,
            random_state=42
        )
        
        severity_model.fit(X_train, y_train)
        
        # Evaluate model
        y_pred = severity_model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        logger.info(f"Severity classification accuracy: {accuracy:.3f}")
        
        # Save model
        model_path = f"{self.models_dir}/severity_classifier.pkl"
        joblib.dump(severity_model, model_path)
        
        return severity_model, accuracy
    
    def create_flutter_integration_code(self):
        """Create Flutter integration code for voice models"""
        logger.info("Creating Flutter integration code...")
        
        flutter_code = '''
// Voice Model Integration for Flutter
import 'dart:convert';
import 'package:flutter/services.dart';

class VoiceModelService {
  static Map<String, dynamic>? _symptomModel;
  static Map<String, dynamic>? _severityModel;
  static Map<String, dynamic>? _vectorizer;
  
  /// Load voice models
  static Future<void> loadModels() async {
    try {
      // Load symptom classifier
      final symptomData = await rootBundle.loadString('assets/models/symptom_classifier.json');
      _symptomModel = json.decode(symptomData);
      
      // Load severity classifier
      final severityData = await rootBundle.loadString('assets/models/severity_classifier.json');
      _severityModel = json.decode(severityData);
      
      // Load vectorizer
      final vectorizerData = await rootBundle.loadString('assets/models/vectorizer.json');
      _vectorizer = json.decode(vectorizerData);
      
      print('✅ Voice models loaded successfully');
    } catch (e) {
      print('❌ Error loading voice models: $e');
    }
  }
  
  /// Convert voice input to structured symptom data
  static Future<Map<String, dynamic>> processVoiceInput(String voiceInput) async {
    try {
      // Vectorize input
      final features = _vectorizeInput(voiceInput);
      
      // Predict symptom
      final symptom = _predictSymptom(features);
      
      // Predict severity
      final severity = _predictSeverity(features);
      
      return {
        'symptom': symptom,
        'severity': severity,
        'confidence': 0.85,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error processing voice input: $e');
      return {};
    }
  }
  
  static List<double> _vectorizeInput(String input) {
    // Implement TF-IDF vectorization
    // This would be a simplified version for Flutter
    return List.filled(1000, 0.0); // Placeholder
  }
  
  static String _predictSymptom(List<double> features) {
    // Implement symptom prediction
    return 'fever'; // Placeholder
  }
  
  static String _predictSeverity(List<double> features) {
    // Implement severity prediction
    return 'moderate'; // Placeholder
  }
}
'''
        
        # Save Flutter integration code
        with open(f"{self.processed_dir}/voice_model_integration.dart", "w") as f:
            f.write(flutter_code)
        
        logger.info("Flutter integration code created")
        return flutter_code
    
    def train(self):
        """Main training pipeline for voice models"""
        logger.info("Starting voice model training pipeline...")
        
        # Setup directories
        os.makedirs(self.models_dir, exist_ok=True)
        os.makedirs(self.processed_dir, exist_ok=True)
        
        # Load comprehensive dataset
        dataset = self.load_comprehensive_dataset()
        if dataset is None:
            logger.error("Failed to load comprehensive dataset")
            return False
        
        # Create training data
        training_data = self.create_voice_training_data(dataset)
        
        # Prepare features
        X, y_symptom, y_severity, y_age_group = self.prepare_features(training_data)
        
        # Train models
        symptom_model, symptom_accuracy = self.train_symptom_classifier(X, y_symptom)
        severity_model, severity_accuracy = self.train_severity_classifier(X, y_severity)
        
        # Save vectorizer
        vectorizer_path = f"{self.models_dir}/vectorizer.pkl"
        joblib.dump(self.vectorizer, vectorizer_path)
        
        # Create Flutter integration
        self.create_flutter_integration_code()
        
        # Save training results
        results = {
            "timestamp": datetime.now().isoformat(),
            "models_trained": 2,
            "training_examples": len(training_data),
            "symptom_accuracy": symptom_accuracy,
            "severity_accuracy": severity_accuracy,
            "model_files": [
                "symptom_classifier.pkl",
                "severity_classifier.pkl",
                "vectorizer.pkl"
            ]
        }
        
        with open(f"{self.processed_dir}/voice_training_results.json", "w") as f:
            json.dump(results, f, indent=2)
        
        logger.info("Voice model training pipeline completed successfully!")
        return True

if __name__ == "__main__":
    trainer = VoiceModelTrainer()
    trainer.train() 