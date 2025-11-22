unit Router4D.LayoutExtensions;

{$I Router4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  {$IFDEF HAS_FMX}
  FMX.Types,
  {$ELSE}
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Controls,
  {$ENDIF}
  Router4D.Interfaces,
  Router4D.Layout;

type
  /// <summary>
  /// Extended component interface with layout support
  /// </summary>
  iRouter4DLayoutComponent = interface(iRouter4DComponent)
    ['{8E7F9A1B-2C3D-4E5F-A6B7-C8D9E0F1A2B3}']
    /// <summary>
    /// Get layout configuration for this component
    /// </summary>
    function GetLayoutConfig: TLayoutConfig;
  end;

  /// <summary>
  /// Layout registry - stores layout configurations for routes
  /// </summary>
  TLayoutRegistry = class
  private
    FLayouts: TDictionary<string, TLayoutConfig>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Register a layout configuration for a route
    /// </summary>
    procedure RegisterLayout(const ARoute: string; AConfig: TLayoutConfig);

    /// <summary>
    /// Get layout configuration for a route
    /// </summary>
    function GetLayout(const ARoute: string): TLayoutConfig;

    /// <summary>
    /// Check if route has layout registered
    /// </summary>
    function HasLayout(const ARoute: string): Boolean;

    /// <summary>
    /// Remove layout for a route
    /// </summary>
    procedure UnregisterLayout(const ARoute: string);

    /// <summary>
    /// Clear all layouts
    /// </summary>
    procedure Clear;
  end;

  /// <summary>
  /// Helper class for layout operations
  /// </summary>
  TRouter4DLayoutHelper = class
  public
    /// <summary>
    /// Apply layout to component after rendering
    /// </summary>
    {$IFDEF HAS_FMX}
    class procedure ApplyLayoutAfterRender(AComponent: TFMXObject; const ARoute: string);
    {$ELSE}
    class procedure ApplyLayoutAfterRender(AComponent: TControl; const ARoute: string);
    {$ENDIF}

    /// <summary>
    /// Create layout zones in a container
    /// </summary>
    {$IFDEF HAS_FMX}
    class function CreateLayoutZones(AParent: TFMXObject): TDictionary<TLayoutZone, TFMXObject>;
    {$ELSE}
    class function CreateLayoutZones(AParent: TWinControl): TDictionary<TLayoutZone, TPanel>;
    {$ENDIF}
  end;

/// <summary>
/// Get global layout registry
/// </summary>
function LayoutRegistry: TLayoutRegistry;

implementation

uses
  Router4D.Logger;

var
  FLayoutRegistry: TLayoutRegistry;

function LayoutRegistry: TLayoutRegistry;
begin
  if not Assigned(FLayoutRegistry) then
    FLayoutRegistry := TLayoutRegistry.Create;
  Result := FLayoutRegistry;
end;

{ TLayoutRegistry }

constructor TLayoutRegistry.Create;
begin
  inherited;
  FLayouts := TDictionary<string, TLayoutConfig>.Create([doOwnsValues]);
end;

destructor TLayoutRegistry.Destroy;
begin
  FLayouts.Free;
  inherited;
end;

procedure TLayoutRegistry.RegisterLayout(const ARoute: string; AConfig: TLayoutConfig);
begin
  if FLayouts.ContainsKey(ARoute) then
    FLayouts.Remove(ARoute);

  FLayouts.Add(ARoute, AConfig);
  Router4DLogger.LogDebug(Format('Registered layout for route: %s (Zone=%d)',
    [ARoute, Ord(AConfig.LayoutZone)]));
end;

function TLayoutRegistry.GetLayout(const ARoute: string): TLayoutConfig;
begin
  if not FLayouts.TryGetValue(ARoute, Result) then
    Result := nil;
end;

function TLayoutRegistry.HasLayout(const ARoute: string): Boolean;
begin
  Result := FLayouts.ContainsKey(ARoute);
end;

procedure TLayoutRegistry.UnregisterLayout(const ARoute: string);
begin
  if FLayouts.ContainsKey(ARoute) then
  begin
    FLayouts.Remove(ARoute);
    Router4DLogger.LogDebug(Format('Unregistered layout for route: %s', [ARoute]));
  end;
end;

procedure TLayoutRegistry.Clear;
begin
  FLayouts.Clear;
  Router4DLogger.LogDebug('Cleared all layout registrations');
end;

{ TRouter4DLayoutHelper }

{$IFDEF HAS_FMX}
class procedure TRouter4DLayoutHelper.ApplyLayoutAfterRender(AComponent: TFMXObject; const ARoute: string);
var
  LConfig: TLayoutConfig;
  LLayoutComponent: iRouter4DLayoutComponent;
begin
  // First check if component implements iRouter4DLayoutComponent
  if Supports(AComponent.Owner, iRouter4DLayoutComponent, LLayoutComponent) then
  begin
    LConfig := LLayoutComponent.GetLayoutConfig;
    if Assigned(LConfig) then
    begin
      TLayoutManager.Apply(AComponent, LConfig);
      Router4DLogger.LogDebug(Format('Applied component layout to: %s', [ARoute]));
      Exit;
    end;
  end;

  // Otherwise check registry
  if LayoutRegistry.HasLayout(ARoute) then
  begin
    LConfig := LayoutRegistry.GetLayout(ARoute);
    if Assigned(LConfig) then
    begin
      TLayoutManager.Apply(AComponent, LConfig);
      Router4DLogger.LogDebug(Format('Applied registry layout to: %s', [ARoute]));
    end;
  end;
end;

class function TRouter4DLayoutHelper.CreateLayoutZones(AParent: TFMXObject): TDictionary<TLayoutZone, TFMXObject>;
var
  LZone: TLayoutZone;
  LContainer: TLayout;
begin
  Result := TDictionary<TLayoutZone, TFMXObject>.Create;

  for LZone := Low(TLayoutZone) to High(TLayoutZone) do
  begin
    if LZone in [lzCenter, lzCustom] then
      Continue; // Skip center and custom

    case LZone of
      lzTop:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.TopBar(60));
      lzBottom:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.BottomBar(40));
      lzLeft:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.LeftSidebar(200));
      lzRight:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.RightSidebar(200));
      lzFill:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.FullScreen);
    else
      Continue;
    end;

    Result.Add(LZone, LContainer);
  end;

  Router4DLogger.LogDebug('Created layout zones');
