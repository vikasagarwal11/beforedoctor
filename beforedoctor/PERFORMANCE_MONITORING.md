# Performance Monitoring Guide

## Overview
This app includes built-in performance monitoring tools for development and debugging. These tools help identify memory leaks, CPU spikes, and performance bottlenecks.

## Features

### 1. Real-time Performance Display
- **Memory Usage**: Shows current memory consumption in MB
- **CPU Usage**: Displays current CPU usage percentage
- **Snapshot Count**: Number of performance measurements taken

### 2. Automatic Monitoring
- **Auto-start**: Performance monitoring starts automatically in debug mode
- **Interval**: Takes measurements every 10 seconds
- **Thresholds**: Warns when memory > 80% or CPU > 70%

### 3. Manual Controls
- **Start Monitoring**: Manually start performance tracking
- **Clear Data**: Reset performance history
- **Real-time Updates**: Performance widget updates automatically

## How to Use

### View Performance Data
1. **Header Widget**: Performance monitor appears in the header (debug mode only)
2. **Real-time Updates**: Data updates every 10 seconds
3. **Threshold Warnings**: Check console for performance warnings

### Control Monitoring
1. **Start Button**: Green "Start Perf" button to begin monitoring
2. **Clear Button**: Red "Clear Perf" button to reset data
3. **Auto-cleanup**: Monitoring stops automatically when screen is disposed

### Console Output
Performance data is logged to the console:
```
📊 Performance: Memory: 125.3MB, CPU: 15.2%
⚠️ HIGH MEMORY USAGE: 450.7MB (90.1%)
⚠️ HIGH CPU USAGE: 75.3%
```

## Performance Thresholds

### Memory Warnings
- **Warning**: > 80% of available memory
- **Critical**: > 90% of available memory
- **Action**: Check for memory leaks, dispose resources

### CPU Warnings
- **Warning**: > 70% CPU usage
- **Critical**: > 90% CPU usage
- **Action**: Optimize animations, reduce rebuilds

## Troubleshooting

### High Memory Usage
1. **Check dispose() methods**: Ensure all controllers are disposed
2. **Monitor WebView**: 3D models can consume significant memory
3. **Clear caches**: Use "Clear Perf" button to reset data

### High CPU Usage
1. **Reduce rebuilds**: Use Riverpod select for specific state
2. **Optimize animations**: Pause animations when not visible
3. **Check loops**: Ensure no infinite loops in state management

### Performance Data Not Showing
1. **Debug mode**: Ensure running in debug mode
2. **Permissions**: Check if performance monitoring is enabled
3. **Restart**: Try restarting the app

## Development vs Production

### Development Mode (kDebugMode = true)
- ✅ Performance monitoring enabled
- ✅ Real-time performance display
- ✅ Console logging
- ✅ Manual controls visible

### Production Mode (kDebugMode = false)
- ❌ Performance monitoring disabled
- ❌ No performance widgets
- ❌ No console logging
- ❌ No performance overhead

## Best Practices

1. **Monitor Regularly**: Check performance during development
2. **Set Baselines**: Know your app's normal performance
3. **Investigate Spikes**: Look into sudden performance changes
4. **Profile Before Release**: Ensure good performance before production

## Technical Details

### Service Architecture
- **Singleton Pattern**: Single instance across the app
- **Timer-based**: Periodic measurements every 10 seconds
- **Memory Management**: Automatically cleans up old data
- **Platform Channels**: Uses native platform APIs for accurate data

### Data Collection
- **Memory**: Available and used memory in bytes
- **CPU**: Current CPU usage percentage
- **Timestamps**: When each measurement was taken
- **Platform**: Operating system information

### Integration Points
- **EnhancedDoctorCharacterScreen**: Main integration point
- **Riverpod**: Uses Consumer for reactive updates
- **Logger**: Integrated with existing logging system
- **Lifecycle**: Automatically starts/stops with screen

## Future Enhancements

1. **Performance Alerts**: Push notifications for critical issues
2. **Historical Data**: Store performance data over time
3. **Export Reports**: Generate performance reports
4. **Custom Thresholds**: User-configurable warning levels
5. **Performance Tips**: Automatic suggestions for improvements
