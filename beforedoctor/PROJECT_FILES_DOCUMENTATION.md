# BeforeDoctor Project Files Documentation

## 📁 **PROJECT STRUCTURE OVERVIEW**

### **🎯 Core Application Files**

#### **`lib/main.dart`**
- **Purpose**: Application entry point
- **Features**: 
  - Initializes Firebase
  - Applies pediatric theme
  - Sets up navigation
- **Dependencies**: `pediatric_theme.dart`, Firebase services
- **Status**: ✅ Complete

#### **`lib/theme/pediatric_theme.dart`**
- **Purpose**: Kid-friendly UI theme
- **Features**: 
  - Sky blue and soft peach color scheme
  - Rounded corners and playful design
  - Raleway font family
- **Dependencies**: Flutter Material Design
- **Status**: ✅ Complete

### **🔧 Core Services**

#### **`lib/services/llm_service.dart`**
- **Purpose**: AI/LLM integration with multiple APIs
- **Features**: 
  - OpenAI and Grok API integration
  - Automatic model selection and fallback
  - Performance tracking and quality scoring
  - SQLite persistence for model performance
- **Dependencies**: `dart_openai`, `http`, `sqflite`, `model_selector_service.dart`
- **Status**: ✅ Complete

#### **`lib/services/stt_service.dart`**
- **Purpose**: Speech-to-Text functionality
- **Features**: 
  - Real-time voice input (currently simulated)
  - Language detection
  - Confidence scoring
  - Translation integration
- **Dependencies**: `google_ml_kit`, `translation_service.dart`
- **Status**: ✅ Complete (simulated due to plugin issues)

#### **`lib/services/tts_service.dart`**
- **Purpose**: Text-to-Speech functionality
- **Features**: 
  - Flutter TTS integration
  - Multiple language support
  - Voice customization
- **Dependencies**: `flutter_tts`
- **Status**: ✅ Complete

#### **`lib/services/usage_logger_service.dart`**
- **Purpose**: HIPAA-compliant analytics logging
- **Features**: 
  - SQLite storage for all AI interactions
  - Upload tracking with `uploaded` flag
  - Performance metrics logging
- **Dependencies**: `sqflite`
- **Status**: ✅ Complete

#### **`lib/services/sheet_uploader_service.dart`**
- **Purpose**: Google Sheets integration for data export
- **Features**: 
  - Uploads unuploaded logs only
  - Service account authentication
  - Batch upload processing
- **Dependencies**: `googleapis`, `googleapis_auth`
- **Status**: ✅ Complete

#### **`lib/services/model_selector_service.dart`**
- **Purpose**: AI model performance tracking and selection
- **Features**: 
  - Persistent model performance in SQLite
  - Quality and speed-based selection
  - Automatic fallback logic
- **Dependencies**: `sqflite`
- **Status**: ✅ Complete

### **🤖 AI & Data Services**

#### **`lib/core/services/ai_prompt_service.dart`**
- **Purpose**: Dynamic prompt generation with real-world data
- **Features**: 
  - Template-based prompt generation
  - Child metadata injection
  - Enhanced with treatment suggestions
  - Follow-up questions and red flags
- **Dependencies**: `data_loader_service.dart`
- **Status**: ✅ Complete (enhanced with new datasets)

#### **`lib/services/data_loader_service.dart`** (NEW)
- **Purpose**: Loads real-world pediatric datasets
- **Features**: 
  - Loads symptom treatment dataset
  - Loads prompt logic tree
  - Age-specific treatment suggestions
  - Caching for performance
- **Dependencies**: `flutter/services.dart`
- **Status**: ✅ Complete

#### **`lib/core/services/character_interaction_engine.dart`**
- **Purpose**: Animated character and TTS integration
- **Features**: 
  - Rive animations for doctor avatar
  - TTS integration with lip-sync
  - Emotional states management
- **Dependencies**: `rive`, `flutter_tts`
- **Status**: ⏳ Basic structure exists

### **📱 UI Components**

#### **`lib/features/voice/presentation/screens/voice_logger_screen.dart`**
- **Purpose**: Main voice logging interface
- **Features**: 
  - Voice input and transcription display
  - AI response display
  - Model selection UI
  - Google Sheets upload button
  - Pediatric theme integration
- **Dependencies**: All core services
- **Status**: ✅ Complete (needs UI enhancement for new features)

#### **`lib/features/settings/presentation/screens/voice_api_settings_screen.dart`**
- **Purpose**: Voice API configuration
- **Features**: 
  - Primary/fallback API selection
  - Auto-fallback toggle
  - Performance tracking display
