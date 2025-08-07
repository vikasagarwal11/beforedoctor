#!/usr/bin/env python3
"""
Treatment Recommendation Model Trainer for BeforeDoctor
Trains models to recommend age-appropriate treatments
"""

import pandas as pd
import numpy as np
import json
import os
import logging
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score
import joblib
from datetime import datetime

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class TreatmentModelTrainer:
    def __init__(self):
        self.models_dir = "models"
        self.data_dir = "data"
        self.processed_dir = "processed"
        self.models = {}
        
    def load_treatment_dataset(self):
        """Load the large pediatric treatment dataset"""
        try:
            # Load from assets/data directory
            data_path = "../../../beforedoctor/assets/data/pediatric_symptom_treatment_large.json"
            with open(data_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            logger.info(f"Loaded treatment dataset with {len(data)} records")
            return data
        except Exception as e:
            logger.error(f"Error loading treatment dataset: {e}")
            return None
    
    def create_treatment_training_data(self, dataset):
        """Create training data for treatment recommendations"""
        logger.info("Creating treatment training data...")
        
        training_data = []
        
        # Process each treatment record
        for record in dataset:
            symptom = record.get('symptom', '')
            age_group = record.get('age_group', '')
            treatment = record.get('treatment', {})
            
            # Extract treatment information
            medications = treatment.get('medications', [])
            home_care = treatment.get('home_care', [])
            red_flags = treatment.get('red_flags', [])
            
            # Create training examples for different treatment types
            for med in medications:
                training_example = {
                    "symptom": symptom,
                    "age_group": age_group,
                    "treatment_type": "medication",
                    "treatment_name": med.get('name', ''),
                    "treatment_category": med.get('type', ''),
                    "priority": "high" if med.get('type') == 'Rx' else "medium"
                }
                training_data.append(training_example)
            
            # Add home care recommendations
            for care in home_care:
                training_example = {
                    "symptom": symptom,
                    "age_group": age_group,
                    "treatment_type": "home_care",
                    "treatment_name": care,
                    "treatment_category": "home_remedy",
                    "priority": "low"
                }
                training_data.append(training_example)
        
        logger.info(f"Created {len(training_data)} treatment training examples")
        return training_data
    
    def prepare_features(self, training_data):
        """Prepare features for treatment recommendation model"""
        logger.info("Preparing features for treatment model...")
        
        # Convert to DataFrame
        df = pd.DataFrame(training_data)
        
        # Create feature encoders
        from sklearn.preprocessing import LabelEncoder
        
        self.encoders = {}
        self.encoders['symptom'] = LabelEncoder()
        self.encoders['age_group'] = LabelEncoder()
        self.encoders['treatment_type'] = LabelEncoder()
        self.encoders['treatment_category'] = LabelEncoder()
        self.encoders['priority'] = LabelEncoder()
        
        # Encode categorical features
        df['symptom_encoded'] = self.encoders['symptom'].fit_transform(df['symptom'])
        df['age_group_encoded'] = self.encoders['age_group'].fit_transform(df['age_group'])
        df['treatment_type_encoded'] = self.encoders['treatment_type'].fit_transform(df['treatment_type'])
        df['treatment_category_encoded'] = self.encoders['treatment_category'].fit_transform(df['treatment_category'])
        df['priority_encoded'] = self.encoders['priority'].fit_transform(df['priority'])
        
        # Create feature matrix
        feature_columns = [
            'symptom_encoded', 'age_group_encoded', 'treatment_type_encoded',
            'treatment_category_encoded', 'priority_encoded'
        ]
        X = df[feature_columns]
        
        # Create target variables
        y_treatment = df['treatment_name']
        y_priority = df['priority']
        
        logger.info(f"Prepared features: {X.shape}")
        return X, y_treatment, y_priority
    
    def train_treatment_recommender(self, X, y_treatment):
        """Train treatment recommendation model"""
        logger.info("Training treatment recommendation model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y_treatment, test_size=0.2, random_state=42
        )
        
        # Train Random Forest classifier
        treatment_model = RandomForestClassifier(
            n_estimators=150,
            max_depth=12,
            random_state=42
        )
        
        treatment_model.fit(X_train, y_train)
        
        # Evaluate model
        y_pred = treatment_model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        logger.info(f"Treatment recommendation accuracy: {accuracy:.3f}")
        
        # Save model
        model_path = f"{self.models_dir}/treatment_recommender.pkl"
        joblib.dump(treatment_model, model_path)
        
        return treatment_model, accuracy
    
    def train_priority_classifier(self, X, y_priority):
        """Train treatment priority classifier"""
        logger.info("Training treatment priority classifier...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y_priority, test_size=0.2, random_state=42
        )
        
        # Train Random Forest classifier
        priority_model = RandomForestClassifier(
            n_estimators=100,
            max_depth=8,
            random_state=42
        )
        
        priority_model.fit(X_train, y_train)
        
        # Evaluate model
        y_pred = priority_model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        logger.info(f"Treatment priority accuracy: {accuracy:.3f}")
        
        # Save model
        model_path = f"{self.models_dir}/treatment_priority.pkl"
        joblib.dump(priority_model, model_path)
        
        return priority_model, accuracy
    
    def create_flutter_integration_code(self):
        """Create Flutter integration code for treatment models"""
        logger.info("Creating Flutter integration code...")
        
        flutter_code = '''
// Treatment Model Integration for Flutter
import 'dart:convert';
import 'package:flutter/services.dart';

class TreatmentModelService {
  static Map<String, dynamic>? _treatmentModel;
  static Map<String, dynamic>? _priorityModel;
  static Map<String, dynamic>? _encoders;
  
  /// Load treatment models
  static Future<void> loadModels() async {
    try {
      // Load treatment recommender
      final treatmentData = await rootBundle.loadString('assets/models/treatment_recommender.json');
      _treatmentModel = json.decode(treatmentData);
      
      // Load priority classifier
      final priorityData = await rootBundle.loadString('assets/models/treatment_priority.json');
      _priorityModel = json.decode(priorityData);
      
      // Load encoders
      final encodersData = await rootBundle.loadString('assets/models/treatment_encoders.json');
      _encoders = json.decode(encodersData);
      
      print('✅ Treatment models loaded successfully');
    } catch (e) {
      print('❌ Error loading treatment models: $e');
    }
  }
  
  /// Get treatment recommendations for a symptom
  static Future<List<Map<String, dynamic>>> getTreatmentRecommendations(
    String symptom, String ageGroup) async {
    try {
      // Encode inputs
      final symptomEncoded = _encodeSymptom(symptom);
      final ageEncoded = _encodeAgeGroup(ageGroup);
      
      // Get treatment recommendations
      final treatments = _predictTreatments(symptomEncoded, ageEncoded);
      
      // Get priorities
      final priorities = _predictPriorities(symptomEncoded, ageEncoded);
      
      // Combine results
      List<Map<String, dynamic>> recommendations = [];
      for (int i = 0; i < treatments.length; i++) {
        recommendations.add({
          'treatment': treatments[i],
          'priority': priorities[i],
          'confidence': 0.85,
        });
      }
      
      return recommendations;
    } catch (e) {
      print('❌ Error getting treatment recommendations: $e');
      return [];
    }
  }
  
  static int _encodeSymptom(String symptom) {
    // Implement symptom encoding
    return 0; // Placeholder
  }
  
  static int _encodeAgeGroup(String ageGroup) {
    // Implement age group encoding
    return 0; // Placeholder
  }
  
  static List<String> _predictTreatments(int symptomEncoded, int ageEncoded) {
    // Implement treatment prediction
    return ['Acetaminophen', 'Rest', 'Fluids']; // Placeholder
  }
  
  static List<String> _predictPriorities(int symptomEncoded, int ageEncoded) {
    // Implement priority prediction
    return ['high', 'medium', 'low']; // Placeholder
  }
}
'''
        
        # Save Flutter integration code
        with open(f"{self.processed_dir}/treatment_model_integration.dart", "w") as f:
            f.write(flutter_code)
        
        logger.info("Flutter integration code created")
        return flutter_code
    
    def train(self):
        """Main training pipeline for treatment models"""
        logger.info("Starting treatment model training pipeline...")
        
        # Setup directories
        os.makedirs(self.models_dir, exist_ok=True)
        os.makedirs(self.processed_dir, exist_ok=True)
        
        # Load treatment dataset
        dataset = self.load_treatment_dataset()
        if dataset is None:
            logger.error("Failed to load treatment dataset")
            return False
        
        # Create training data
        training_data = self.create_treatment_training_data(dataset)
        
        # Prepare features
        X, y_treatment, y_priority = self.prepare_features(training_data)
        
        # Train models
        treatment_model, treatment_accuracy = self.train_treatment_recommender(X, y_treatment)
        priority_model, priority_accuracy = self.train_priority_classifier(X, y_priority)
        
        # Save encoders
        encoders_path = f"{self.models_dir}/treatment_encoders.pkl"
        joblib.dump(self.encoders, encoders_path)
        
        # Create Flutter integration
        self.create_flutter_integration_code()
        
        # Save training results
        results = {
            "timestamp": datetime.now().isoformat(),
            "models_trained": 2,
            "training_examples": len(training_data),
            "treatment_accuracy": treatment_accuracy,
            "priority_accuracy": priority_accuracy,
            "model_files": [
                "treatment_recommender.pkl",
                "treatment_priority.pkl",
                "treatment_encoders.pkl"
            ]
        }
        
        with open(f"{self.processed_dir}/treatment_training_results.json", "w") as f:
            json.dump(results, f, indent=2)
        
        logger.info("Treatment model training pipeline completed successfully!")
        return True

if __name__ == "__main__":
    trainer = TreatmentModelTrainer()
    trainer.train() 