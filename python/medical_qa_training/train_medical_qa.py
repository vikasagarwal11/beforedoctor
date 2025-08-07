#!/usr/bin/env python3
"""
Medical Q&A Training Script for BeforeDoctor
Trains models on comprehensive medical Q&A dataset
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
import sys
import os

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from medical_qa_training.medical_qa_processor import MedicalQAProcessor

def setup_logging():
    """Setup logging configuration"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('python/medical_qa_training/medical_qa_training.log'),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)

def load_medical_qa_data():
    """Load Medical Q&A dataset files"""
    logger = logging.getLogger(__name__)
    data_dir = Path("medical_qa_training/data")
    
    # Look for Medical Q&A dataset files
    qa_files = list(data_dir.glob("*.csv")) + list(data_dir.glob("*.json")) + list(data_dir.glob("*.xlsx"))
    
    if not qa_files:
        logger.error("❌ No Medical Q&A dataset files found in data directory!")
        logger.info("Please run the download script first: python python/download_datasets.py")
        return None
    
    logger.info(f"📊 Found {len(qa_files)} Medical Q&A dataset files")
    
    datasets = {}
    for file_path in qa_files:
        try:
            if file_path.suffix == '.csv':
                df = pd.read_csv(file_path)
            elif file_path.suffix == '.json':
                df = pd.read_json(file_path)
            elif file_path.suffix == '.xlsx':
                df = pd.read_excel(file_path)
            else:
                continue
                
            datasets[file_path.name] = df
            logger.info(f"✅ Loaded {file_path.name}: {df.shape[0]} rows, {df.shape[1]} columns")
            
        except Exception as e:
            logger.error(f"❌ Failed to load {file_path.name}: {e}")
    
    return datasets

def train_medical_qa_models():
    """Train Medical Q&A models on real data"""
    logger = setup_logging()
    
    logger.info("🚀 Starting Medical Q&A Model Training")
    logger.info("=" * 50)
    
    # Load real Medical Q&A data
    datasets = load_medical_qa_data()
    if not datasets:
        return False
    
    # Initialize data processor
    processor = MedicalQAProcessor()
    
    try:
        # Process real Medical Q&A data
        logger.info("🔄 Processing real Medical Q&A data...")
        processed_data = processor.process_real_medical_qa_data(datasets)
        
        if processed_data is None or len(processed_data) == 0:
            logger.error("❌ No valid data after processing!")
            return False
        
        logger.info(f"✅ Processed {len(processed_data)} training examples")
        
        # Train models
        logger.info("🔄 Training Medical Q&A models...")
        models = processor.train_models(processed_data)
        
        # Save models
        logger.info("💾 Saving trained models...")
        processor.save_models(models)
        
        # Generate Flutter integration
        logger.info("📱 Generating Flutter integration...")
        processor.generate_flutter_integration()
        
        logger.info("🎉 Medical Q&A training completed successfully!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Training failed: {e}")
        return False

def main():
    """Main training function"""
    print("🏥 Medical Q&A Model Training for BeforeDoctor")
    print("=" * 50)
    
    success = train_medical_qa_models()
    
    if success:
        print("\n✅ Medical Q&A training completed!")
        print("📁 Models saved to: python/medical_qa_training/processed/")
        print("📱 Flutter integration ready!")
    else:
        print("\n❌ Medical Q&A training failed!")
        print("📋 Check logs: python/medical_qa_training/medical_qa_training.log")

if __name__ == "__main__":
    main() 