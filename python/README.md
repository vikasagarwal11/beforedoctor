# BeforeDoctor Dataset Training Pipeline

This directory contains the complete training pipeline for both CDC pediatric health data and Medical Q&A datasets.

## 📁 Directory Structure

```
python/
├── download_datasets.py              # Download both datasets
├── run_parallel_training.py          # Run both trainings in parallel
├── requirements.txt                  # Python dependencies
├── cdc_training/
│   ├── train_cdc_models.py          # CDC training script
│   ├── cdc_data_processor.py        # CDC data processor
│   ├── data/                        # CDC dataset files
│   └── processed/                   # Trained CDC models
├── medical_qa_training/
│   ├── train_medical_qa.py          # Medical Q&A training script
│   ├── medical_qa_processor.py      # Medical Q&A processor
│   ├── data/                        # Medical Q&A dataset files
│   └── processed/                   # Trained Medical Q&A models
└── README.md                        # This file
```

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
# Navigate to python directory
cd python

# Install Python dependencies
pip install -r requirements.txt
```

### Step 2: Download Datasets

```bash
# Download both CDC and Medical Q&A datasets
python download_datasets.py
```

This will:
- Download CDC pediatric health dataset from Kaggle
- Download Medical Q&A dataset from Kaggle
- Create necessary directories
- Copy files to appropriate locations

### Step 3: Run Training

#### Option A: Parallel Training (Recommended)
```bash
# Run both trainings simultaneously
python run_parallel_training.py
```

#### Option B: Individual Training
```bash
# Train CDC models only
python cdc_training/train_cdc_models.py

# Train Medical Q&A models only
python medical_qa_training/train_medical_qa.py
```

## 📊 Dataset Information

### CDC Dataset
- **Source**: CDC Health Conditions Among Children Under 18 Years
- **Content**: Pediatric health statistics, prevalence data, demographic patterns
- **Purpose**: Risk assessment, age-specific analysis, statistical modeling
- **Expected Size**: ~50MB
- **Training Time**: 2-3 hours

### Medical Q&A Dataset
- **Source**: Comprehensive Medical Q&A Dataset
- **Content**: Medical questions and answers, professional responses
- **Purpose**: Natural language processing, response generation
- **Expected Size**: ~100MB
- **Training Time**: 4-6 hours

## 🔧 Detailed Instructions

### Manual Execution Steps

#### 1. Environment Setup
```bash
# Navigate to project root
cd C:\Vikas\Projects\Healthcare\beforedoctor

# Create and activate virtual environment (optional but recommended)
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# Install dependencies
cd python
pip install -r requirements.txt
```

#### 2. Dataset Download
```bash
# From python directory
python download_datasets.py
```

**Expected Output:**
```
🚀 BeforeDoctor Dataset Download Script
==================================================
✅ Created directory: python/cdc_training/data
✅ Created directory: python/cdc_training/processed
✅ Created directory: python/medical_qa_training/data
✅ Created directory: python/medical_qa_training/processed

🔄 Downloading CDC dataset...
Dataset: cdc/health-conditions-among-children-under-18-years
✅ CDC dataset downloaded to: /path/to/download
📄 Copied: cdc_data.csv
🎉 CDC dataset ready! 1 files copied to python/cdc_training/data

🔄 Downloading Medical Q&A dataset...
Dataset: thedevastator/comprehensive-medical-q-a-dataset
✅ Medical Q&A dataset downloaded to: /path/to/download
📄 Copied: medical_qa_data.csv
🎉 Medical Q&A dataset ready! 1 files copied to python/medical_qa_training/data

==================================================
📊 Download Summary:
CDC Dataset: ✅ Success
Medical Q&A: ✅ Success

🎉 Both datasets downloaded successfully!

📁 Next Steps:
1. Run CDC training: python python/cdc_training/train_cdc_models.py
2. Run Medical Q&A training: python python/medical_qa_training/train_medical_qa.py
3. Or run both in parallel using the provided scripts
```

#### 3. Training Execution

**Option A: Parallel Training (Recommended)**
```bash
# From python directory
python run_parallel_training.py
```

**Option B: Sequential Training**
```bash
# Train CDC first
python cdc_training/train_cdc_models.py

# Then train Medical Q&A
python medical_qa_training/train_medical_qa.py
```

**Option C: Individual Training with Monitoring**
```bash
# Terminal 1: CDC Training
python cdc_training/train_cdc_models.py

