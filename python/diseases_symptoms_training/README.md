# Diseases_Symptoms Training Module

This module downloads and trains on the Hugging Face Diseases_Symptoms dataset (QuyenAnhDE/Diseases_Symptoms) to provide disease prediction capabilities for the BeforeDoctor app.

## Overview

The Diseases_Symptoms dataset contains ~510 records of diseases, symptoms, and treatments, including pediatric cases. This training module:

- Downloads the dataset from Hugging Face
- Processes and cleans the data
- Trains a Random Forest classifier for disease prediction
- Generates Flutter integration code
- Provides comprehensive symptom analysis

## Features

### Dataset Information
- **Source**: Hugging Face - QuyenAnhDE/Diseases_Symptoms
- **Records**: ~510 disease-symptom-treatment mappings
- **Pediatric Focus**: Includes pediatric cases (e.g., viral fever)
- **Format**: JSON/CSV with symptoms, diseases, and treatments

### Training Capabilities
- **Text Classification**: Uses TF-IDF vectorization for symptom-to-disease mapping
- **Random Forest**: Robust classifier for medical symptom analysis
- **Feature Engineering**: Combines symptoms and diseases for better classification
- **Model Persistence**: Saves trained models for Flutter integration

### Flutter Integration
- **Disease Prediction**: Predict diseases from symptom lists
- **Common Symptoms**: Provides list of common pediatric symptoms
- **Treatment Mappings**: Disease-to-treatment recommendations
- **Emergency Detection**: Identifies emergency symptoms requiring immediate care
- **Severity Assessment**: Analyzes symptom severity levels

## Installation

### Prerequisites
```bash
# Install Python dependencies
pip install -r requirements.txt

# Or install individually
pip install scikit-learn pandas numpy datasets transformers joblib scipy tqdm
```

### Directory Structure
```
diseases_symptoms_training/
├── data/                    # Raw dataset storage
├── processed/              # Processed training data
├── models/                 # Trained model files
├── outputs/               # Training results and Flutter code
├── diseases_symptoms_trainer.py  # Main training script
├── requirements.txt        # Python dependencies
└── README.md             # This file
```

## Usage

### Quick Start
```bash
# Run complete training pipeline
python diseases_symptoms_trainer.py

# Or use the runner script
python ../run_diseases_symptoms_training.py

# Test the module
python ../test_diseases_symptoms_training.py
```

### Step-by-Step Training

1. **Download Dataset**
   ```python
   from diseases_symptoms_trainer import DiseasesSymptomsTrainer
   
   trainer = DiseasesSymptomsTrainer()
   trainer.download_dataset()
   ```

2. **Process Data**
   ```python
   trainer.process_dataset()
   ```

3. **Train Models**
   ```python
   trainer.train_models()
   ```

4. **Generate Flutter Integration**
   ```python
   trainer.create_flutter_integration()
   ```

### Complete Pipeline
```python
trainer = DiseasesSymptomsTrainer()
success = trainer.run_complete_pipeline()
```

## Model Details

### Training Algorithm
- **Classifier**: Random Forest (100 estimators)
- **Vectorizer**: TF-IDF (5000 features, 1-2 n-grams)
- **Features**: Combined symptoms and diseases text
- **Validation**: 80/20 train-test split

### Performance Metrics
- **Accuracy**: Measured on test set
- **Classification Report**: Precision, recall, F1-score
- **Feature Importance**: Top features for disease prediction

### Output Files
- `models/diseases_symptoms_vectorizer.pkl`: TF-IDF vectorizer
- `models/diseases_symptoms_classifier.pkl`: Trained classifier
- `outputs/training_results.json`: Performance metrics
- `outputs/diseases_symptoms_flutter_integration.dart`: Flutter code

## Flutter Integration

