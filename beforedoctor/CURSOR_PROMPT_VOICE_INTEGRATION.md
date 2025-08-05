# 🚀 **CURSOR PROMPT: COMPLETE VOICE INTEGRATION WORKFLOW**

## **🎯 SINGLE CURSOR INSTRUCTION**

```
Create a complete Flutter voice integration system for BeforeDoctor pediatric app with the following requirements:

1. **Load Pediatric Dataset**: 
   - Load `assets/data/pediatric_llm_prompt_templates_full.json` into `AIPromptService`
   - Ensure all 9 symptom templates are properly loaded (fever, cough, vomiting, diarrhea, ear_pain, rash, headache, sore_throat, breathing_difficulty)
   - Add fallback to built-in templates if JSON file is not available

2. **Voice Input Service Integration**:
   - Integrate `VoiceInputService` with speech-to-text, xAI Grok Voice API, and OpenAI Realtime Audio API
   - Implement real-time transcription with confidence scoring
   - Add symptom detection using keyword matching and AI enhancement
   - Include automatic fallback between primary and secondary voice APIs

3. **Symptom Extraction Service**:
   - Create `SymptomExtractionService` that enhances voice input with AI
   - Extract temperature, duration, medications, and red flags from transcription
   - Support both Grok and OpenAI APIs with automatic fallback
   - Return structured symptom data with confidence scores

4. **Voice Logging Screen**:
   - Create `VoiceLoggingScreen` with real-time transcription display
   - Show confidence feedback with color-coded progress bars
   - Display detected symptoms as chips
   - Include animated microphone button with pulse effect
   - Add processing indicators and treatment recommendation dialogs
   - Integrate with `CharacterInteractionEngine` for animated doctor responses

5. **Complete Workflow Integration**:
   - Voice Input → Symptom Detection → AI Enhancement → Prompt Building → Treatment Recommendation → Character Response
   - Ensure all services work together seamlessly
   - Add proper error handling and fallback mechanisms
   - Include loading states and user feedback

6. **UI/UX Requirements**:
   - Use GetWidget components for modern UI
   - Include Flutter Animate for smooth animations
   - Show real-time transcription with confidence scoring
   - Display detected symptoms with visual feedback
   - Include treatment recommendation dialogs
   - Add character animation integration

7. **Technical Requirements**:
   - All services should be singleton pattern
   - Include proper error handling and logging
   - Support offline fallback with Google ML Kit
   - Implement automatic API fallback (Grok → OpenAI → ML Kit)
   - Add comprehensive testing for all components

8. **File Structure**:
   - `lib/core/services/voice_input_service.dart` - Voice input handling
   - `lib/core/services/symptom_extraction_service.dart` - AI-enhanced symptom extraction
   - `lib/features/voice/presentation/screens/voice_logging_screen.dart` - Main voice logging UI
   - `lib/features/voice/presentation/widgets/voice_confidence_widget.dart` - Confidence feedback
   - Update existing `ai_prompt_service.dart` to load external JSON templates

9. **Integration Points**:
   - Connect voice input to symptom extraction
   - Link symptom extraction to AI prompt service
   - Connect prompts to treatment recommendations
   - Integrate with character interaction engine
   - Add voice confidence feedback throughout

10. **Testing & Validation**:
    - Test with sample voice inputs for each symptom
    - Verify API fallback mechanisms work correctly
    - Test offline functionality with ML Kit
    - Validate treatment recommendations are age-appropriate
    - Test character animations and TTS integration

**Expected Output**: A complete, working voice integration system that can:
- Record voice input with real-time transcription
- Detect symptoms using keyword matching and AI enhancement
- Build dynamic prompts based on detected symptoms
- Generate treatment recommendations
- Display results with animated character responses
- Handle errors gracefully with proper fallbacks

**Success Criteria**:
- Voice recording works with confidence feedback
- Symptom detection is accurate for all 9 supported symptoms
- AI enhancement improves extraction quality
- Treatment recommendations are clinically appropriate
- Character animations and TTS work smoothly
- All APIs have proper fallback mechanisms
- UI is responsive and user-friendly
```

