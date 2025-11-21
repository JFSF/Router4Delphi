unit Router4D.Config;

{$I Router4D.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Global configuration for Router4D
  /// </summary>
  TRouter4DConfig = class
  private
    FMaxFrameCache: Integer;
    FMaxHistoryCache: Integer;
    FEnableLogging: Boolean;
    FStrictMode: Boolean;
    FEnableAnimation: Boolean;
    FDefaultAnimationDuration: Integer;
    class var FInstance: TRouter4DConfig;
    class function GetInstance: TRouter4DConfig; static;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Gets the singleton instance
    /// </summary>
    class property Instance: TRouter4DConfig read GetInstance;

    /// <summary>
    /// Maximum number of cached form instances (default: 25)
    /// </summary>
    property MaxFrameCache: Integer read FMaxFrameCache write FMaxFrameCache;

    /// <summary>
    /// Maximum number of history entries (default: 10)
    /// </summary>
    property MaxHistoryCache: Integer read FMaxHistoryCache write FMaxHistoryCache;

    /// <summary>
    /// Enable/disable logging (default: False)
    /// </summary>
    property EnableLogging: Boolean read FEnableLogging write FEnableLogging;

    /// <summary>
    /// Strict mode raises exceptions instead of silent failures (default: True)
    /// </summary>
    property StrictMode: Boolean read FStrictMode write FStrictMode;

    /// <summary>
    /// Enable/disable animations (default: True)
    /// </summary>
    property EnableAnimation: Boolean read FEnableAnimation write FEnableAnimation;

    /// <summary>
    /// Default animation duration in milliseconds (default: 300)
    /// </summary>
    property DefaultAnimationDuration: Integer read FDefaultAnimationDuration write FDefaultAnimationDuration;

    /// <summary>
    /// Reset all settings to defaults
    /// </summary>
    procedure ResetToDefaults;

    /// <summary>
    /// Fluent configuration methods
    /// </summary>
    function SetMaxFrameCache(const AValue: Integer): TRouter4DConfig;
    function SetMaxHistoryCache(const AValue: Integer): TRouter4DConfig;
    function SetEnableLogging(const AValue: Boolean): TRouter4DConfig;
    function SetStrictMode(const AValue: Boolean): TRouter4DConfig;
    function SetEnableAnimation(const AValue: Boolean): TRouter4DConfig;
    function SetDefaultAnimationDuration(const AValue: Integer): TRouter4DConfig;
  end;

implementation

var
  FConfigLock: TObject;

{ TRouter4DConfig }

constructor TRouter4DConfig.Create;
begin
  inherited;
  ResetToDefaults;
end;

destructor TRouter4DConfig.Destroy;
begin
  inherited;
end;

class function TRouter4DConfig.GetInstance: TRouter4DConfig;
begin
  if not Assigned(FInstance) then
  begin
    TMonitor.Enter(FConfigLock);
    try
      if not Assigned(FInstance) then
        FInstance := TRouter4DConfig.Create;
    finally
      TMonitor.Exit(FConfigLock);
    end;
  end;
  Result := FInstance;
end;

procedure TRouter4DConfig.ResetToDefaults;
begin
  FMaxFrameCache := 25;
  FMaxHistoryCache := 10;
  FEnableLogging := False;
  FStrictMode := True;
  FEnableAnimation := True;
  FDefaultAnimationDuration := 300;
end;

function TRouter4DConfig.SetDefaultAnimationDuration(const AValue: Integer): TRouter4DConfig;
begin
  Result := Self;
  FDefaultAnimationDuration := AValue;
end;

function TRouter4DConfig.SetEnableAnimation(const AValue: Boolean): TRouter4DConfig;
begin
  Result := Self;
  FEnableAnimation := AValue;
end;

function TRouter4DConfig.SetEnableLogging(const AValue: Boolean): TRouter4DConfig;
begin
  Result := Self;
  FEnableLogging := AValue;
end;

function TRouter4DConfig.SetMaxFrameCache(const AValue: Integer): TRouter4DConfig;
begin
  Result := Self;
  FMaxFrameCache := AValue;
end;

function TRouter4DConfig.SetMaxHistoryCache(const AValue: Integer): TRouter4DConfig;
begin
  Result := Self;
  FMaxHistoryCache := AValue;
end;

function TRouter4DConfig.SetStrictMode(const AValue: Boolean): TRouter4DConfig;
begin
  Result := Self;
  FStrictMode := AValue;
end;

initialization
  FConfigLock := TObject.Create;

finalization
  FConfigLock.Free;
  if Assigned(TRouter4DConfig.FInstance) then
    TRouter4DConfig.FInstance.Free;

end.