- **Dependencies**: `llm_service.dart`
- **Status**: ⏳ UI exists, needs backend integration

### **📊 Data Assets**

#### **`assets/data/pediatric_symptom_treatment_dataset.json`** (NEW)
- **Purpose**: Age-specific treatment recommendations
- **Features**: 
  - Structured JSON with age groups
  - Medication recommendations (OTC/Rx)
  - Home care instructions
  - Red flag alerts
- **Usage**: Loaded by `data_loader_service.dart`
- **Status**: ✅ Sample data created

#### **`assets/data/prompt_logic_tree.json`** (NEW)
- **Purpose**: Dynamic follow-up questions and red flags
- **Features**: 
  - Symptom-specific follow-up questions
  - Red flag triggers
  - ML training data structure
- **Usage**: Loaded by `data_loader_service.dart`
- **Status**: ✅ Sample data created

#### **`assets/data/pediatric_llm_prompt_templates_full.json`**
- **Purpose**: Prompt templates for common symptoms
- **Features**: 
  - Structured templates with placeholders
  - Child metadata injection
  - Follow-up questions per symptom
- **Usage**: Loaded by `ai_prompt_service.dart`
- **Status**: ✅ Complete

### **🔧 Configuration Files**

#### **`pubspec.yaml`**
- **Purpose**: Project dependencies and assets
- **Features**: 
  - All required packages
  - Asset paths configuration
  - Platform-specific settings
- **Status**: ✅ Complete

#### **`.env`**
- **Purpose**: Environment variables and API keys
- **Features**: 
  - OpenAI API key
  - Grok API key
  - Google Sheets credentials
- **Status**: ✅ Complete

### **📋 Testing & Development**

#### **`test_treatment_recommendations.dart`**
- **Purpose**: Treatment recommendation testing
- **Features**: 
  - Unit tests for treatment logic
  - Accuracy validation
  - Edge case testing
- **Status**: ⏳ Basic test exists

## 🔄 **SERVICE INTERACTIONS**

### **Voice Input Flow:**
```
STT Service → Translation Service → AI Prompt Service → LLM Service → TTS Service
```

### **Data Enhancement Flow:**
```
Data Loader Service → AI Prompt Service → Enhanced LLM Prompts
```

### **Logging Flow:**
```
All Services → Usage Logger Service → Sheet Uploader Service → Google Sheets
```

### **Model Selection Flow:**
```
LLM Service → Model Selector Service → Performance Tracking → Auto Selection
```

## 📊 **DEPENDENCY MAP**

### **Core Dependencies:**
- `flutter_riverpod` - State management
- `sqflite` - Local database
- `dart_openai` - OpenAI API
- `http` - HTTP requests
- `flutter_tts` - Text-to-speech
- `google_ml_kit` - ML features
- `rive` - Animations

### **Service Dependencies:**
- `llm_service.dart` depends on `model_selector_service.dart`
- `ai_prompt_service.dart` depends on `data_loader_service.dart`
- `voice_logger_screen.dart` depends on all core services
- `usage_logger_service.dart` depends on `sqflite`

## 🎯 **DEVELOPMENT STATUS**

### **✅ Production Ready:**
- Core AI/LLM integration
- Voice input (simulated)
- TTS functionality
- Analytics logging
- Google Sheets export
- Model selection
- Pediatric theme

### **⏳ In Progress:**
- Enhanced UI for treatment display
- Real-world dataset integration

### **📋 Planned:**
- Real voice input (fix plugin)
- Animated character integration
- Clinic sharing features
- Security compliance

## 🔧 **MAINTENANCE NOTES**

### **Critical Files to Preserve:**
1. `lib/services/llm_service.dart` - Core AI functionality
2. `lib/core/services/ai_prompt_service.dart` - Enhanced prompts
3. `lib/services/data_loader_service.dart` - New data integration
4. `lib/features/voice/presentation/screens/voice_logger_screen.dart` - Main UI

### **Recent Enhancements:**
- Added `data_loader_service.dart` for real-world data
- Enhanced `ai_prompt_service.dart` with treatment suggestions
- Created sample datasets for testing
- Updated tracking documentation

### **Next Steps:**
1. Update UI to display treatment suggestions
2. Integrate real-world datasets
3. Fix speech recognition plugin
4. Add comprehensive testing

---

**Last Updated**: Current session - Enhanced Treatment System
**Maintainer**: AI Assistant
**Version**: 1.0.0 