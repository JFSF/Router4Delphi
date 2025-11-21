unit Router4D.Logger;

{$I Router4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  /// <summary>
  /// Log level enumeration
  /// </summary>
  TRouter4DLogLevel = (llDebug, llInfo, llWarning, llError, llCritical);

  /// <summary>
  /// Interface for Router4D logging system
  /// </summary>
  IRouter4DLogger = interface
    ['{8F3C4B5D-9E2A-4F1B-B7D6-1A9C8E4F2D3B}']
    /// <summary>
    /// Logs a navigation event
    /// </summary>
    procedure LogNavigation(const AFrom, ATo: string);

    /// <summary>
    /// Logs an error message
    /// </summary>
    procedure LogError(const AMessage: string);

    /// <summary>
    /// Logs a warning message
    /// </summary>
    procedure LogWarning(const AMessage: string);

    /// <summary>
    /// Logs an informational message
    /// </summary>
    procedure LogInfo(const AMessage: string);

    /// <summary>
    /// Logs a debug message
    /// </summary>
    procedure LogDebug(const AMessage: string);

    /// <summary>
    /// Logs a message with specified level
    /// </summary>
    procedure Log(const ALevel: TRouter4DLogLevel; const AMessage: string);

    /// <summary>
    /// Gets or sets the minimum log level
    /// </summary>
    function GetMinLevel: TRouter4DLogLevel;
    procedure SetMinLevel(const AValue: TRouter4DLogLevel);
    property MinLevel: TRouter4DLogLevel read GetMinLevel write SetMinLevel;

    /// <summary>
    /// Gets or sets whether logging is enabled
    /// </summary>
    function GetEnabled: Boolean;
    procedure SetEnabled(const AValue: Boolean);
    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;

  /// <summary>
  /// Default implementation of Router4D logger
  /// Logs to a file or can be extended for custom output
  /// </summary>
  TRouter4DLogger = class(TInterfacedObject, IRouter4DLogger)
  private
    FMinLevel: TRouter4DLogLevel;
    FEnabled: Boolean;
    FLogFile: string;
    FLock: TCriticalSection;
    FUseFile: Boolean;
    FLogToConsole: Boolean;
    procedure WriteToFile(const AMessage: string);
    procedure WriteToConsole(const AMessage: string);
    function LevelToString(const ALevel: TRouter4DLogLevel): string;
  public
    constructor Create(const ALogFile: string = ''; AUseFile: Boolean = False; ALogToConsole: Boolean = True);
    destructor Destroy; override;

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

  /// <summary>
  /// Null logger implementation - does nothing
  /// Use this when you want to disable logging
  /// </summary>
  TRouter4DNullLogger = class(TInterfacedObject, IRouter4DLogger)
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

/// <summary>
/// Gets the global Router4D logger instance
/// </summary>
function Router4DLogger: IRouter4DLogger;

/// <summary>
/// Sets a custom logger implementation
/// </summary>
procedure SetRouter4DLogger(const ALogger: IRouter4DLogger);

implementation

var
  FGlobalLogger: IRouter4DLogger;

function Router4DLogger: IRouter4DLogger;
begin
  if not Assigned(FGlobalLogger) then
    FGlobalLogger := TRouter4DNullLogger.Create;
  Result := FGlobalLogger;
end;

procedure SetRouter4DLogger(const ALogger: IRouter4DLogger);
begin
  FGlobalLogger := ALogger;
end;

{ TRouter4DLogger }

constructor TRouter4DLogger.Create(const ALogFile: string = ''; AUseFile: Boolean = False; ALogToConsole: Boolean = True);
begin
  inherited Create;
  FMinLevel := llInfo;
  FEnabled := True;
  FLogFile := ALogFile;
  FUseFile := AUseFile;
  FLogToConsole := ALogToConsole;
  FLock := TCriticalSection.Create;

  if FUseFile and FLogFile.IsEmpty then
    FLogFile := 'Router4D.log';
end;

destructor TRouter4DLogger.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TRouter4DLogger.LevelToString(const ALevel: TRouter4DLogLevel): string;
begin
  case ALevel of
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO';
    llWarning: Result := 'WARNING';
    llError: Result := 'ERROR';
    llCritical: Result := 'CRITICAL';
  else
    Result := 'UNKNOWN';
  end;
end;

procedure TRouter4DLogger.WriteToFile(const AMessage: string);
var
  LFile: TextFile;
begin
  if not FUseFile then Exit;

  FLock.Enter;
  try
    try
      AssignFile(LFile, FLogFile);
      if FileExists(FLogFile) then
        Append(LFile)
      else
        Rewrite(LFile);
      try
        WriteLn(LFile, AMessage);
      finally
        CloseFile(LFile);
      end;
    except
      // Silently fail if file write fails
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TRouter4DLogger.WriteToConsole(const AMessage: string);
begin
  if FLogToConsole then
  begin
    {$IFDEF CONSOLE}
    WriteLn(AMessage);
    {$ENDIF}
  end;
end;

procedure TRouter4DLogger.Log(const ALevel: TRouter4DLogLevel; const AMessage: string);
var
  LFormattedMessage: string;
begin
  if not FEnabled then Exit;
  if ALevel < FMinLevel then Exit;

  LFormattedMessage := Format('[%s] [%s] %s',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), LevelToString(ALevel), AMessage]);

  WriteToFile(LFormattedMessage);
  WriteToConsole(LFormattedMessage);
