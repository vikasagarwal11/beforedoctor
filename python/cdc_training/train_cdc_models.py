#!/usr/bin/env python3
"""
CDC Training Script for BeforeDoctor
Trains models on real CDC pediatric health data
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import joblib
import json
import logging
from pathlib import Path
import sys
import os

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from cdc_training.cdc_data_processor import CDCDataProcessor

def setup_logging():
    """Setup logging configuration"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('python/cdc_training/cdc_training.log'),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)

def load_real_cdc_data():
    """Load real CDC dataset files"""
    logger = logging.getLogger(__name__)
    data_dir = Path("cdc_training/data")
    
    # Look for CDC dataset files
    cdc_files = list(data_dir.glob("*.csv")) + list(data_dir.glob("*.xlsx"))
    
    if not cdc_files:
        logger.error("❌ No CDC dataset files found in data directory!")
        logger.info("Please run the download script first: python python/download_datasets.py")
        return None
    
    logger.info(f"📊 Found {len(cdc_files)} CDC dataset files")
    
    datasets = {}
    for file_path in cdc_files:
        try:
            if file_path.suffix == '.csv':
                df = pd.read_csv(file_path)
            elif file_path.suffix == '.xlsx':
                df = pd.read_excel(file_path)
            else:
                continue
                
            datasets[file_path.name] = df
            logger.info(f"✅ Loaded {file_path.name}: {df.shape[0]} rows, {df.shape[1]} columns")
            
        except Exception as e:
            logger.error(f"❌ Failed to load {file_path.name}: {e}")
    
    return datasets

def train_cdc_models():
    """Train CDC models on real data"""
    logger = setup_logging()
    
    logger.info("🚀 Starting CDC Model Training")
    logger.info("=" * 50)
    
    # Load real CDC data
    datasets = load_real_cdc_data()
    if not datasets:
        return False
    
    # Initialize data processor
    processor = CDCDataProcessor()
    
    try:
        # Process real CDC data
        logger.info("🔄 Processing real CDC data...")
        processed_data = processor.process_real_cdc_data(datasets)
        
        if processed_data is None or len(processed_data) == 0:
            logger.error("❌ No valid data after processing!")
            return False
        
        logger.info(f"✅ Processed {len(processed_data)} training examples")
        
        # Train models
        logger.info("🔄 Training CDC models...")
        models = processor.train_models(processed_data)
        
        # Save models
        logger.info("💾 Saving trained models...")
        processor.save_models(models)
        
        # Generate Flutter integration
        logger.info("📱 Generating Flutter integration...")
        processor.generate_flutter_integration()
        
        logger.info("🎉 CDC training completed successfully!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Training failed: {e}")
        return False

def main():
    """Main training function"""
    print("🏥 CDC Model Training for BeforeDoctor")
    print("=" * 50)
    
    success = train_cdc_models()
    
    if success:
        print("\n✅ CDC training completed!")
        print("📁 Models saved to: python/cdc_training/processed/")
        print("📱 Flutter integration ready!")
    else:
        print("\n❌ CDC training failed!")
        print("📋 Check logs: python/cdc_training/cdc_training.log")

if __name__ == "__main__":
    main() 