end;

{$ELSE}

class procedure TRouter4DLayoutHelper.ApplyLayoutAfterRender(AComponent: TControl; const ARoute: string);
var
  LConfig: TLayoutConfig;
  LLayoutComponent: iRouter4DLayoutComponent;
begin
  // First check if component implements iRouter4DLayoutComponent
  if Assigned(AComponent) and (AComponent is TForm) then
  begin
    if Supports(AComponent, iRouter4DLayoutComponent, LLayoutComponent) then
    begin
      LConfig := LLayoutComponent.GetLayoutConfig;
      if Assigned(LConfig) then
      begin
        TLayoutManager.Apply(AComponent, LConfig);
        Router4DLogger.LogDebug(Format('Applied component layout to: %s', [ARoute]));
        Exit;
      end;
    end;
  end;

  // Otherwise check registry
  if LayoutRegistry.HasLayout(ARoute) then
  begin
    LConfig := LayoutRegistry.GetLayout(ARoute);
    if Assigned(LConfig) then
    begin
      TLayoutManager.Apply(AComponent, LConfig);
      Router4DLogger.LogDebug(Format('Applied registry layout to: %s', [ARoute]));
    end;
  end;
end;

class function TRouter4DLayoutHelper.CreateLayoutZones(AParent: TWinControl): TDictionary<TLayoutZone, TPanel>;
var
  LZone: TLayoutZone;
  LContainer: TPanel;
begin
  Result := TDictionary<TLayoutZone, TPanel>.Create;

  for LZone := Low(TLayoutZone) to High(TLayoutZone) do
  begin
    if LZone in [lzCenter, lzCustom, lzTopLeft, lzTopRight, lzBottomLeft, lzBottomRight] then
      Continue; // Skip center, custom and corners for VCL

    case LZone of
      lzTop:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.TopBar(60));
      lzBottom:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.BottomBar(40));
      lzLeft:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.LeftSidebar(200));
      lzRight:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.RightSidebar(200));
      lzFill:
        LContainer := TLayoutManager.CreateContainer(AParent,
          TLayoutConfig.FullScreen);
    else
      Continue;
    end;

    Result.Add(LZone, LContainer);
  end;

  Router4DLogger.LogDebug('Created VCL layout zones');
end;

{$ENDIF}

initialization

finalization
  if Assigned(FLayoutRegistry) then
    FLayoutRegistry.Free;

end.
