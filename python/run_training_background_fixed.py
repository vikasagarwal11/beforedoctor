#!/usr/bin/env python3
"""
Background Training Execution Script for BeforeDoctor
Runs training in background with nohup - you can step away from system
"""

import sys
import os
import subprocess
import time
from pathlib import Path
from datetime import datetime

def create_background_script():
    """Create a background execution script"""
    script_content = '''#!/usr/bin/env python3
"""
Background Training Script - Auto-generated
This script runs the robust training executor in background
"""

import sys
import os
from pathlib import Path

# Add current directory to Python path
sys.path.append(str(Path(__file__).parent))

def main():
    try:
        from run_training_robust import RobustTrainingExecutor
        
        print("Starting background training...")
        print("All output will be logged to logs/ directory")
        print("Progress will be saved automatically")
        print("You can step away from the system now!")
        
        executor = RobustTrainingExecutor()
        results = executor.run_all_modules()
        
        print("Background training completed!")
        return 0
        
    except Exception as e:
        print(f"Background training error: {e}")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
'''
    
    script_path = Path("background_training.py")
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    # Make executable
    os.chmod(script_path, 0o755)
    return script_path

def run_background_training():
    """Run training in background using nohup"""
    print("Starting BeforeDoctor AI Training in Background")
    print("=" * 60)
    
    # Create background script
    script_path = create_background_script()
    
    # Create log file with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"training_background_{timestamp}.log"
    
    # Create nohup command
    nohup_cmd = [
        "nohup",
        sys.executable,
        str(script_path),
        ">",
        log_file,
        "2>&1",
        "&"
    ]
    
    print(f"Training will run in background")
    print(f"Progress will be saved to: training_progress.json")
    print(f"Logs will be saved to: {log_file}")
    print(f"Estimated time: 30-45 minutes")
    print(f"You can step away from the system now!")
    print(f"Check progress with: tail -f {log_file}")
    print(f"Check results with: cat training_results.json")
    
    print(f"Starting background process...")
    
    try:
        # Run nohup command
        process = subprocess.Popen(
            " ".join(nohup_cmd),
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Get the process ID
        time.sleep(2)  # Give it time to start
        
        print(f"Background training started successfully!")
        print(f"Process ID: {process.pid}")
        print(f"Log file: {log_file}")
        
        # Show how to monitor
        print(f"To monitor progress:")
        print(f"   tail -f {log_file}")
        print(f"   cat training_progress.json")
        
        print(f"To stop training:")
        print(f"   kill {process.pid}")
        
        print(f"Files to check:")
        print(f"   Progress: training_progress.json")
        print(f"   Results: training_results.json")
        print(f"   Logs: logs/ directory")
        print(f"   Background log: {log_file}")
        
        return process.pid
        
    except Exception as e:
        print(f"Error starting background training: {e}")
        return None

def check_background_status():
    """Check status of background training"""
    print("Checking background training status...")
    
    # Check if progress file exists
    progress_file = Path("training_progress.json")
    if progress_file.exists():
        try:
            import json
            with open(progress_file, 'r') as f:
                progress = json.load(f)
            
            print(f"Training Progress:")
            print(f"   Completed: {len(progress.get('completed_modules', []))}")
            print(f"   Failed: {len(progress.get('failed_modules', []))}")
            print(f"   Overall Progress: {progress.get('overall_progress', 0):.1f}%")
            
            if progress.get('current_module'):
                print(f"   Current Module: {progress['current_module']}")
            
        except Exception as e:
            print(f"Could not read progress: {e}")
    else:
        print("No progress file found - training may not have started")
    
    # Check if results file exists
    results_file = Path("training_results.json")
    if results_file.exists():
        print(f"Training completed! Check: {results_file}")
    else:
        print("Training still in progress...")

def main():
    """Main function"""
    if len(sys.argv) > 1:
        if sys.argv[1] == "--status":
            check_background_status()
            return 0
        elif sys.argv[1] == "--help":
            print("BeforeDoctor Background Training")
            print("Usage:")
            print("  python run_training_background_fixed.py          # Start background training")
            print("  python run_training_background_fixed.py --status # Check training status")
            print("  python run_training_background_fixed.py --help   # Show this help")
            return 0
        else:
            print(f"Unknown argument: {sys.argv[1]}")
            print("Use --help for usage information")
            return 1
    
    # Start background training
    pid = run_background_training()
    
    if pid:
        print(f"Background training started with PID: {pid}")
        print(f"You can now step away from the system!")
        print(f"Check status later with: python run_training_background_fixed.py --status")
        return 0
    else:
        print(f"Failed to start background training")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 