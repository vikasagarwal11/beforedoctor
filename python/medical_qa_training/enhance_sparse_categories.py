#!/usr/bin/env python3
"""
Enhance Sparse Categories for Medical Q&A Training
This script addresses the sparse categories issue by:
1. Generating synthetic data for sparse categories
2. Combining multiple medical Q&A datasets
3. Implementing confidence scoring
"""

import json
import logging
from pathlib import Path
from typing import Dict, List, Tuple
import pandas as pd
from transformers import pipeline
import openai
import os

class SparseCategoryEnhancer:
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.setup_logging()
        
        # Load existing category analysis
        self.sparse_categories = self._load_sparse_categories()
        
    def setup_logging(self):
        """Setup logging configuration"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    def _load_sparse_categories(self) -> Dict[str, int]:
        """Load analysis of sparse categories from previous training"""
        try:
            with open("medical_qa_training/processed/category_analysis.json", 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            # Default sparse categories based on typical medical Q&A data
            return {
                'rare_conditions': 2,
                'specialized_treatments': 3,
                'emergency_procedures': 1,
                'pediatric_specialties': 4,
                'genetic_disorders': 1,
                'rare_infections': 2
            }
    
    def generate_synthetic_data(self, category: str, count: int = 10) -> List[Dict]:
        """Generate synthetic Q&A pairs for sparse categories"""
        self.logger.info(f"🔄 Generating {count} synthetic examples for category: {category}")
        
        # Template-based generation for medical accuracy
        templates = self._get_category_templates(category)
        synthetic_data = []
        
        for i in range(count):
            template = templates[i % len(templates)]
            question = template['question'].format(
                symptom=self._get_random_symptom(),
                age=self._get_random_age(),
                condition=self._get_random_condition()
            )
            answer = template['answer'].format(
                recommendation=self._get_recommendation(category)
            )
            
            synthetic_data.append({
                'question': question,
                'answer': answer,
                'category': category,
                'source': 'synthetic',
                'confidence': 0.8  # High confidence for synthetic data
            })
        
        return synthetic_data
    
    def _get_category_templates(self, category: str) -> List[Dict]:
        """Get question-answer templates for specific categories"""
        templates = {
            'rare_conditions': [
                {
                    'question': 'What are the symptoms of {condition} in a {age} year old child?',
                    'answer': 'Symptoms may include {symptom}. Consult a pediatrician for proper diagnosis and treatment.'
                },
                {
                    'question': 'How is {condition} diagnosed in children?',
                    'answer': 'Diagnosis involves {symptom} evaluation. {recommendation}'
                }
            ],
            'specialized_treatments': [
                {
                    'question': 'What treatment options are available for {condition}?',
                    'answer': 'Treatment depends on severity. {recommendation}'
                },
                {
                    'question': 'Are there specialized treatments for {condition} in children?',
                    'answer': 'Yes, pediatric specialists may recommend {recommendation}'
                }
            ],
            'emergency_procedures': [
                {
                    'question': 'When should I seek emergency care for {symptom}?',
                    'answer': 'Seek immediate medical attention if {symptom} is severe. {recommendation}'
                }
            ],
            'pediatric_specialties': [
                {
                    'question': 'What pediatric specialist should I consult for {condition}?',
                    'answer': 'Consult a pediatric {specialty} specialist. {recommendation}'
                }
            ]
        }
        
        return templates.get(category, [
            {
                'question': 'What should I know about {condition}?',
                'answer': 'Consult a healthcare professional. {recommendation}'
            }
        ])
    
    def _get_random_symptom(self) -> str:
        """Get random symptom for template filling"""
        symptoms = [
            'fever', 'cough', 'rash', 'vomiting', 'diarrhea',
            'headache', 'fatigue', 'loss of appetite', 'pain'
        ]
        return symptoms[len(symptoms) % 9]  # Simple randomization
    
    def _get_random_age(self) -> str:
        """Get random age for template filling"""
        ages = ['2', '5', '8', '12', '15']
        return ages[len(ages) % 5]
    
    def _get_random_condition(self) -> str:
        """Get random condition for template filling"""
        conditions = [
            'asthma', 'diabetes', 'allergies', 'infection',
            'developmental delay', 'behavioral issue'
        ]
        return conditions[len(conditions) % 6]
    
    def _get_recommendation(self, category: str) -> str:
        """Get category-specific recommendation"""
        recommendations = {
            'rare_conditions': 'Schedule consultation with pediatric specialist.',
            'specialized_treatments': 'Follow treatment plan from healthcare provider.',
            'emergency_procedures': 'Contact emergency services if symptoms worsen.',
            'pediatric_specialties': 'Schedule appointment with appropriate specialist.'
        }
        return recommendations.get(category, 'Consult healthcare professional.')
    
    def combine_datasets(self, datasets: List[Path]) -> List[Dict]:
        """Combine multiple medical Q&A datasets"""
        self.logger.info(f"🔄 Combining {len(datasets)} datasets...")
        
        combined_data = []
        
        for dataset_path in datasets:
            if dataset_path.exists():
                try:
                    if dataset_path.suffix == '.csv':
                        df = pd.read_csv(dataset_path)
                    elif dataset_path.suffix == '.json':
                        with open(dataset_path, 'r') as f:
                            data = json.load(f)
                            df = pd.DataFrame(data)
                    else:
                        continue
                    
                    # Process dataset
                    processed = self._process_dataset(df, dataset_path.stem)
                    combined_data.extend(processed)
                    
                except Exception as e:
                    self.logger.error(f"❌ Error processing {dataset_path}: {e}")
        
        return combined_data
    
    def _process_dataset(self, df: pd.DataFrame, source: str) -> List[Dict]:
        """Process individual dataset"""
        processed = []
        
        # Identify question and answer columns
        question_cols = [col for col in df.columns if 'question' in col.lower()]
        answer_cols = [col for col in df.columns if 'answer' in col.lower() or 'response' in col.lower()]
        category_cols = [col for col in df.columns if 'category' in col.lower() or 'type' in col.lower()]
        
        for _, row in df.iterrows():
            question = self._extract_text(row, question_cols)
            answer = self._extract_text(row, answer_cols)
            category = self._extract_category(row, category_cols, question)
            
            if question and answer:
                processed.append({
                    'question': question,
                    'answer': answer,
                    'category': category,
                    'source': source,
                    'confidence': 0.9  # High confidence for real data
                })
        
        return processed
    
    def _extract_text(self, row: pd.Series, columns: List[str]) -> str:
        """Extract text from row using available columns"""
        for col in columns:
            if col in row and pd.notna(row[col]):
                return str(row[col]).strip()
        return ""
    
    def _extract_category(self, row: pd.Series, columns: List[str], question: str) -> str:
        """Extract or infer category"""
        for col in columns:
            if col in row and pd.notna(row[col]):
                return str(row[col]).strip()
        
        # Infer category from question content
        return self._infer_category_from_question(question)
    
    def _infer_category_from_question(self, question: str) -> str:
        """Infer category from question content"""
        question_lower = question.lower()
        
        if any(word in question_lower for word in ['emergency', 'urgent', 'critical']):
            return 'emergency_procedures'
        elif any(word in question_lower for word in ['rare', 'unusual', 'uncommon']):
            return 'rare_conditions'
        elif any(word in question_lower for word in ['treatment', 'therapy', 'medication']):
            return 'specialized_treatments'
        elif any(word in question_lower for word in ['pediatric', 'child', 'baby']):
            return 'pediatric_specialties'
        else:
            return 'general'
    
    def implement_confidence_scoring(self, data: List[Dict]) -> List[Dict]:
        """Implement confidence scoring for responses"""
        self.logger.info("🔄 Implementing confidence scoring...")
        
        for item in data:
            # Calculate confidence based on multiple factors
            confidence = self._calculate_confidence(item)
            item['confidence'] = confidence
            
            # Add confidence-based recommendations
            if confidence < 0.6:
                item['recommendation'] = 'Consult healthcare professional for verification.'
            elif confidence < 0.8:
                item['recommendation'] = 'Consider consulting specialist for complex cases.'
            else:
                item['recommendation'] = 'Standard medical guidance applies.'
        
        return data
    
    def _calculate_confidence(self, item: Dict) -> float:
        """Calculate confidence score for response"""
        base_confidence = item.get('confidence', 0.7)
        
        # Adjust based on source
        if item.get('source') == 'synthetic':
            base_confidence *= 0.8  # Reduce confidence for synthetic data
        
        # Adjust based on category complexity
        category = item.get('category', 'general')
        if category in ['rare_conditions', 'emergency_procedures']:
            base_confidence *= 0.9  # Slightly reduce for complex categories
        
        # Adjust based on response length (longer responses may be more comprehensive)
        answer_length = len(item.get('answer', ''))
        if answer_length > 200:
            base_confidence *= 1.1
        elif answer_length < 50:
            base_confidence *= 0.9
        
        return min(base_confidence, 1.0)  # Cap at 1.0
    
    def save_enhanced_data(self, data: List[Dict], output_path: Path):
        """Save enhanced dataset"""
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"✅ Enhanced data saved to {output_path}")
        self.logger.info(f"📊 Total examples: {len(data)}")
        
        # Generate category statistics
        category_stats = {}
        for item in data:
            category = item.get('category', 'unknown')
            category_stats[category] = category_stats.get(category, 0) + 1
        
        self.logger.info("📈 Category distribution:")
        for category, count in sorted(category_stats.items()):
            self.logger.info(f"  {category}: {count} examples")

def main():
    """Main function to enhance sparse categories"""
    enhancer = SparseCategoryEnhancer()
    
    # Step 1: Generate synthetic data for sparse categories
    synthetic_data = []
    for category, count in enhancer.sparse_categories.items():
        if count < 5:  # Generate for categories with less than 5 examples
            synthetic = enhancer.generate_synthetic_data(category, count=10)
            synthetic_data.extend(synthetic)
    
    # Step 2: Combine with existing datasets (if available)
    existing_datasets = [
        Path("medical_qa_training/data/medical_qa_dataset.csv"),
        Path("medical_qa_training/data/additional_medical_qa.json")
    ]
    
    combined_data = enhancer.combine_datasets(existing_datasets)
    combined_data.extend(synthetic_data)
    
    # Step 3: Implement confidence scoring
    enhanced_data = enhancer.implement_confidence_scoring(combined_data)
    
    # Step 4: Save enhanced dataset
    output_path = Path("medical_qa_training/processed/enhanced_medical_qa.json")
    enhancer.save_enhanced_data(enhanced_data, output_path)
    
    print("✅ Sparse category enhancement completed!")
    print("📁 Enhanced dataset saved to: medical_qa_training/processed/enhanced_medical_qa.json")

if __name__ == "__main__":
    main() 