# Terminal 2: Medical Q&A Training (in new terminal)
python medical_qa_training/train_medical_qa.py
```

### Expected Training Output

#### CDC Training
```
🏥 CDC Model Training for BeforeDoctor
==================================================
📊 Found 1 CDC dataset files
✅ Loaded cdc_data.csv: 1000 rows, 15 columns
🔄 Processing real CDC data...
📋 Columns: ['age_group', 'condition', 'prevalence', 'gender', 'region']
🎯 Found age columns: ['age_group']
🏥 Found condition columns: ['condition']
📈 Found prevalence columns: ['prevalence']
✅ Processed 800 training examples from real CDC data
🔄 Training CDC models...
📊 Model accuracy: 0.9234
💾 Saving CDC models...
✅ Models saved to python/cdc_training/processed
📱 Generating Flutter integration...
✅ Flutter integration saved to lib/core/services/cdc_risk_assessment_service.dart

✅ CDC training completed!
📁 Models saved to: python/cdc_training/processed/
📱 Flutter integration ready!
```

#### Medical Q&A Training
```
🏥 Medical Q&A Model Training for BeforeDoctor
==================================================
📊 Found 1 Medical Q&A dataset files
✅ Loaded medical_qa_data.csv: 5000 rows, 8 columns
🔄 Processing real Medical Q&A data...
📋 Columns: ['question', 'answer', 'category', 'specialty', 'difficulty']
❓ Found question columns: ['question']
💬 Found answer columns: ['answer']
🏷️ Found category columns: ['category', 'specialty']
✅ Processed 4500 training examples from real Medical Q&A data
🔄 Training Medical Q&A models...
📊 Model accuracy: 0.8765
💾 Saving Medical Q&A models...
✅ Models saved to python/medical_qa_training/processed
📱 Generating Flutter integration...
✅ Flutter integration saved to lib/core/services/medical_qa_service.dart

✅ Medical Q&A training completed!
📁 Models saved to: python/medical_qa_training/processed/
📱 Flutter integration ready!
```

## 📁 Output Files

### CDC Training Output
```
python/cdc_training/processed/
├── cdc_risk_model.pkl              # Trained Random Forest model
├── cdc_training_data.json          # Processed training data
├── cdc_model_info.json             # Model metadata
└── cdc_training.log                # Training logs
```

### Medical Q&A Training Output
```
python/medical_qa_training/processed/
├── medical_qa_model/               # Trained transformer model
│   ├── config.json
│   ├── pytorch_model.bin
│   └── tokenizer.json
├── category_mapping.json           # Category mappings
├── medical_qa_model_info.json     # Model metadata
└── medical_qa_training.log        # Training logs
```

### Flutter Integration
```
lib/core/services/
├── cdc_risk_assessment_service.dart    # CDC integration
└── medical_qa_service.dart             # Medical Q&A integration
```

## 🔍 Monitoring and Debugging

### Check Training Progress
```bash
# Monitor CDC training logs
tail -f python/cdc_training/cdc_training.log

# Monitor Medical Q&A training logs
tail -f python/medical_qa_training/medical_qa_training.log
```

### Verify Dataset Downloads
```bash
# Check CDC data
ls -la python/cdc_training/data/

# Check Medical Q&A data
ls -la python/medical_qa_training/data/
```

### Check Model Outputs
```bash
# Verify CDC models
ls -la python/cdc_training/processed/

# Verify Medical Q&A models
ls -la python/medical_qa_training/processed/
```

## ⚠️ Troubleshooting

### Common Issues

#### 1. KaggleHub Installation Error
```bash
# If kagglehub installation fails
pip install --upgrade pip
pip install kagglehub --no-cache-dir
```

#### 2. Memory Issues
```bash
# For large datasets, reduce batch size in medical_qa_processor.py
per_device_train_batch_size=4  # Reduce from 8
per_device_eval_batch_size=4   # Reduce from 8
```

#### 3. CUDA/GPU Issues
```bash
# Force CPU training
export CUDA_VISIBLE_DEVICES=""
# Or in Windows
set CUDA_VISIBLE_DEVICES=
```

#### 4. Dataset Download Failures
```bash
# Manual download fallback
# Download from Kaggle website and place in respective data/ directories
```

## 📈 Performance Expectations

### Training Times (Approximate)
- **CDC Training**: 2-3 hours (CPU), 1-2 hours (GPU)
- **Medical Q&A Training**: 4-6 hours (CPU), 2-3 hours (GPU)
- **Parallel Training**: 4-6 hours total

### Model Accuracy Targets
- **CDC Risk Assessment**: >90% accuracy
- **Medical Q&A Classification**: >85% accuracy

### System Requirements
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 2GB free space
- **CPU**: 4+ cores recommended
- **GPU**: Optional but recommended for faster training

## 🎯 Next Steps

After successful training:

1. **Integrate with Flutter App**
   - Models are automatically integrated via generated Dart services
   - Test integration in voice_logger_screen.dart

2. **Validate Results**
   - Test CDC risk assessment with sample pediatric cases
   - Test Medical Q&A with sample medical questions

3. **Deploy to Production**
   - Models are ready for production use
   - Monitor performance and accuracy in real-world usage

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review training logs for specific error messages
3. Verify dataset downloads and file permissions
4. Ensure all dependencies are properly installed 