/// App-wide models to avoid circular imports

/// Audience enum for tone adaptation (kid vs parent)
enum Audience { child, parent }

/// App status for UI state management
enum AppStatus { 
  ready, 
  listening, 
  processing, 
  speaking, 
  complete, 
  concerned 
}
