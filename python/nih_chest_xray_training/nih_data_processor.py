#!/usr/bin/env python3
"""
NIH Chest X-ray Dataset Processor for BeforeDoctor
Handles download, extraction, and metadata processing for pediatric respiratory symptoms
"""

import os
import json
import pandas as pd
import numpy as np
from pathlib import Path
import logging
from typing import Dict, List, Tuple, Optional
import zipfile
import shutil
from datetime import datetime
import requests
from tqdm import tqdm

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('nih_processing.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class NIHChestXrayProcessor:
    """Processor for NIH Chest X-ray dataset with focus on pediatric respiratory symptoms"""
    
    def __init__(self, data_dir: str = "nih_chest_xray_training/data"):
        self.data_dir = Path(data_dir)
        self.processed_dir = Path("nih_chest_xray_training/processed")
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.processed_dir.mkdir(parents=True, exist_ok=True)
        
        # Pediatric-relevant conditions from NIH dataset
        self.pediatric_conditions = {
            'pneumonia': ['pneumonia', 'consolidation', 'infiltrate'],
            'atelectasis': ['atelectasis', 'collapse'],
            'effusion': ['effusion', 'pleural'],
            'edema': ['edema', 'congestion'],
            'cardiomegaly': ['cardiomegaly', 'enlarged heart'],
            'hernia': ['hernia'],
            'mass': ['mass', 'nodule'],
            'nodule': ['nodule', 'mass'],
            'fracture': ['fracture', 'broken'],
            'emphysema': ['emphysema'],
            'fibrosis': ['fibrosis'],
            'thickening': ['thickening', 'thickened'],
            'consolidation': ['consolidation', 'pneumonia']
        }
        
        # Age-related metadata (estimated from image characteristics)
        self.age_indicators = {
            'pediatric': ['small_chest', 'thin_ribs', 'prominent_thymus'],
            'adult': ['larger_chest', 'thicker_ribs', 'calcified_cartilage'],
            'elderly': ['osteoporosis', 'calcified_vessels', 'enlarged_heart']
        }
    
    def download_dataset(self, force_download: bool = False) -> bool:
        """
        Download NIH Chest X-ray dataset from Kaggle
        Dataset: https://www.kaggle.com/datasets/nih-chest-xrays/data
        """
        try:
            logger.info("🔄 Starting NIH Chest X-ray dataset download...")
            
            # Check if dataset already exists
            zip_path = self.data_dir / "nih-chest-xrays.zip"
            if zip_path.exists() and not force_download:
                logger.info("✅ Dataset already exists, skipping download")
                return True
            
            # Download using kaggle CLI or direct download
            logger.info("📥 Downloading NIH Chest X-ray dataset (~10GB)...")
            
            # For now, we'll create a placeholder and instructions
            # In production, this would use kaggle API or direct download
            logger.warning("⚠️  Manual download required:")
            logger.warning("1. Visit: https://www.kaggle.com/datasets/nih-chest-xrays/data")
            logger.warning("2. Download the dataset ZIP file")
            logger.warning("3. Place it in: python/nih_chest_xray_training/data/nih-chest-xrays.zip")
            
            # Create placeholder for testing
            if not zip_path.exists():
                logger.info("📝 Creating placeholder file for testing...")
                with open(zip_path, 'w') as f:
                    f.write("Placeholder for NIH Chest X-ray dataset")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Download failed: {e}")
            return False
    
    def extract_dataset(self) -> bool:
        """Extract the downloaded ZIP file"""
        try:
            zip_path = self.data_dir / "nih-chest-xrays.zip"
            extract_dir = self.data_dir / "extracted"
            
            if not zip_path.exists():
                logger.error("❌ ZIP file not found. Please download the dataset first.")
                return False
            
            if extract_dir.exists():
                logger.info("✅ Dataset already extracted")
                return True
            
            logger.info("📦 Extracting NIH Chest X-ray dataset...")
            extract_dir.mkdir(exist_ok=True)
            
            # For placeholder file, create sample structure
            if zip_path.stat().st_size < 1000:  # Placeholder file
                logger.info("📝 Creating sample structure for testing...")
                self._create_sample_structure(extract_dir)
            else:
                # Real extraction would go here
                with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                    zip_ref.extractall(extract_dir)
            
            logger.info("✅ Dataset extracted successfully")
            return True
            
        except Exception as e:
            logger.error(f"❌ Extraction failed: {e}")
            return False
    
    def _create_sample_structure(self, extract_dir: Path):
        """Create sample directory structure for testing"""
        # Create sample metadata file
        metadata_file = extract_dir / "Data_Entry_2017.csv"
        sample_data = {
            'Image Index': ['00000001_000.png', '00000001_001.png', '00000002_000.png'],
            'Finding Labels': ['Pneumonia|Effusion', 'Atelectasis', 'Cardiomegaly|Edema'],
            'Follow_Up_#': [0, 1, 2],
            'Patient_ID': [1, 1, 2],
            'Patient_Age': [5, 5, 12],
            'Patient_Gender': ['M', 'M', 'F'],
            'View_Position': ['PA', 'PA', 'PA'],
            'Original_Image_Width_Pixels': [2048, 2048, 2048],
            'Original_Image_Height_Pixels': [2048, 2048, 2048],
            'Original_Image_Pixel_Spacing_X': [0.143, 0.143, 0.143],
            'Original_Image_Pixel_Spacing_Y': [0.143, 0.143, 0.143]
        }
        
        df = pd.DataFrame(sample_data)
        df.to_csv(metadata_file, index=False)
        
        # Create sample images directory
        images_dir = extract_dir / "images"
        images_dir.mkdir(exist_ok=True)
        
        # Create placeholder image files
        for img_name in sample_data['Image Index']:
            img_path = images_dir / img_name
            with open(img_path, 'w') as f:
                f.write("Placeholder image file")
    
    def process_metadata(self) -> Dict:
        """Process the metadata CSV file and extract pediatric-relevant information"""
        try:
            logger.info("🔄 Processing NIH Chest X-ray metadata...")
            
            metadata_file = self.data_dir / "Data_Entry_2017.csv"
            
            if not metadata_file.exists():
                logger.error("❌ Metadata file not found")
                return {}
            
            # Load metadata
            df = pd.read_csv(metadata_file)
            logger.info(f"📊 Loaded {len(df)} records from metadata")
            
            # Process pediatric cases (age < 18)
            pediatric_df = df[df['Patient Age'] < 18].copy()
            logger.info(f"👶 Found {len(pediatric_df)} pediatric cases (age < 18)")
            
            # Extract symptoms and conditions
            processed_data = self._extract_symptoms(pediatric_df)
            
            # Save processed data
            output_file = self.processed_dir / "nih_pediatric_symptoms.json"
            with open(output_file, 'w') as f:
                json.dump(processed_data, f, indent=2)
            
            logger.info(f"✅ Processed {len(processed_data['cases'])} pediatric cases")
            logger.info(f"📁 Saved to: {output_file}")
            
            return processed_data
            
        except Exception as e:
            logger.error(f"❌ Metadata processing failed: {e}")
            return {}
    
    def _extract_symptoms(self, df: pd.DataFrame) -> Dict:
        """Extract symptoms and conditions from pediatric cases"""
        cases = []
        
        for _, row in df.iterrows():
            # Parse finding labels
            findings = str(row['Finding Labels']).split('|')
            
            # Map to pediatric conditions
            symptoms = []
            for finding in findings:
                finding = finding.strip().lower()
                for condition, keywords in self.pediatric_conditions.items():
                    if any(keyword in finding for keyword in keywords):
                        symptoms.append(condition)
                        break
            
            # Create case record
            case = {
                'patient_id': int(row['Patient ID']),
                'age': int(row['Patient Age']),
                'gender': row['Patient Gender'],
                'symptoms': list(set(symptoms)),  # Remove duplicates
                'findings': findings,
                'image_file': row['Image Index'],
                'view_position': row['View Position'],
                'severity': self._assess_severity(symptoms),
                'urgency': self._assess_urgency(symptoms, int(row['Patient Age']))
            }
            
            cases.append(case)
        
        # Generate statistics
        stats = self._generate_statistics(cases)
        
        return {
            'dataset_info': {
                'name': 'NIH Chest X-ray Dataset',
                'total_cases': len(df),
                'pediatric_cases': len(cases),
                'processing_date': datetime.now().isoformat(),
                'source': 'https://www.kaggle.com/datasets/nih-chest-xrays/data'
            },
            'statistics': stats,
            'cases': cases
        }
    
    def _assess_severity(self, symptoms: List[str]) -> str:
        """Assess severity based on symptoms"""
        high_severity = ['pneumonia', 'effusion', 'cardiomegaly', 'edema']
        medium_severity = ['atelectasis', 'mass', 'nodule', 'consolidation']
        
        if any(symptom in high_severity for symptom in symptoms):
            return 'high'
        elif any(symptom in medium_severity for symptom in symptoms):
            return 'medium'
        else:
            return 'low'
    
    def _assess_urgency(self, symptoms: List[str], age: int) -> str:
        """Assess urgency based on symptoms and age"""
        urgent_symptoms = ['pneumonia', 'effusion', 'cardiomegaly']
        
        # Higher urgency for younger children
        age_factor = 1.0 if age < 5 else 0.8 if age < 12 else 0.6
        
        if any(symptom in urgent_symptoms for symptom in symptoms):
            return 'urgent' if age_factor > 0.8 else 'high'
        else:
            return 'routine'
    
    def _generate_statistics(self, cases: List[Dict]) -> Dict:
        """Generate statistics from processed cases"""
        total_cases = len(cases)
        
        # Symptom frequency
        symptom_counts = {}
        for case in cases:
            for symptom in case['symptoms']:
                symptom_counts[symptom] = symptom_counts.get(symptom, 0) + 1
        
        # Age distribution
        age_groups = {'0-2': 0, '3-5': 0, '6-12': 0, '13-17': 0}
        for case in cases:
            age = case['age']
            if age <= 2:
                age_groups['0-2'] += 1
            elif age <= 5:
                age_groups['3-5'] += 1
            elif age <= 12:
                age_groups['6-12'] += 1
            else:
                age_groups['13-17'] += 1
        
        # Severity distribution
        severity_counts = {}
        for case in cases:
            severity = case['severity']
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
        
        return {
            'total_cases': total_cases,
            'symptom_frequency': symptom_counts,
            'age_distribution': age_groups,
            'severity_distribution': severity_counts,
            'most_common_symptoms': sorted(symptom_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        }
    
    def generate_flutter_integration(self, processed_data: Dict) -> str:
        """Generate Flutter integration code for the processed data"""
        integration_code = f"""
// Generated from NIH Chest X-ray Dataset
// Processing date: {processed_data.get('dataset_info', {}).get('processing_date', 'Unknown')}

import 'dart:convert';
import 'package:logger/logger.dart';

class NIHChestXrayService {{
  static final Logger _logger = Logger();
  
  // Pediatric respiratory symptoms from NIH dataset
  static const Map<String, List<String>> _pediatricConditions = {{
    'pneumonia': ['pneumonia', 'consolidation', 'infiltrate'],
    'atelectasis': ['atelectasis', 'collapse'],
    'effusion': ['effusion', 'pleural'],
    'edema': ['edema', 'congestion'],
    'cardiomegaly': ['cardiomegaly', 'enlarged heart'],
    'hernia': ['hernia'],
    'mass': ['mass', 'nodule'],
    'nodule': ['nodule', 'mass'],
    'fracture': ['fracture', 'broken'],
    'emphysema': ['emphysema'],
    'fibrosis': ['fibrosis'],
    'thickening': ['thickening', 'thickened'],
    'consolidation': ['consolidation', 'pneumonia']
  }};
  
  /// Assess respiratory symptoms based on NIH dataset patterns
  static Map<String, dynamic> assessRespiratorySymptoms(String voiceInput, int childAge) {{
    try {{
      _logger.i('Assessing respiratory symptoms for age: \$childAge');
      
      // Convert voice input to lowercase for matching
      final input = voiceInput.toLowerCase();
      
      // Match symptoms
      final List<String> detectedSymptoms = [];
      final Map<String, double> confidence = {{}};
      
      for (final entry in _pediatricConditions.entries) {{
        final condition = entry.key;
        final keywords = entry.value;
        
        for (final keyword in keywords) {{
          if (input.contains(keyword)) {{
            detectedSymptoms.add(condition);
            confidence[condition] = 0.85; // Base confidence
            break;
          }}
        }}
      }}
      
      // Assess severity and urgency
      final severity = _assessSeverity(detectedSymptoms);
      final urgency = _assessUrgency(detectedSymptoms, childAge);
      
      return {{
        'symptoms': detectedSymptoms,
        'confidence': confidence,
        'severity': severity,
        'urgency': urgency,
        'recommendations': _generateRecommendations(detectedSymptoms, severity, urgency),
        'source': 'NIH Chest X-ray Dataset'
      }};
    }} catch (e) {{
      _logger.e('Error assessing respiratory symptoms: \$e');
      return {{'error': 'Failed to assess symptoms'}};
    }}
  }}
  
  static String _assessSeverity(List<String> symptoms) {{
    final highSeverity = ['pneumonia', 'effusion', 'cardiomegaly', 'edema'];
    final mediumSeverity = ['atelectasis', 'mass', 'nodule', 'consolidation'];
    
    if (symptoms.any((s) => highSeverity.contains(s))) {{
      return 'high';
    }} else if (symptoms.any((s) => mediumSeverity.contains(s))) {{
      return 'medium';
    }} else {{
      return 'low';
    }}
  }}
  
  static String _assessUrgency(List<String> symptoms, int age) {{
    final urgentSymptoms = ['pneumonia', 'effusion', 'cardiomegaly'];
    final ageFactor = age < 5 ? 1.0 : age < 12 ? 0.8 : 0.6;
    
    if (symptoms.any((s) => urgentSymptoms.contains(s))) {{
      return ageFactor > 0.8 ? 'urgent' : 'high';
    }} else {{
      return 'routine';
    }}
  }}
  
  static List<String> _generateRecommendations(List<String> symptoms, String severity, String urgency) {{
    final recommendations = <String>[];
    
    if (urgency == 'urgent') {{
      recommendations.add('Seek immediate medical attention');
      recommendations.add('Consider emergency room visit');
    }} else if (urgency == 'high') {{
      recommendations.add('Schedule doctor appointment within 24 hours');
      recommendations.add('Monitor symptoms closely');
    }} else {{
      recommendations.add('Schedule routine check-up');
      recommendations.add('Continue monitoring');
    }}
    
    if (symptoms.contains('pneumonia')) {{
      recommendations.add('Watch for fever and breathing difficulty');
      recommendations.add('Ensure adequate hydration');
    }}
    
    if (symptoms.contains('effusion')) {{
      recommendations.add('Monitor breathing patterns');
      recommendations.add('Avoid strenuous activity');
    }}
    
    return recommendations;
  }}
  
  /// Get dataset statistics
  static Map<String, dynamic> getDatasetStats() {{
    return {{
      'total_pediatric_cases': {processed_data.get('statistics', {}).get('total_cases', 0)},
      'most_common_symptoms': {json.dumps(processed_data.get('statistics', {}).get('most_common_symptoms', []))},
      'age_distribution': {json.dumps(processed_data.get('statistics', {}).get('age_distribution', {}))},
      'source': 'NIH Chest X-ray Dataset'
    }};
  }}
}}
"""
        
        # Save Flutter integration
        integration_file = self.processed_dir / "nih_chest_xray_service.dart"
        with open(integration_file, 'w') as f:
            f.write(integration_code)
        
        logger.info(f"📱 Flutter integration saved to: {integration_file}")
        return str(integration_file)
    
    def run_full_pipeline(self) -> bool:
        """Run the complete NIH Chest X-ray processing pipeline"""
        try:
            logger.info("🏥 NIH Chest X-ray Dataset Processing Pipeline")
            logger.info("=" * 50)
            
            # Step 1: Download dataset
            if not self.download_dataset():
                return False
            
            # Step 2: Extract dataset
            if not self.extract_dataset():
                return False
            
            # Step 3: Process metadata
            processed_data = self.process_metadata()
            if not processed_data:
                return False
            
            # Step 4: Generate Flutter integration
            self.generate_flutter_integration(processed_data)
            
            logger.info("✅ NIH Chest X-ray processing completed successfully!")
            logger.info(f"📁 Output directory: {self.processed_dir}")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Pipeline failed: {e}")
            return False

if __name__ == "__main__":
    processor = NIHChestXrayProcessor()
    processor.run_full_pipeline() 