#!/usr/bin/env python3
"""
Test script for Diseases_Symptoms training module
"""

import sys
import os
from pathlib import Path

# Add the diseases_symptoms_training directory to Python path
training_dir = Path(__file__).parent / "diseases_symptoms_training"
sys.path.insert(0, str(training_dir))

def test_diseases_symptoms_training():
    """Test the diseases_symptoms training module"""
    try:
        print("🧪 Testing Diseases_Symptoms Training Module...")
        print("=" * 50)
        
        # Test import
        from diseases_symptoms_trainer import DiseasesSymptomsTrainer
        print("✅ Import successful")
        
        # Test initialization
        trainer = DiseasesSymptomsTrainer()
        print("✅ Trainer initialization successful")
        
        # Test directory creation
        assert trainer.data_dir.exists(), "Data directory should exist"
        assert trainer.processed_dir.exists(), "Processed directory should exist"
        assert trainer.models_dir.exists(), "Models directory should exist"
        assert trainer.outputs_dir.exists(), "Outputs directory should exist"
        print("✅ Directory structure created successfully")
        
        # Test dataset download (this will actually download the dataset)
        print("\n🔄 Testing dataset download...")
        download_success = trainer.download_dataset()
        if download_success:
            print("✅ Dataset download successful")
        else:
            print("❌ Dataset download failed")
            return False
        
        # Test dataset processing
        print("\n🔄 Testing dataset processing...")
        process_success = trainer.process_dataset()
        if process_success:
            print("✅ Dataset processing successful")
        else:
            print("❌ Dataset processing failed")
            return False
        
        # Test model training
        print("\n🔄 Testing model training...")
        train_success = trainer.train_models()
        if train_success:
            print("✅ Model training successful")
        else:
            print("❌ Model training failed")
            return False
        
        # Test Flutter integration creation
        print("\n🔄 Testing Flutter integration creation...")
        flutter_success = trainer.create_flutter_integration()
        if flutter_success:
            print("✅ Flutter integration creation successful")
        else:
            print("❌ Flutter integration creation failed")
            return False
        
        print("\n🎉 All tests passed successfully!")
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Make sure you have installed the required dependencies:")
        print("   pip install -r python/diseases_symptoms_training/requirements.txt")
        return False
    except Exception as e:
        print(f"❌ Test error: {e}")
        return False

def main():
    """Main test function"""
    success = test_diseases_symptoms_training()
    
    if success:
        print("\n✅ Diseases_Symptoms training module is working correctly!")
        print("\n📁 Next steps:")
        print("1. Run full training: python python/run_diseases_symptoms_training.py")
        print("2. Integrate with Flutter app")
        print("3. Test with voice logger screen")
        sys.exit(0)
    else:
        print("\n❌ Diseases_Symptoms training module has issues!")
        sys.exit(1)

if __name__ == "__main__":
    main() 