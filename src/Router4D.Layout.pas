unit Router4D.Layout;

{$I Router4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  {$IFDEF HAS_FMX}
  FMX.Types,
  FMX.Layouts,
  {$ELSE}
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Controls,
  {$ENDIF}
  System.Generics.Collections;

type
  /// <summary>
  /// Layout positioning zones
  /// </summary>
  TLayoutZone = (
    lzCenter,      // Center of container
    lzTop,         // Top of container
    lzBottom,      // Bottom of container
    lzLeft,        // Left of container
    lzRight,       // Right of container
    lzTopLeft,     // Top-left corner
    lzTopRight,    // Top-right corner
    lzBottomLeft,  // Bottom-left corner
    lzBottomRight, // Bottom-right corner
    lzFill,        // Fill entire container
    lzCustom       // Custom position
  );

  /// <summary>
  /// Dimension type - absolute or percentage
  /// </summary>
  TDimensionType = (dtAbsolute, dtPercentage);

  /// <summary>
  /// Dimension specification
  /// </summary>
  TDimension = record
  private
    FValue: Single;
    FType: TDimensionType;
  public
    class function Absolute(const AValue: Single): TDimension; static;
    class function Percentage(const AValue: Single): TDimension; static;
    class function Auto: TDimension; static;

    function Calculate(const AContainerSize: Single): Single;
    function IsAuto: Boolean;

    property Value: Single read FValue;
    property DimensionType: TDimensionType read FType;
  end;

  /// <summary>
  /// Margin/Padding specification
  /// </summary>
  TSpacing = record
  private
    FLeft: Single;
    FTop: Single;
    FRight: Single;
    FBottom: Single;
  public
    class function Create(const AAll: Single): TSpacing; overload; static;
    class function Create(const AHorizontal, AVertical: Single): TSpacing; overload; static;
    class function Create(const ALeft, ATop, ARight, ABottom: Single): TSpacing; overload; static;
    class function Zero: TSpacing; static;

    property Left: Single read FLeft write FLeft;
    property Top: Single read FTop write FTop;
    property Right: Single read FRight write FRight;
    property Bottom: Single read FBottom write FBottom;
  end;

  /// <summary>
  /// Layout configuration for a component
  /// </summary>
  TLayoutConfig = class
  private
    FZone: TLayoutZone;
    FWidth: TDimension;
    FHeight: TDimension;
    FMargin: TSpacing;
    FPadding: TSpacing;
    FCustomX: Single;
    FCustomY: Single;
    FMinWidth: Single;
    FMinHeight: Single;
    FMaxWidth: Single;
    FMaxHeight: Single;
  public
    constructor Create;

    /// <summary>
    /// Set layout zone
    /// </summary>
    function Zone(const AZone: TLayoutZone): TLayoutConfig;

    /// <summary>
    /// Set width (absolute or percentage)
    /// </summary>
    function Width(const AWidth: TDimension): TLayoutConfig; overload;
    function Width(const AWidth: Single): TLayoutConfig; overload; // Absolute

    /// <summary>
    /// Set height (absolute or percentage)
    /// </summary>
    function Height(const AHeight: TDimension): TLayoutConfig; overload;
    function Height(const AHeight: Single): TLayoutConfig; overload; // Absolute

    /// <summary>
    /// Set margin
    /// </summary>
    function Margin(const AMargin: TSpacing): TLayoutConfig; overload;
    function Margin(const AAll: Single): TLayoutConfig; overload;

    /// <summary>
    /// Set padding
    /// </summary>
    function Padding(const APadding: TSpacing): TLayoutConfig; overload;
    function Padding(const AAll: Single): TLayoutConfig; overload;

    /// <summary>
    /// Set custom position (for lzCustom zone)
    /// </summary>
    function Position(const AX, AY: Single): TLayoutConfig;

    /// <summary>
    /// Set minimum dimensions
    /// </summary>
    function MinSize(const AWidth, AHeight: Single): TLayoutConfig;

    /// <summary>
    /// Set maximum dimensions
    /// </summary>
    function MaxSize(const AWidth, AHeight: Single): TLayoutConfig;

    /// <summary>
    /// Quick configurations
    /// </summary>
    class function CenterFill: TLayoutConfig; static;
    class function TopBar(const AHeight: Single): TLayoutConfig; static;
    class function BottomBar(const AHeight: Single): TLayoutConfig; static;
    class function LeftSidebar(const AWidth: Single): TLayoutConfig; static;
    class function RightSidebar(const AWidth: Single): TLayoutConfig; static;
    class function FullScreen: TLayoutConfig; static;

    property LayoutZone: TLayoutZone read FZone;
    property WidthDim: TDimension read FWidth;
    property HeightDim: TDimension read FHeight;
    property MarginSpace: TSpacing read FMargin;
    property PaddingSpace: TSpacing read FPadding;
  end;

  /// <summary>
  /// Layout manager - applies layout configurations to components
  /// </summary>
  TLayoutManager = class
  private
    {$IFDEF HAS_FMX}
    class procedure ApplyToFMX(AComponent: TFMXObject; AConfig: TLayoutConfig);
    class function GetAlignFromZone(AZone: TLayoutZone): TAlignLayout;
    {$ELSE}
    class procedure ApplyToVCL(AComponent: TControl; AConfig: TLayoutConfig);
    class function GetAlignFromZone(AZone: TLayoutZone): TAlign;
    {$ENDIF}
  public
    /// <summary>
    /// Apply layout configuration to component
    /// </summary>
    {$IFDEF HAS_FMX}
    class procedure Apply(AComponent: TFMXObject; AConfig: TLayoutConfig);
    {$ELSE}
    class procedure Apply(AComponent: TControl; AConfig: TLayoutConfig);
    {$ENDIF}

    /// <summary>
    /// Create a layout container with specific configuration
    /// </summary>
    {$IFDEF HAS_FMX}
    class function CreateContainer(AParent: TFMXObject; AConfig: TLayoutConfig): TLayout;
    {$ELSE}
    class function CreateContainer(AParent: TWinControl; AConfig: TLayoutConfig): TPanel;
    {$ENDIF}
  end;

implementation

uses
  Router4D.Logger;

{ TDimension }

class function TDimension.Absolute(const AValue: Single): TDimension;
begin
  Result.FValue := AValue;
  Result.FType := dtAbsolute;
end;

class function TDimension.Percentage(const AValue: Single): TDimension;
begin
  Result.FValue := AValue;
  Result.FType := dtPercentage;
end;

class function TDimension.Auto: TDimension;
begin
  Result.FValue := -1;
  Result.FType := dtAbsolute;
end;

function TDimension.Calculate(const AContainerSize: Single): Single;
begin
  if IsAuto then
    Exit(AContainerSize);

  case FType of
    dtAbsolute: Result := FValue;
    dtPercentage: Result := (AContainerSize * FValue) / 100;
  else
    Result := FValue;
  end;
end;

function TDimension.IsAuto: Boolean;
begin
  Result := (FType = dtAbsolute) and (FValue < 0);
end;

{ TSpacing }

class function TSpacing.Create(const AAll: Single): TSpacing;
begin
  Result.FLeft := AAll;
  Result.FTop := AAll;
  Result.FRight := AAll;
  Result.FBottom := AAll;
end;

class function TSpacing.Create(const AHorizontal, AVertical: Single): TSpacing;
begin
  Result.FLeft := AHorizontal;
  Result.FTop := AVertical;
  Result.FRight := AHorizontal;
  Result.FBottom := AVertical;
end;

class function TSpacing.Create(const ALeft, ATop, ARight, ABottom: Single): TSpacing;
begin
  Result.FLeft := ALeft;
  Result.FTop := ATop;
  Result.FRight := ARight;
  Result.FBottom := ABottom;
end;

class function TSpacing.Zero: TSpacing;
begin
  Result := TSpacing.Create(0);
end;

{ TLayoutConfig }

constructor TLayoutConfig.Create;
begin
  inherited;
  FZone := lzCenter;
  FWidth := TDimension.Auto;
  FHeight := TDimension.Auto;
  FMargin := TSpacing.Zero;
  FPadding := TSpacing.Zero;
  FCustomX := 0;
  FCustomY := 0;
  FMinWidth := 0;
  FMinHeight := 0;
  FMaxWidth := 0;
  FMaxHeight := 0;
end;

function TLayoutConfig.Zone(const AZone: TLayoutZone): TLayoutConfig;
begin
  Result := Self;
  FZone := AZone;
end;

function TLayoutConfig.Width(const AWidth: TDimension): TLayoutConfig;
begin
  Result := Self;
  FWidth := AWidth;
end;

function TLayoutConfig.Width(const AWidth: Single): TLayoutConfig;
begin
  Result := Self;
  FWidth := TDimension.Absolute(AWidth);
end;

function TLayoutConfig.Height(const AHeight: TDimension): TLayoutConfig;
begin
  Result := Self;
  FHeight := AHeight;
end;

function TLayoutConfig.Height(const AHeight: Single): TLayoutConfig;
begin
  Result := Self;
  FHeight := TDimension.Absolute(AHeight);
end;

function TLayoutConfig.Margin(const AMargin: TSpacing): TLayoutConfig;
begin
  Result := Self;
  FMargin := AMargin;
end;

function TLayoutConfig.Margin(const AAll: Single): TLayoutConfig;
begin
  Result := Self;
  FMargin := TSpacing.Create(AAll);
end;

function TLayoutConfig.Padding(const APadding: TSpacing): TLayoutConfig;
begin
  Result := Self;
  FPadding := APadding;
end;

function TLayoutConfig.Padding(const AAll: Single): TLayoutConfig;
begin
  Result := Self;
  FPadding := TSpacing.Create(AAll);
end;

function TLayoutConfig.Position(const AX, AY: Single): TLayoutConfig;
begin
  Result := Self;
  FCustomX := AX;
  FCustomY := AY;
  FZone := lzCustom;
end;

function TLayoutConfig.MinSize(const AWidth, AHeight: Single): TLayoutConfig;
begin
  Result := Self;
  FMinWidth := AWidth;
  FMinHeight := AHeight;
end;

function TLayoutConfig.MaxSize(const AWidth, AHeight: Single): TLayoutConfig;
begin
  Result := Self;
  FMaxWidth := AWidth;
  FMaxHeight := AHeight;
end;

class function TLayoutConfig.CenterFill: TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzCenter)
    .Width(TDimension.Percentage(80))
    .Height(TDimension.Percentage(80))
    .Margin(10);
