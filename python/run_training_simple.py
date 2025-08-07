#!/usr/bin/env python3
"""
Simple Training Execution Script for BeforeDoctor
Runs all training modules without emojis to avoid encoding issues
"""

import sys
import os
import json
import time
import subprocess
from pathlib import Path
from datetime import datetime

class SimpleTrainingExecutor:
    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.progress_file = self.base_dir / "training_progress.json"
        self.results_file = self.base_dir / "training_results.json"
        self.log_dir = self.base_dir / "logs"
        self.log_dir.mkdir(exist_ok=True)
        
        self.training_modules = {
            "cdc": "cdc_training/cdc_model_trainer.py",
            "voice": "voice_training/voice_model_trainer.py", 
            "treatment": "treatment_training/treatment_model_trainer.py"
        }
        
        self.progress = {
            "start_time": datetime.now().isoformat(),
            "completed_modules": [],
            "failed_modules": [],
            "current_module": None,
            "overall_progress": 0.0
        }
        
    def save_progress(self):
        """Save current progress to file"""
        try:
            with open(self.progress_file, 'w', encoding='utf-8') as f:
                json.dump(self.progress, f, indent=2)
        except Exception as e:
            print(f"Error saving progress: {e}")
    
    def run_module(self, module_name, script_path):
        """Run a single training module"""
        print(f"Starting {module_name} training...")
        
        self.progress["current_module"] = module_name
        self.save_progress()
        
        try:
            # Run the module
            result = subprocess.run(
                [sys.executable, script_path],
                capture_output=True,
                text=True,
                cwd=self.base_dir
            )
            
            if result.returncode == 0:
                print(f"SUCCESS: {module_name} training completed")
                self.progress["completed_modules"].append(module_name)
                return True
            else:
                print(f"FAILED: {module_name} training failed")
                print(f"Error: {result.stderr}")
                self.progress["failed_modules"].append(module_name)
                return False
                
        except Exception as e:
            print(f"ERROR: {module_name} training exception: {e}")
            self.progress["failed_modules"].append(module_name)
            return False
        finally:
            self.progress["current_module"] = None
            self.save_progress()
    
    def run_all_modules(self):
        """Run all training modules"""
        print("Starting BeforeDoctor AI Training")
        print("=" * 50)
        
        total_modules = len(self.training_modules)
        completed = 0
        
        results = {}
        
        for module_name, script_path in self.training_modules.items():
            print(f"\n--- Training Module: {module_name.upper()} ---")
            
            success = self.run_module(module_name, script_path)
            results[module_name] = success
            
            if success:
                completed += 1
            
            # Update overall progress
            self.progress["overall_progress"] = (completed / total_modules) * 100
            self.save_progress()
            
            print(f"Progress: {completed}/{total_modules} modules completed")
            print(f"Overall Progress: {self.progress['overall_progress']:.1f}%")
        
        # Save final results
        final_results = {
            "training_completed": datetime.now().isoformat(),
            "total_modules": total_modules,
            "completed_modules": len(self.progress["completed_modules"]),
            "failed_modules": len(self.progress["failed_modules"]),
            "overall_progress": self.progress["overall_progress"],
            "results": results
        }
        
        with open(self.results_file, 'w', encoding='utf-8') as f:
            json.dump(final_results, f, indent=2)
        
        print(f"\n--- Training Complete ---")
        print(f"Completed: {len(self.progress['completed_modules'])}")
        print(f"Failed: {len(self.progress['failed_modules'])}")
        print(f"Overall Progress: {self.progress['overall_progress']:.1f}%")
        
        return final_results

def main():
    """Main function"""
    executor = SimpleTrainingExecutor()
    results = executor.run_all_modules()
    
    if results["failed_modules"] == 0:
        print("All training modules completed successfully!")
        return 0
    else:
        print(f"Some modules failed. Check logs for details.")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 