#!/usr/bin/env python3
"""
Training Execution Script for BeforeDoctor
Simple script to run all training modules
"""

import sys
import os
from pathlib import Path

# Add the current directory to Python path
sys.path.append(str(Path(__file__).parent))

def main():
    """Main execution function"""
    print("🚀 Starting BeforeDoctor AI Training Pipeline")
    print("=" * 50)
    
    # Import and run the orchestrator
    try:
        from master_training_orchestrator import MasterTrainingOrchestrator
        
        orchestrator = MasterTrainingOrchestrator()
        
        # Check if specific modules are requested
        if len(sys.argv) > 1:
            modules = sys.argv[1:]
            print(f"🎯 Running specific modules: {modules}")
            results = orchestrator.run_specific_modules(modules)
        else:
            print("🎯 Running all training modules")
            results = orchestrator.run_all_training_modules()
        
        # Print results
        print("\n📊 Training Results:")
        print("=" * 30)
        
        for module_name, result in results.items():
            status = result["status"]
            emoji = "✅" if status == "success" else "❌"
            print(f"{emoji} {module_name}: {status}")
        
        print("\n🎉 Training pipeline completed!")
        
    except ImportError as e:
        print(f"❌ Error importing training modules: {e}")
        print("Make sure all training files are in the correct location")
        return 1
    except Exception as e:
        print(f"❌ Error running training pipeline: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 