### Service Usage
```dart
import 'package:beforedoctor/services/diseases_symptoms_service.dart';

final diseasesService = DiseasesSymptomsService();

// Predict disease from symptoms
final prediction = await diseasesService.predictDisease(['fever', 'cough']);

// Get common symptoms
final symptoms = diseasesService.getCommonSymptoms();

// Get treatments
final treatments = diseasesService.getDiseaseTreatments();

// Analyze symptoms comprehensively
final analysis = await diseasesService.analyzeSymptoms('fever and cough');
```

### Key Features
- **Symptom Extraction**: NLP-based symptom detection from text
- **Emergency Detection**: Identifies symptoms requiring immediate care
- **Urgency Assessment**: Determines care urgency levels
- **Treatment Recommendations**: Disease-specific treatment guidance
- **Pediatric Focus**: Age-appropriate symptom analysis

## Integration with Voice Logger

The Diseases_Symptoms service is integrated with the voice logger screen to provide:

1. **Real-time Analysis**: Analyzes voice-input symptoms
2. **Emergency Alerts**: Flags emergency symptoms immediately
3. **Treatment Guidance**: Provides evidence-based recommendations
4. **Severity Assessment**: Evaluates symptom severity levels
5. **Pediatric Considerations**: Age-appropriate medical advice

### Voice Logger Integration
```dart
// In voice_logger_screen.dart
final DiseasesSymptomsService _diseasesSymptomsService = DiseasesSymptomsService();

// During symptom processing
final analysis = await _diseasesSymptomsService.analyzeSymptoms(symptomText);
```

## Testing

### Run Tests
```bash
# Test the training module
python ../test_diseases_symptoms_training.py

# Test individual components
python -c "
from diseases_symptoms_trainer import DiseasesSymptomsTrainer
trainer = DiseasesSymptomsTrainer()
print('✅ Module imported successfully')
"
```

### Validation
- **Dataset Download**: Verifies Hugging Face dataset access
- **Data Processing**: Validates data cleaning and preparation
- **Model Training**: Confirms successful model training
- **Flutter Integration**: Tests code generation

## Troubleshooting

### Common Issues

1. **Import Errors**
   ```bash
   pip install -r requirements.txt
   ```

2. **Dataset Download Failures**
   - Check internet connection
   - Verify Hugging Face access
   - Try alternative dataset sources

3. **Memory Issues**
   - Reduce `max_features` in TF-IDF vectorizer
   - Use smaller dataset subset for testing

4. **Model Performance**
   - Adjust Random Forest parameters
   - Increase training data
   - Feature engineering improvements

### Debug Mode
```python
import logging
logging.basicConfig(level=logging.DEBUG)

trainer = DiseasesSymptomsTrainer()
# Detailed logging will be displayed
```

## Performance Optimization

### Training Optimization
- **Parallel Processing**: Uses all CPU cores for training
- **Memory Management**: Efficient data structures
- **Caching**: Saves intermediate results

### Runtime Optimization
- **Model Caching**: Pre-loaded models for fast inference
- **Batch Processing**: Efficient symptom analysis
- **Async Operations**: Non-blocking API calls

## Future Enhancements

### Planned Features
- **Deep Learning Models**: Neural network classifiers
- **Multi-language Support**: International symptom analysis
- **Real-time Updates**: Live model improvements
- **Advanced NLP**: Better symptom extraction
- **Clinical Validation**: Medical expert review

### Research Areas
- **Transfer Learning**: Pre-trained medical models
- **Ensemble Methods**: Multiple classifier combination
- **Active Learning**: Continuous model improvement
- **Clinical Integration**: EHR system connectivity

## Contributing

### Development Setup
1. Clone the repository
2. Install dependencies
3. Run tests
4. Make changes
5. Submit pull request

### Code Standards
- Follow PEP 8 style guide
- Add comprehensive docstrings
- Include unit tests
- Update documentation

## License

This module is part of the BeforeDoctor project and follows the same licensing terms.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the test scripts
3. Check the main project documentation
4. Create an issue in the repository

---

**Note**: This module is designed for educational and research purposes. Medical decisions should always be made by qualified healthcare professionals. 