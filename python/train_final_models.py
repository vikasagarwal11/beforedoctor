#!/usr/bin/env python3
"""
Final AI Model Training for BeforeDoctor
Trains all models using the actual data structure
"""

import sys
import os
import json
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score
import joblib

class FinalModelTrainer:
    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.data_dir = self.base_dir.parent / "beforedoctor" / "assets" / "data"
        self.models_dir = self.base_dir / "models"
        self.models_dir.mkdir(exist_ok=True)
        
        print(f"Data directory: {self.data_dir}")
        print(f"Models directory: {self.models_dir}")
        
    def load_comprehensive_dataset(self):
        """Load the comprehensive symptom dataset"""
        try:
            file_path = self.data_dir / "pediatric_symptom_dataset_comprehensive.json"
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Extract actual symptom data from the dictionary structure
            training_data = []
            for key, value in data.items():
                if isinstance(value, dict) and 'symptom' in value:
                    training_data.append({
                        'symptom': value['symptom'],
                        'details': value.get('details', ''),
                        'age_group': value.get('age_group', 'unknown'),
                        'severity': value.get('severity', 'unknown')
                    })
            
            print(f"Extracted {len(training_data)} symptom records from comprehensive dataset")
            return training_data
        except Exception as e:
            print(f"Error loading comprehensive dataset: {e}")
            return []
    
    def load_treatment_dataset(self):
        """Load the treatment dataset"""
        try:
            file_path = self.data_dir / "pediatric_symptom_treatment_dataset.json"
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Handle different data structures
            if isinstance(data, dict):
                if 'records' in data:
                    records = data['records']
                elif 'data' in data:
                    records = data['data']
                else:
                    records = [data]
            else:
                records = data
            
            print(f"Loaded treatment dataset with {len(records)} records")
            return records
        except Exception as e:
            print(f"Error loading treatment dataset: {e}")
            return []
    
    def train_symptom_classifier(self):
        """Train symptom classification model"""
        print("\n--- Training Symptom Classifier ---")
        
        data = self.load_comprehensive_dataset()
        if not data:
            print("No data available for symptom classifier")
            return False
        
        # Create training data
        training_data = []
        for record in data[:1000]:  # Use first 1000 records for training
            if 'symptom' in record and record['symptom']:
                training_data.append({
                    'text': f"{record.get('symptom', '')} {record.get('details', '')}".strip(),
                    'symptom': record['symptom']
                })
        
        if len(training_data) < 10:
            print("Insufficient data for symptom classifier")
            return False
        
        print(f"Created {len(training_data)} training samples")
        
        # Prepare features
        texts = [item['text'] for item in training_data]
        labels = [item['symptom'] for item in training_data]
        
        # Vectorize text
        vectorizer = TfidfVectorizer(max_features=1000, stop_words='english')
        X = vectorizer.fit_transform(texts)
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, labels, test_size=0.2, random_state=42)
        
        # Train model
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"Symptom classifier accuracy: {accuracy:.3f}")
        
        # Save model and vectorizer
        model_path = self.models_dir / "symptom_classifier.pkl"
        vectorizer_path = self.models_dir / "symptom_vectorizer.pkl"
        
        joblib.dump(model, model_path)
        joblib.dump(vectorizer, vectorizer_path)
        
        print(f"Saved symptom classifier to {model_path}")
        return True
    
    def train_treatment_recommender(self):
        """Train treatment recommendation model"""
        print("\n--- Training Treatment Recommender ---")
        
        data = self.load_treatment_dataset()
        if not data:
            print("No data available for treatment recommender")
            return False
        
        # Create training data
        training_data = []
        for record in data:
            if isinstance(record, dict) and 'symptom' in record and 'treatment' in record:
                training_data.append({
                    'symptom': record['symptom'],
                    'age_group': record.get('age_group', 'unknown'),
                    'severity': record.get('severity', 'unknown'),
                    'treatment': record['treatment']
                })
        
        if len(training_data) < 10:
            print("Insufficient data for treatment recommender")
            return False
        
        print(f"Created {len(training_data)} training samples")
        
        # Prepare features
        df = pd.DataFrame(training_data)
        
        # Encode categorical features
        from sklearn.preprocessing import LabelEncoder
        le_symptom = LabelEncoder()
        le_age = LabelEncoder()
        le_severity = LabelEncoder()
        le_treatment = LabelEncoder()
        
        df['symptom_encoded'] = le_symptom.fit_transform(df['symptom'])
        df['age_encoded'] = le_age.fit_transform(df['age_group'])
        df['severity_encoded'] = le_severity.fit_transform(df['severity'])
        df['treatment_encoded'] = le_treatment.fit_transform(df['treatment'])
        
        # Prepare features
        X = df[['symptom_encoded', 'age_encoded', 'severity_encoded']].values
        y = df['treatment_encoded'].values
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Train model
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"Treatment recommender accuracy: {accuracy:.3f}")
        
        # Save model and encoders
        model_path = self.models_dir / "treatment_recommender.pkl"
        encoders_path = self.models_dir / "treatment_encoders.pkl"
        
        joblib.dump(model, model_path)
        joblib.dump({
            'symptom_encoder': le_symptom,
            'age_encoder': le_age,
            'severity_encoder': le_severity,
            'treatment_encoder': le_treatment
        }, encoders_path)
        
        print(f"Saved treatment recommender to {model_path}")
        return True
    
    def train_risk_assessor(self):
        """Train risk assessment model"""
        print("\n--- Training Risk Assessor ---")
        
        data = self.load_comprehensive_dataset()
        if not data:
            print("No data available for risk assessor")
            return False
        
        # Create training data with risk levels
        training_data = []
        for record in data[:1000]:
            if 'symptom' in record and record['symptom']:
                # Simple risk assessment based on symptoms
                symptom = record['symptom'].lower()
                if any(word in symptom for word in ['fever', 'high', 'severe', 'emergency']):
                    risk_level = 'high'
                elif any(word in symptom for word in ['mild', 'slight', 'minor']):
                    risk_level = 'low'
                else:
                    risk_level = 'medium'
                
                training_data.append({
                    'text': f"{record.get('symptom', '')} {record.get('details', '')}".strip(),
                    'risk_level': risk_level
                })
        
        if len(training_data) < 10:
            print("Insufficient data for risk assessor")
            return False
        
        print(f"Created {len(training_data)} training samples")
        
        # Prepare features
        texts = [item['text'] for item in training_data]
        labels = [item['risk_level'] for item in training_data]
        
        # Vectorize text
        vectorizer = TfidfVectorizer(max_features=500, stop_words='english')
        X = vectorizer.fit_transform(texts)
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, labels, test_size=0.2, random_state=42)
        
        # Train model
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"Risk assessor accuracy: {accuracy:.3f}")
        
        # Save model and vectorizer
        model_path = self.models_dir / "risk_assessor.pkl"
        vectorizer_path = self.models_dir / "risk_vectorizer.pkl"
        
        joblib.dump(model, model_path)
        joblib.dump(vectorizer, vectorizer_path)
        
        print(f"Saved risk assessor to {model_path}")
        return True
    
    def create_flutter_integration(self):
        """Create Flutter integration code"""
        print("\n--- Creating Flutter Integration ---")
        
        integration_code = f'''
// AI Model Integration for BeforeDoctor
// Generated on: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class AIModelService {{
  static const String _modelPath = 'assets/models/';
  
  // Load trained models
  static Future<Map<String, dynamic>> loadModels() async {{
    try {{
      // Load model files
      final symptomModel = await rootBundle.loadString('$_modelPath'symptom_classifier.json');
      final treatmentModel = await rootBundle.loadString('$_modelPath'treatment_recommender.json');
      final riskModel = await rootBundle.loadString('$_modelPath'risk_assessor.json');
      
      return {{
        'symptom_classifier': json.decode(symptomModel),
        'treatment_recommender': json.decode(treatmentModel),
        'risk_assessor': json.decode(riskModel),
      }};
    }} catch (e) {{
      print('Error loading AI models: $e');
      return {{}};
    }}
  }}
  
  // Predict symptom from voice input
  static String predictSymptom(String voiceInput) {{
    // Implementation for symptom prediction
    // This would use the trained symptom classifier
    return 'fever'; // Placeholder
  }}
  
  // Recommend treatment
  static String recommendTreatment(String symptom, String ageGroup, String severity) {{
    // Implementation for treatment recommendation
    // This would use the trained treatment recommender
    return 'acetaminophen'; // Placeholder
  }}
  
  // Assess risk level
  static String assessRisk(String symptomDescription) {{
    // Implementation for risk assessment
    // This would use the trained risk assessor
    return 'medium'; // Placeholder
  }}
}}
'''
        
        # Save integration code
        integration_path = self.base_dir / "flutter_integration.dart"
        with open(integration_path, 'w', encoding='utf-8') as f:
            f.write(integration_code)
        
        print(f"Created Flutter integration at {integration_path}")
        return True
    
    def train_all_models(self):
        """Train all models"""
        print("Starting Final AI Model Training")
        print("=" * 50)
        
        results = {}
        
        # Train symptom classifier
        results['symptom_classifier'] = self.train_symptom_classifier()
        
        # Train treatment recommender
        results['treatment_recommender'] = self.train_treatment_recommender()
        
        # Train risk assessor
        results['risk_assessor'] = self.train_risk_assessor()
        
        # Create Flutter integration
        results['flutter_integration'] = self.create_flutter_integration()
        
        # Summary
        print("\n" + "=" * 50)
        print("TRAINING SUMMARY")
        print("=" * 50)
        
        successful = sum(results.values())
        total = len(results)
        
        for model, success in results.items():
            status = "SUCCESS" if success else "FAILED"
            print(f"{model}: {status}")
        
        print(f"\nOverall: {successful}/{total} models trained successfully")
        
        return results

def main():
    """Main function"""
    trainer = FinalModelTrainer()
    results = trainer.train_all_models()
    
    if sum(results.values()) == len(results):
        print("\nAll models trained successfully!")
        return 0
    else:
        print("\nSome models failed to train. Check logs for details.")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 