#!/usr/bin/env python3
"""
Continuous Learning Trainer for BeforeDoctor
Trains models on real user interaction data collected from the app
"""

import json
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, accuracy_score, precision_recall_fscore_support
import joblib
import os
import logging
from datetime import datetime, timedelta
from pathlib import Path
import argparse

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ContinuousLearningTrainer:
    def __init__(self, learning_data_dir='learning_data'):
        self.learning_data_dir = Path(learning_data_dir)
        self.models_dir = Path('models')
        self.models_dir.mkdir(exist_ok=True)
        
        # Model files
        self.symptom_model_path = self.models_dir / 'continuous_symptom_classifier.pkl'
        self.risk_model_path = self.models_dir / 'continuous_risk_assessor.pkl'
        self.followup_model_path = self.models_dir / 'continuous_followup_generator.pkl'
        
        # Vectorizers
        self.text_vectorizer_path = self.models_dir / 'continuous_text_vectorizer.pkl'
        self.feature_vectorizer_path = self.models_dir / 'continuous_feature_vectorizer.pkl'
        
        # Performance tracking
        self.performance_file = self.models_dir / 'continuous_model_performance.json'
        
    def load_learning_data(self):
        """Load user interaction data from Flutter app"""
        try:
            interactions_file = self.learning_data_dir / 'user_interactions.jsonl'
            
            if not interactions_file.exists():
                logger.warning("No learning data found")
                return None
            
            # Load JSONL data
            interactions = []
            with open(interactions_file, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.strip():
                        try:
                            interactions.append(json.loads(line))
                        except json.JSONDecodeError:
                            continue
            
            logger.info(f"Loaded {len(interactions)} interaction records")
            return interactions
            
        except Exception as e:
            logger.error(f"Error loading learning data: {e}")
            return None
    
    def prepare_training_data(self, interactions):
        """Prepare training data from interactions"""
        try:
            if not interactions:
                return None, None, None
            
            # Convert to DataFrame
            df = pd.DataFrame(interactions)
            
            # Filter high-quality interactions
            quality_threshold = 0.7
            df_quality = df[df['quality_score'] >= quality_threshold].copy()
            
            logger.info(f"Quality interactions: {len(df_quality)}/{len(df)}")
            
            if len(df_quality) < 100:
                logger.warning("Insufficient quality data for training")
                return None, None, None
            
            # Prepare features for different models
            training_data = {}
            
            # 1. Symptom Classification Model
            training_data['symptom'] = self._prepare_symptom_data(df_quality)
            
            # 2. Risk Assessment Model
            training_data['risk'] = self._prepare_risk_data(df_quality)
            
            # 3. Follow-up Question Model
            training_data['followup'] = self._prepare_followup_data(df_quality)
            
            return training_data
            
        except Exception as e:
            logger.error(f"Error preparing training data: {e}")
            return None
    
    def _prepare_symptom_data(self, df):
        """Prepare data for symptom classification"""
        try:
            # Extract symptoms from cloud AI responses
            symptoms_data = []
            
            for _, row in df.iterrows():
                try:
                    user_input = str(row['user_input']).lower()
                    cloud_response = row['cloud_ai_response']
                    
                    if 'symptoms' in cloud_response and cloud_response['symptoms']:
                        symptoms = cloud_response['symptoms']
                        if isinstance(symptoms, list):
                            for symptom in symptoms:
                                symptoms_data.append({
                                    'text': user_input,
                                    'symptom': symptom,
                                    'quality': row['quality_score']
                                })
                except Exception as e:
                    continue
            
            if not symptoms_data:
                return None
            
            symptom_df = pd.DataFrame(symptoms_data)
            logger.info(f"Prepared {len(symptom_df)} symptom training examples")
            
            return symptom_df
            
        except Exception as e:
            logger.error(f"Error preparing symptom data: {e}")
            return None
    
    def _prepare_risk_data(self, df):
        """Prepare data for risk assessment"""
        try:
            risk_data = []
            
            for _, row in df.iterrows():
                try:
                    cloud_response = row['cloud_ai_response']
                    child_context = row['child_context']
                    
                    if 'risk_level' in cloud_response and 'symptoms' in cloud_response:
                        risk_data.append({
                            'age': child_context.get('child_age', 5),
                            'symptoms': cloud_response['symptoms'],
                            'risk_level': cloud_response['risk_level'],
                            'severity': cloud_response.get('severity', 'unknown'),
                            'quality': row['quality_score']
                        })
                except Exception as e:
                    continue
            
            if not risk_data:
                return None
            
            risk_df = pd.DataFrame(risk_data)
            logger.info(f"Prepared {len(risk_df)} risk assessment examples")
            
            return risk_df
            
        except Exception as e:
            logger.error(f"Error preparing risk data: {e}")
            return None
    
    def _prepare_followup_data(self, df):
        """Prepare data for follow-up question generation"""
        try:
            followup_data = []
            
            for _, row in df.iterrows():
                try:
                    user_input = str(row['user_input']).lower()
                    cloud_response = row['cloud_ai_response']
                    child_context = row['child_context']
                    
                    if 'follow_up_questions' in cloud_response and cloud_response['follow_up_questions']:
                        questions = cloud_response['follow_up_questions']
                        if isinstance(questions, list):
                            for question in questions:
                                followup_data.append({
                                    'user_input': user_input,
                                    'symptoms': cloud_response.get('symptoms', []),
                                    'age': child_context.get('child_age', 5),
                                    'followup_question': question,
                                    'quality': row['quality_score']
                                })
                except Exception as e:
                    continue
            
            if not followup_data:
                return None
            
            followup_df = pd.DataFrame(followup_data)
            logger.info(f"Prepared {len(followup_df)} follow-up question examples")
            
            return followup_df
            
        except Exception as e:
            logger.error(f"Error preparing followup data: {e}")
            return None
    
    def train_models(self, training_data):
        """Train models on the prepared data"""
        try:
            if not training_data:
                logger.warning("No training data available")
                return False
            
            models_trained = {}
            
            # 1. Train Symptom Classification Model
            if training_data.get('symptom') is not None:
                models_trained['symptom'] = self._train_symptom_model(training_data['symptom'])
            
            # 2. Train Risk Assessment Model
            if training_data.get('risk') is not None:
                models_trained['risk'] = self._train_risk_model(training_data['risk'])
            
            # 3. Train Follow-up Question Model
            if training_data.get('followup') is not None:
                models_trained['followup'] = self._train_followup_model(training_data['followup'])
            
            # Save performance metrics
            self._save_performance_metrics(models_trained)
            
            return any(models_trained.values())
            
        except Exception as e:
            logger.error(f"Error training models: {e}")
            return False
    
    def _train_symptom_model(self, df):
        """Train symptom classification model"""
        try:
            # Prepare features
            X = df['text'].values
            y = df['symptom'].values
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, random_state=42, stratify=y
            )
            
            # Vectorize text
            vectorizer = TfidfVectorizer(max_features=1000, stop_words='english')
            X_train_vec = vectorizer.fit_transform(X_train)
            X_test_vec = vectorizer.transform(X_test)
            
            # Train model
            model = RandomForestClassifier(n_estimators=100, random_state=42)
            model.fit(X_train_vec, y_train)
            
            # Evaluate
            y_pred = model.predict(X_test_vec)
            accuracy = accuracy_score(y_test, y_pred)
            
            logger.info(f"Symptom model accuracy: {accuracy:.3f}")
            
            # Save model and vectorizer
            joblib.dump(model, self.symptom_model_path)
            joblib.dump(vectorizer, self.text_vectorizer_path)
            
            return {
                'accuracy': accuracy,
                'model_path': str(self.symptom_model_path),
                'vectorizer_path': str(self.text_vectorizer_path)
            }
            
        except Exception as e:
            logger.error(f"Error training symptom model: {e}")
            return None
    
    def _train_risk_model(self, df):
        """Train risk assessment model"""
        try:
            # Prepare features
            df_features = df.copy()
            
            # Encode categorical variables
            le_symptoms = LabelEncoder()
            le_risk = LabelEncoder()
            le_severity = LabelEncoder()
            
            # Create symptom encoding (flatten list of symptoms)
            all_symptoms = []
            for symptoms in df_features['symptoms']:
                if isinstance(symptoms, list):
                    all_symptoms.extend(symptoms)
                else:
                    all_symptoms.append(str(symptoms))
            
            le_symptoms.fit(all_symptoms)
            
            # Create feature matrix
            feature_data = []
            for _, row in df_features.iterrows():
                symptoms = row['symptoms'] if isinstance(row['symptoms'], list) else [row['symptoms']]
                symptom_encoded = [le_symptoms.transform([s])[0] for s in symptoms if s in le_symptoms.classes_]
                
                # Create feature vector
                features = [
                    row['age'],
                    np.mean(symptom_encoded) if symptom_encoded else 0,
                    len(symptoms),
                    row['quality']
                ]
                feature_data.append(features)
            
            X = np.array(feature_data)
            y_risk = le_risk.fit_transform(df_features['risk_level'])
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                X, y_risk, test_size=0.2, random_state=42, stratify=y_risk
            )
            
            # Train model
            model = RandomForestClassifier(n_estimators=100, random_state=42)
            model.fit(X_train, y_train)
            
            # Evaluate
            y_pred = model.predict(X_test)
            accuracy = accuracy_score(y_test, y_pred)
            
            logger.info(f"Risk model accuracy: {accuracy:.3f}")
            
            # Save model
            joblib.dump(model, self.risk_model_path)
            
            return {
                'accuracy': accuracy,
                'model_path': str(self.risk_model_path)
            }
            
        except Exception as e:
            logger.error(f"Error training risk model: {e}")
            return None
    
    def _train_followup_model(self, df):
        """Train follow-up question generation model"""
        try:
            # For now, we'll create a simple rule-based model
            # In the future, this could be a more sophisticated NLP model
            
            # Group by symptoms and age to find common follow-up patterns
            followup_patterns = {}
            
            for _, row in df.iterrows():
                symptoms_key = tuple(sorted(row['symptoms']))
                age_group = self._get_age_group(row['age'])
                
                key = (symptoms_key, age_group)
                if key not in followup_patterns:
                    followup_patterns[key] = []
                
                followup_patterns[key].append(row['followup_question'])
            
            # Save patterns
            patterns_file = self.models_dir / 'followup_patterns.json'
            with open(patterns_file, 'w') as f:
                json.dump(followup_patterns, f, indent=2)
            
            logger.info(f"Saved {len(followup_patterns)} follow-up question patterns")
            
            return {
                'patterns_count': len(followup_patterns),
                'patterns_file': str(patterns_file)
            }
            
        except Exception as e:
            logger.error(f"Error training followup model: {e}")
            return None
    
    def _get_age_group(self, age):
        """Convert age to age group"""
        if age < 2:
            return '0-2'
        elif age < 6:
            return '3-5'
        elif age < 13:
            return '6-12'
        else:
            return '13-17'
    
    def _save_performance_metrics(self, models_trained):
        """Save model performance metrics"""
        try:
            performance = {
                'training_date': datetime.now().isoformat(),
                'models_trained': list(models_trained.keys()),
                'performance_metrics': {},
                'model_files': {}
            }
            
            for model_name, result in models_trained.items():
                if result:
                    performance['performance_metrics'][model_name] = {
                        'accuracy': result.get('accuracy', 'N/A'),
                        'status': 'trained'
                    }
                    performance['model_files'][model_name] = result.get('model_path', 'N/A')
                else:
                    performance['performance_metrics'][model_name] = {
                        'status': 'failed'
                    }
            
            # Save performance data
            with open(self.performance_file, 'w') as f:
                json.dump(performance, f, indent=2)
            
            logger.info("Performance metrics saved")
            
        except Exception as e:
            logger.error(f"Error saving performance metrics: {e}")
    
    def run_training_pipeline(self):
        """Run the complete training pipeline"""
        try:
            logger.info("🚀 Starting continuous learning training pipeline...")
            
            # Load learning data
            interactions = self.load_learning_data()
            if not interactions:
                logger.warning("No learning data available")
                return False
            
            # Prepare training data
            training_data = self.prepare_training_data(interactions)
            if not training_data:
                logger.warning("No training data prepared")
                return False
            
            # Train models
            success = self.train_models(training_data)
            
            if success:
                logger.info("✅ Continuous learning training completed successfully")
            else:
                logger.warning("⚠️ Some models failed to train")
            
            return success
            
        except Exception as e:
            logger.error(f"❌ Training pipeline failed: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description='Continuous Learning Trainer for BeforeDoctor')
    parser.add_argument('--data-dir', default='learning_data', help='Directory containing learning data')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    trainer = ContinuousLearningTrainer(args.data_dir)
    success = trainer.run_training_pipeline()
    
    if success:
        print("✅ Training completed successfully")
        exit(0)
    else:
        print("❌ Training failed")
        exit(1)

if __name__ == "__main__":
    main()