end;

class function TLayoutConfig.TopBar(const AHeight: Single): TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzTop)
    .Height(AHeight);
end;

class function TLayoutConfig.BottomBar(const AHeight: Single): TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzBottom)
    .Height(AHeight);
end;

class function TLayoutConfig.LeftSidebar(const AWidth: Single): TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzLeft)
    .Width(AWidth);
end;

class function TLayoutConfig.RightSidebar(const AWidth: Single): TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzRight)
    .Width(AWidth);
end;

class function TLayoutConfig.FullScreen: TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzFill);
end;

{ TLayoutManager }

{$IFDEF HAS_FMX}
class function TLayoutManager.GetAlignFromZone(AZone: TLayoutZone): TAlignLayout;
begin
  case AZone of
    lzCenter: Result := TAlignLayout.Center;
    lzTop: Result := TAlignLayout.Top;
    lzBottom: Result := TAlignLayout.Bottom;
    lzLeft: Result := TAlignLayout.Left;
    lzRight: Result := TAlignLayout.Right;
    lzFill: Result := TAlignLayout.Client;
    else Result := TAlignLayout.None;
  end;
end;

class procedure TLayoutManager.ApplyToFMX(AComponent: TFMXObject; AConfig: TLayoutConfig);
var
  LControl: TControl;
  LParentWidth, LParentHeight: Single;
