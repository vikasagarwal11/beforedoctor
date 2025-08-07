#!/usr/bin/env python3
"""
Robust Training Execution Script for BeforeDoctor
Features: Progress tracking, logging, background execution, resume capability
"""

import sys
import os
import time
import json
import logging
import signal
import subprocess
from datetime import datetime
from pathlib import Path
import threading
from typing import Dict, List, Optional

# Set up comprehensive logging
def setup_logging():
    """Setup comprehensive logging with file and console output"""
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"training_{timestamp}.log"
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    return logging.getLogger(__name__)

class RobustTrainingExecutor:
    def __init__(self):
        self.logger = setup_logging()
        self.base_dir = Path(__file__).parent
        self.progress_file = self.base_dir / "training_progress.json"
        self.results_file = self.base_dir / "training_results.json"
        self.is_running = True
        
        # Training modules configuration
        self.training_modules = {
            "cdc": {
                "script": "cdc_training/cdc_model_trainer.py",
                "description": "CDC Risk Assessment Models",
                "estimated_time": "5-10 minutes",
                "dataset": "CDC synthetic data (400 records)"
            },
            "voice": {
                "script": "voice_training/voice_model_trainer.py",
                "description": "Voice-to-Symptom Models",
                "estimated_time": "10-15 minutes",
                "dataset": "pediatric_symptom_dataset_comprehensive.json (5,064 records)"
            },
            "treatment": {
                "script": "treatment_training/treatment_model_trainer.py",
                "description": "Treatment Recommendation Models",
                "estimated_time": "15-20 minutes",
                "dataset": "pediatric_symptom_treatment_large.json (26,794 records)"
            }
        }
        
        # Load previous progress if exists
        self.progress = self.load_progress()
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def signal_handler(self, signum, frame):
        """Handle interrupt signals gracefully"""
        self.logger.info("🛑 Received interrupt signal. Saving progress and shutting down gracefully...")
        self.save_progress()
        self.is_running = False
        sys.exit(0)
    
    def load_progress(self) -> Dict:
        """Load previous training progress"""
        if self.progress_file.exists():
            try:
                with open(self.progress_file, 'r') as f:
                    progress = json.load(f)
                self.logger.info(f"📋 Loaded previous progress: {len(progress.get('completed_modules', []))} modules completed")
                return progress
            except Exception as e:
                self.logger.warning(f"⚠️ Could not load previous progress: {e}")
        
        return {
            "start_time": datetime.now().isoformat(),
            "completed_modules": [],
            "failed_modules": [],
            "current_module": None,
            "overall_progress": 0
        }
    
    def save_progress(self):
        """Save current training progress"""
        try:
            with open(self.progress_file, 'w') as f:
                json.dump(self.progress, f, indent=2)
            self.logger.info("💾 Progress saved successfully")
        except Exception as e:
            self.logger.error(f"❌ Error saving progress: {e}")
    
    def print_banner(self):
        """Print training banner with instructions"""
        banner = """
╔══════════════════════════════════════════════════════════════╗
║                    BeforeDoctor AI Training                  ║
║                                                              ║
║  🚀 Starting comprehensive AI model training pipeline       ║
║  📊 Progress tracking enabled                               ║
║  💾 Auto-save progress every module                        ║
║  🔄 Resume capability if interrupted                       ║
║  📝 Detailed logging to logs/ directory                    ║
║                                                              ║
║  Press Ctrl+C to pause training (progress will be saved)   ║
╚══════════════════════════════════════════════════════════════╝
        """
        print(banner)
    
    def print_module_info(self):
        """Print information about training modules"""
        print("\n📋 Training Modules:")
        print("=" * 60)
        
        for module_name, config in self.training_modules.items():
            status = "✅ COMPLETED" if module_name in self.progress["completed_modules"] else "⏳ PENDING"
            print(f"{status} | {module_name.upper()}")
            print(f"   Description: {config['description']}")
            print(f"   Estimated Time: {config['estimated_time']}")
            print(f"   Dataset: {config['dataset']}")
            print()
    
    def run_module_with_progress(self, module_name: str) -> bool:
        """Run a single training module with progress tracking"""
        if not self.is_running:
            return False
        
        config = self.training_modules[module_name]
        self.progress["current_module"] = module_name
        
        self.logger.info(f"🎯 Starting {module_name} training module...")
        self.logger.info(f"📝 Description: {config['description']}")
        self.logger.info(f"⏱️  Estimated time: {config['estimated_time']}")
        self.logger.info(f"📊 Dataset: {config['dataset']}")
        
        start_time = time.time()
        
        try:
            # Run the training module
            script_path = self.base_dir / config["script"]
            
            if not script_path.exists():
                self.logger.error(f"❌ Training script not found: {script_path}")
                return False
            
            # Run with subprocess and capture output
            process = subprocess.Popen(
                [sys.executable, str(script_path)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=self.base_dir
            )
            
            # Monitor process with progress updates
            while process.poll() is None and self.is_running:
                time.sleep(5)  # Check every 5 seconds
                elapsed = time.time() - start_time
                self.logger.info(f"⏳ {module_name} training in progress... ({elapsed:.0f}s elapsed)")
            
            # Get final output
            stdout, stderr = process.communicate()
            
            if process.returncode == 0:
                elapsed = time.time() - start_time
                self.logger.info(f"✅ {module_name} training completed successfully! ({elapsed:.0f}s)")
                
                # Add to completed modules
                if module_name not in self.progress["completed_modules"]:
                    self.progress["completed_modules"].append(module_name)
                
                # Update overall progress
                total_modules = len(self.training_modules)
                completed = len(self.progress["completed_modules"])
                self.progress["overall_progress"] = (completed / total_modules) * 100
                
                self.save_progress()
                return True
            else:
                self.logger.error(f"❌ {module_name} training failed!")
                self.logger.error(f"Error output: {stderr}")
                
                # Add to failed modules
                if module_name not in self.progress["failed_modules"]:
                    self.progress["failed_modules"].append(module_name)
                
                self.save_progress()
                return False
                
        except Exception as e:
            self.logger.error(f"❌ Error running {module_name} training: {e}")
            return False
    
    def run_all_modules(self) -> Dict:
        """Run all training modules with comprehensive tracking"""
        self.print_banner()
        self.print_module_info()
        
        # Check if we should resume or start fresh
        if self.progress["completed_modules"]:
            print(f"\n🔄 Resuming from previous session...")
            print(f"✅ Completed: {len(self.progress['completed_modules'])} modules")
            print(f"❌ Failed: {len(self.progress['failed_modules'])} modules")
            
            resume = input("\n❓ Resume training? (y/n): ").lower().strip()
            if resume != 'y':
                self.progress = {
                    "start_time": datetime.now().isoformat(),
                    "completed_modules": [],
                    "failed_modules": [],
                    "current_module": None,
                    "overall_progress": 0
                }
                self.save_progress()
        
        total_modules = len(self.training_modules)
        results = {
            "start_time": datetime.now().isoformat(),
            "completed": [],
            "failed": [],
            "total_modules": total_modules
        }
        
        print(f"\n🚀 Starting training pipeline...")
        print(f"📊 Total modules: {total_modules}")
        print(f"⏱️  Estimated total time: 30-45 minutes")
        print(f"💾 Progress will be saved automatically")
        print(f"📝 Logs saved to: logs/ directory")
        
        # Run each module
        for i, (module_name, config) in enumerate(self.training_modules.items(), 1):
            if not self.is_running:
                break
            
            # Skip if already completed
            if module_name in self.progress["completed_modules"]:
                self.logger.info(f"⏭️  Skipping {module_name} (already completed)")
                results["completed"].append(module_name)
                continue
            
            print(f"\n{'='*60}")
            print(f"🎯 Module {i}/{total_modules}: {module_name.upper()}")
            print(f"📝 {config['description']}")
            print(f"⏱️  Estimated time: {config['estimated_time']}")
            print(f"{'='*60}")
            
            success = self.run_module_with_progress(module_name)
            
            if success:
                results["completed"].append(module_name)
                print(f"✅ {module_name} completed successfully!")
            else:
                results["failed"].append(module_name)
                print(f"❌ {module_name} failed!")
            
            # Progress update
            completed = len(results["completed"])
            progress_percent = (completed / total_modules) * 100
            print(f"📊 Overall Progress: {progress_percent:.1f}% ({completed}/{total_modules})")
            
            # Brief pause between modules
            if i < total_modules and self.is_running:
                print("⏸️  Pausing 5 seconds before next module...")
                time.sleep(5)
        
        # Final results
        results["end_time"] = datetime.now().isoformat()
        results["success_rate"] = len(results["completed"]) / total_modules * 100
        
        self.save_final_results(results)
        self.print_final_summary(results)
        
        return results
    
    def save_final_results(self, results: Dict):
        """Save final training results"""
        try:
            with open(self.results_file, 'w') as f:
                json.dump(results, f, indent=2)
            self.logger.info(f"💾 Final results saved to: {self.results_file}")
        except Exception as e:
            self.logger.error(f"❌ Error saving final results: {e}")
    
    def print_final_summary(self, results: Dict):
        """Print final training summary"""
        print("\n" + "="*60)
        print("🎉 TRAINING PIPELINE COMPLETED!")
        print("="*60)
        
        print(f"📊 Final Results:")
        print(f"   ✅ Successful: {len(results['completed'])} modules")
        print(f"   ❌ Failed: {len(results['failed'])} modules")
        print(f"   📈 Success Rate: {results['success_rate']:.1f}%")
        
        if results["completed"]:
            print(f"\n✅ Completed Modules:")
            for module in results["completed"]:
                print(f"   • {module}")
        
        if results["failed"]:
            print(f"\n❌ Failed Modules:")
            for module in results["failed"]:
                print(f"   • {module}")
        
        print(f"\n📁 Files Generated:")
        print(f"   • Training results: {self.results_file}")
        print(f"   • Progress file: {self.progress_file}")
        print(f"   • Log files: logs/ directory")
        
        print(f"\n🚀 Next Steps:")
        print(f"   • Check logs/ for detailed training logs")
        print(f"   • Review training results in {self.results_file}")
        print(f"   • Integrate trained models into Flutter app")
        
        print("\n" + "="*60)

def main():
    """Main execution function"""
    try:
        executor = RobustTrainingExecutor()
        
        # Check command line arguments
        if len(sys.argv) > 1:
            if sys.argv[1] == "--resume":
                print("🔄 Resuming previous training session...")
            elif sys.argv[1] == "--fresh":
                print("🆕 Starting fresh training session...")
                # Clear previous progress
                progress_file = Path("training_progress.json")
                if progress_file.exists():
                    progress_file.unlink()
            else:
                print(f"❌ Unknown argument: {sys.argv[1]}")
                print("Usage: python run_training_robust.py [--resume|--fresh]")
                return 1
        else:
            print("🚀 Starting new training session...")
        
        # Run training pipeline
        results = executor.run_all_modules()
        
        return 0 if results["success_rate"] >= 50 else 1
        
    except KeyboardInterrupt:
        print("\n🛑 Training interrupted by user")
        return 1
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 