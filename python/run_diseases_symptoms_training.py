#!/usr/bin/env python3
"""
Runner script for Diseases_Symptoms training
"""

import sys
import os
from pathlib import Path

# Add the diseases_symptoms_training directory to Python path
training_dir = Path(__file__).parent / "diseases_symptoms_training"
sys.path.insert(0, str(training_dir))

try:
    from diseases_symptoms_trainer import DiseasesSymptomsTrainer
    
    print("🚀 Starting Diseases_Symptoms Training...")
    print("=" * 50)
    
    trainer = DiseasesSymptomsTrainer()
    success = trainer.run_complete_pipeline()
    
    if success:
        print("\n🎉 Diseases_Symptoms training completed successfully!")
        print("\n📁 Generated files:")
        print(f"  - Models: {trainer.models_dir}")
        print(f"  - Results: {trainer.outputs_dir}")
        print(f"  - Processed data: {trainer.processed_dir}")
        sys.exit(0)
    else:
        print("\n❌ Diseases_Symptoms training failed!")
        sys.exit(1)
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("💡 Make sure you have installed the required dependencies:")
    print("   pip install -r python/diseases_symptoms_training/requirements.txt")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1) 