begin
  if not (AComponent is TControl) then
    Exit;

  LControl := TControl(AComponent);

  // Get parent dimensions
  if Assigned(LControl.ParentControl) then
  begin
    LParentWidth := LControl.ParentControl.Width;
    LParentHeight := LControl.ParentControl.Height;
  end
  else
  begin
    LParentWidth := LControl.Width;
    LParentHeight := LControl.Height;
  end;

  // Apply alignment/zone
  if AConfig.LayoutZone <> lzCustom then
  begin
    LControl.Align := GetAlignFromZone(AConfig.LayoutZone);
  end
  else
  begin
    LControl.Align := TAlignLayout.None;
    LControl.Position.X := AConfig.FCustomX;
    LControl.Position.Y := AConfig.FCustomY;
  end;

  // Apply dimensions
  if not AConfig.WidthDim.IsAuto then
  begin
    LControl.Width := AConfig.WidthDim.Calculate(LParentWidth);
  end;

  if not AConfig.HeightDim.IsAuto then
  begin
    LControl.Height := AConfig.HeightDim.Calculate(LParentHeight);
  end;

  // Apply margins
  LControl.Margins.Left := AConfig.MarginSpace.Left;
  LControl.Margins.Top := AConfig.MarginSpace.Top;
  LControl.Margins.Right := AConfig.MarginSpace.Right;
  LControl.Margins.Bottom := AConfig.MarginSpace.Bottom;

  // Apply padding
  LControl.Padding.Left := AConfig.PaddingSpace.Left;
  LControl.Padding.Top := AConfig.PaddingSpace.Top;
  LControl.Padding.Right := AConfig.PaddingSpace.Right;
  LControl.Padding.Bottom := AConfig.PaddingSpace.Bottom;

  // Apply constraints
  if AConfig.FMinWidth > 0 then
    LControl.Width := Max(LControl.Width, AConfig.FMinWidth);
  if AConfig.FMinHeight > 0 then
    LControl.Height := Max(LControl.Height, AConfig.FMinHeight);
  if AConfig.FMaxWidth > 0 then
    LControl.Width := Min(LControl.Width, AConfig.FMaxWidth);
  if AConfig.FMaxHeight > 0 then
    LControl.Height := Min(LControl.Height, AConfig.FMaxHeight);

  Router4DLogger.LogDebug(Format('Applied FMX layout: Zone=%d, W=%.0f, H=%.0f',
    [Ord(AConfig.LayoutZone), LControl.Width, LControl.Height]));
