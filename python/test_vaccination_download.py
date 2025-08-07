#!/usr/bin/env python3
"""
Test script for vaccination coverage dataset download
"""

import sys
import os
from pathlib import Path

# Add the current directory to Python path
sys.path.append(str(Path(__file__).parent))

try:
    from vaccination_coverage_downloader import VaccinationDatasetDownloader
    
    print("🚀 Testing Vaccination Coverage Dataset Download...")
    print("=" * 50)
    
    # Initialize downloader
    downloader = VaccinationDatasetDownloader()
    
    # Test download
    print("📥 Attempting to download dataset...")
    success = downloader.run()
    
    if success:
        print("✅ Vaccination dataset download test completed successfully!")
        print("\n📁 Generated files:")
        print(f"   • Flutter service: {downloader.outputs_dir}/vaccination_coverage_service.dart")
        print(f"   • Dataset info: {downloader.processed_dir}/dataset_info.json")
        print(f"   • Data directory: {downloader.data_dir}")
        
        # Check if Flutter service was created
        flutter_file = downloader.outputs_dir / "vaccination_coverage_service.dart"
        if flutter_file.exists():
            print(f"✅ Flutter integration service created: {flutter_file}")
        else:
            print("❌ Flutter service file not found")
            
    else:
        print("❌ Vaccination dataset download test failed!")
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure you have the required dependencies installed:")
    print("pip install pandas kagglehub")
    
except Exception as e:
    print(f"❌ Test failed with error: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 50)
print("Test completed!") 