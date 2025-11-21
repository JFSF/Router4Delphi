unit Router4D.DeepLinks;

{$I Router4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.RegularExpressions,
  Router4D.Props;

type
  /// <summary>
  /// Route parameters extracted from URL
  /// </summary>
  TRouteParams = class
  private
    FParams: TDictionary<string, string>;
    FQueryParams: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Get parameter value
    /// </summary>
    function Get(const AKey: string; const ADefault: string = ''): string;

    /// <summary>
    /// Get parameter as integer
    /// </summary>
    function GetInt(const AKey: string; const ADefault: Integer = 0): Integer;

    /// <summary>
    /// Get query parameter value
    /// </summary>
    function GetQuery(const AKey: string; const ADefault: string = ''): string;

    /// <summary>
    /// Get query parameter as integer
    /// </summary>
    function GetQueryInt(const AKey: string; const ADefault: Integer = 0): Integer;

    /// <summary>
    /// Check if parameter exists
    /// </summary>
    function Has(const AKey: string): Boolean;

    /// <summary>
    /// Check if query parameter exists
    /// </summary>
    function HasQuery(const AKey: string): Boolean;

    /// <summary>
    /// Get all parameters
    /// </summary>
    function GetAll: TDictionary<string, string>;

    /// <summary>
    /// Get all query parameters
    /// </summary>
    function GetAllQuery: TDictionary<string, string>;

    /// <summary>
    /// Convert to TProps
    /// </summary>
    function ToProps: TProps;
  end;

  /// <summary>
  /// Route pattern matching
  /// </summary>
  TRoutePattern = class
  private
    FPattern: string;
    FRegex: TRegEx;
    FParamNames: TList<string>;
    procedure BuildRegex;
  public
    constructor Create(const APattern: string);
    destructor Destroy; override;

    /// <summary>
    /// Check if URL matches this pattern
    /// </summary>
    function Matches(const AURL: string): Boolean;

    /// <summary>
    /// Extract parameters from URL
    /// </summary>
    function ExtractParams(const AURL: string): TRouteParams;

    property Pattern: string read FPattern;
  end;

  /// <summary>
  /// Deep link route definition
  /// </summary>
  TDeepLinkRoute = class
  private
    FPattern: TRoutePattern;
    FRouteName: string;
  public
    constructor Create(const APattern: string; const ARouteName: string);
    destructor Destroy; override;

    property Pattern: TRoutePattern read FPattern;
    property RouteName: string read FRouteName;
  end;

  /// <summary>
  /// Deep link manager
  /// </summary>
  TDeepLinkManager = class
  private
    FRoutes: TObjectList<TDeepLinkRoute>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Register a deep link pattern
    /// Example: RegisterPattern('users/:id', 'UserDetail')
    /// Example: RegisterPattern('posts/:postId/comments/:commentId', 'CommentDetail')
    /// </summary>
    procedure RegisterPattern(const APattern: string; const ARouteName: string);

    /// <summary>
    /// Match URL to route and extract parameters
    /// </summary>
    function MatchURL(const AURL: string; out ARouteName: string; out AParams: TRouteParams): Boolean;

    /// <summary>
    /// Build URL from route name and parameters
    /// </summary>
    function BuildURL(const ARouteName: string; AParams: TRouteParams): string;

    /// <summary>
    /// Parse query string into parameters
    /// </summary>
    class function ParseQueryString(const AQueryString: string): TDictionary<string, string>;
  end;

function DeepLinkManager: TDeepLinkManager;

implementation

uses
  Router4D.Logger;

var
  FDeepLinkManager: TDeepLinkManager;

function DeepLinkManager: TDeepLinkManager;
begin
  if not Assigned(FDeepLinkManager) then
    FDeepLinkManager := TDeepLinkManager.Create;
  Result := FDeepLinkManager;
end;

{ TRouteParams }

constructor TRouteParams.Create;
begin
  inherited;
  FParams := TDictionary<string, string>.Create;
  FQueryParams := TDictionary<string, string>.Create;
end;

destructor TRouteParams.Destroy;
begin
  FParams.Free;
  FQueryParams.Free;
  inherited;
end;

function TRouteParams.Get(const AKey, ADefault: string): string;
begin
  if not FParams.TryGetValue(AKey, Result) then
    Result := ADefault;
end;

function TRouteParams.GetInt(const AKey: string; const ADefault: Integer): Integer;
var
  LValue: string;
begin
  LValue := Get(AKey);
  if not TryStrToInt(LValue, Result) then
    Result := ADefault;
end;

function TRouteParams.GetQuery(const AKey, ADefault: string): string;
begin
  if not FQueryParams.TryGetValue(AKey, Result) then
    Result := ADefault;
end;

function TRouteParams.GetQueryInt(const AKey: string; const ADefault: Integer): Integer;
var
  LValue: string;
begin
  LValue := GetQuery(AKey);
  if not TryStrToInt(LValue, Result) then
    Result := ADefault;
end;

function TRouteParams.Has(const AKey: string): Boolean;
begin
  Result := FParams.ContainsKey(AKey);
end;

function TRouteParams.HasQuery(const AKey: string): Boolean;
begin
  Result := FQueryParams.ContainsKey(AKey);
end;

function TRouteParams.GetAll: TDictionary<string, string>;
begin
  Result := FParams;
end;

function TRouteParams.GetAllQuery: TDictionary<string, string>;
begin
  Result := FQueryParams;
end;

function TRouteParams.ToProps: TProps;
var
  LPair: TPair<string, string>;
begin
  Result := TProps.Create;

  // Add path parameters as string properties
  for LPair in FParams do
    Result.PropString(LPair.Value);

  // Add query parameters
  for LPair in FQueryParams do
    Result.PropString(LPair.Value);
end;

{ TRoutePattern }

constructor TRoutePattern.Create(const APattern: string);
begin
  inherited Create;
  FPattern := APattern;
  FParamNames := TList<string>.Create;
  BuildRegex;
end;

destructor TRoutePattern.Destroy;
begin
  FParamNames.Free;
  inherited;
end;

procedure TRoutePattern.BuildRegex;
var
  LRegexPattern: string;
  LMatches: TMatchCollection;
  LMatch: TMatch;
begin
  // Convert pattern like "users/:id/posts/:postId" to regex
  LRegexPattern := FPattern;

  // Find all :param patterns
  LMatches := TRegEx.Matches(FPattern, ':([a-zA-Z_][a-zA-Z0-9_]*)');
  for LMatch in LMatches do
  begin
    FParamNames.Add(LMatch.Groups[1].Value);
  end;

  // Replace :param with capture groups
  LRegexPattern := TRegEx.Replace(LRegexPattern, ':([a-zA-Z_][a-zA-Z0-9_]*)', '([^/]+)');

  // Anchor to start and end (but allow query string)
  LRegexPattern := '^' + LRegexPattern + '(\?.*)?$';

  FRegex := TRegEx.Create(LRegexPattern, [roIgnoreCase]);
end;

function TRoutePattern.Matches(const AURL: string): Boolean;
var
  LCleanURL: string;
  LQueryPos: Integer;
begin
  // Remove query string for matching
  LCleanURL := AURL;
  LQueryPos := Pos('?', LCleanURL);
  if LQueryPos > 0 then
    LCleanURL := Copy(LCleanURL, 1, LQueryPos - 1);

  Result := FRegex.IsMatch(LCleanURL);
end;

function TRoutePattern.ExtractParams(const AURL: string): TRouteParams;
var
  LMatch: TMatch;
  I: Integer;
  LCleanURL: string;
  LQueryString: string;
  LQueryPos: Integer;
  LQueryParams: TDictionary<string, string>;
  LPair: TPair<string, string>;
begin
  Result := TRouteParams.Create;

  // Split URL and query string
  LQueryPos := Pos('?', AURL);
  if LQueryPos > 0 then
  begin
    LCleanURL := Copy(AURL, 1, LQueryPos - 1);
    LQueryString := Copy(AURL, LQueryPos + 1, Length(AURL));
  end
  else
  begin
    LCleanURL := AURL;
    LQueryString := '';
  end;

  // Extract path parameters
  LMatch := FRegex.Match(LCleanURL);
  if LMatch.Success then
  begin
    for I := 0 to FParamNames.Count - 1 do
    begin
      if I + 1 < LMatch.Groups.Count then
        Result.FParams.Add(FParamNames[I], LMatch.Groups[I + 1].Value);
    end;
  end;

  // Parse query string
  if not LQueryString.IsEmpty then
  begin
    LQueryParams := TDeepLinkManager.ParseQueryString(LQueryString);
    try
      for LPair in LQueryParams do
        Result.FQueryParams.Add(LPair.Key, LPair.Value);
    finally
      LQueryParams.Free;
    end;
  end;
end;

{ TDeepLinkRoute }

constructor TDeepLinkRoute.Create(const APattern, ARouteName: string);
begin
  inherited Create;
  FPattern := TRoutePattern.Create(APattern);
  FRouteName := ARouteName;
end;

destructor TDeepLinkRoute.Destroy;
begin
  FPattern.Free;
  inherited;
end;

{ TDeepLinkManager }

constructor TDeepLinkManager.Create;
begin
  inherited;
  FRoutes := TObjectList<TDeepLinkRoute>.Create(True);
end;

destructor TDeepLinkManager.Destroy;
begin
  FRoutes.Free;
  inherited;
end;

procedure TDeepLinkManager.RegisterPattern(const APattern, ARouteName: string);
var
  LRoute: TDeepLinkRoute;
begin
  LRoute := TDeepLinkRoute.Create(APattern, ARouteName);
  FRoutes.Add(LRoute);
  Router4DLogger.LogDebug(Format('Registered deep link pattern: %s -> %s', [APattern, ARouteName]));
end;

function TDeepLinkManager.MatchURL(const AURL: string; out ARouteName: string; out AParams: TRouteParams): Boolean;
var
  LRoute: TDeepLinkRoute;
begin
  Result := False;
  ARouteName := '';
  AParams := nil;

  for LRoute in FRoutes do
  begin
    if LRoute.Pattern.Matches(AURL) then
    begin
      ARouteName := LRoute.RouteName;
      AParams := LRoute.Pattern.ExtractParams(AURL);
      Router4DLogger.LogDebug(Format('Matched URL %s to route: %s', [AURL, ARouteName]));
      Exit(True);
    end;
  end;

  Router4DLogger.LogWarning(Format('No route found for URL: %s', [AURL]));
end;

function TDeepLinkManager.BuildURL(const ARouteName: string; AParams: TRouteParams): string;
var
  LRoute: TDeepLinkRoute;
  LPattern: string;
  LParam: TPair<string, string>;
begin
  Result := '';

  for LRoute in FRoutes do
  begin
    if SameText(LRoute.RouteName, ARouteName) then
    begin
      LPattern := LRoute.Pattern.Pattern;

      // Replace parameters in pattern
      for LParam in AParams.GetAll do
        LPattern := StringReplace(LPattern, ':' + LParam.Key, LParam.Value, [rfReplaceAll, rfIgnoreCase]);

      Result := LPattern;
      Break;
    end;
  end;
end;

class function TDeepLinkManager.ParseQueryString(const AQueryString: string): TDictionary<string, string>;
var
  LPairs: TArray<string>;
  LPair: string;
  LKeyValue: TArray<string>;
begin
  Result := TDictionary<string, string>.Create;

  LPairs := AQueryString.Split(['&']);
  for LPair in LPairs do
  begin
    if LPair.IsEmpty then
      Continue;

    LKeyValue := LPair.Split(['=']);
    if Length(LKeyValue) = 2 then
      Result.AddOrSetValue(LKeyValue[0], LKeyValue[1])
    else if Length(LKeyValue) = 1 then
      Result.AddOrSetValue(LKeyValue[0], '');
  end;
end;

initialization

finalization
  if Assigned(FDeepLinkManager) then
    FDeepLinkManager.Free;

end.
