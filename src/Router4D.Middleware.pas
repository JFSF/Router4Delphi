unit Router4D.Middleware;

{$I Router4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Router4D.Props,
  Router4D.Guards;

type
  /// <summary>
  /// Middleware context - data passed through the pipeline
  /// </summary>
  TMiddlewareContext = class
  private
    FRouteContext: TRouteContext;
    FData: TDictionary<string, TValue>;
    FAborted: Boolean;
    FAbortReason: string;
  public
    constructor Create(ARouteContext: TRouteContext);
    destructor Destroy; override;

    property RouteContext: TRouteContext read FRouteContext;
    property Data: TDictionary<string, TValue> read FData;
    property Aborted: Boolean read FAborted write FAborted;
    property AbortReason: string read FAbortReason write FAbortReason;

    procedure Abort(const AReason: string);
  end;

  /// <summary>
  /// Middleware interface - implement to create custom middleware
  /// </summary>
  IMiddleware = interface
    ['{7C4D5E6F-8A9B-4C2D-9E3F-1A2B3C4D5E6F}']
    /// <summary>
    /// Execute middleware logic
    /// Return True to continue, False to abort pipeline
    /// </summary>
    function Execute(const AContext: TMiddlewareContext): Boolean;

    /// <summary>
    /// Get middleware name for logging
    /// </summary>
    function GetName: string;
  end;

  /// <summary>
  /// Base middleware class with default implementation
  /// </summary>
  TMiddleware = class(TInterfacedObject, IMiddleware)
  protected
    FName: string;
  public
    constructor Create(const AName: string);
    function Execute(const AContext: TMiddlewareContext): Boolean; virtual;
    function GetName: string; virtual;
  end;

  /// <summary>
  /// Logging middleware - logs all navigation
  /// </summary>
  TLoggingMiddleware = class(TMiddleware)
  public
    constructor Create;
    function Execute(const AContext: TMiddlewareContext): Boolean; override;
  end;

  /// <summary>
  /// Timing middleware - measures navigation time
  /// </summary>
  TTimingMiddleware = class(TMiddleware)
  private
    FStartTime: TDateTime;
  public
    constructor Create;
    function Execute(const AContext: TMiddlewareContext): Boolean; override;
  end;

  /// <summary>
  /// Authentication middleware - checks if user is logged in
  /// </summary>
  TAuthMiddleware = class(TMiddleware)
  private
    FCheckAuthFunc: TFunc<Boolean>;
    FRedirectRoute: string;
  public
    constructor Create(ACheckAuthFunc: TFunc<Boolean>; const ARedirectRoute: string = 'Login');
    function Execute(const AContext: TMiddlewareContext): Boolean; override;
  end;

  /// <summary>
  /// Validation middleware - validates navigation data
  /// </summary>
  TValidationMiddleware = class(TMiddleware)
  private
    FValidationFunc: TFunc<TMiddlewareContext, Boolean>;
  public
    constructor Create(AValidationFunc: TFunc<TMiddlewareContext, Boolean>);
    function Execute(const AContext: TMiddlewareContext): Boolean; override;
  end;

  /// <summary>
  /// Middleware pipeline manager
  /// </summary>
  TMiddlewarePipeline = class
  private
    FMiddlewares: TList<IMiddleware>;
    FRouteMiddlewares: TDictionary<string, TList<IMiddleware>>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Add global middleware (runs for all routes)
    /// </summary>
    procedure AddMiddleware(AMiddleware: IMiddleware);

    /// <summary>
    /// Add middleware for specific route
    /// </summary>
    procedure AddRouteMiddleware(const ARoute: string; AMiddleware: IMiddleware);

    /// <summary>
    /// Remove all middleware from a route
    /// </summary>
    procedure RemoveRouteMiddleware(const ARoute: string);

    /// <summary>
    /// Execute pipeline for navigation
    /// </summary>
    function Execute(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;

    /// <summary>
    /// Clear all middleware
    /// </summary>
    procedure Clear;
  end;

function MiddlewarePipeline: TMiddlewarePipeline;

implementation

uses
  System.DateUtils,
  Router4D.Logger;

var
  FMiddlewarePipeline: TMiddlewarePipeline;

function MiddlewarePipeline: TMiddlewarePipeline;
begin
  if not Assigned(FMiddlewarePipeline) then
    FMiddlewarePipeline := TMiddlewarePipeline.Create;
  Result := FMiddlewarePipeline;
end;

{ TMiddlewareContext }

constructor TMiddlewareContext.Create(ARouteContext: TRouteContext);
begin
  inherited Create;
  FRouteContext := ARouteContext;
  FData := TDictionary<string, TValue>.Create;
  FAborted := False;
  FAbortReason := '';
end;

destructor TMiddlewareContext.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TMiddlewareContext.Abort(const AReason: string);
begin
  FAborted := True;
  FAbortReason := AReason;
end;

{ TMiddleware }

constructor TMiddleware.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TMiddleware.Execute(const AContext: TMiddlewareContext): Boolean;
begin
  Result := True; // Default: continue
end;

function TMiddleware.GetName: string;
begin
  Result := FName;
end;

{ TLoggingMiddleware }

constructor TLoggingMiddleware.Create;
begin
  inherited Create('LoggingMiddleware');
end;

function TLoggingMiddleware.Execute(const AContext: TMiddlewareContext): Boolean;
begin
  Router4DLogger.LogInfo(Format('[Middleware] Navigation: %s -> %s',
    [AContext.RouteContext.FromRoute, AContext.RouteContext.ToRoute]));
  Result := True;
end;

{ TTimingMiddleware }

constructor TTimingMiddleware.Create;
begin
  inherited Create('TimingMiddleware');
  FStartTime := Now;
end;

function TTimingMiddleware.Execute(const AContext: TMiddlewareContext): Boolean;
var
  LElapsed: Int64;
begin
  LElapsed := MilliSecondsBetween(Now, FStartTime);
  Router4DLogger.LogDebug(Format('[Middleware] Navigation time: %d ms', [LElapsed]));
  AContext.Data.AddOrSetValue('NavigationTime', LElapsed);
  Result := True;
end;

{ TAuthMiddleware }

constructor TAuthMiddleware.Create(ACheckAuthFunc: TFunc<Boolean>; const ARedirectRoute: string = 'Login');
begin
  inherited Create('AuthMiddleware');
  FCheckAuthFunc := ACheckAuthFunc;
  FRedirectRoute := ARedirectRoute;
end;

function TAuthMiddleware.Execute(const AContext: TMiddlewareContext): Boolean;
begin
  if Assigned(FCheckAuthFunc) then
  begin
    Result := FCheckAuthFunc();
    if not Result then
    begin
      Router4DLogger.LogWarning(Format('[Middleware] Authentication failed for route: %s',
        [AContext.RouteContext.ToRoute]));
      AContext.Abort('Authentication required');
    end;
  end
  else
    Result := True;
end;

{ TValidationMiddleware }

constructor TValidationMiddleware.Create(AValidationFunc: TFunc<TMiddlewareContext, Boolean>);
begin
  inherited Create('ValidationMiddleware');
  FValidationFunc := AValidationFunc;
end;

function TValidationMiddleware.Execute(const AContext: TMiddlewareContext): Boolean;
begin
  if Assigned(FValidationFunc) then
  begin
    Result := FValidationFunc(AContext);
    if not Result then
    begin
      Router4DLogger.LogWarning('[Middleware] Validation failed');
      AContext.Abort('Validation failed');
    end;
  end
  else
    Result := True;
end;

{ TMiddlewarePipeline }

constructor TMiddlewarePipeline.Create;
begin
  inherited;
  FMiddlewares := TList<IMiddleware>.Create;
  FRouteMiddlewares := TDictionary<string, TList<IMiddleware>>.Create;
end;

destructor TMiddlewarePipeline.Destroy;
var
  LList: TList<IMiddleware>;
begin
  for LList in FRouteMiddlewares.Values do
    LList.Free;
  FRouteMiddlewares.Free;
  FMiddlewares.Free;
  inherited;
end;

procedure TMiddlewarePipeline.AddMiddleware(AMiddleware: IMiddleware);
begin
  FMiddlewares.Add(AMiddleware);
  Router4DLogger.LogDebug(Format('Added global middleware: %s', [AMiddleware.GetName]));
end;

procedure TMiddlewarePipeline.AddRouteMiddleware(const ARoute: string; AMiddleware: IMiddleware);
var
  LList: TList<IMiddleware>;
begin
  if not FRouteMiddlewares.TryGetValue(ARoute, LList) then
  begin
    LList := TList<IMiddleware>.Create;
    FRouteMiddlewares.Add(ARoute, LList);
  end;
  LList.Add(AMiddleware);
  Router4DLogger.LogDebug(Format('Added middleware %s to route: %s',
    [AMiddleware.GetName, ARoute]));
end;

procedure TMiddlewarePipeline.RemoveRouteMiddleware(const ARoute: string);
var
  LList: TList<IMiddleware>;
begin
  if FRouteMiddlewares.TryGetValue(ARoute, LList) then
  begin
    LList.Free;
    FRouteMiddlewares.Remove(ARoute);
    Router4DLogger.LogDebug(Format('Removed middleware from route: %s', [ARoute]));
  end;
end;

procedure TMiddlewarePipeline.Clear;
var
  LList: TList<IMiddleware>;
begin
  FMiddlewares.Clear;
  for LList in FRouteMiddlewares.Values do
    LList.Free;
  FRouteMiddlewares.Clear;
  Router4DLogger.LogDebug('Cleared all middleware');
end;

function TMiddlewarePipeline.Execute(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;
var
  LRouteContext: TRouteContext;
  LContext: TMiddlewareContext;
  LMiddleware: IMiddleware;
  LRouteMiddlewares: TList<IMiddleware>;
begin
  Result := True;
  LRouteContext := TRouteContext.Create(AFromRoute, AToRoute, AProps);
  LContext := TMiddlewareContext.Create(LRouteContext);
  try
    // Execute global middleware
    for LMiddleware in FMiddlewares do
    begin
      Router4DLogger.LogDebug(Format('Executing middleware: %s', [LMiddleware.GetName]));
      if not LMiddleware.Execute(LContext) or LContext.Aborted then
      begin
        Router4DLogger.LogWarning(Format('Middleware %s aborted navigation: %s',
          [LMiddleware.GetName, LContext.AbortReason]));
        Exit(False);
      end;
    end;

    // Execute route-specific middleware
    if FRouteMiddlewares.TryGetValue(AToRoute, LRouteMiddlewares) then
    begin
      for LMiddleware in LRouteMiddlewares do
      begin
        Router4DLogger.LogDebug(Format('Executing route middleware: %s', [LMiddleware.GetName]));
        if not LMiddleware.Execute(LContext) or LContext.Aborted then
        begin
          Router4DLogger.LogWarning(Format('Route middleware %s aborted navigation: %s',
            [LMiddleware.GetName, LContext.AbortReason]));
          Exit(False);
        end;
      end;
    end;
  finally
    LContext.Free;
    LRouteContext.Free;
  end;
end;

initialization

finalization
  if Assigned(FMiddlewarePipeline) then
    FMiddlewarePipeline.Free;

end.
