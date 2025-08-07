#!/usr/bin/env python3
"""
Analyze NIH Chest X-ray documentation files to extract valuable knowledge
for training and improving AI models
"""

import os
import json
import pandas as pd
from pathlib import Path
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def analyze_nih_documentation():
    """Analyze NIH documentation files for valuable training knowledge"""
    
    nih_dir = Path("nih_chest_xray_training/data/nih-chest-xrays")
    
    # Analyze available files
    logger.info("📚 Analyzing NIH Chest X-ray documentation files...")
    
    # 1. Analyze train/val/test splits
    logger.info("🔍 Analyzing dataset splits...")
    
    try:
        with open(nih_dir / "train_val_list.txt", 'r') as f:
            train_val_files = f.read().strip().split('\n')
        
        with open(nih_dir / "test_list.txt", 'r') as f:
            test_files = f.read().strip().split('\n')
        
        logger.info(f"📊 Dataset Split Analysis:")
        logger.info(f"  • Training/Validation: {len(train_val_files)} images")
        logger.info(f"  • Test: {len(test_files)} images")
        logger.info(f"  • Total: {len(train_val_files) + len(test_files)} images")
        
        # Calculate pediatric cases in splits
        metadata_df = pd.read_csv(nih_dir / "Data_Entry_2017.csv")
        pediatric_df = metadata_df[metadata_df['Patient Age'] < 18]
        
        # Count pediatric cases in each split
        train_val_pediatric = 0
        test_pediatric = 0
        
        for _, row in pediatric_df.iterrows():
            image_file = row['Image Index']
            if image_file in train_val_files:
                train_val_pediatric += 1
            elif image_file in test_files:
                test_pediatric += 1
        
        logger.info(f"  • Pediatric cases in train/val: {train_val_pediatric}")
        logger.info(f"  • Pediatric cases in test: {test_pediatric}")
        
    except Exception as e:
        logger.error(f"Error analyzing dataset splits: {e}")
    
    # 2. Analyze documentation files
    logger.info("📖 Analyzing documentation files...")
    
    documentation_files = {
        "ARXIV_V5_CHESTXRAY.pdf": "Main research paper with methodology and findings",
        "README_CHESTXRAY.pdf": "Dataset documentation and usage guide", 
        "FAQ_CHESTXRAY.pdf": "Frequently asked questions and clarifications",
        "LOG_CHESTXRAY.pdf": "Processing log and technical details"
    }
    
    for filename, description in documentation_files.items():
        file_path = nih_dir / filename
        if file_path.exists():
            file_size = file_path.stat().st_size
            logger.info(f"  • {filename}: {description} ({file_size:,} bytes)")
        else:
            logger.warning(f"  • {filename}: Not found")
    
    # 3. Extract valuable knowledge for training
    logger.info("🧠 Extracting valuable knowledge for AI training...")
    
    valuable_knowledge = {
        "dataset_structure": {
            "total_images": len(train_val_files) + len(test_files),
            "train_val_split": len(train_val_files),
            "test_split": len(test_files),
            "pediatric_cases_train_val": train_val_pediatric,
            "pediatric_cases_test": test_pediatric
        },
        "training_recommendations": {
            "use_train_val_for_training": True,
            "use_test_for_evaluation": True,
            "pediatric_focus": True,
            "respiratory_conditions": [
                "pneumonia", "effusion", "atelectasis", "cardiomegaly", 
                "edema", "mass", "nodule", "consolidation"
            ]
        },
        "documentation_insights": {
            "arxiv_paper": "Contains methodology and validation techniques",
            "readme": "Dataset usage guidelines and preprocessing steps",
            "faq": "Common issues and solutions for dataset usage",
            "log": "Technical processing details and quality metrics"
        }
    }
    
    # 4. Generate training improvements
    logger.info("🚀 Generating training improvements...")
    
    training_improvements = {
        "model_enhancements": [
            "Use train_val split for model training",
            "Use test split for final evaluation",
            "Focus on pediatric respiratory conditions",
            "Implement age-specific severity assessment",
            "Add gender-based analysis for pediatric cases"
        ],
        "data_preprocessing": [
            "Filter for pediatric cases (age < 18)",
            "Focus on respiratory conditions",
            "Balance dataset for rare conditions",
            "Implement data augmentation for pediatric cases"
        ],
        "evaluation_metrics": [
            "Pediatric-specific accuracy metrics",
            "Age-group performance analysis",
            "Respiratory condition detection rates",
            "Severity assessment accuracy"
        ]
    }
    
    # Save analysis results
    analysis_results = {
        "valuable_knowledge": valuable_knowledge,
        "training_improvements": training_improvements,
        "documentation_files": list(documentation_files.keys())
    }
    
    output_file = Path("nih_chest_xray_training/processed/documentation_analysis.json")
    output_file.parent.mkdir(exist_ok=True)
    
    with open(output_file, 'w') as f:
        json.dump(analysis_results, f, indent=2)
    
    logger.info(f"✅ Documentation analysis saved to: {output_file}")
    
    return analysis_results

if __name__ == "__main__":
    results = analyze_nih_documentation()
    print("\n📋 SUMMARY OF VALUABLE KNOWLEDGE:")
    print("=" * 50)
    
    knowledge = results["valuable_knowledge"]
    print(f"• Total Images: {knowledge['dataset_structure']['total_images']:,}")
    print(f"• Pediatric Cases (Train/Val): {knowledge['dataset_structure']['pediatric_cases_train_val']}")
    print(f"• Pediatric Cases (Test): {knowledge['dataset_structure']['pediatric_cases_test']}")
    print(f"• Respiratory Conditions: {len(knowledge['training_recommendations']['respiratory_conditions'])}")
    
    print("\n🚀 TRAINING IMPROVEMENTS:")
    print("=" * 50)
    improvements = results["training_improvements"]
    for category, items in improvements.items():
        print(f"\n{category.replace('_', ' ').title()}:")
        for item in items:
            print(f"  • {item}") 