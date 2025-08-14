import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';  // COMMENTED OUT - replacing with flutter_gl
import 'dart:convert';

/// Service for managing 3D character rendering and animations
class ThreeDCharacterService {
  static const String _baseUrl = 'https://readyplayer.me';
  static const String _characterId = 'dr-healthie'; // Will be created
  
  // Character states
  static const String _stateIdle = 'idle';
  static const String _stateListening = 'listening';
  static const String _stateSpeaking = 'speaking';
  static const String _stateThinking = 'thinking';
  static const String _stateConcerned = 'concerned';
  static const String _stateUrgent = 'urgent';
  static const String _stateHappy = 'happy';
  static const String _stateExplaining = 'explaining';

  String _currentState = _stateIdle;
  bool _isInitialized = false;
  // WebViewController? _webViewController; // COMMENTED OUT - replacing with flutter_gl

  /// Initialize the 3D character service
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      print('🎭 3D Character Service initialized');
    } catch (e) {
      print('❌ Error initializing 3D Character Service: $e');
    }
  }

  /// Get the HTML content for the 3D character viewer
  String getCharacterHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dr. Healthie - 3D Character</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            font-family: Arial, sans-serif;
            overflow: hidden;
        }
        
        #character-container {
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            position: relative;
        }
        
        #character-viewer {
            width: 100%;
            height: 100%;
            border: none;
        }
        
        .loading {
            color: white;
            font-size: 24px;
            text-align: center;
        }
        
        .character-info {
            position: absolute;
            bottom: 20px;
            left: 20px;
            color: white;
            background: rgba(0,0,0,0.5);
            padding: 10px;
            border-radius: 10px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div id="character-container">
        <div class="loading">Loading Dr. Healthie...</div>
        <div class="character-info">
            <div>State: <span id="current-state">$_currentState</span></div>
            <div>Status: <span id="status">Initializing...</span></div>
        </div>
    </div>
    
    <script>
        // 3D Character Viewer using Three.js
        let scene, camera, renderer, character;
        let currentAnimation = 'idle';
        let isSpeaking = false;
        
        // Initialize Three.js scene
        function init() {
            // Create scene
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0x667eea);
            
            // Create camera
            camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
            camera.position.z = 5;
            
            // Create renderer
            renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.shadowMap.enabled = true;
            renderer.shadowMap.type = THREE.PCFSoftShadowMap;
            
            // Add renderer to DOM
            document.getElementById('character-container').innerHTML = '';
            document.getElementById('character-container').appendChild(renderer.domElement);
            
            // Add lighting
            const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
            scene.add(ambientLight);
            
            const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
            directionalLight.position.set(10, 10, 5);
            directionalLight.castShadow = true;
            scene.add(directionalLight);
            
            // Create placeholder character (will be replaced with actual 3D model)
            createPlaceholderCharacter();
            
            // Start animation loop
            animate();
            
            // Update status
            document.getElementById('status').textContent = 'Ready';
        }
        
        // Create placeholder character (temporary until we have the actual 3D model)
        function createPlaceholderCharacter() {
            const geometry = new THREE.BoxGeometry(1, 2, 1);
            const material = new THREE.MeshLambertMaterial({ 
                color: 0x4CAF50,
                transparent: true,
                opacity: 0.8
            });
            character = new THREE.Mesh(geometry, material);
            character.position.y = 0;
            scene.add(character);
        }
        
        // Animation loop
        function animate() {
            requestAnimationFrame(animate);
            
            // Animate character based on state
            if (character) {
                switch (currentAnimation) {
                    case 'idle':
                        character.rotation.y += 0.01;
                        break;
                    case 'listening':
                        character.rotation.y += 0.02;
                        character.scale.setScalar(1.1);
                        break;
                    case 'speaking':
                        character.rotation.y += 0.03;
                        character.scale.setScalar(1.2);
                        break;
                    case 'thinking':
                        character.rotation.y += 0.005;
                        character.scale.setScalar(0.9);
                        break;
                }
            }
            
            renderer.render(scene, camera);
        }
        
        // Handle window resize
        window.addEventListener('resize', onWindowResize, false);
        function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        }
        
        // Function to change character state
        function changeState(newState) {
            currentAnimation = newState;
            document.getElementById('current-state').textContent = newState;
            
            // Update character appearance based on state
            if (character) {
                switch (newState) {
                    case 'idle':
                        character.material.color.setHex(0x4CAF50);
                        break;
                    case 'listening':
                        character.material.color.setHex(0x2196F3);
                        break;
                    case 'speaking':
                        character.material.color.setHex(0xFF9800);
                        break;
                    case 'thinking':
                        character.material.color.setHex(0x9C27B0);
                        break;
                    case 'concerned':
                        character.material.color.setHex(0xFF5722);
                        break;
                    case 'urgent':
                        character.material.color.setHex(0xF44336);
                        break;
                    case 'happy':
                        character.material.color.setHex(0xFFEB3B);
                        break;
                    case 'explaining':
                        character.material.color.setHex(0x00BCD4);
                        break;
                }
            }
        }
        
        // Function to handle lip sync (placeholder)
        function startLipSync() {
            isSpeaking = true;
            changeState('speaking');
        }
        
        function stopLipSync() {
            isSpeaking = false;
            changeState('idle');
        }
        
        // Initialize when page loads
        window.addEventListener('load', function() {
            // Load Three.js from CDN
            const script = document.createElement('script');
            script.src = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
            script.onload = init;
            document.head.appendChild(script);
        });
        
        // Expose functions to Flutter
        window.changeCharacterState = changeState;
        window.startLipSync = startLipSync;
        window.stopLipSync = stopLipSync;
    </script>
</body>
</html>
    ''';
  }

  /// Change character state
  Future<void> changeState(String state) async {
    if (!_isInitialized) return;
    
    _currentState = state;
    
    // Execute JavaScript to change character state
    // if (_webViewController != null) { // COMMENTED OUT - replacing with flutter_gl
    //   await _webViewController!.runJavaScript('changeCharacterState("$state")'); // COMMENTED OUT - replacing with flutter_gl
    // } // COMMENTED OUT - replacing with flutter_gl
    
    print('🎭 Character state changed to: $state');
  }

  /// Start lip sync animation
  Future<void> startLipSync() async {
    if (!_isInitialized) return;
    
    await changeState(_stateSpeaking);
    
    // if (_webViewController != null) { // COMMENTED OUT - replacing with flutter_gl
    //   await _webViewController!.runJavaScript('startLipSync()'); // COMMENTED OUT - replacing with flutter_gl
    // } // COMMENTED OUT - replacing with flutter_gl
    
    print('🎭 Lip sync started');
  }

  /// Stop lip sync animation
  Future<void> stopLipSync() async {
    if (!_isInitialized) return;
    
    await changeState(_stateIdle);
    
    // if (_webViewController != null) { // COMMENTED OUT - replacing with flutter_gl
    //   await _webViewController!.runJavaScript('stopLipSync()'); // COMMENTED OUT - replacing with flutter_gl
    // } // COMMENTED OUT - replacing with flutter_gl
    
    print('🎭 Lip sync stopped');
  }

  /// Set WebViewController reference
  // void setWebViewController(WebViewController controller) { // COMMENTED OUT - replacing with flutter_gl
  //   _webViewController = controller; // COMMENTED OUT - replacing with flutter_gl
  // } // COMMENTED OUT - replacing with flutter_gl

  /// Get current state
  String get currentState => _currentState;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    // _webViewController = null; // COMMENTED OUT - replacing with flutter_gl
    _isInitialized = false;
  }
} 