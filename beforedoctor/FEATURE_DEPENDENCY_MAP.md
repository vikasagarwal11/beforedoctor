# 🔗 **BeforeDoctor Feature Dependency Map**

## **📊 FEATURE INTERACTION MATRIX**

### **✅ COMPLETED FEATURES & THEIR DEPENDENCIES**

#### **1. Character Interaction Engine**
```
📁 File: lib/core/services/character_interaction_engine.dart
🔗 Dependencies:
├── rive: ^0.12.4 (animations)
├── flutter_tts: ^3.8.3 (speech)
└── intl: ^0.19.0 (localization)

📤 Outputs:
├── Character states (idle, listening, speaking, thinking)
├── TTS audio output
├── Rive animation triggers
└── Emotional tone responses

⚠️ Integration Points:
├── Voice input → Character listening state
├── AI response → Character speaking state
├── Symptom severity → Emotional tone
└── Language setting → Localized speech
```

#### **2. AI Singing Service**
```
📁 File: lib/core/services/ai_singing_service.dart
🔗 Dependencies:
├── http: ^1.2.2 (ElevenLabs API)
├── just_audio: ^0.9.36 (playback)
├── audio_session: ^0.1.18 (background audio)
└── AppConfig (API keys)

📤 Outputs:
├── Generated singing audio
├── Dynamic lyrics based on symptoms
├── Audio session management
└── Fallback to regular TTS

⚠️ Integration Points:
├── Symptom data → Lyrics generation
├── Character engine → Lip-sync coordination
├── Audio session → Background playback
└── Error handling → TTS fallback
```

#### **3. Treatment Recommendation Service**
```
📁 File: lib/core/services/treatment_recommendation_service.dart
🔗 Dependencies:
├── http: ^1.2.2 (OpenAI API)
├── dart_openai: ^5.1.0 (GPT-4o)
└── AppConfig (API keys)

📤 Outputs:
├── Treatment recommendations
├── Medication dosing (age-appropriate)
├── Home remedies
├── Red flag monitoring
└── Safety disclaimers

⚠️ Integration Points:
├── Symptom + Age → Treatment plan
├── AI response → Structured recommendations
├── Rule-based fallback → Offline recommendations
└── Safety checks → Red flag alerts
```

#### **4. Voice Confidence Widget**
```
📁 File: lib/features/voice/presentation/widgets/voice_confidence_widget.dart
🔗 Dependencies:
├── getwidget: ^4.0.0 (UI components)
└── flutter/material.dart

📤 Outputs:
├── Confidence score display (0-100%)
├── Transcription text
├── Re-record option
└── Accept/Reject buttons

⚠️ Integration Points:
├── STT result → Confidence score
├── Low confidence → Re-record prompt
├── High confidence → Accept option
└── User action → Callback functions
```

#### **5. Voice API Settings Screen**
```
📁 File: lib/features/settings/presentation/screens/voice_api_settings_screen.dart
🔗 Dependencies:
├── getwidget: ^4.0.0 (UI components)
├── flutter_riverpod: ^2.5.1 (state management)
└── AppConfig (API settings)

📤 Outputs:
├── Primary/fallback API selection
├── Auto-fallback toggle
├── API status indicators
└── Settings persistence

⚠️ Integration Points:
├── User selection → API configuration
├── Settings change → Service updates
├── API status → Real-time indicators
└── Configuration → App-wide settings
```

---

## **🔄 PENDING FEATURES & DEPENDENCIES**

### **📋 VOICE LOGGING IMPLEMENTATION**
```
📁 Planned Files:
├── lib/features/voice/presentation/screens/voice_logging_screen.dart
├── lib/features/voice/presentation/widgets/voice_recorder_widget.dart
├── lib/core/services/voice_service.dart
└── lib/core/services/symptom_extraction_service.dart

🔗 Dependencies:
├── speech_to_text: ^6.6.0 (microphone access)
├── google_ml_kit: ^0.18.0 (offline STT)
├── permission_handler: ^11.3.1 (mic permissions)
└── Existing services (Character, Confidence, Treatment)

⚠️ Integration Points:
├── Microphone input → STT processing
├── STT result → Confidence widget
├── Extracted symptoms → Treatment service
├── Character engine → Voice interaction
└── Database → Symptom storage
```

### **📋 DATABASE INTEGRATION**
```
📁 Planned Files:
├── lib/core/database/database_helper.dart
├── lib/core/database/models/symptom_model.dart
├── lib/core/database/models/treatment_model.dart
└── lib/core/repositories/symptom_repository.dart

🔗 Dependencies:
├── sqflite: ^2.3.3 (local database)
├── firebase_database: ^11.0.0 (cloud sync)
└── Existing services (Treatment, Voice)

⚠️ Integration Points:
├── Voice logging → Symptom storage
├── Treatment recommendations → Database
├── Offline/online sync → Firebase
└── Data retrieval → Timeline UI
```

---

## **🚨 CONFLICT PREVENTION RULES**

