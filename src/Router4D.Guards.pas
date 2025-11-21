unit Router4D.Guards;

{$I Router4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Router4D.Props;

type
  /// <summary>
  /// Context information passed to guards
  /// </summary>
  TRouteContext = class
  private
    FFromRoute: string;
    FToRoute: string;
    FProps: TProps;
  public
    constructor Create(const AFromRoute, AToRoute: string; AProps: TProps = nil);
    destructor Destroy; override;

    property FromRoute: string read FFromRoute;
    property ToRoute: string read FToRoute;
    property Props: TProps read FProps;
  end;

  /// <summary>
  /// Interface for route guards
  /// Implement this to control access to routes
  /// </summary>
  IRouteGuard = interface
    ['{9B2C5E7F-4A1D-4C8E-B3F6-8D9E1A2B3C4D}']
    /// <summary>
    /// Called before navigating to a route
    /// Return True to allow navigation, False to block it
    /// </summary>
    function CanActivate(const AContext: TRouteContext): Boolean;

    /// <summary>
    /// Called before leaving the current route
    /// Return True to allow navigation away, False to block it
    /// </summary>
    function CanDeactivate(const AContext: TRouteContext): Boolean;
  end;

  /// <summary>
  /// Base class for route guards with default implementations
  /// </summary>
  TRouteGuard = class(TInterfacedObject, IRouteGuard)
  public
    function CanActivate(const AContext: TRouteContext): Boolean; virtual;
    function CanDeactivate(const AContext: TRouteContext): Boolean; virtual;
  end;

  /// <summary>
  /// Authentication guard - blocks access if not authenticated
  /// </summary>
  TAuthGuard = class(TRouteGuard)
  private
    FCheckAuthFunc: TFunc<Boolean>;
    FRedirectRoute: string;
  public
    constructor Create(ACheckAuthFunc: TFunc<Boolean>; const ARedirectRoute: string = 'Login');
    function CanActivate(const AContext: TRouteContext): Boolean; override;
  end;

  /// <summary>
  /// Confirmation guard - asks for confirmation before leaving
  /// Useful for unsaved changes
  /// </summary>
  TConfirmationGuard = class(TRouteGuard)
  private
    FMessage: string;
    FConfirmFunc: TFunc<string, Boolean>;
  public
    constructor Create(const AMessage: string; AConfirmFunc: TFunc<string, Boolean>);
    function CanDeactivate(const AContext: TRouteContext): Boolean; override;
  end;

  /// <summary>
  /// Role-based guard - checks if user has required role
  /// </summary>
  TRoleGuard = class(TRouteGuard)
  private
    FRequiredRoles: TArray<string>;
    FCheckRoleFunc: TFunc<string, Boolean>;
  public
    constructor Create(const ARequiredRoles: TArray<string>; ACheckRoleFunc: TFunc<string, Boolean>);
    function CanActivate(const AContext: TRouteContext): Boolean; override;
  end;

  /// <summary>
  /// Manager for route guards
  /// </summary>
  TRouteGuardManager = class
  private
    FGuards: TDictionary<string, TList<IRouteGuard>>;
    FGlobalGuards: TList<IRouteGuard>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Add a guard for a specific route
    /// </summary>
    procedure AddGuard(const ARoute: string; AGuard: IRouteGuard);

    /// <summary>
    /// Add a global guard that applies to all routes
    /// </summary>
    procedure AddGlobalGuard(AGuard: IRouteGuard);

    /// <summary>
    /// Remove all guards for a route
    /// </summary>
    procedure RemoveGuards(const ARoute: string);

    /// <summary>
    /// Check if navigation is allowed
    /// </summary>
    function CanNavigate(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;

    /// <summary>
    /// Check if we can leave current route
    /// </summary>
    function CanLeave(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;
  end;

function RouteGuardManager: TRouteGuardManager;

implementation

uses
  Router4D.Logger;

var
  FGuardManager: TRouteGuardManager;

function RouteGuardManager: TRouteGuardManager;
begin
  if not Assigned(FGuardManager) then
    FGuardManager := TRouteGuardManager.Create;
  Result := FGuardManager;
end;

{ TRouteContext }

constructor TRouteContext.Create(const AFromRoute, AToRoute: string; AProps: TProps = nil);
begin
  inherited Create;
  FFromRoute := AFromRoute;
  FToRoute := AToRoute;
  FProps := AProps;
end;

destructor TRouteContext.Destroy;
begin
  // Props ownership is managed elsewhere
  inherited;
end;

{ TRouteGuard }

function TRouteGuard.CanActivate(const AContext: TRouteContext): Boolean;
begin
  Result := True; // Default: allow
end;

function TRouteGuard.CanDeactivate(const AContext: TRouteContext): Boolean;
begin
  Result := True; // Default: allow
end;

{ TAuthGuard }

constructor TAuthGuard.Create(ACheckAuthFunc: TFunc<Boolean>; const ARedirectRoute: string = 'Login');
begin
  inherited Create;
  FCheckAuthFunc := ACheckAuthFunc;
  FRedirectRoute := ARedirectRoute;
end;

function TAuthGuard.CanActivate(const AContext: TRouteContext): Boolean;
begin
  if Assigned(FCheckAuthFunc) then
  begin
    Result := FCheckAuthFunc();
    if not Result then
      Router4DLogger.LogWarning(Format('Access denied to %s: Not authenticated', [AContext.ToRoute]));
  end
  else
    Result := True;
end;

{ TConfirmationGuard }

constructor TConfirmationGuard.Create(const AMessage: string; AConfirmFunc: TFunc<string, Boolean>);
begin
  inherited Create;
  FMessage := AMessage;
  FConfirmFunc := AConfirmFunc;
end;

function TConfirmationGuard.CanDeactivate(const AContext: TRouteContext): Boolean;
begin
  if Assigned(FConfirmFunc) then
  begin
    Result := FConfirmFunc(FMessage);
    if not Result then
      Router4DLogger.LogInfo(Format('Navigation from %s to %s cancelled by user',
        [AContext.FromRoute, AContext.ToRoute]));
  end
  else
    Result := True;
end;

{ TRoleGuard }

constructor TRoleGuard.Create(const ARequiredRoles: TArray<string>; ACheckRoleFunc: TFunc<string, Boolean>);
begin
  inherited Create;
  FRequiredRoles := ARequiredRoles;
  FCheckRoleFunc := ACheckRoleFunc;
end;

function TRoleGuard.CanActivate(const AContext: TRouteContext): Boolean;
var
  LRole: string;
begin
  Result := False;

  if not Assigned(FCheckRoleFunc) then
    Exit(True);

  for LRole in FRequiredRoles do
  begin
    if FCheckRoleFunc(LRole) then
    begin
      Result := True;
      Break;
    end;
  end;

  if not Result then
    Router4DLogger.LogWarning(Format('Access denied to %s: Required role not found', [AContext.ToRoute]));
end;

{ TRouteGuardManager }

constructor TRouteGuardManager.Create;
begin
  inherited;
  FGuards := TDictionary<string, TList<IRouteGuard>>.Create;
  FGlobalGuards := TList<IRouteGuard>.Create;
end;

destructor TRouteGuardManager.Destroy;
var
  LList: TList<IRouteGuard>;
begin
  for LList in FGuards.Values do
    LList.Free;
  FGuards.Free;
  FGlobalGuards.Free;
  inherited;
end;

procedure TRouteGuardManager.AddGuard(const ARoute: string; AGuard: IRouteGuard);
var
  LList: TList<IRouteGuard>;
begin
  if not FGuards.TryGetValue(ARoute, LList) then
  begin
    LList := TList<IRouteGuard>.Create;
    FGuards.Add(ARoute, LList);
  end;
  LList.Add(AGuard);
  Router4DLogger.LogDebug(Format('Added guard to route: %s', [ARoute]));
end;

procedure TRouteGuardManager.AddGlobalGuard(AGuard: IRouteGuard);
begin
  FGlobalGuards.Add(AGuard);
  Router4DLogger.LogDebug('Added global guard');
end;

procedure TRouteGuardManager.RemoveGuards(const ARoute: string);
var
  LList: TList<IRouteGuard>;
begin
  if FGuards.TryGetValue(ARoute, LList) then
  begin
    LList.Free;
    FGuards.Remove(ARoute);
    Router4DLogger.LogDebug(Format('Removed guards from route: %s', [ARoute]));
  end;
end;

function TRouteGuardManager.CanNavigate(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;
var
  LContext: TRouteContext;
  LGuards: TList<IRouteGuard>;
  LGuard: IRouteGuard;
begin
  Result := True;
  LContext := TRouteContext.Create(AFromRoute, AToRoute, AProps);
  try
    // Check global guards first
    for LGuard in FGlobalGuards do
    begin
      if not LGuard.CanActivate(LContext) then
      begin
        Router4DLogger.LogWarning(Format('Global guard blocked navigation to: %s', [AToRoute]));
        Exit(False);
      end;
    end;

    // Check route-specific guards
    if FGuards.TryGetValue(AToRoute, LGuards) then
    begin
      for LGuard in LGuards do
      begin
        if not LGuard.CanActivate(LContext) then
        begin
          Router4DLogger.LogWarning(Format('Route guard blocked navigation to: %s', [AToRoute]));
          Exit(False);
        end;
      end;
    end;
  finally
    LContext.Free;
  end;
end;

function TRouteGuardManager.CanLeave(const AFromRoute, AToRoute: string; AProps: TProps = nil): Boolean;
var
  LContext: TRouteContext;
  LGuards: TList<IRouteGuard>;
  LGuard: IRouteGuard;
begin
  Result := True;
  LContext := TRouteContext.Create(AFromRoute, AToRoute, AProps);
  try
    // Check global guards
    for LGuard in FGlobalGuards do
    begin
      if not LGuard.CanDeactivate(LContext) then
      begin
        Router4DLogger.LogWarning(Format('Global guard blocked leaving: %s', [AFromRoute]));
        Exit(False);
      end;
    end;

    // Check route-specific guards
    if FGuards.TryGetValue(AFromRoute, LGuards) then
    begin
      for LGuard in LGuards do
      begin
        if not LGuard.CanDeactivate(LContext) then
        begin
          Router4DLogger.LogWarning(Format('Route guard blocked leaving: %s', [AFromRoute]));
          Exit(False);
        end;
      end;
    end;
  finally
    LContext.Free;
  end;
end;

initialization

finalization
  if Assigned(FGuardManager) then
    FGuardManager.Free;

end.
