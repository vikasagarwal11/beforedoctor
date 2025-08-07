# Model Versioning Strategy

## Overview
This document outlines how ML models are versioned, stored, and managed in the BeforeDoctor project.

## Model Storage Strategy

### 1. **Local Development Models**
- **Location**: `python/models/` and `beforedoctor/assets/models/`
- **Purpose**: Development and testing
- **Version Control**: Excluded from Git (too large)
- **Backup**: Stored locally with version naming

### 2. **Production Models**
- **Location**: Firebase Storage or dedicated model repository
- **Purpose**: Production deployment
- **Version Control**: Versioned through Firebase Storage
- **Access**: Downloaded by app on first run

## Model Versioning Convention

### Version Format: `v{major}.{minor}.{patch}-{date}`
Example: `v1.2.3-20241215`

### Version Components:
- **Major**: Breaking changes in model architecture
- **Minor**: New features or significant improvements
- **Patch**: Bug fixes or minor improvements
- **Date**: YYYYMMDD format for easy tracking

## Model Management Workflow

### 1. **Training Phase**
```bash
# Train model with version
python train_model.py --version v1.2.3-20241215

# Model saved as: model_v1.2.3-20241215.pkl
```

### 2. **Validation Phase**
```bash
# Test model performance
python validate_model.py --model model_v1.2.3-20241215.pkl

# Generate performance report
python generate_model_report.py --model model_v1.2.3-20241215.pkl
```

### 3. **Deployment Phase**
```bash
# Upload to Firebase Storage
python deploy_model.py --model model_v1.2.3-20241215.pkl --environment production

# Update model registry
python update_model_registry.py --version v1.2.3-20241215
```

## Model Registry

### Structure:
```json
{
  "models": {
    "symptom_classifier": {
      "current_version": "v1.2.3-20241215",
      "firebase_path": "models/symptom_classifier_v1.2.3-20241215.pkl",
      "performance": {
        "accuracy": 0.94,
        "precision": 0.92,
        "recall": 0.89
      },
      "training_date": "2024-12-15",
      "dataset_version": "v1.1.0-20241210"
    }
  }
}
```

## Training Script Versioning

### 1. **Script Changes**
- All training scripts are version controlled in Git
- Changes tracked through commit history
- Training parameters documented in scripts

### 2. **Dataset Versioning**
- Datasets versioned separately from models
- Dataset changes trigger model retraining
- Dataset version referenced in model metadata

### 3. **Experiment Tracking**
- Each training run logged with:
  - Script version
  - Dataset version
  - Hyperparameters
  - Performance metrics
  - Model version

## Implementation Steps

### Phase 1: Setup Model Registry
1. Create Firebase Storage bucket for models
2. Implement model upload/download scripts
3. Create model registry JSON structure

### Phase 2: Versioning System
1. Update training scripts to include versioning
2. Implement model validation pipeline
3. Create deployment automation

### Phase 3: Integration
1. Update Flutter app to download models from Firebase
2. Implement model version checking
3. Add fallback to local models

## Current Models

### Symptom Classifier
- **Current Version**: v1.0.0-20241215
- **Size**: ~64MB
- **Purpose**: Classify symptoms from voice input
- **Performance**: 94% accuracy

### Treatment Recommender
- **Current Version**: v1.0.0-20241215
- **Size**: ~1.4GB
- **Purpose**: Recommend treatments based on symptoms
- **Performance**: 89% accuracy

### NIH Chest X-Ray Model
- **Current Version**: v1.0.0-20241215
- **Size**: ~500MB
- **Purpose**: Analyze chest X-ray images
- **Performance**: 92% accuracy

## Backup Strategy

### Local Backups
- Models backed up to external storage
- Version history maintained locally
- Training logs preserved

### Cloud Backups
- Firebase Storage with versioning
- Model registry backed up to Git
- Training scripts version controlled

## Future Enhancements

1. **Automated Training Pipeline**
   - CI/CD for model training
   - Automated performance validation
   - Automatic deployment on improvement

2. **Model Monitoring**
   - Real-time performance tracking
   - Drift detection
   - Automatic retraining triggers

3. **A/B Testing**
   - Multiple model versions in production
   - Performance comparison
   - Gradual rollout strategy 