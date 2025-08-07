#!/usr/bin/env python3
"""
Disease Database Download Script for BeforeDoctor
Downloads and filters the FreedomIntelligence/Disease_Database dataset for pediatric records
"""

import os
import json
import pandas as pd
from pathlib import Path
from datasets import load_dataset
import logging
from datetime import datetime

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'python/logs/disease_database_download_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def create_directories():
    """Create necessary directories"""
    directories = [
        "python/disease_database_training/data",
        "python/disease_database_training/processed",
        "python/disease_database_training/models",
        "python/logs"
    ]
    
    for dir_path in directories:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        logger.info(f"✅ Created directory: {dir_path}")

def download_disease_database():
    """Download Disease Database dataset from Hugging Face"""
    try:
        logger.info("🔄 Downloading Disease Database dataset...")
        logger.info("Dataset: FreedomIntelligence/Disease_Database")
        
        # Load dataset from Hugging Face (English version)
        dataset = load_dataset("FreedomIntelligence/Disease_Database", "en")
        logger.info(f"✅ Dataset loaded successfully!")
        logger.info(f"Dataset structure: {dataset}")
        
        # Convert to pandas DataFrame for easier processing
        df = dataset['train'].to_pandas()
        logger.info(f"📊 Original dataset shape: {df.shape}")
        logger.info(f"📋 Columns: {list(df.columns)}")
        
        # Save original dataset
        data_dir = Path("python/disease_database_training/data")
        data_dir.mkdir(parents=True, exist_ok=True)
        
        original_file = data_dir / "disease_database_original.json"
        df.to_json(original_file, orient='records', indent=2)
        logger.info(f"💾 Original dataset saved to: {original_file}")
        
        return df
        
    except Exception as e:
        logger.error(f"❌ Disease Database download failed: {e}")
        return None

def filter_pediatric_records(df):
    """Filter dataset for pediatric-relevant records"""
    try:
        logger.info("🔍 Filtering for pediatric records...")
        
        # Create a copy for filtering
        pediatric_df = df.copy()
        
        # Define pediatric keywords for filtering
        pediatric_keywords = [
            'child', 'children', 'pediatric', 'infant', 'baby', 'toddler',
            'adolescent', 'teen', 'teenager', 'youth', 'young', 'juvenile',
            'school-age', 'preschool', 'neonatal', 'newborn', 'toddler',
            'fever', 'cough', 'cold', 'flu', 'vaccination', 'immunization',
            'growth', 'development', 'milestone', 'behavior', 'learning',
            'asthma', 'allergy', 'eczema', 'diarrhea', 'vomiting', 'rash',
            'ear infection', 'strep throat', 'pink eye', 'chickenpox',
            'measles', 'mumps', 'rubella', 'whooping cough', 'rotavirus'
        ]
        
        # Create a mask for pediatric-relevant records
        pediatric_mask = pediatric_df.apply(
            lambda row: any(
                keyword.lower() in str(value).lower() 
                for value in row.values 
                for keyword in pediatric_keywords
            ), axis=1
        )
        
        # Apply the filter
        pediatric_df = pediatric_df[pediatric_mask]
        
        logger.info(f"📊 Pediatric records found: {len(pediatric_df)} out of {len(df)} total records")
        logger.info(f"📈 Filtering ratio: {len(pediatric_df)/len(df)*100:.1f}%")
        
        # Additional filtering for high-quality pediatric records
        # Look for records with more specific pediatric content
        specific_pediatric_keywords = [
            'pediatric', 'child', 'children', 'infant', 'baby', 'toddler',
            'adolescent', 'teen', 'teenager', 'school-age', 'preschool'
        ]
        
        high_quality_mask = pediatric_df.apply(
            lambda row: any(
                keyword.lower() in str(value).lower() 
                for value in row.values 
                for keyword in specific_pediatric_keywords
            ), axis=1
        )
        
        high_quality_df = pediatric_df[high_quality_mask]
        logger.info(f"🎯 High-quality pediatric records: {len(high_quality_df)}")
        
        return high_quality_df
        
    except Exception as e:
        logger.error(f"❌ Pediatric filtering failed: {e}")
        return df

