#!/usr/bin/env python3
"""
Parallel Training Script for BeforeDoctor
Runs CDC and Medical Q&A training simultaneously
"""

import subprocess
import threading
import time
import sys
import os
from pathlib import Path

def run_cdc_training():
    """Run CDC training in a separate process"""
    print("🏥 Starting CDC Training...")
    try:
        result = subprocess.run([
            sys.executable, 
            "python/cdc_training/train_cdc_models.py"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ CDC Training completed successfully!")
        else:
            print(f"❌ CDC Training failed: {result.stderr}")
            
    except Exception as e:
        print(f"❌ CDC Training error: {e}")

def run_medical_qa_training():
    """Run Medical Q&A training in a separate process"""
    print("🏥 Starting Medical Q&A Training...")
    try:
        result = subprocess.run([
            sys.executable, 
            "python/medical_qa_training/train_medical_qa.py"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Medical Q&A Training completed successfully!")
        else:
            print(f"❌ Medical Q&A Training failed: {result.stderr}")
            
    except Exception as e:
        print(f"❌ Medical Q&A Training error: {e}")

def main():
    """Run both training processes in parallel"""
    print("🚀 BeforeDoctor Parallel Training")
    print("=" * 50)
    print("Running CDC and Medical Q&A training simultaneously...")
    print("This may take several hours depending on dataset size and system performance.")
    print()
    
    # Check if datasets are downloaded
    cdc_data_dir = Path("python/cdc_training/data")
    medical_qa_data_dir = Path("python/medical_qa_training/data")
    
    if not cdc_data_dir.exists() or not any(cdc_data_dir.iterdir()):
        print("❌ CDC dataset not found!")
        print("Please run: python python/download_datasets.py")
        return
    
    if not medical_qa_data_dir.exists() or not any(medical_qa_data_dir.iterdir()):
        print("❌ Medical Q&A dataset not found!")
        print("Please run: python python/download_datasets.py")
        return
    
    print("✅ Datasets found, starting parallel training...")
    print()
    
    # Start both training processes in parallel
    cdc_thread = threading.Thread(target=run_cdc_training)
    medical_qa_thread = threading.Thread(target=run_medical_qa_training)
    
    start_time = time.time()
    
    cdc_thread.start()
    medical_qa_thread.start()
    
    # Wait for both to complete
    cdc_thread.join()
    medical_qa_thread.join()
    
    end_time = time.time()
    duration = end_time - start_time
    
    print("\n" + "=" * 50)
    print("📊 Parallel Training Summary:")
    print(f"⏱️ Total time: {duration:.2f} seconds ({duration/60:.2f} minutes)")
    print("📁 Check individual logs:")
    print("  - CDC: python/cdc_training/cdc_training.log")
    print("  - Medical Q&A: python/medical_qa_training/medical_qa_training.log")
    print("\n🎉 Parallel training completed!")

if __name__ == "__main__":
    main() 