unit Router4D.Events;

{$I Router4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Router4D.Props;

type
  /// <summary>
  /// Navigation event data
  /// </summary>
  TNavigationEventData = class
  private
    FFromRoute: string;
    FToRoute: string;
    FProps: TProps;
    FCancelled: Boolean;
    FTimestamp: TDateTime;
  public
    constructor Create(const AFromRoute, AToRoute: string; AProps: TProps = nil);

    property FromRoute: string read FFromRoute;
    property ToRoute: string read FToRoute;
    property Props: TProps read FProps;
    property Cancelled: Boolean read FCancelled write FCancelled;
    property Timestamp: TDateTime read FTimestamp;
  end;

  /// <summary>
  /// Navigation event types
  /// </summary>
  TNavigationEvent = procedure(Sender: TObject; EventData: TNavigationEventData) of object;
  TNavigationCancellableEvent = procedure(Sender: TObject; EventData: TNavigationEventData; var Cancel: Boolean) of object;

  /// <summary>
  /// Navigation events manager
  /// </summary>
  TNavigationEvents = class
  private
    FOnBeforeNavigate: TNavigationCancellableEvent;
    FOnAfterNavigate: TNavigationEvent;
    FOnNavigationError: TNavigationEvent;
    FOnNavigationCancelled: TNavigationEvent;
    FEventHistory: TList<TNavigationEventData>;
    FMaxHistorySize: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Fired before navigation occurs - can be cancelled
    /// </summary>
    property OnBeforeNavigate: TNavigationCancellableEvent read FOnBeforeNavigate write FOnBeforeNavigate;

    /// <summary>
    /// Fired after successful navigation
    /// </summary>
    property OnAfterNavigate: TNavigationEvent read FOnAfterNavigate write FOnAfterNavigate;

    /// <summary>
    /// Fired when navigation error occurs
    /// </summary>
    property OnNavigationError: TNavigationEvent read FOnNavigationError write FOnNavigationError;

    /// <summary>
    /// Fired when navigation is cancelled
    /// </summary>
    property OnNavigationCancelled: TNavigationCancellableEvent read FOnNavigationCancelled write FOnNavigationCancelled;

    /// <summary>
    /// Trigger before navigate event
    /// </summary>
    function TriggerBeforeNavigate(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;

    /// <summary>
    /// Trigger after navigate event
    /// </summary>
    procedure TriggerAfterNavigate(const AFromRoute, AToRoute: string; AProps: TProps = nil);

    /// <summary>
    /// Trigger navigation error event
    /// </summary>
    procedure TriggerNavigationError(const AFromRoute, AToRoute: string; AProps: TProps = nil);

    /// <summary>
    /// Trigger navigation cancelled event
    /// </summary>
    procedure TriggerNavigationCancelled(const AFromRoute, AToRoute: string; AProps: TProps = nil);

    /// <summary>
    /// Get navigation history
    /// </summary>
    function GetNavigationHistory: TArray<TNavigationEventData>;

    /// <summary>
    /// Clear navigation history
    /// </summary>
    procedure ClearHistory;

    /// <summary>
    /// Maximum number of events to keep in history (default: 50)
    /// </summary>
    property MaxHistorySize: Integer read FMaxHistorySize write FMaxHistorySize;
  end;

function NavigationEvents: TNavigationEvents;

implementation

uses
  Router4D.Logger;

var
  FNavigationEvents: TNavigationEvents;

function NavigationEvents: TNavigationEvents;
begin
  if not Assigned(FNavigationEvents) then
    FNavigationEvents := TNavigationEvents.Create;
  Result := FNavigationEvents;
end;

{ TNavigationEventData }

constructor TNavigationEventData.Create(const AFromRoute, AToRoute: string; AProps: TProps = nil);
begin
  inherited Create;
  FFromRoute := AFromRoute;
  FToRoute := AToRoute;
  FProps := AProps;
  FCancelled := False;
  FTimestamp := Now;
end;

{ TNavigationEvents }

constructor TNavigationEvents.Create;
begin
  inherited;
  FEventHistory := TList<TNavigationEventData>.Create;
  FMaxHistorySize := 50;
end;

destructor TNavigationEvents.Destroy;
var
  LEvent: TNavigationEventData;
begin
  for LEvent in FEventHistory do
    LEvent.Free;
  FEventHistory.Free;
  inherited;
end;

procedure TNavigationEvents.ClearHistory;
var
  LEvent: TNavigationEventData;
begin
  for LEvent in FEventHistory do
    LEvent.Free;
  FEventHistory.Clear;
  Router4DLogger.LogDebug('Navigation history cleared');
end;

function TNavigationEvents.GetNavigationHistory: TArray<TNavigationEventData>;
begin
  Result := FEventHistory.ToArray;
end;

function TNavigationEvents.TriggerBeforeNavigate(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;
var
  LEventData: TNavigationEventData;
  LCancel: Boolean;
begin
  LCancel := False;
  Result := True;

  if Assigned(FOnBeforeNavigate) then
  begin
    LEventData := TNavigationEventData.Create(AFromRoute, AToRoute, AProps);
    try
      FOnBeforeNavigate(Self, LEventData, LCancel);
      if LCancel then
      begin
        Router4DLogger.LogInfo(Format('Navigation cancelled by event handler: %s -> %s',
          [AFromRoute, AToRoute]));
        LEventData.Cancelled := True;
        Result := False;
      end;
    finally
      // Don't free here - will be added to history
      if not LCancel then
        LEventData.Free;
    end;
  end;
end;

procedure TNavigationEvents.TriggerAfterNavigate(const AFromRoute, AToRoute: string; AProps: TProps = nil);
var
  LEventData: TNavigationEventData;
begin
  LEventData := TNavigationEventData.Create(AFromRoute, AToRoute, AProps);

  if Assigned(FOnAfterNavigate) then
    FOnAfterNavigate(Self, LEventData);

  // Add to history
  FEventHistory.Add(LEventData);

  // Limit history size
  while FEventHistory.Count > FMaxHistorySize do
  begin
    FEventHistory[0].Free;
    FEventHistory.Delete(0);
  end;

  Router4DLogger.LogDebug(Format('After navigate event: %s -> %s', [AFromRoute, AToRoute]));
end;

procedure TNavigationEvents.TriggerNavigationCancelled(const AFromRoute, AToRoute: string; AProps: TProps = nil);
var
  LEventData: TNavigationEventData;
  LCancel: Boolean;
begin
  LEventData := TNavigationEventData.Create(AFromRoute, AToRoute, AProps);
  LEventData.Cancelled := True;

  if Assigned(FOnNavigationCancelled) then
    FOnNavigationCancelled(Self, LEventData, LCancel);

  Router4DLogger.LogInfo(Format('Navigation cancelled: %s -> %s', [AFromRoute, AToRoute]));

  LEventData.Free;
end;

procedure TNavigationEvents.TriggerNavigationError(const AFromRoute, AToRoute: string; AProps: TProps = nil);
var
  LEventData: TNavigationEventData;
begin
  LEventData := TNavigationEventData.Create(AFromRoute, AToRoute, AProps);

  if Assigned(FOnNavigationError) then
    FOnNavigationError(Self, LEventData);

  Router4DLogger.LogError(Format('Navigation error: %s -> %s', [AFromRoute, AToRoute]));

  LEventData.Free;
end;

initialization

finalization
  if Assigned(FNavigationEvents) then
    FNavigationEvents.Free;

end.
