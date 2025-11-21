# Router4D Logging System

## Overview

Router4D now includes a comprehensive logging system that helps you track navigation events, errors, warnings, and debug information throughout your application.

## Features

- **Multiple log levels**: Debug, Info, Warning, Error, Critical
- **Thread-safe**: Uses critical sections for safe multi-threaded logging
- **Flexible output**: Log to console, file, or implement custom loggers
- **Configurable**: Enable/disable logging, set minimum log level
- **Null logger**: Zero-overhead logging when disabled (default)

## Quick Start

### 1. Enable Logging (Simple Console Logging)

```delphi
uses
  Router4D,
  Router4D.Logger;

// In your initialization code (e.g., DPR file or main form)
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Enable console logging
  SetRouter4DLogger(TRouter4DLogger.Create('', False, True));

  // Configure your routes...
  TRouter4D.Switch
    .Router('Home', THomeForm)
    .Router('About', TAboutForm);
end;
```

### 2. Enable File Logging

```delphi
// Log to file with console output
SetRouter4DLogger(TRouter4DLogger.Create('my_app.log', True, True));
```

### 3. Configure Log Level

```delphi
var
  Logger: IRouter4DLogger;
begin
  Logger := TRouter4DLogger.Create;
  Logger.MinLevel := llWarning;  // Only log warnings and above
  Logger.Enabled := True;
  SetRouter4DLogger(Logger);
end;
```

## Log Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `llDebug` | Detailed diagnostic information | Development and troubleshooting |
| `llInfo` | General informational messages | Normal application flow |
| `llWarning` | Warning messages for potential issues | Non-critical problems |
| `llError` | Error messages for failures | Errors that don't crash the app |
| `llCritical` | Critical errors requiring attention | Severe errors |

## What Gets Logged Automatically

Router4D automatically logs:

- **Navigation events**: Every route change with source and destination
- **Errors**: All routing errors with detailed messages
- **Component registration**: EventBus subscriber registration
- **Cache operations**: Cache hits, misses, and evictions
- **Route creation**: Dynamic route instantiation

## Example Log Output

```
[2025-01-15 10:30:15] [INFO] Navigation: -> Home
[2025-01-15 10:30:16] [DEBUG] Registered EventBus subscriber: THomeForm
[2025-01-15 10:30:20] [INFO] Navigation: Home -> About
[2025-01-15 10:30:25] [ERROR] Route not found: InvalidRoute
[2025-01-15 10:30:30] [INFO] Going back to: Home
[2025-01-15 10:31:00] [DEBUG] Cache limit reached. Removing oldest item: OldRoute
```

## Custom Logger Implementation

Implement `IRouter4DLogger` for custom behavior:

```delphi
type
  TMyCustomLogger = class(TInterfacedObject, IRouter4DLogger)
  private
    FMinLevel: TRouter4DLogLevel;
    FEnabled: Boolean;
  public
    procedure LogNavigation(const AFrom, ATo: string);
    procedure LogError(const AMessage: string);
    procedure LogWarning(const AMessage: string);
    procedure LogInfo(const AMessage: string);
    procedure LogDebug(const AMessage: string);
    procedure Log(const ALevel: TRouter4DLogLevel; const AMessage: string);
    function GetMinLevel: TRouter4DLogLevel;
    procedure SetMinLevel(const AValue: TRouter4DLogLevel);
    function GetEnabled: Boolean;
    procedure SetEnabled(const AValue: Boolean);
  end;

// Usage
SetRouter4DLogger(TMyCustomLogger.Create);
```

## Best Practices

### Development
```delphi
// Verbose logging during development
var Logger := TRouter4DLogger.Create('debug.log', True, True);
Logger.MinLevel := llDebug;
SetRouter4DLogger(Logger);
```

### Production
```delphi
// Minimal logging in production
var Logger := TRouter4DLogger.Create('app.log', True, False);
Logger.MinLevel := llWarning;  // Only warnings and errors
SetRouter4DLogger(Logger);
```

### Debugging Specific Issues
```delphi
// Enable logging only when needed
Router4DLogger.Enabled := True;
Router4DLogger.MinLevel := llDebug;

// ... perform operations ...

// Disable when done
Router4DLogger.Enabled := False;
```

## Performance Considerations

- **Null Logger (Default)**: Zero overhead when logging is disabled
- **File I/O**: File logging may impact performance in high-frequency scenarios
- **Console Output**: Console logging is fast but not recommended for production
- **Log Level Filtering**: Set appropriate `MinLevel` to reduce overhead

## Integration with External Systems

### Send Logs to Server
```delphi
type
  TServerLogger = class(TInterfacedObject, IRouter4DLogger)
    procedure Log(const ALevel: TRouter4DLogLevel; const AMessage: string);
    begin
      // Send to your logging service
      MyLoggingService.SendLog(LevelToString(ALevel), AMessage);
    end;
  end;
```

### Integration with Third-Party Loggers
```delphi
// Example: CodeSite integration
procedure TCodeSiteLogger.Log(const ALevel: TRouter4DLogLevel; const AMessage: string);
begin
  case ALevel of
    llDebug: CodeSite.Send(AMessage);
    llInfo: CodeSite.SendNote(AMessage);
    llWarning: CodeSite.SendWarning(AMessage);
    llError: CodeSite.SendError(AMessage);
    llCritical: CodeSite.SendFatalError(AMessage);
  end;
end;
```

## Troubleshooting

### Logs Not Appearing

1. Check if logger is enabled:
   ```delphi
   if not Router4DLogger.Enabled then
     Router4DLogger.SetEnabled(True);
   ```

2. Verify log level:
   ```delphi
   Router4DLogger.SetMinLevel(llDebug);  // Most verbose
   ```

3. Ensure logger is configured:
   ```delphi
   SetRouter4DLogger(TRouter4DLogger.Create);
   ```

### File Not Created

- Check write permissions for the log file location
- Ensure directory exists
- Try using absolute path: `SetRouter4DLogger(TRouter4DLogger.Create('C:\Logs\app.log', True, False));`

## API Reference

### Global Functions

- `Router4DLogger: IRouter4DLogger` - Get current logger instance
- `SetRouter4DLogger(const ALogger: IRouter4DLogger)` - Set custom logger

### IRouter4DLogger Methods

- `LogNavigation(const AFrom, ATo: string)` - Log navigation event
- `LogError(const AMessage: string)` - Log error message
- `LogWarning(const AMessage: string)` - Log warning message
- `LogInfo(const AMessage: string)` - Log info message
- `LogDebug(const AMessage: string)` - Log debug message
- `Log(const ALevel: TRouter4DLogLevel; const AMessage: string)` - Log with specific level

### Properties

- `Enabled: Boolean` - Enable/disable logging
- `MinLevel: TRouter4DLogLevel` - Minimum level to log

## Changelog

### Phase 2 (Current)
- Initial logging system implementation
- Automatic logging for all routing operations
- File and console output support
- Thread-safe implementation
- Null logger for zero overhead when disabled