## **🎯 DETAILED IMPLEMENTATION STEPS**

### **Step 1: Load Pediatric Dataset**
```dart
// In AIPromptService, ensure JSON loading works:
await loadTemplates(); // Should load from assets/data/pediatric_llm_prompt_templates_full.json
final symptoms = getSupportedSymptoms(); // Should return all 9 symptoms
```

### **Step 2: Voice Input Service**
```dart
// Initialize and test voice service:
final voiceService = VoiceInputService.instance;
await voiceService.initialize();
await voiceService.startListening();
voiceService.transcriptionStream.listen((transcription) {
  print('Transcription: $transcription');
});
```

### **Step 3: Symptom Extraction**
```dart
// Test symptom extraction:
final extractionService = SymptomExtractionService.instance;
final result = await extractionService.extractSymptoms('My child has a fever of 102 degrees');
print('Extracted: ${result['symptoms']}');
```

### **Step 4: Complete Workflow**
```dart
// Test complete workflow:
1. Voice Input: "My 3-year-old has a fever of 102°F for 2 days"
2. Symptom Detection: ['fever']
3. AI Enhancement: Extract temperature, duration, severity
4. Prompt Building: Build dynamic prompt with child metadata
5. Treatment Recommendation: Generate age-appropriate treatment
6. Character Response: Animated doctor speaks the recommendation
```

## **🎯 TESTING SCENARIOS**

### **Scenario 1: Fever**
- **Input**: "My child has a fever of 103 degrees"
- **Expected**: Detect fever, extract temperature, show treatment dialog
- **Character**: "I understand your child has a fever. Let me provide some guidance..."

### **Scenario 2: Multiple Symptoms**
- **Input**: "My child has a cough and fever for 3 days"
- **Expected**: Detect both cough and fever, show combined treatment
- **Character**: "I see your child has multiple symptoms. Let me help you..."

### **Scenario 3: Red Flags**
- **Input**: "My child has difficulty breathing and blue lips"
- **Expected**: Detect red flags, show emergency warning
- **Character**: "This is concerning. Please seek immediate medical attention..."

### **Scenario 4: Offline Mode**
- **Input**: "My child has a rash"
- **Expected**: Use ML Kit fallback, basic symptom detection
- **Character**: "I can help with the rash. Let me provide some guidance..."

## **🎯 SUCCESS METRICS**

### **Technical Metrics**
- ✅ Voice recording starts within 2 seconds
- ✅ Transcription accuracy >90% for clear speech
- ✅ Symptom detection accuracy >85% for supported symptoms
- ✅ AI enhancement improves extraction by >20%
- ✅ Treatment recommendations are clinically appropriate
- ✅ Character animations run smoothly at 60fps

### **User Experience Metrics**
- ✅ Real-time transcription feedback
- ✅ Confidence scoring is accurate and helpful
- ✅ Detected symptoms are clearly displayed
- ✅ Treatment dialogs are informative and actionable
- ✅ Character responses are engaging and calming
- ✅ Error handling is graceful and informative

### **Integration Metrics**
- ✅ All services work together seamlessly
- ✅ API fallbacks work correctly
- ✅ Offline mode functions properly
- ✅ Data flows correctly through the entire pipeline
- ✅ Performance is smooth and responsive

## **🎯 FINAL DELIVERABLE**

A complete voice integration system that provides:
1. **Voice Recording**: Real-time transcription with confidence feedback
2. **Symptom Detection**: AI-enhanced extraction of pediatric symptoms
3. **Treatment Recommendations**: Age-appropriate clinical guidance
4. **Character Interaction**: Animated doctor responses with TTS
5. **Error Handling**: Graceful fallbacks and user feedback
6. **Offline Support**: ML Kit integration for offline functionality

**Ready for immediate testing and deployment!** 🚀✅ 