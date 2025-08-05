# Project Overview: BeforeDoctor

## Overview
BeforeDoctor is a voice-driven health app that helps caregivers (parents, grandparents) log children's symptoms via natural speech, generating structured reports to streamline clinic visits (saving 5-15 minutes per visit). It empowers users with interactive voice control (like Grok's mode), multilingual support (English, Spanish, Chinese, French, Hindi), AI extraction/prompts, and basic contextual insights (e.g., weather-based flags). The app is offline-first, HIPAA-compliant, and focused on caregiver collaboration.

## Key Features (MVP)
- **Voice Logging**: Capture symptoms via voice (e.g., "Aarav has 102 fever, threw up twice"), trigger functions (e.g., save log, prompt follow-up).
- **Symptom Extraction**: Parse voice to JSON (symptom, timeline, meds, severity) via AI.
- **Intelligent Prompts**: AI-generated follow-ups (e.g., "Any cough?") with rule-based offline fallback.
- **Multilingual Support**: Auto-detect/translate input (major US languages) for reports.
- **Contextual Insights**: Rule-based flags (e.g., "High fever—see doctor") + weather context.
- **Clinic Sharing**: QR export or Firebase sync for reports.
- **Voice API Config**: User choice between xAI Grok Voice API (primary) and OpenAI Realtime Audio API (fallback), with auto-switch on errors.
- **Storage**: SQLite for offline logs; Firebase for real-time caregiver sync and secure sharing.
- **Animated Character**: Interactive cartoon doctor avatar with lip-sync, TTS, and emotional states for engaging user experience.
- **AI-Generated Singing Response**: ElevenLabs TTS integration for calming lullabies with dynamic lyrics based on symptoms. Real-time lip-sync with Rive animations for viral differentiator.

## Tech Stack
- **Framework**: Flutter (cross-platform iOS/Android).
- **Voice Recognition**: xAI Grok Voice API (cloud, multilingual, function calling); OpenAI Realtime Audio API (fallback); Google ML Kit (offline STT/translation).
- **AI/ML**: GPT-4o (extraction/prompts/insights); rule-based fallback; no fine-tuning for MVP.
- **UI/UX**: GetWidget (sleek, modern components with Material 3, calming blues/greens, animations like FadeTransition).
- **Animated Character**: Rive (animated avatar), Flutter TTS (speech), phoneme-based lip-sync.
- **AI Singing Response**: ElevenLabs TTS (singing voice), just_audio (playback), audio_session (background audio).
- **State Management**: Riverpod (reactive, type-safe).
- **Storage/Sync**: SQLite (sqflite, local/offline); Firebase (authentication, realtime database for sync).
- **Other**: geolocator (location), intl (multilingual), qr_flutter (QR), permission_handler (mic/location), http (APIs like OpenWeather).
- **Testing**: flutter_test, mocktail (mocks), sqflite_common_ffi (SQLite tests); aim for 90%+ accuracy on 100 synthetic logs.
- **Dev Tools**: Cursor (AI code gen), Android Studio (emulator), Codemagic (iOS builds on Windows).

## Animated Character Implementation

### Character Design
- **Type**: Friendly cartoon doctor avatar (medical theme, kid-friendly)
- **States**: idle, listening, speaking, thinking, concerned, happy, explaining
- **Features**: Lip-sync, emotional expressions, gesture animations, voice tone matching

### Technical Implementation
- **Dependencies**: flutter_rive (animations), flutter_tts (speech), rive (assets)
- **Integration**: Voice input → Character listens → AI processes → Character responds with TTS + lip-sync
- **Phases**: 
  - Phase 1 (Week 2): Basic character with idle/speaking animations
  - Phase 2 (Week 3): Interactive character with lip-sync and emotional states
  - Phase 3 (Week 4): Smart character with context-aware responses

### User Experience
- **Kid-Friendly**: Character speaks to children in friendly, encouraging tone
- **Parent-Friendly**: Character provides symptom summaries and medical guidance
- **Multilingual**: Character speaks in user's preferred language
- **Accessibility**: Visual feedback for voice input, clear communication states

## Development Guidelines
- **Offline-First**: All features work offline (ML Kit, SQLite); sync when online (Firebase).
- **HIPAA/Privacy**: Local data (SQLite encrypted), explicit consents for sync/sharing.
- **Accuracy Goal**: >90% for STT/extraction (test with synthetic logs).
- **User Flow**: Voice input → Transcription → Extraction → Prompt/Insight → Save (SQLite) → Sync (Firebase) → Report/QR.
- **Character Flow**: Character greets → Listens → Processes → Responds with animation.
- **Future**: Save logs/diagnoses for ML training; expand to treatment suggestions/online clinics.

## Development Phases

### Week 1: Foundation
- Project setup and dependencies
- Basic voice input/output
- SQLite database structure
- Firebase integration

### Week 2: Core Features
- Voice processing with xAI Grok/OpenAI
- Symptom extraction with GPT-4o
- Basic animated character (idle/speaking)
- Multilingual support

### Week 3: AI Singing Response (MVP)
- ElevenLabs TTS integration for singing voice
- Dynamic lyrics generation based on symptoms
- Real-time lip-sync coordination with singing
- Background audio session management

### Week 4: Advanced Features
- Interactive character with lip-sync
- Emotional states and gestures
- Weather insights integration
- User-configurable voice APIs

### Week 4: Polish & Testing
- Performance optimization
- 90%+ accuracy testing
- UI/UX refinement
- App store preparation

This overview ensures consistent, high-quality code generation with animated character integration. 