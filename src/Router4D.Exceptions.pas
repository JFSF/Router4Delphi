unit Router4D.Exceptions;

{$I Router4D.inc}

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Base exception class for all Router4D exceptions
  /// </summary>
  ERouter4DException = class(Exception);

  /// <summary>
  /// Exception raised when a route is not found in the registry
  /// </summary>
  ERouteNotFoundException = class(ERouter4DException)
  public
    constructor Create(const ARouteName: string);
  end;

  /// <summary>
  /// Exception raised when container is not configured or invalid
  /// </summary>
  EInvalidContainerException = class(ERouter4DException)
  public
    constructor Create(const AContainerName: string);
  end;

  /// <summary>
  /// Exception raised when navigation fails
  /// </summary>
  ENavigationException = class(ERouter4DException);

  /// <summary>
  /// Exception raised when route configuration is invalid
  /// </summary>
  EInvalidRouteConfigException = class(ERouter4DException);

  /// <summary>
  /// Exception raised when component doesn't implement required interface
  /// </summary>
  EComponentInterfaceException = class(ERouter4DException)
  public
    constructor Create(const AClassName: string; const AInterfaceName: string);
  end;

implementation

{ ERouteNotFoundException }

constructor ERouteNotFoundException.Create(const ARouteName: string);
begin
  inherited CreateFmt('Route "%s" not found. Make sure it is registered using TRouter4D.Switch.Router()', [ARouteName]);
end;

{ EInvalidContainerException }

constructor EInvalidContainerException.Create(const AContainerName: string);
begin
  if AContainerName.IsEmpty then
    inherited Create('Container not configured. Call TRouter4D.Render<T>.SetElement() first.')
  else
    inherited CreateFmt('Container "%s" not found or not configured properly.', [AContainerName]);
end;

{ EComponentInterfaceException }

constructor EComponentInterfaceException.Create(const AClassName: string; const AInterfaceName: string);
begin
  inherited CreateFmt('Component "%s" does not implement required interface "%s"', [AClassName, AInterfaceName]);
end;

end.
