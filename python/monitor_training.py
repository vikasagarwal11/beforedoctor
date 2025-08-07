#!/usr/bin/env python3
"""
Training Monitor for BeforeDoctor
Real-time monitoring of training progress
"""

import os
import json
import time
from pathlib import Path
from datetime import datetime

def monitor_training():
    """Monitor training progress in real-time"""
    print("📊 BeforeDoctor Training Monitor")
    print("=" * 40)
    
    progress_file = Path("training_progress.json")
    results_file = Path("training_results.json")
    
    print("🔍 Monitoring training progress...")
    print("Press Ctrl+C to stop monitoring")
    print()
    
    try:
        while True:
            # Clear screen (works on most terminals)
            os.system('cls' if os.name == 'nt' else 'clear')
            
            print("📊 BeforeDoctor Training Monitor")
            print("=" * 40)
            print(f"⏰ Last Update: {datetime.now().strftime('%H:%M:%S')}")
            print()
            
            # Check progress file
            if progress_file.exists():
                try:
                    with open(progress_file, 'r') as f:
                        progress = json.load(f)
                    
                    print("📋 Training Progress:")
                    print(f"   ✅ Completed: {len(progress.get('completed_modules', []))}")
                    print(f"   ❌ Failed: {len(progress.get('failed_modules', []))}")
                    print(f"   📊 Overall Progress: {progress.get('overall_progress', 0):.1f}%")
                    
                    if progress.get('current_module'):
                        print(f"   🎯 Current Module: {progress['current_module']}")
                    
                    # Show completed modules
                    if progress.get('completed_modules'):
                        print(f"\n✅ Completed Modules:")
                        for module in progress['completed_modules']:
                            print(f"   • {module}")
                    
                    # Show failed modules
                    if progress.get('failed_modules'):
                        print(f"\n❌ Failed Modules:")
                        for module in progress['failed_modules']:
                            print(f"   • {module}")
                    
                except Exception as e:
                    print(f"⚠️ Could not read progress: {e}")
            else:
                print("❌ No progress file found")
            
            # Check results file
            if results_file.exists():
                try:
                    with open(results_file, 'r') as f:
                        results = json.load(f)
                    
                    print(f"\n🎉 Training Completed!")
                    print(f"   📈 Success Rate: {results.get('success_rate', 0):.1f}%")
                    print(f"   ✅ Successful: {len(results.get('completed', []))}")
                    print(f"   ❌ Failed: {len(results.get('failed', []))}")
                    
                    print(f"\n📁 Check results in: {results_file}")
                    break
                    
                except Exception as e:
                    print(f"⚠️ Could not read results: {e}")
            
            # Check log files
            log_dir = Path("logs")
            if log_dir.exists():
                log_files = list(log_dir.glob("*.log"))
                if log_files:
                    latest_log = max(log_files, key=lambda x: x.stat().st_mtime)
                    print(f"\n📝 Latest Log: {latest_log.name}")
                    
                    # Show last few lines of log
                    try:
                        with open(latest_log, 'r') as f:
                            lines = f.readlines()
                            if lines:
                                print("📄 Recent Log Entries:")
                                for line in lines[-3:]:  # Last 3 lines
                                    print(f"   {line.strip()}")
                    except Exception as e:
                        print(f"⚠️ Could not read log: {e}")
            
            print(f"\n🔄 Refreshing in 10 seconds... (Ctrl+C to stop)")
            time.sleep(10)
            
    except KeyboardInterrupt:
        print(f"\n🛑 Monitoring stopped")
        print(f"📊 Final status saved in: {progress_file}")
        if results_file.exists():
            print(f"🎉 Results available in: {results_file}")

def show_quick_status():
    """Show quick training status"""
    progress_file = Path("training_progress.json")
    results_file = Path("training_results.json")
    
    print("📊 Quick Training Status")
    print("=" * 30)
    
    if results_file.exists():
        print("✅ Training completed!")
        try:
            with open(results_file, 'r') as f:
                results = json.load(f)
            print(f"📈 Success Rate: {results.get('success_rate', 0):.1f}%")
        except:
            pass
    elif progress_file.exists():
        try:
            with open(progress_file, 'r') as f:
                progress = json.load(f)
            print(f"⏳ Training in progress...")
            print(f"📊 Progress: {progress.get('overall_progress', 0):.1f}%")
            print(f"✅ Completed: {len(progress.get('completed_modules', []))}")
            print(f"❌ Failed: {len(progress.get('failed_modules', []))}")
        except:
            print("⏳ Training in progress...")
    else:
        print("❌ No training session found")

def main():
    """Main function"""
    if len(sys.argv) > 1:
        if sys.argv[1] == "--quick":
            show_quick_status()
            return 0
        elif sys.argv[1] == "--help":
            print("BeforeDoctor Training Monitor")
            print("Usage:")
            print("  python monitor_training.py        # Start real-time monitoring")
            print("  python monitor_training.py --quick # Show quick status")
            print("  python monitor_training.py --help  # Show this help")
            return 0
        else:
            print(f"❌ Unknown argument: {sys.argv[1]}")
            print("Use --help for usage information")
            return 1
    
    # Start monitoring
    monitor_training()
    return 0

if __name__ == "__main__":
    import sys
    exit_code = main()
    sys.exit(exit_code) 