end;

procedure TRouter4DLogger.LogDebug(const AMessage: string);
begin
  Log(llDebug, AMessage);
end;

procedure TRouter4DLogger.LogError(const AMessage: string);
begin
  Log(llError, AMessage);
end;

procedure TRouter4DLogger.LogInfo(const AMessage: string);
begin
  Log(llInfo, AMessage);
end;

procedure TRouter4DLogger.LogNavigation(const AFrom, ATo: string);
begin
  if AFrom.IsEmpty then
    LogInfo(Format('Navigation: -> %s', [ATo]))
  else
    LogInfo(Format('Navigation: %s -> %s', [AFrom, ATo]));
end;

procedure TRouter4DLogger.LogWarning(const AMessage: string);
begin
  Log(llWarning, AMessage);
end;

function TRouter4DLogger.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TRouter4DLogger.GetMinLevel: TRouter4DLogLevel;
begin
  Result := FMinLevel;
end;

procedure TRouter4DLogger.SetEnabled(const AValue: Boolean);
begin
  FEnabled := AValue;
end;

procedure TRouter4DLogger.SetMinLevel(const AValue: TRouter4DLogLevel);
begin
  FMinLevel := AValue;
end;

{ TRouter4DNullLogger }

function TRouter4DNullLogger.GetEnabled: Boolean;
begin
  Result := False;
end;

function TRouter4DNullLogger.GetMinLevel: TRouter4DLogLevel;
begin
  Result := llInfo;
end;

procedure TRouter4DNullLogger.Log(const ALevel: TRouter4DLogLevel; const AMessage: string);
begin
  // Do nothing
end;

procedure TRouter4DNullLogger.LogDebug(const AMessage: string);
begin
  // Do nothing
end;

procedure TRouter4DNullLogger.LogError(const AMessage: string);
begin
  // Do nothing
end;

procedure TRouter4DNullLogger.LogInfo(const AMessage: string);
begin
  // Do nothing
end;

procedure TRouter4DNullLogger.LogNavigation(const AFrom, ATo: string);
begin
  // Do nothing
end;

procedure TRouter4DNullLogger.LogWarning(const AMessage: string);
begin
  // Do nothing
end;

procedure TRouter4DNullLogger.SetEnabled(const AValue: Boolean);
begin
  // Do nothing
end;

procedure TRouter4DNullLogger.SetMinLevel(const AValue: TRouter4DLogLevel);
begin
  // Do nothing
end;

initialization
  FGlobalLogger := TRouter4DNullLogger.Create;

finalization
  FGlobalLogger := nil;

end.
