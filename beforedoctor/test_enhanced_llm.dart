import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'lib/core/services/llm_service.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  print('🧪 Testing Enhanced LLM Service...');
  
  final llmService = LLMService();
  
  // Test 1: Auto-selection with medical prompt
  print('\n📋 Test 1: Auto-selection with medical prompt');
  try {
    final response = await llmService.getLLMResponse(
      'A 3-year-old child has a fever of 102°F and is complaining of a headache. What should the parent do?'
    );
    print('✅ Response received: ${response.substring(0, 100)}...');
  } catch (e) {
    print('❌ Error: $e');
  }
  
  // Test 2: Specific model selection
  print('\n📋 Test 2: Specific OpenAI model');
  try {
    final response = await llmService.callOpenAI(
      'What are the common symptoms of ear infection in children?'
    );
    print('✅ OpenAI response: ${response.substring(0, 100)}...');
  } catch (e) {
    print('❌ OpenAI error: $e');
  }
  
  // Test 3: Fallback response
  print('\n📋 Test 3: Fallback response');
  final fallback = llmService.generateFallbackResponse('fever in children');
  print('✅ Fallback response: $fallback');
  
  // Test 4: Quality scores
  print('\n📋 Test 4: Quality scores');
  final scores = llmService.getQualityScores();
  print('✅ Quality scores: $scores');
  
  print('\n🎉 Enhanced LLM Service test completed!');
} 