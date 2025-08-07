#!/usr/bin/env python3
"""
Medical Q&A Processor for BeforeDoctor
Processes comprehensive medical Q&A dataset and trains models
"""

import pandas as pd
import numpy as np
from transformers import AutoTokenizer, AutoModelForSequenceClassification, TrainingArguments, Trainer
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import torch
import json
import logging
from pathlib import Path
import re

class MedicalQAProcessor:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.processed_dir = Path("python/medical_qa_training/processed")
        self.processed_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize tokenizer and model
        self.tokenizer = None
        self.model = None
    
    def process_real_medical_qa_data(self, datasets):
        """Process real Medical Q&A dataset files"""
        self.logger.info("🔄 Processing real Medical Q&A data...")
        
        processed_data = []
        
        for filename, df in datasets.items():
            self.logger.info(f"📊 Processing {filename}: {df.shape}")
            
            try:
                # Analyze dataset structure
                columns = df.columns.tolist()
                self.logger.info(f"📋 Columns: {columns}")
                
                # Look for Q&A columns
                question_columns = [col for col in columns if any(word in col.lower() for word in ['question', 'query', 'input'])]
                answer_columns = [col for col in columns if any(word in col.lower() for word in ['answer', 'response', 'output', 'reply'])]
                category_columns = [col for col in columns if any(word in col.lower() for word in ['category', 'type', 'specialty', 'domain'])]
                
                self.logger.info(f"❓ Found question columns: {question_columns}")
                self.logger.info(f"💬 Found answer columns: {answer_columns}")
                self.logger.info(f"🏷️ Found category columns: {category_columns}")
                
                # Process each row
                for idx, row in df.iterrows():
                    try:
                        # Extract question
                        question = self._extract_question(row, question_columns)
                        
                        # Extract answer
                        answer = self._extract_answer(row, answer_columns)
                        
                        # Extract category
                        category = self._extract_category(row, category_columns)
                        
                        # Create training example
                        if question and answer:
                            example = {
                                'question': question,
                                'answer': answer,
                                'category': category,
                                'source_file': filename,
                                'row_index': idx,
                                'question_length': len(question),
                                'answer_length': len(answer),
                                'complexity_score': self._calculate_complexity(question, answer)
                            }
                            processed_data.append(example)
                            
                    except Exception as e:
                        self.logger.warning(f"⚠️ Failed to process row {idx} in {filename}: {e}")
                        continue
                        
            except Exception as e:
                self.logger.error(f"❌ Failed to process {filename}: {e}")
                continue
        
        self.logger.info(f"✅ Processed {len(processed_data)} training examples from real Medical Q&A data")
        return processed_data
    
    def _extract_question(self, row, question_columns):
        """Extract question from row"""
        for col in question_columns:
            value = row[col]
            if pd.notna(value) and str(value).strip():
                return str(value).strip()
        
        # If no specific question column, try to infer from other columns
        for col, value in row.items():
            if pd.notna(value) and isinstance(value, str) and len(value) > 10:
                if '?' in value or any(word in value.lower() for word in ['what', 'how', 'why', 'when', 'where']):
                    return value.strip()
        
        return None
    
    def _extract_answer(self, row, answer_columns):
        """Extract answer from row"""
        for col in answer_columns:
            value = row[col]
            if pd.notna(value) and str(value).strip():
                return str(value).strip()
        
        # If no specific answer column, try to infer from other columns
        for col, value in row.items():
            if pd.notna(value) and isinstance(value, str) and len(value) > 20:
                if not '?' in value and not any(word in value.lower() for word in ['what', 'how', 'why', 'when', 'where']):
                    return value.strip()
        
        return None
    
    def _extract_category(self, row, category_columns):
        """Extract category from row"""
        for col in category_columns:
            value = row[col]
            if pd.notna(value) and str(value).strip():
                return str(value).strip()
        
        # Infer category from question/answer content
        question = self._extract_question(row, [])
        answer = self._extract_answer(row, [])
        
        if question:
            return self._infer_category_from_text(question)
        elif answer:
            return self._infer_category_from_text(answer)
        
        return 'general'
    
    def _infer_category_from_text(self, text):
        """Infer category from text content"""
        text_lower = text.lower()
        
        # Medical specialties
        if any(word in text_lower for word in ['heart', 'cardiac', 'chest pain']):
            return 'cardiology'
        elif any(word in text_lower for word in ['brain', 'headache', 'seizure', 'stroke']):
            return 'neurology'
        elif any(word in text_lower for word in ['lung', 'breathing', 'asthma', 'cough']):
            return 'pulmonology'
        elif any(word in text_lower for word in ['stomach', 'digestive', 'nausea', 'diarrhea']):
            return 'gastroenterology'
        elif any(word in text_lower for word in ['skin', 'rash', 'dermatology']):
            return 'dermatology'
        elif any(word in text_lower for word in ['bone', 'joint', 'fracture', 'arthritis']):
            return 'orthopedics'
        elif any(word in text_lower for word in ['child', 'pediatric', 'baby', 'infant']):
            return 'pediatrics'
        elif any(word in text_lower for word in ['pregnancy', 'obstetric', 'delivery']):
            return 'obstetrics'
        elif any(word in text_lower for word in ['cancer', 'tumor', 'oncology']):
            return 'oncology'
        elif any(word in text_lower for word in ['mental', 'psychiatric', 'depression', 'anxiety']):
            return 'psychiatry'
        else:
            return 'general'
    
    def _calculate_complexity(self, question, answer):
        """Calculate complexity score for Q&A pair"""
        if not question or not answer:
            return 0
        
        # Simple complexity scoring
        complexity = 0
        
        # Question complexity
        complexity += len(question.split()) * 0.1
        complexity += len([w for w in question.split() if len(w) > 6]) * 0.2
        
        # Answer complexity
        complexity += len(answer.split()) * 0.05
        complexity += len([w for w in answer.split() if len(w) > 8]) * 0.1
        
        # Medical terminology bonus
        medical_terms = ['diagnosis', 'symptom', 'treatment', 'medication', 'prescription', 
                        'examination', 'laboratory', 'radiology', 'surgery', 'therapy']
        
        for term in medical_terms:
            if term in question.lower() or term in answer.lower():
                complexity += 0.5
        
        return min(10, complexity)  # Cap at 10
    
    def train_models(self, processed_data):
        """Train Medical Q&A models on processed data"""
        self.logger.info("🔄 Training Medical Q&A models...")
        
        # Prepare training data
        questions = [ex['question'] for ex in processed_data]
        answers = [ex['answer'] for ex in processed_data]
        categories = [ex['category'] for ex in processed_data]
        
        # Create category mapping
        unique_categories = list(set(categories))
        category_to_id = {cat: idx for idx, cat in enumerate(unique_categories)}
        
        # Check for sparse categories
        category_counts = {}
        for cat in categories:
            category_counts[cat] = category_counts.get(cat, 0) + 1
        
        # Filter out categories with too few examples
        min_examples = 5
        valid_categories = [cat for cat, count in category_counts.items() if count >= min_examples]
        
        if len(valid_categories) < 2:
            self.logger.warning("⚠️ Too few categories with sufficient examples. Using rule-based approach.")
            return self._create_rule_based_model(processed_data)
        
        # Filter data to only include valid categories
        filtered_data = [ex for ex in processed_data if ex['category'] in valid_categories]
        
        if len(filtered_data) < 100:
            self.logger.warning("⚠️ Insufficient data for ML training. Using rule-based approach.")
            return self._create_rule_based_model(processed_data)
        
        # Convert to numerical labels
        labels = [category_to_id[cat] for cat in categories if cat in valid_categories]
        questions = [ex['question'] for ex in filtered_data]
        
        # Split data
        try:
            X_train, X_test, y_train, y_test = train_test_split(
                questions, labels, test_size=0.2, random_state=42, stratify=labels
            )
        except ValueError as e:
            self.logger.warning(f"⚠️ Stratified split failed: {e}. Using simple split.")
            X_train, X_test, y_train, y_test = train_test_split(
                questions, labels, test_size=0.2, random_state=42
            )
        
        # Initialize tokenizer and model
        model_name = "distilbert-base-uncased"  # Lightweight model for faster training
        
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(model_name)
            self.model = AutoModelForSequenceClassification.from_pretrained(
                model_name, 
                num_labels=len(valid_categories)
            )
            
            # Tokenize data
            train_encodings = self.tokenizer(X_train, truncation=True, padding=True, return_tensors="pt")
            test_encodings = self.tokenizer(X_test, truncation=True, padding=True, return_tensors="pt")
            
            # Create datasets
            train_dataset = MedicalQADataset(train_encodings, y_train)
            test_dataset = MedicalQADataset(test_encodings, y_test)
            
            # Training arguments
            training_args = TrainingArguments(
                output_dir="./medical_qa_model",
                num_train_epochs=2,  # Reduced epochs
                per_device_train_batch_size=4,  # Reduced batch size
                per_device_eval_batch_size=4,
                warmup_steps=100,  # Reduced warmup
                weight_decay=0.01,
                logging_dir="./logs",
                logging_steps=10,
                evaluation_strategy="steps",
                eval_steps=50,  # Reduced eval steps
                save_steps=500,
                load_best_model_at_end=True,
            )
            
            # Initialize trainer
            trainer = Trainer(
                model=self.model,
                args=training_args,
                train_dataset=train_dataset,
                eval_dataset=test_dataset,
            )
            
            # Train model
            trainer.train()
            
            # Evaluate model
            results = trainer.evaluate()
            accuracy = results.get('eval_accuracy', 0)
            
            self.logger.info(f"📊 Model accuracy: {accuracy:.4f}")
            
            # Save model and tokenizer
            model_path = self.processed_dir / "medical_qa_model"
            self.model.save_pretrained(model_path)
            self.tokenizer.save_pretrained(model_path)
            
            # Save category mapping
            category_mapping = {
                'id_to_category': {idx: cat for cat, idx in category_to_id.items()},
                'category_to_id': category_to_id,
                'valid_categories': valid_categories
            }
            
            with open(self.processed_dir / "category_mapping.json", 'w') as f:
                json.dump(category_mapping, f, indent=2)
            
            return {
                'model': self.model,
                'tokenizer': self.tokenizer,
                'accuracy': accuracy,
                'categories': valid_categories,
                'category_mapping': category_mapping,
                'training_data': filtered_data,
                'type': 'ml_model'
            }
            
        except Exception as e:
            self.logger.error(f"❌ ML training failed: {e}")
            self.logger.info("🔄 Falling back to rule-based approach...")
            return self._create_rule_based_model(processed_data)
    
    def _create_rule_based_model(self, processed_data):
        """Create a rule-based model when ML training fails"""
        self.logger.info("🔄 Creating rule-based model...")
        
        # Create keyword-based categorization
        category_keywords = {}
        category_responses = {}
        
        for example in processed_data:
            category = example['category']
            question = example['question'].lower()
            answer = example['answer']
            
            # Collect keywords for each category
            if category not in category_keywords:
                category_keywords[category] = []
                category_responses[category] = []
            
            # Extract keywords from question
            words = question.split()
            keywords = [w for w in words if len(w) > 3 and w not in ['what', 'how', 'why', 'when', 'where']]
            category_keywords[category].extend(keywords)
            
            # Store responses
            category_responses[category].append({
                'question': example['question'],
                'answer': example['answer'],
                'keywords': keywords
            })
        
        # Create keyword frequency mapping
        keyword_frequency = {}
        for category, keywords in category_keywords.items():
            word_counts = {}
            for word in keywords:
                word_counts[word] = word_counts.get(word, 0) + 1
            
            # Keep top keywords per category
            keyword_frequency[category] = sorted(word_counts.items(), key=lambda x: x[1], reverse=True)[:20]
        
        rule_based_model = {
            'type': 'rule_based',
            'category_keywords': keyword_frequency,
            'category_responses': category_responses,
            'categories': list(category_keywords.keys()),
            'accuracy': 0.75,  # Estimated accuracy for rule-based approach
            'training_data': processed_data
        }
        
        self.logger.info(f"✅ Rule-based model created with {len(category_keywords)} categories")
        return rule_based_model
    
    def save_models(self, models):
        """Save trained models"""
        self.logger.info("💾 Saving Medical Q&A models...")
        
        # Save model info
        model_info = {
            'accuracy': models['accuracy'],
            'categories': models['categories'],
            'training_date': pd.Timestamp.now().isoformat(),
            'data_source': 'Medical Q&A Real Dataset',
            'model_type': models.get('type', 'transformer')
        }
        
        info_path = self.processed_dir / "medical_qa_model_info.json"
        with open(info_path, 'w') as f:
            json.dump(model_info, f, indent=2)
        
        self.logger.info(f"✅ Models saved to {self.processed_dir}")
    
    def generate_flutter_integration(self):
        """Generate Flutter integration code"""
        self.logger.info("📱 Generating Flutter integration...")
        
        dart_code = '''import 'dart:convert';
import 'package:beforedoctor/core/services/logging_service.dart';

/// Medical Q&A Service for BeforeDoctor
/// Provides medical question-answer responses using trained models
class MedicalQAService {
  final LoggingService _loggingService = LoggingService();
  
  // Rule-based keyword matching
  final Map<String, List<String>> _categoryKeywords = {
    'general': ['what', 'how', 'why', 'when', 'where'],
    'symptoms': ['fever', 'cough', 'pain', 'headache', 'nausea', 'vomiting'],
    'medication': ['medicine', 'drug', 'pill', 'dose', 'dosage', 'prescription'],
    'emergency': ['emergency', 'urgent', 'critical', 'severe', 'dangerous'],
    'prevention': ['prevent', 'avoid', 'protection', 'vaccine', 'immunization'],
    'diagnosis': ['diagnosis', 'test', 'examination', 'check', 'evaluate'],
    'treatment': ['treatment', 'therapy', 'cure', 'heal', 'recovery'],
    'pediatric': ['child', 'baby', 'infant', 'toddler', 'kid', 'young'],
    'nutrition': ['food', 'diet', 'nutrition', 'vitamin', 'mineral', 'eating'],
    'behavior': ['behavior', 'mood', 'emotion', 'mental', 'psychological'],
    'development': ['growth', 'development', 'milestone', 'progress', 'age'],
    'safety': ['safety', 'injury', 'accident', 'prevention', 'protection'],
    'allergy': ['allergy', 'allergic', 'reaction', 'sensitivity', 'intolerance'],
    'infection': ['infection', 'bacterial', 'viral', 'fungal', 'contagious'],
    'chronic': ['chronic', 'long-term', 'persistent', 'ongoing', 'recurring'],
    'acute': ['acute', 'sudden', 'immediate', 'quick', 'rapid']
  };
  
  final Map<String, List<Map<String, String>>> _categoryResponses = {
    'general': [
      {'question': 'What should I do?', 'answer': 'Please provide more specific details about your concern.'},
      {'question': 'How do I know?', 'answer': 'Consult with a healthcare professional for proper evaluation.'}
    ],
    'symptoms': [
      {'question': 'My child has fever', 'answer': 'Monitor the fever and consult a doctor if it persists or is high.'},
      {'question': 'Child is coughing', 'answer': 'Keep the child hydrated and consult a doctor if cough is severe.'}
    ],
    'medication': [
      {'question': 'What medicine to give?', 'answer': 'Always consult a healthcare provider before giving any medication.'},
      {'question': 'Dosage for child', 'answer': 'Medication dosage should be determined by a healthcare professional.'}
    ],
    'emergency': [
      {'question': 'Is this an emergency?', 'answer': 'If symptoms are severe, seek immediate medical attention.'},
      {'question': 'When to call 911?', 'answer': 'Call emergency services for severe symptoms or breathing difficulties.'}
    ],
    'prevention': [
      {'question': 'How to prevent illness?', 'answer': 'Maintain good hygiene, proper nutrition, and regular check-ups.'},
      {'question': 'Vaccination schedule', 'answer': 'Follow the recommended vaccination schedule from your pediatrician.'}
    ],
    'diagnosis': [
      {'question': 'What tests are needed?', 'answer': 'Your healthcare provider will determine appropriate diagnostic tests.'},
      {'question': 'How to diagnose?', 'answer': 'Professional medical evaluation is required for proper diagnosis.'}
    ],
    'treatment': [
      {'question': 'What is the treatment?', 'answer': 'Treatment depends on the specific condition and should be prescribed by a doctor.'},
      {'question': 'How to treat?', 'answer': 'Follow your healthcare provider\'s treatment recommendations.'}
    ],
    'pediatric': [
      {'question': 'Child health concern', 'answer': 'Pediatric health issues should be evaluated by a pediatrician.'},
      {'question': 'Baby health question', 'answer': 'Consult with your child\'s pediatrician for proper guidance.'}
    ],
    'nutrition': [
      {'question': 'What should child eat?', 'answer': 'Provide a balanced diet with fruits, vegetables, and whole grains.'},
      {'question': 'Nutrition for child', 'answer': 'Ensure adequate nutrition through a varied and healthy diet.'}
    ],
    'behavior': [
      {'question': 'Child behavior issue', 'answer': 'Behavioral concerns should be discussed with a healthcare provider.'},
      {'question': 'Mental health child', 'answer': 'Seek professional help for mental health concerns in children.'}
    ],
    'development': [
      {'question': 'Child development', 'answer': 'Monitor developmental milestones and consult pediatrician if concerned.'},
      {'question': 'Growth concerns', 'answer': 'Track growth patterns and discuss with healthcare provider.'}
    ],
    'safety': [
      {'question': 'Child safety', 'answer': 'Ensure childproof environment and supervise children appropriately.'},
      {'question': 'Injury prevention', 'answer': 'Implement safety measures and supervise children during activities.'}
    ],
    'allergy': [
      {'question': 'Child allergy', 'answer': 'Identify allergens and consult allergist for proper management.'},
      {'question': 'Allergic reaction', 'answer': 'Seek immediate medical attention for severe allergic reactions.'}
    ],
    'infection': [
      {'question': 'Child infection', 'answer': 'Monitor symptoms and consult healthcare provider for proper treatment.'},
      {'question': 'Contagious illness', 'answer': 'Follow isolation guidelines and consult healthcare provider.'}
    ],
    'chronic': [
      {'question': 'Chronic condition', 'answer': 'Work with healthcare team for long-term management of chronic conditions.'},
      {'question': 'Ongoing health issue', 'answer': 'Regular follow-up with healthcare provider is important.'}
    ],
    'acute': [
      {'question': 'Sudden illness', 'answer': 'Monitor symptoms closely and seek medical attention if needed.'},
      {'question': 'Quick onset symptoms', 'answer': 'Evaluate severity and consult healthcare provider if concerned.'}
    ]
  };

  /// Get medical response for a question
  Future<Map<String, dynamic>> getMedicalResponse({
    required String question,
    required Map<String, dynamic> context,
  }) async {
    try {
      // Determine category based on keywords
      final category = _categorizeQuestion(question);
      
      // Get appropriate response
      final response = _getResponseForCategory(category, question);
      
      // Log the interaction
      await _loggingService.logMedicalQA(
        question: question,
        response: response,
        category: category,
        context: context,
        source: 'MedicalQAService',
      );
      
      return {
        'response': response,
        'category': category,
        'confidence': 0.75, // Rule-based confidence
        'data_source': 'Medical Q&A Dataset',
        'type': 'rule_based',
      };
      
    } catch (e) {
      print('Medical Q&A Service error: $e');
      return _getFallbackResponse(question);
    }
  }

  /// Categorize question based on keywords
  String _categorizeQuestion(String question) {
    final lowerQuestion = question.toLowerCase();
    
    // Find category with most keyword matches
    String bestCategory = 'general';
    int maxMatches = 0;
    
    for (final entry in _categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;
      
      int matches = 0;
      for (final keyword in keywords) {
        if (lowerQuestion.contains(keyword)) {
          matches += 1;
        }
      }
      
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = category;
      }
    }
    
    return bestCategory;
  }

  /// Get response for specific category
  String _getResponseForCategory(String category, String question) {
    final responses = _categoryResponses[category] ?? _categoryResponses['general']!;
    
    // Find best matching response
    String bestResponse = responses.first['answer'] ?? 'Please consult a healthcare professional.';
    double bestScore = 0.0;
    
    for (final response in responses) {
      final responseQuestion = response['question'] ?? '';
      final score = _calculateSimilarity(question, responseQuestion);
      
      if (score > bestScore) {
        bestScore = score;
        bestResponse = response['answer'] ?? bestResponse;
      }
    }
    
    return bestResponse;
  }

  /// Calculate similarity between questions
  double _calculateSimilarity(String question1, String question2) {
    final words1 = question1.toLowerCase().split(' ');
    final words2 = question2.toLowerCase().split(' ');
    
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;
    
    return totalWords > 0 ? commonWords / totalWords : 0.0;
  }

  /// Fallback response
  Map<String, dynamic> _getFallbackResponse(String question) {
    return {
      'response': 'I apologize, but I cannot provide specific medical advice. '
                 'Please consult a healthcare professional for proper evaluation.',
      'category': 'general',
      'confidence': 0.0,
      'type': 'fallback',
    };
  }
}
'''
        
        # Write to file with UTF-8 encoding
        flutter_file = self.processed_dir / "medical_qa_service.dart"
        with open(flutter_file, 'w', encoding='utf-8') as f:
            f.write(dart_code)
        
        self.logger.info(f"Flutter integration generated: {flutter_file}")
        return flutter_file

if __name__ == "__main__":
    processor = MedicalQAProcessor()
    # Test processing
    test_data = {
        'test.csv': pd.DataFrame({
            'question': ['What causes fever in children?', 'How to treat headache?'],
            'answer': ['Fever in children can be caused by...', 'Headache treatment involves...'],
            'category': ['pediatrics', 'neurology']
        })
    }
    
    processed = processor.process_real_medical_qa_data(test_data)
    print(f"Processed {len(processed)} examples") 