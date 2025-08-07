#!/usr/bin/env python3
"""
Dataset Download Script for BeforeDoctor
Downloads both CDC pediatric data and Medical Q&A dataset
"""

import kagglehub
import os
import zipfile
import shutil
import json
from pathlib import Path
import sys

def create_directories():
    """Create necessary directories"""
    directories = [
        "python/cdc_training/data",
        "python/cdc_training/processed", 
        "python/medical_qa_training/data",
        "python/medical_qa_training/processed"
    ]
    
    for dir_path in directories:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        print(f"✅ Created directory: {dir_path}")

def download_cdc_dataset():
    """Download CDC pediatric health dataset"""
    try:
        print("\n🔄 Downloading CDC dataset...")
        print("Dataset: cdc/health-conditions-among-children-under-18-years")
        
        # Download dataset
        path = kagglehub.dataset_download("cdc/health-conditions-among-children-under-18-years")
        print(f"✅ CDC dataset downloaded to: {path}")
        
        # Copy files to our data directory
        data_dir = Path("python/cdc_training/data")
        data_dir.mkdir(parents=True, exist_ok=True)
        
        files_copied = 0
        for file_path in Path(path).glob("*"):
            if file_path.is_file():
                # Handle long filenames for Windows
                if file_path.name.endswith('.csv'):
                    dest_path = data_dir / "cdc_data.csv"
                else:
                    dest_path = data_dir / file_path.name
                shutil.copy2(file_path, dest_path)
                print(f"📄 Copied: {file_path.name} -> {dest_path.name}")
                files_copied += 1
        
        print(f"🎉 CDC dataset ready! {files_copied} files copied to {data_dir}")
        return True
        
    except Exception as e:
        print(f"❌ CDC download failed: {e}")
        return False

def download_medical_qa_dataset():
    """Download Medical Q&A dataset"""
    try:
        print("\n🔄 Downloading Medical Q&A dataset...")
        print("Dataset: thedevastator/comprehensive-medical-q-a-dataset")
        
        # Download dataset
        path = kagglehub.dataset_download("thedevastator/comprehensive-medical-q-a-dataset")
        print(f"✅ Medical Q&A dataset downloaded to: {path}")
        
        # Copy files to our data directory
        data_dir = Path("python/medical_qa_training/data")
        data_dir.mkdir(parents=True, exist_ok=True)
        
        files_copied = 0
        for file_path in Path(path).glob("*"):
            if file_path.is_file():
                dest_path = data_dir / file_path.name
                shutil.copy2(file_path, dest_path)
                print(f"📄 Copied: {file_path.name}")
                files_copied += 1
        
        print(f"🎉 Medical Q&A dataset ready! {files_copied} files copied to {data_dir}")
        return True
        
    except Exception as e:
        print(f"❌ Medical Q&A download failed: {e}")
        return False

def main():
    """Main download function"""
    print("🚀 BeforeDoctor Dataset Download Script")
    print("=" * 50)
    
    # Create directories
    create_directories()
    
    # Download both datasets
    cdc_success = download_cdc_dataset()
    medical_qa_success = download_medical_qa_dataset()
    
    print("\n" + "=" * 50)
    print("📊 Download Summary:")
    print(f"CDC Dataset: {'✅ Success' if cdc_success else '❌ Failed'}")
    print(f"Medical Q&A: {'✅ Success' if medical_qa_success else '❌ Failed'}")
    
    if cdc_success and medical_qa_success:
        print("\n🎉 Both datasets downloaded successfully!")
        print("\n📁 Next Steps:")
        print("1. Run CDC training: python python/cdc_training/train_cdc_models.py")
        print("2. Run Medical Q&A training: python python/medical_qa_training/train_medical_qa.py")
        print("3. Or run both in parallel using the provided scripts")
    else:
        print("\n⚠️ Some downloads failed. Check the errors above.")

if __name__ == "__main__":
    main() 