def analyze_dataset(df, filename_prefix):
    """Analyze the dataset and generate insights"""
    try:
        logger.info(f"📊 Analyzing {filename_prefix} dataset...")
        
        analysis = {
            'total_records': len(df),
            'columns': list(df.columns),
            'column_types': df.dtypes.to_dict(),
            'missing_values': df.isnull().sum().to_dict(),
            'sample_records': df.head(3).to_dict('records')
        }
        
        # Save analysis
        analysis_file = Path(f"python/disease_database_training/processed/{filename_prefix}_analysis.json")
        with open(analysis_file, 'w') as f:
            json.dump(analysis, f, indent=2, default=str)
        
        logger.info(f"📈 Analysis saved to: {analysis_file}")
        logger.info(f"📊 Dataset summary: {len(df)} records, {len(df.columns)} columns")
        
        return analysis
        
    except Exception as e:
        logger.error(f"❌ Dataset analysis failed: {e}")
        return None

def save_processed_dataset(df, filename):
    """Save processed dataset in multiple formats"""
    try:
        processed_dir = Path("python/disease_database_training/processed")
        processed_dir.mkdir(parents=True, exist_ok=True)
        
        # Save as JSON
        json_file = processed_dir / f"{filename}.json"
        df.to_json(json_file, orient='records', indent=2)
        logger.info(f"💾 JSON saved: {json_file}")
        
        # Save as CSV
        csv_file = processed_dir / f"{filename}.csv"
        df.to_csv(csv_file, index=False)
        logger.info(f"💾 CSV saved: {csv_file}")
        
        # Save as Parquet
        parquet_file = processed_dir / f"{filename}.parquet"
        df.to_parquet(parquet_file, index=False)
        logger.info(f"💾 Parquet saved: {parquet_file}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Failed to save processed dataset: {e}")
        return False

