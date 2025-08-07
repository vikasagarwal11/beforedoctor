#!/usr/bin/env python3
"""
Diseases_Symptoms Training Module for BeforeDoctor
Downloads and trains on Hugging Face Diseases_Symptoms dataset
"""

import os
import sys
import json
import logging
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime
from datasets import load_dataset
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score
import joblib
import pickle

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DiseasesSymptomsTrainer:
    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.data_dir = self.base_dir / "data"
        self.processed_dir = self.base_dir / "processed"
        self.models_dir = self.base_dir / "models"
        self.outputs_dir = self.base_dir / "outputs"
        
        # Create directories
        for dir_path in [self.data_dir, self.processed_dir, self.models_dir, self.outputs_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
        
        self.dataset = None
        self.train_data = None
        self.test_data = None
        self.vectorizer = None
        self.classifier = None
        
    def download_dataset(self):
        """Download the Diseases_Symptoms dataset from Hugging Face"""
        try:
            logger.info("🔄 Downloading Diseases_Symptoms dataset from Hugging Face...")
            
            # Load dataset from Hugging Face
            self.dataset = load_dataset("QuyenAnhDE/Diseases_Symptoms")
            
            logger.info(f"✅ Dataset loaded successfully!")
            logger.info(f"📊 Dataset info: {self.dataset}")
            
            # Save raw dataset info
            dataset_info = {
                "dataset_name": "QuyenAnhDE/Diseases_Symptoms",
                "download_timestamp": datetime.now().isoformat(),
                "splits": list(self.dataset.keys()),
                "features": list(self.dataset['train'].features.keys()) if 'train' in self.dataset else [],
                "total_records": len(self.dataset['train']) if 'train' in self.dataset else 0
            }
            
            with open(self.data_dir / "dataset_info.json", "w") as f:
                json.dump(dataset_info, f, indent=2)
            
            logger.info(f"📄 Dataset info saved to: {self.data_dir / 'dataset_info.json'}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to download dataset: {e}")
            return False
    
    def process_dataset(self):
        """Process the dataset for training"""
        try:
            logger.info("🔄 Processing Diseases_Symptoms dataset...")
            
            # Convert to pandas DataFrame for easier processing
            if 'train' in self.dataset:
                df = self.dataset['train'].to_pandas()
            else:
                # If no train split, use the first available split
                df = list(self.dataset.values())[0].to_pandas()
            
            logger.info(f"📊 Original dataset shape: {df.shape}")
            logger.info(f"📋 Columns: {list(df.columns)}")
            
            # Display sample data
            logger.info("📄 Sample data:")
            logger.info(df.head())
            
            # Clean and prepare data
            df_processed = self._clean_data(df)
            
            # Split into train/test
            self.train_data, self.test_data = train_test_split(
                df_processed, test_size=0.2, random_state=42, stratify=df_processed['label'] if 'label' in df_processed.columns else None
            )
            
            logger.info(f"📊 Training set size: {len(self.train_data)}")
            logger.info(f"📊 Test set size: {len(self.test_data)}")
            
            # Save processed data
            self.train_data.to_csv(self.processed_dir / "train_data.csv", index=False)
            self.test_data.to_csv(self.processed_dir / "test_data.csv", index=False)
            
            logger.info("✅ Dataset processing completed!")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to process dataset: {e}")
            return False
    
    def _clean_data(self, df):
        """Clean and prepare the dataset"""
        logger.info("🧹 Cleaning dataset...")
        
        # Remove duplicates
        df_clean = df.drop_duplicates()
        logger.info(f"📊 After removing duplicates: {df_clean.shape}")
        
        # Handle missing values
        df_clean = df_clean.dropna()
        logger.info(f"📊 After removing missing values: {df_clean.shape}")
        
        # Create text features for classification
        if 'symptoms' in df_clean.columns and 'diseases' in df_clean.columns:
            # Combine symptoms and diseases for better classification
            df_clean['text_features'] = df_clean['symptoms'].astype(str) + " " + df_clean['diseases'].astype(str)
        elif 'symptoms' in df_clean.columns:
            df_clean['text_features'] = df_clean['symptoms'].astype(str)
        elif 'diseases' in df_clean.columns:
            df_clean['text_features'] = df_clean['diseases'].astype(str)
        else:
            # Use all text columns
            text_columns = [col for col in df_clean.columns if df_clean[col].dtype == 'object']
            if text_columns:
                df_clean['text_features'] = df_clean[text_columns].astype(str).agg(' '.join, axis=1)
            else:
                logger.error("❌ No suitable text columns found for classification")
                return df_clean
        
        # Create labels for classification (use diseases as labels if available)
        if 'diseases' in df_clean.columns:
            df_clean['label'] = df_clean['diseases']
        elif 'disease' in df_clean.columns:
            df_clean['label'] = df_clean['disease']
        else:
            # Create a generic label
            df_clean['label'] = 'medical_condition'
        
        # Keep only necessary columns
        columns_to_keep = ['text_features', 'label']
        if 'symptoms' in df_clean.columns:
            columns_to_keep.append('symptoms')
        if 'diseases' in df_clean.columns:
            columns_to_keep.append('diseases')
        if 'treatments' in df_clean.columns:
            columns_to_keep.append('treatments')
        
        df_clean = df_clean[columns_to_keep]
        
        logger.info(f"📊 Final processed dataset shape: {df_clean.shape}")
        logger.info(f"📋 Final columns: {list(df_clean.columns)}")
        
        return df_clean
    
    def train_models(self):
        """Train classification models"""
        try:
            logger.info("🔄 Training Diseases_Symptoms classification models...")
            
            # Prepare text features
            X_train = self.train_data['text_features']
            y_train = self.train_data['label']
            X_test = self.test_data['text_features']
            y_test = self.test_data['label']
            
            # Create TF-IDF vectorizer
            self.vectorizer = TfidfVectorizer(
                max_features=5000,
                ngram_range=(1, 2),
                stop_words='english',
                min_df=2
            )
            
            # Transform text to features
            X_train_vectors = self.vectorizer.fit_transform(X_train)
            X_test_vectors = self.vectorizer.transform(X_test)
            
            logger.info(f"📊 Feature matrix shape: {X_train_vectors.shape}")
            
            # Train Random Forest classifier
            self.classifier = RandomForestClassifier(
                n_estimators=100,
                random_state=42,
                n_jobs=-1
            )
            
            self.classifier.fit(X_train_vectors, y_train)
            
            # Make predictions
            y_pred = self.classifier.predict(X_test_vectors)
            
            # Calculate accuracy
            accuracy = accuracy_score(y_test, y_pred)
            
            # Generate classification report
            report = classification_report(y_test, y_pred, output_dict=True)
            
            # Save results
            results = {
                "model_type": "RandomForest",
                "accuracy": accuracy,
                "classification_report": report,
                "training_timestamp": datetime.now().isoformat(),
                "feature_count": X_train_vectors.shape[1],
                "training_samples": len(X_train),
                "test_samples": len(X_test)
            }
            
            with open(self.outputs_dir / "training_results.json", "w") as f:
                json.dump(results, f, indent=2)
            
            # Save models
            joblib.dump(self.vectorizer, self.models_dir / "diseases_symptoms_vectorizer.pkl")
            joblib.dump(self.classifier, self.models_dir / "diseases_symptoms_classifier.pkl")
            
            logger.info(f"✅ Training completed!")
            logger.info(f"📊 Accuracy: {accuracy:.4f}")
            logger.info(f"📄 Results saved to: {self.outputs_dir / 'training_results.json'}")
            logger.info(f"💾 Models saved to: {self.models_dir}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to train models: {e}")
            return False
    
    def create_flutter_integration(self):
        """Create Flutter integration code"""
        try:
            logger.info("🔄 Creating Flutter integration...")
            
            flutter_code = '''
// Diseases_Symptoms Model Integration for Flutter
// Generated on: ''' + datetime.now().isoformat() + '''

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DiseasesSymptomsModel {
  static const String _modelUrl = 'YOUR_MODEL_ENDPOINT';
  
  static Future<Map<String, dynamic>> predictDisease(List<String> symptoms) async {
    try {
      final response = await http.post(
        Uri.parse('$_modelUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'symptoms': symptoms,
          'model_type': 'diseases_symptoms'
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error predicting disease: $e');
    }
  }
  
  static Future<List<String>> getCommonSymptoms() async {
    // Return common symptoms from the dataset
    return [
      'fever',
      'cough',
      'headache',
      'fatigue',
      'nausea',
      'vomiting',
      'diarrhea',
      'abdominal pain',
      'sore throat',
      'runny nose'
    ];
  }
  
  static Future<Map<String, String>> getDiseaseTreatments() async {
    // Return disease-treatment mappings
    return {
      'viral fever': 'Rest, fluids, acetaminophen',
      'common cold': 'Rest, fluids, over-the-counter medications',
      'stomach flu': 'Rest, fluids, bland diet',
      'migraine': 'Pain relievers, rest in dark room',
      'pneumonia': 'Antibiotics, rest, fluids'
    };
  }
}
''';
            
            # Save Flutter integration code
            with open(self.outputs_dir / "diseases_symptoms_flutter_integration.dart", "w") as f:
                f.write(flutter_code)
            
            logger.info(f"✅ Flutter integration created: {self.outputs_dir / 'diseases_symptoms_flutter_integration.dart'}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to create Flutter integration: {e}")
            return False
    
    def run_complete_pipeline(self):
        """Run the complete training pipeline"""
        logger.info("🚀 Starting Diseases_Symptoms training pipeline...")
        
        steps = [
            ("Download Dataset", self.download_dataset),
            ("Process Dataset", self.process_dataset),
            ("Train Models", self.train_models),
            ("Create Flutter Integration", self.create_flutter_integration)
        ]
        
        results = {}
        
        for step_name, step_func in steps:
            logger.info(f"\n{'='*50}")
            logger.info(f"🔄 Step: {step_name}")
            logger.info(f"{'='*50}")
            
            try:
                success = step_func()
                results[step_name] = "✅ Success" if success else "❌ Failed"
                
                if not success:
                    logger.error(f"❌ Pipeline failed at step: {step_name}")
                    break
                    
            except Exception as e:
                logger.error(f"❌ Error in step {step_name}: {e}")
                results[step_name] = f"❌ Error: {e}"
                break
        
        # Generate summary
        logger.info(f"\n{'='*50}")
        logger.info("📊 Training Pipeline Summary")
        logger.info(f"{'='*50}")
        
        for step_name, result in results.items():
            logger.info(f"{step_name}: {result}")
        
        # Save summary
        with open(self.outputs_dir / "pipeline_summary.json", "w") as f:
            json.dump({
                "pipeline_timestamp": datetime.now().isoformat(),
                "results": results
            }, f, indent=2)
        
        logger.info(f"\n📄 Summary saved to: {self.outputs_dir / 'pipeline_summary.json'}")
        
        return all("✅ Success" in result for result in results.values())

def main():
    """Main function"""
    trainer = DiseasesSymptomsTrainer()
    success = trainer.run_complete_pipeline()
    
    if success:
        logger.info("\n🎉 Diseases_Symptoms training pipeline completed successfully!")
        sys.exit(0)
    else:
        logger.error("\n❌ Diseases_Symptoms training pipeline failed!")
        sys.exit(1)

if __name__ == "__main__":
    main() 