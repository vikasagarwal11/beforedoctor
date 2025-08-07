#!/usr/bin/env python3
"""
Disease Database Training Script for BeforeDoctor
Trains models for pediatric disease classification, symptom matching, and treatment recommendations
"""

import os
import json
import pandas as pd
import numpy as np
from pathlib import Path
import logging
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix
from sklearn.pipeline import Pipeline
import joblib
import re
from typing import List, Dict, Tuple

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'python/logs/disease_training_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class DiseaseDatabaseTrainer:
    def __init__(self):
        self.data_path = Path("python/disease_database_training/processed/disease_database_pediatric.json")
        self.models_path = Path("python/disease_database_training/models")
        self.models_path.mkdir(parents=True, exist_ok=True)
        
        self.df = None
        self.disease_classifier = None
        self.symptom_matcher = None
        self.treatment_recommender = None
        
    def load_data(self):
        """Load the pediatric disease database"""
        try:
            logger.info("📊 Loading pediatric disease database...")
            
            # Load JSON data
            with open(self.data_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            self.df = pd.DataFrame(data)
            logger.info(f"✅ Loaded {len(self.df)} pediatric disease records")
            logger.info(f"📋 Columns: {list(self.df.columns)}")
            
            # Display sample data
            logger.info("📄 Sample records:")
            for i, row in self.df.head(3).iterrows():
                logger.info(f"  Disease: {row['disease']}")
                logger.info(f"  Symptoms: {row['common_symptom'][:100]}...")
                logger.info(f"  Treatment: {row['treatment'][:100]}...")
                logger.info("  ---")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to load data: {e}")
            return False
    
    def preprocess_data(self):
        """Preprocess the disease data for training"""
        try:
            logger.info("🔧 Preprocessing disease data...")
            
            # Clean and normalize text data
            self.df['disease_clean'] = self.df['disease'].str.lower().str.strip()
            self.df['symptoms_clean'] = self.df['common_symptom'].str.lower().str.strip()
            self.df['treatment_clean'] = self.df['treatment'].str.lower().str.strip()
            
            # Extract key symptoms (first 200 characters for training)
            self.df['symptoms_key'] = self.df['symptoms_clean'].str[:200]
            
            # Create disease categories for classification
            self.df['disease_category'] = self.df['disease_clean'].apply(self._categorize_disease)
            
            # Create symptom categories
            self.df['symptom_category'] = self.df['symptoms_clean'].apply(self._categorize_symptoms)
            
            logger.info(f"✅ Preprocessing completed")
            logger.info(f"📊 Disease categories: {self.df['disease_category'].value_counts().to_dict()}")
            logger.info(f"📊 Symptom categories: {self.df['symptom_category'].value_counts().to_dict()}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Preprocessing failed: {e}")
            return False
    
    def _categorize_disease(self, disease_name: str) -> str:
        """Categorize diseases into major groups"""
        disease_lower = disease_name.lower()
        
        if any(word in disease_lower for word in ['fever', 'infection', 'viral', 'bacterial']):
            return 'infectious_disease'
        elif any(word in disease_lower for word in ['asthma', 'allergy', 'respiratory', 'breathing']):
            return 'respiratory_disease'
        elif any(word in disease_lower for word in ['diabetes', 'endocrine', 'hormone', 'metabolic']):
            return 'endocrine_disease'
        elif any(word in disease_lower for word in ['heart', 'cardiac', 'cardiovascular']):
            return 'cardiovascular_disease'
        elif any(word in disease_lower for word in ['skin', 'dermatitis', 'eczema', 'rash']):
            return 'dermatological_disease'
        elif any(word in disease_lower for word in ['dental', 'tooth', 'teeth', 'oral']):
            return 'dental_disease'
        elif any(word in disease_lower for word in ['premature', 'neonatal', 'newborn']):
            return 'neonatal_disease'
        elif any(word in disease_lower for word in ['developmental', 'growth', 'milestone']):
            return 'developmental_disease'
        else:
            return 'other_disease'
    
    def _categorize_symptoms(self, symptoms: str) -> str:
        """Categorize symptoms into major groups"""
        symptoms_lower = symptoms.lower()
        
        if any(word in symptoms_lower for word in ['fever', 'temperature', 'hot']):
            return 'fever_symptoms'
        elif any(word in symptoms_lower for word in ['cough', 'breathing', 'wheezing', 'asthma']):
            return 'respiratory_symptoms'
        elif any(word in symptoms_lower for word in ['rash', 'skin', 'itching', 'redness']):
            return 'skin_symptoms'
        elif any(word in symptoms_lower for word in ['vomiting', 'nausea', 'diarrhea', 'stomach']):
            return 'gastrointestinal_symptoms'
        elif any(word in symptoms_lower for word in ['headache', 'pain', 'ache']):
            return 'pain_symptoms'
        elif any(word in symptoms_lower for word in ['fatigue', 'tired', 'weakness']):
            return 'fatigue_symptoms'
        else:
            return 'other_symptoms'
    
    def train_disease_classifier(self):
        """Train a disease classification model"""
        try:
            logger.info("🏥 Training disease classification model...")
            
            # Prepare data
            X = self.df['symptoms_key']
            y = self.df['disease_category']
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42, stratify=y
            )
            
            # Create pipeline
            pipeline = Pipeline([
                ('tfidf', TfidfVectorizer(
                    max_features=5000,
                    ngram_range=(1, 2),
                    stop_words='english'
                )),
                ('classifier', RandomForestClassifier(
                    n_estimators=100,
                    random_state=42,
                    n_jobs=-1
                ))
            ])
            
            # Train model
            pipeline.fit(X_train, y_train)
            
            # Evaluate
            y_pred = pipeline.predict(X_test)
            accuracy = accuracy_score(y_test, y_pred)
            
            logger.info(f"✅ Disease classifier trained successfully!")
            logger.info(f"📊 Accuracy: {accuracy:.3f}")
            logger.info(f"📋 Classification Report:")
            logger.info(classification_report(y_test, y_pred))
            
            # Save model
            model_path = self.models_path / "disease_classifier.pkl"
            joblib.dump(pipeline, model_path)
            logger.info(f"💾 Model saved: {model_path}")
            
            self.disease_classifier = pipeline
            return True
            
        except Exception as e:
            logger.error(f"❌ Disease classifier training failed: {e}")
            return False
    
    def train_symptom_matcher(self):
        """Train a symptom matching model"""
        try:
            logger.info("🔍 Training symptom matching model...")
            
            # Prepare data for symptom matching
            X = self.df['symptoms_key']
            y = self.df['symptom_category']
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42, stratify=y
            )
            
            # Create pipeline
            pipeline = Pipeline([
                ('tfidf', TfidfVectorizer(
                    max_features=3000,
                    ngram_range=(1, 2),
                    stop_words='english'
                )),
                ('classifier', LogisticRegression(
                    random_state=42,
                    max_iter=1000
                ))
            ])
            
            # Train model
            pipeline.fit(X_train, y_train)
            
            # Evaluate
            y_pred = pipeline.predict(X_test)
            accuracy = accuracy_score(y_test, y_pred)
            
            logger.info(f"✅ Symptom matcher trained successfully!")
            logger.info(f"📊 Accuracy: {accuracy:.3f}")
            logger.info(f"📋 Classification Report:")
            logger.info(classification_report(y_test, y_pred))
            
            # Save model
            model_path = self.models_path / "symptom_matcher.pkl"
            joblib.dump(pipeline, model_path)
            logger.info(f"💾 Model saved: {model_path}")
            
            self.symptom_matcher = pipeline
            return True
            
        except Exception as e:
            logger.error(f"❌ Symptom matcher training failed: {e}")
            return False
    
    def train_treatment_recommender(self):
        """Train a treatment recommendation model"""
        try:
            logger.info("💊 Training treatment recommendation model...")
            
            # Create treatment embeddings
            self.df['treatment_key'] = self.df['treatment_clean'].str[:300]
            
            # Prepare data
            X = self.df['symptoms_key']
            y = self.df['treatment_key']
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42
            )
            
            # Create pipeline for treatment recommendation
            pipeline = Pipeline([
                ('tfidf', TfidfVectorizer(
                    max_features=4000,
                    ngram_range=(1, 2),
                    stop_words='english'
                )),
                ('classifier', RandomForestClassifier(
                    n_estimators=50,
                    random_state=42,
                    n_jobs=-1
                ))
            ])
            
            # Train model
            pipeline.fit(X_train, y_train)
            
            # Evaluate
            y_pred = pipeline.predict(X_test)
            accuracy = accuracy_score(y_test, y_pred)
            
            logger.info(f"✅ Treatment recommender trained successfully!")
            logger.info(f"📊 Accuracy: {accuracy:.3f}")
            
            # Save model
            model_path = self.models_path / "treatment_recommender.pkl"
            joblib.dump(pipeline, model_path)
            logger.info(f"💾 Model saved: {model_path}")
            
            self.treatment_recommender = pipeline
            return True
            
        except Exception as e:
            logger.error(f"❌ Treatment recommender training failed: {e}")
            return False
    
    def create_disease_embeddings(self):
        """Create disease embeddings for similarity matching"""
        try:
            logger.info("🔤 Creating disease embeddings...")
            
            # Create TF-IDF embeddings for diseases
            vectorizer = TfidfVectorizer(
                max_features=2000,
                ngram_range=(1, 2),
                stop_words='english'
            )
            
            # Fit on disease names and symptoms
            disease_texts = self.df['disease_clean'] + ' ' + self.df['symptoms_key']
            embeddings = vectorizer.fit_transform(disease_texts)
            
            # Save vectorizer
            vectorizer_path = self.models_path / "disease_vectorizer.pkl"
            joblib.dump(vectorizer, vectorizer_path)
            logger.info(f"💾 Disease vectorizer saved: {vectorizer_path}")
            
            # Save embeddings
            embeddings_path = self.models_path / "disease_embeddings.pkl"
            joblib.dump(embeddings, embeddings_path)
            logger.info(f"💾 Disease embeddings saved: {embeddings_path}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Disease embeddings creation failed: {e}")
            return False
    
    def create_flutter_integration(self):
        """Create Flutter integration for the trained models"""
        try:
            logger.info("🔧 Creating Flutter integration...")
            
            # Create Dart service for disease prediction
            dart_content = '''// Disease Prediction Service for BeforeDoctor
// Generated from trained disease database models

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class DiseasePredictionService {
  static Future<Map<String, dynamic>> predictDisease(String symptoms) async {
    // TODO: Implement model inference
    // This would typically call a Python backend or use TensorFlow Lite
    return {
      'disease': 'Predicted Disease',
      'confidence': 0.85,
      'symptoms': symptoms,
      'recommendations': ['Rest', 'Hydration', 'Monitor symptoms']
    };
  }

  static Future<List<String>> getSimilarDiseases(String query) async {
    // TODO: Implement similarity search
    return ['Similar Disease 1', 'Similar Disease 2'];
  }

  static Future<Map<String, dynamic>> getTreatmentRecommendations(String disease) async {
    // TODO: Implement treatment lookup
    return {
      'treatments': ['Treatment 1', 'Treatment 2'],
      'medications': ['Medication 1', 'Medication 2'],
      'lifestyle': ['Rest', 'Hydration']
    };
  }
}

class DiseaseDatabase {
  static List<Map<String, dynamic>> diseases = [];
  
  static Future<void> loadDiseases() async {
    // TODO: Load from assets
    final String response = await rootBundle.loadString('assets/data/pediatric_disease_database.json');
    final data = await json.decode(response);
    diseases = List<Map<String, dynamic>>.from(data);
  }
  
  static List<Map<String, dynamic>> searchDiseases(String query) {
    return diseases.where((disease) => 
      disease['disease'].toString().toLowerCase().contains(query.toLowerCase()) ||
      disease['common_symptom'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
'''
            
            # Save Dart service
            dart_path = Path("beforedoctor/lib/services/disease_prediction_service.dart")
            dart_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(dart_path, 'w', encoding='utf-8') as f:
                f.write(dart_content)
            
            logger.info(f"💾 Flutter service saved: {dart_path}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Flutter integration creation failed: {e}")
            return False
    
    def generate_training_report(self):
        """Generate a comprehensive training report"""
        try:
            logger.info("📊 Generating training report...")
            
            report = {
                'training_date': datetime.now().isoformat(),
                'dataset_info': {
                    'total_records': len(self.df),
                    'disease_categories': self.df['disease_category'].value_counts().to_dict(),
                    'symptom_categories': self.df['symptom_category'].value_counts().to_dict()
                },
                'models_trained': [
                    'disease_classifier.pkl',
                    'symptom_matcher.pkl', 
                    'treatment_recommender.pkl',
                    'disease_vectorizer.pkl',
                    'disease_embeddings.pkl'
                ],
                'model_sizes': {},
                'training_metrics': {
                    'disease_classifier_accuracy': 'TBD',
                    'symptom_matcher_accuracy': 'TBD',
                    'treatment_recommender_accuracy': 'TBD'
                }
            }
            
            # Calculate model sizes
            for model_file in report['models_trained']:
                model_path = self.models_path / model_file
                if model_path.exists():
                    size_mb = model_path.stat().st_size / (1024 * 1024)
                    report['model_sizes'][model_file] = f"{size_mb:.2f} MB"
            
            # Save report
            report_path = self.models_path / "training_report.json"
            with open(report_path, 'w', encoding='utf-8') as f:
                json.dump(report, f, indent=2, default=str)
            
            logger.info(f"💾 Training report saved: {report_path}")
            logger.info("📊 Training Report Summary:")
            logger.info(f"  - Total records: {report['dataset_info']['total_records']}")
            logger.info(f"  - Disease categories: {len(report['dataset_info']['disease_categories'])}")
            logger.info(f"  - Models trained: {len(report['models_trained'])}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Training report generation failed: {e}")
            return False
    
    def run_training(self):
        """Run the complete training pipeline"""
        logger.info("🚀 Starting Disease Database Training Pipeline")
        logger.info("=" * 60)
        
        # Step 1: Load data
        if not self.load_data():
            return False
        
        # Step 2: Preprocess data
        if not self.preprocess_data():
            return False
        
        # Step 3: Train models
        training_success = True
        
        if not self.train_disease_classifier():
            training_success = False
        
        if not self.train_symptom_matcher():
            training_success = False
        
        if not self.train_treatment_recommender():
            training_success = False
        
        # Step 4: Create embeddings
        if not self.create_disease_embeddings():
            training_success = False
        
        # Step 5: Create Flutter integration
        if not self.create_flutter_integration():
            training_success = False
        
        # Step 6: Generate report
        if not self.generate_training_report():
            training_success = False
        
        logger.info("\n" + "=" * 60)
        if training_success:
            logger.info("🎉 Disease Database Training Completed Successfully!")
            logger.info("\n📁 Generated Files:")
            logger.info("- python/disease_database_training/models/disease_classifier.pkl")
            logger.info("- python/disease_database_training/models/symptom_matcher.pkl")
            logger.info("- python/disease_database_training/models/treatment_recommender.pkl")
            logger.info("- python/disease_database_training/models/disease_vectorizer.pkl")
            logger.info("- python/disease_database_training/models/disease_embeddings.pkl")
            logger.info("- beforedoctor/lib/services/disease_prediction_service.dart")
            logger.info("- python/disease_database_training/models/training_report.json")
        else:
            logger.error("❌ Disease Database Training Failed!")
        
        return training_success

def main():
    """Main training function"""
    trainer = DiseaseDatabaseTrainer()
    success = trainer.run_training()
    
    if success:
        print("\n✅ Disease Database Training Completed!")
        print("📋 Next Steps:")
        print("1. Integrate the trained models into your Flutter app")
        print("2. Test the disease prediction functionality")
        print("3. Update your voice logger to use the new disease models")
    else:
        print("\n❌ Disease Database Training Failed!")
        print("Please check the logs for details.")

if __name__ == "__main__":
    main() 