### **🔒 SERVICE ISOLATION**
```
✅ Each service is independent
✅ Clear interfaces between services
✅ No circular dependencies
✅ Error handling in each service
✅ Fallback mechanisms for each service
```

### **📋 DEVELOPMENT CHECKLIST**
Before modifying any existing feature:

1. **✅ Check Dependencies**
   - Review the service's dependencies
   - Ensure no breaking changes to interfaces
   - Test with dependent services

2. **✅ Update Documentation**
   - Update this dependency map
   - Update DEVELOPMENT_TRACKER.md
   - Update inline code comments

3. **✅ Test Integration**
   - Test with all dependent services
   - Verify error handling
   - Check fallback mechanisms

4. **✅ Version Control**
   - Commit changes with clear messages
   - Tag releases appropriately
   - Maintain rollback capability

---

## **🔧 INTEGRATION PATTERNS**

### **🎯 VOICE → AI → DATABASE FLOW**
```
1. Voice Input (speech_to_text)
   ↓
2. Confidence Check (voice_confidence_widget)
   ↓
3. Symptom Extraction (symptom_extraction_service)
   ↓
4. Treatment Recommendation (treatment_recommendation_service)
   ↓
5. Character Response (character_interaction_engine)
   ↓
6. Database Storage (database_helper)
   ↓
7. Cloud Sync (firebase_database)
```

### **🎯 OFFLINE-FIRST ARCHITECTURE**
```
✅ Local Processing (SQLite + ML Kit)
✅ Offline Fallbacks (Rule-based recommendations)
✅ Sync When Online (Firebase)
✅ Conflict Resolution (Timestamp-based)
✅ Data Integrity (Validation + Encryption)
```

---

## **📊 FEATURE COMPATIBILITY MATRIX**

| Feature | Character Engine | AI Singing | Treatment Service | Voice Confidence | Voice API Settings |
|---------|------------------|------------|-------------------|------------------|-------------------|
| **Character Engine** | ✅ Self | ✅ Audio output | ✅ Treatment display | ✅ Voice input | ✅ API selection |
| **AI Singing** | ✅ Lip-sync | ✅ Self | ✅ Symptom input | ❌ | ✅ API selection |
| **Treatment Service** | ✅ Response | ✅ Symptom data | ✅ Self | ❌ | ✅ API selection |
| **Voice Confidence** | ✅ Voice input | ❌ | ✅ Confidence data | ✅ Self | ✅ API selection |
| **Voice API Settings** | ✅ API config | ✅ API config | ✅ API config | ✅ API config | ✅ Self |

---

## **🚀 DEVELOPMENT ROADMAP**

### **📋 WEEK 2: VOICE IMPLEMENTATION**
```
Day 1-2: Voice Logging Screens
├── Create voice_recorder_widget.dart
├── Integrate with confidence widget
├── Test with character engine
└── Add error handling

Day 3-4: Symptom Extraction
├── Create symptom_extraction_service.dart
├── Integrate with treatment service
├── Add AI/rule-based fallbacks
└── Test extraction accuracy

Day 5: Integration Testing
├── Test complete voice → AI → treatment flow
├── Verify offline functionality
├── Test error scenarios
└── Performance optimization
```

### **📋 WEEK 3: DATABASE & SYNC**
```
Day 1-2: Database Foundation
├── Create database_helper.dart
├── Design symptom_model.dart
├── Implement CRUD operations
└── Add data validation

Day 3-4: Firebase Integration
├── Set up authentication
├── Implement real-time sync
├── Add conflict resolution
└── Test offline/online scenarios

Day 5: Advanced Features
├── Longitudinal timeline UI
├── Data visualization
├── Export functionality
└── Performance testing
```

---

## **⚠️ RISK ASSESSMENT**

### **🔴 HIGH RISK AREAS**
| Feature | Risk | Mitigation |
|---------|------|------------|
| **Voice API Integration** | API rate limits, network issues | Fallback to ML Kit, offline mode |
| **Database Sync** | Data conflicts, loss | Timestamp-based resolution, backups |
| **AI Service Dependencies** | API failures, costs | Rule-based fallbacks, caching |
| **Audio Playback** | Permission issues, conflicts | Graceful degradation, user prompts |

### **🟡 MEDIUM RISK AREAS**
| Feature | Risk | Mitigation |
|---------|------|------------|
| **Character Animation** | Performance issues | Optimized assets, lazy loading |
| **Treatment Recommendations** | Medical accuracy | Disclaimers, doctor consultation prompts |
| **Multilingual Support** | Translation accuracy | Human review, context awareness |
| **Cross-platform Compatibility** | Platform differences | Platform-specific code, testing |

### **🟢 LOW RISK AREAS**
| Feature | Risk | Mitigation |
|---------|------|------------|
| **UI Components** | Visual inconsistencies | Design system, component library |
| **Configuration** | Environment issues | Validation, default values |
| **Settings Management** | User preferences | Persistent storage, validation |

---

**Last Updated**: August 4, 2025  
**Next Review**: August 11, 2025  
**Development Status**: Phase 2 - Voice & AI Implementation 