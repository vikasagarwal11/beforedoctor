# 🚀 BeforeDoctor AI Training System

Complete training pipeline for BeforeDoctor AI models with progress tracking, background execution, and monitoring capabilities.

## 📋 Overview

This training system processes your pediatric datasets and trains multiple AI models:

- **🗣️ Voice Training**: Convert voice input to structured symptoms
- **💊 Treatment Training**: Recommend age-appropriate treatments  
- **⚠️ CDC Training**: Risk assessment and emergency detection

## 🎯 Quick Start

### 1. Install Dependencies
```bash
cd python/
pip install -r requirements_training.txt
```

### 2. Run Training (Choose Your Method)

#### **Option A: Interactive Training** (Stay at terminal)
```bash
python run_training_robust.py
```
- ✅ Real-time progress updates
- ✅ Can pause/resume with Ctrl+C
- ✅ Detailed logging
- ⚠️ Must stay at terminal

#### **Option B: Background Training** (Step away from system)
```bash
python run_training_background.py
```
- ✅ Runs in background
- ✅ You can step away from system
- ✅ Auto-saves progress
- ✅ Continue working on other things

#### **Option C: Fresh Start**
```bash
python run_training_robust.py --fresh
python run_training_background.py --fresh
```

## 📊 Monitoring Training

### Real-time Monitoring
```bash
python monitor_training.py
```
- 🔄 Auto-refreshes every 10 seconds
- 📊 Shows progress percentage
- 📝 Shows recent log entries
- 🎯 Shows current module

### Quick Status Check
```bash
python monitor_training.py --quick
python run_training_background.py --status
```

### Manual Progress Check
```bash
cat training_progress.json
cat training_results.json
```

## 📁 Generated Files

After training, you'll have:

```
python/
├── training_progress.json     # 📊 Current progress
├── training_results.json      # 🎉 Final results
├── logs/                     # 📝 Detailed logs
│   └── training_*.log
├── voice_training/           # 🗣️ Voice models
│   ├── models/
│   └── processed/
├── treatment_training/        # 💊 Treatment models
│   ├── models/
│   └── processed/
└── cdc_training/            # ⚠️ CDC models
    ├── models/
    └── processed/
```

## ⏱️ Estimated Training Times

| Module | Dataset Size | Estimated Time | Description |
|--------|-------------|----------------|-------------|
| **CDC** | 400 records | 5-10 minutes | Risk assessment models |
| **Voice** | 5,064 records | 10-15 minutes | Voice-to-symptom models |
| **Treatment** | 26,794 records | 15-20 minutes | Treatment recommendation models |
| **Total** | 32,258 records | 30-45 minutes | Complete pipeline |

## 🔄 Resume Capability

The training system automatically saves progress after each module. If interrupted:

1. **Interactive Mode**: Press Ctrl+C to pause, progress is saved
2. **Background Mode**: Process continues even if you close terminal
3. **Resume**: Run same command to resume from where you left off

## 📊 Progress Tracking

### Progress File Structure
```json
{
  "start_time": "2024-01-15T10:30:00",
  "completed_modules": ["cdc", "voice"],
  "failed_modules": [],
  "current_module": "treatment",
  "overall_progress": 66.7
}
```

### Results File Structure
```json
{
  "start_time": "2024-01-15T10:30:00",
  "end_time": "2024-01-15T11:15:00",
  "completed": ["cdc", "voice", "treatment"],
  "failed": [],
  "total_modules": 3,
  "success_rate": 100.0
}
```

## 🛠️ Advanced Usage

### Run Specific Modules
```bash
# Run only voice training
python run_training_robust.py voice

# Run multiple specific modules
python run_training_robust.py voice treatment
```

### Check Background Process
```bash
# Check if background training is running
ps aux | grep background_training

# Kill background training
kill <process_id>
```

### View Logs
```bash
# View latest log
tail -f logs/training_*.log

# View background log
tail -f training_background_*.log
```

## 🚨 Troubleshooting

### Common Issues

#### **1. Module Not Found Error**
```bash
# Check if training scripts exist
ls voice_training/voice_model_trainer.py
ls treatment_training/treatment_model_trainer.py
ls cdc_training/cdc_model_trainer.py
```

#### **2. Dataset Not Found Error**
```bash
# Check if datasets exist
ls ../beforedoctor/assets/data/pediatric_symptom_dataset_comprehensive.json
ls ../beforedoctor/assets/data/pediatric_symptom_treatment_large.json
```

#### **3. Background Process Not Starting**
```bash
# Check nohup availability
which nohup

# Try running in foreground first
python run_training_robust.py
```

#### **4. Memory Issues**
```bash
# Monitor memory usage
htop
# or
top

# If needed, run modules individually
python run_training_robust.py cdc
python run_training_robust.py voice
python run_training_robust.py treatment
```

## 📈 Expected Results

### Success Metrics
- **Voice Model**: 85%+ accuracy for symptom classification
- **Treatment Model**: 90%+ accuracy for treatment recommendations
- **CDC Model**: 95%+ accuracy for risk assessment

### Output Files
- **Models**: `.pkl` files in each module's `models/` directory
- **Flutter Integration**: `.dart` files for Flutter app integration
- **Results**: JSON files with training metrics and results

## 🔧 Integration with Flutter

After training, integrate models into your Flutter app:

1. **Copy Models**: Copy `.pkl` files to Flutter assets
2. **Load Models**: Use generated Dart integration code
3. **Test Integration**: Verify models work in Flutter app

## 📞 Support

If you encounter issues:

1. **Check Logs**: Review `logs/` directory for detailed error messages
2. **Verify Dependencies**: Ensure all requirements are installed
3. **Check Datasets**: Verify dataset files exist and are accessible
4. **Monitor Resources**: Ensure sufficient memory and disk space

## 🎉 Success Checklist

- [ ] All dependencies installed
- [ ] Datasets available in `assets/data/`
- [ ] Training completed successfully
- [ ] Models generated in `*/models/` directories
- [ ] Flutter integration code generated
- [ ] Models integrated into Flutter app
- [ ] Testing completed with real voice input

---

**Happy Training! 🚀✨** 