end;

class procedure TLayoutManager.Apply(AComponent: TFMXObject; AConfig: TLayoutConfig);
begin
  ApplyToFMX(AComponent, AConfig);
end;

class function TLayoutManager.CreateContainer(AParent: TFMXObject; AConfig: TLayoutConfig): TLayout;
begin
  Result := TLayout.Create(nil);
  Result.Parent := AParent;
  Apply(Result, AConfig);
end;

{$ELSE}

class function TLayoutManager.GetAlignFromZone(AZone: TLayoutZone): TAlign;
begin
  case AZone of
    lzTop: Result := alTop;
    lzBottom: Result := alBottom;
    lzLeft: Result := alLeft;
    lzRight: Result := alRight;
    lzFill: Result := alClient;
    else Result := alNone;
  end;
end;

class procedure TLayoutManager.ApplyToVCL(AComponent: TControl; AConfig: TLayoutConfig);
var
  LParentWidth, LParentHeight: Integer;
begin
  // Get parent dimensions
  if Assigned(AComponent.Parent) then
  begin
    LParentWidth := AComponent.Parent.ClientWidth;
    LParentHeight := AComponent.Parent.ClientHeight;
  end
  else
  begin
    LParentWidth := AComponent.Width;
    LParentHeight := AComponent.Height;
  end;

  // Apply alignment/zone
  if AConfig.LayoutZone in [lzTop, lzBottom, lzLeft, lzRight, lzFill] then
  begin
    AComponent.Align := GetAlignFromZone(AConfig.LayoutZone);
  end
  else if AConfig.LayoutZone = lzCustom then
  begin
    AComponent.Align := alNone;
    AComponent.Left := Round(AConfig.FCustomX);
    AComponent.Top := Round(AConfig.FCustomY);
  end
  else if AConfig.LayoutZone = lzCenter then
  begin
    AComponent.Align := alNone;
    if not AConfig.WidthDim.IsAuto then
      AComponent.Width := Round(AConfig.WidthDim.Calculate(LParentWidth));
    if not AConfig.HeightDim.IsAuto then
      AComponent.Height := Round(AConfig.HeightDim.Calculate(LParentHeight));

    AComponent.Left := (LParentWidth - AComponent.Width) div 2;
    AComponent.Top := (LParentHeight - AComponent.Height) div 2;
  end
  else // Corners
  begin
    AComponent.Align := alNone;
    if not AConfig.WidthDim.IsAuto then
      AComponent.Width := Round(AConfig.WidthDim.Calculate(LParentWidth));
    if not AConfig.HeightDim.IsAuto then
      AComponent.Height := Round(AConfig.HeightDim.Calculate(LParentHeight));

    case AConfig.LayoutZone of
      lzTopLeft:
        begin
          AComponent.Left := Round(AConfig.MarginSpace.Left);
          AComponent.Top := Round(AConfig.MarginSpace.Top);
        end;
      lzTopRight:
        begin
          AComponent.Left := LParentWidth - AComponent.Width - Round(AConfig.MarginSpace.Right);
          AComponent.Top := Round(AConfig.MarginSpace.Top);
        end;
      lzBottomLeft:
        begin
          AComponent.Left := Round(AConfig.MarginSpace.Left);
          AComponent.Top := LParentHeight - AComponent.Height - Round(AConfig.MarginSpace.Bottom);
        end;
      lzBottomRight:
        begin
          AComponent.Left := LParentWidth - AComponent.Width - Round(AConfig.MarginSpace.Right);
          AComponent.Top := LParentHeight - AComponent.Height - Round(AConfig.MarginSpace.Bottom);
        end;
    end;
  end;

  // Apply dimensions if not centered
  if AConfig.LayoutZone <> lzCenter then
  begin
    if not AConfig.WidthDim.IsAuto and (AComponent.Align in [alNone, alTop, alBottom]) then
      AComponent.Width := Round(AConfig.WidthDim.Calculate(LParentWidth));

    if not AConfig.HeightDim.IsAuto and (AComponent.Align in [alNone, alLeft, alRight]) then
      AComponent.Height := Round(AConfig.HeightDim.Calculate(LParentHeight));
  end;

  // Apply constraints
  if AConfig.FMinWidth > 0 then
    AComponent.Width := Max(AComponent.Width, Round(AConfig.FMinWidth));
  if AConfig.FMinHeight > 0 then
    AComponent.Height := Max(AComponent.Height, Round(AConfig.FMinHeight));
  if AConfig.FMaxWidth > 0 then
    AComponent.Width := Min(AComponent.Width, Round(AConfig.FMaxWidth));
  if AConfig.FMaxHeight > 0 then
    AComponent.Height := Min(AComponent.Height, Round(AConfig.FMaxHeight));

  Router4DLogger.LogDebug(Format('Applied VCL layout: Zone=%d, W=%d, H=%d',
    [Ord(AConfig.LayoutZone), AComponent.Width, AComponent.Height]));
end;

class procedure TLayoutManager.Apply(AComponent: TControl; AConfig: TLayoutConfig);
begin
  ApplyToVCL(AComponent);
end;

class function TLayoutManager.CreateContainer(AParent: TWinControl; AConfig: TLayoutConfig): TPanel;
begin
  Result := TPanel.Create(nil);
  Result.Parent := AParent;
  Result.BevelOuter := bvNone;
  Apply(Result, AConfig);
end;

{$ENDIF}

end.