def create_flutter_integration():
    """Create Flutter integration files for the dataset"""
    try:
        logger.info("🔧 Creating Flutter integration files...")
        
        # Create Dart model for disease database
        dart_model_content = '''// Disease Database Model for BeforeDoctor
// Generated from Hugging Face FreedomIntelligence/Disease_Database dataset

class DiseaseRecord {
  final String? disease;
  final String? symptoms;
  final String? treatments;
  final String? causes;
  final String? prevention;
  final String? diagnosis;
  final String? complications;
  final String? riskFactors;
  final String? epidemiology;
  final String? prognosis;
  final String? differentialDiagnosis;
  final String? laboratoryTests;
  final String? imagingStudies;
  final String? medications;
  final String? surgery;
  final String? lifestyleModifications;
  final String? followUp;
  final String? patientEducation;
  final String? emergencySigns;
  final String? referralCriteria;

  DiseaseRecord({
    this.disease,
    this.symptoms,
    this.treatments,
    this.causes,
    this.prevention,
    this.diagnosis,
    this.complications,
    this.riskFactors,
    this.epidemiology,
    this.prognosis,
    this.differentialDiagnosis,
    this.laboratoryTests,
    this.imagingStudies,
    this.medications,
    this.surgery,
    this.lifestyleModifications,
    this.followUp,
    this.patientEducation,
    this.emergencySigns,
    this.referralCriteria,
  });

  factory DiseaseRecord.fromJson(Map<String, dynamic> json) {
    return DiseaseRecord(
      disease: json['disease'],
      symptoms: json['symptoms'],
      treatments: json['treatments'],
      causes: json['causes'],
      prevention: json['prevention'],
      diagnosis: json['diagnosis'],
      complications: json['complications'],
      riskFactors: json['risk_factors'],
      epidemiology: json['epidemiology'],
      prognosis: json['prognosis'],
      differentialDiagnosis: json['differential_diagnosis'],
      laboratoryTests: json['laboratory_tests'],
      imagingStudies: json['imaging_studies'],
      medications: json['medications'],
      surgery: json['surgery'],
      lifestyleModifications: json['lifestyle_modifications'],
      followUp: json['follow_up'],
      patientEducation: json['patient_education'],
      emergencySigns: json['emergency_signs'],
      referralCriteria: json['referral_criteria'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'symptoms': symptoms,
      'treatments': treatments,
      'causes': causes,
      'prevention': prevention,
      'diagnosis': diagnosis,
      'complications': complications,
      'risk_factors': riskFactors,
      'epidemiology': epidemiology,
      'prognosis': prognosis,
      'differential_diagnosis': differentialDiagnosis,
      'laboratory_tests': laboratoryTests,
      'imaging_studies': imagingStudies,
      'medications': medications,
      'surgery': surgery,
      'lifestyle_modifications': lifestyleModifications,
      'follow_up': followUp,
      'patient_education': patientEducation,
      'emergency_signs': emergencySigns,
      'referral_criteria': referralCriteria,
    };
  }

  @override
  String toString() {
    return 'DiseaseRecord(disease: $disease, symptoms: $symptoms, treatments: $treatments)';
  }
}

class PediatricDiseaseService {
  static List<DiseaseRecord> loadPediatricDiseases() {
    // TODO: Load from assets/data/pediatric_disease_database.json
    return [];
  }

  static List<DiseaseRecord> searchDiseases(String query) {
    // TODO: Implement search functionality
    return [];
  }

  static List<DiseaseRecord> getDiseasesBySymptoms(List<String> symptoms) {
    // TODO: Implement symptom-based disease matching
    return [];
  }
}
'''
        
        # Save Dart model
        dart_file = Path("beforedoctor/lib/services/pediatric_disease_service.dart")
        dart_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(dart_file, 'w') as f:
            f.write(dart_model_content)
        
        logger.info(f"💾 Dart model saved: {dart_file}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Flutter integration creation failed: {e}")
        return False

def main():
    """Main download and processing function"""
    logger.info("🚀 BeforeDoctor Disease Database Download Script")
    logger.info("=" * 60)
    
    # Create directories
    create_directories()
    
    # Download dataset
    df = download_disease_database()
    if df is None:
        logger.error("❌ Failed to download dataset. Exiting.")
        return
    
    # Filter for pediatric records
    pediatric_df = filter_pediatric_records(df)
    
    # Analyze datasets
    analyze_dataset(df, "disease_database_original")
    analyze_dataset(pediatric_df, "disease_database_pediatric")
    
    # Save processed datasets
    save_processed_dataset(df, "disease_database_original")
    save_processed_dataset(pediatric_df, "disease_database_pediatric")
    
    # Create Flutter integration
    create_flutter_integration()
    
    logger.info("\n" + "=" * 60)
    logger.info("📊 Processing Summary:")
    logger.info(f"Original records: {len(df)}")
    logger.info(f"Pediatric records: {len(pediatric_df)}")
    logger.info(f"Filtering efficiency: {len(pediatric_df)/len(df)*100:.1f}%")
    
    logger.info("\n🎉 Disease Database processing completed!")
    logger.info("\n📁 Files created:")
    logger.info("- python/disease_database_training/data/disease_database_original.json")
    logger.info("- python/disease_database_training/processed/disease_database_pediatric.json")
    logger.info("- python/disease_database_training/processed/disease_database_pediatric.csv")
    logger.info("- python/disease_database_training/processed/disease_database_pediatric.parquet")
    logger.info("- beforedoctor/lib/services/pediatric_disease_service.dart")
    
    logger.info("\n📋 Next Steps:")
    logger.info("1. Review the pediatric dataset in the processed folder")
    logger.info("2. Integrate the Dart service into your Flutter app")
    logger.info("3. Use the dataset for training pediatric disease models")

if __name__ == "__main__":
    main() 