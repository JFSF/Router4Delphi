# Router4D Exception Handling

## Overview

Router4D Phase 2 introduces custom exception classes that provide clear, actionable error messages and make it easier to handle specific error scenarios in your application.

## Exception Hierarchy

```
Exception (System)
└── ERouter4DException (Base)
    ├── ERouteNotFoundException
    ├── EInvalidContainerException
    ├── ENavigationException
    ├── EInvalidRouteConfigException
    └── EComponentInterfaceException
```

## Exception Classes

### ERouter4DException

**Base class for all Router4D exceptions.**

Use this for generic catch-all handling:

```delphi
try
  TRouter4D.Link.&To('SomeRoute');
except
  on E: ERouter4DException do
    ShowMessage('Router error: ' + E.Message);
end;
```

---

### ERouteNotFoundException

**Raised when a route is not registered in the Switch.**

**Common Causes:**
- Forgot to register the route with `TRouter4D.Switch.Router()`
- Typo in the route name
- Route not registered before navigation

**Example:**
```delphi
// Error: Route 'Users' not registered
TRouter4D.Link.&To('Users');  // ❌ Raises ERouteNotFoundException
```

**Solution:**
```delphi
// Register the route first
TRouter4D.Switch.Router('Users', TUsersForm);
TRouter4D.Link.&To('Users');  // ✅ Works
```

**Handling:**
```delphi
try
  TRouter4D.Link.&To(UserInputRoute);
except
  on E: ERouteNotFoundException do
  begin
    ShowMessage('Page not found: ' + E.Message);
    TRouter4D.Link.&To('Home');  // Fallback
  end;
end;
```

---

### EInvalidContainerException

**Raised when a container is not configured or is nil.**

**Common Causes:**
- `MainRouter` not configured before navigation
- `IndexRouter` accessed before setup
- Named container not found
- `SetElement()` not called

**Example:**
```delphi
// Error: MainRouter not set up
TRouter4D.Link.&To('Home');  // ❌ Raises EInvalidContainerException
```

**Solution:**
```delphi
// Configure container first
TRouter4D.Render<THomeForm>.SetElement(MainPanel);
TRouter4D.Link.&To('Home');  // ✅ Works
```

**Handling:**
```delphi
try
  TRouter4D.Link.&To('Dashboard', 'CustomContainer');
except
  on E: EInvalidContainerException do
  begin
    LogError('Container error: ' + E.Message);
    // Use default container as fallback
    TRouter4D.Link.&To('Dashboard');
  end;
end;
```

---

### ENavigationException

**Generic navigation failure exception.**

**Use for custom navigation validation:**

```delphi
procedure TMyApp.SafeNavigate(const ARoute: string);
begin
  if not CanUserAccessRoute(ARoute) then
    raise ENavigationException.Create('Access denied to: ' + ARoute);

  TRouter4D.Link.&To(ARoute);
end;
```

---

### EInvalidRouteConfigException

**Raised when route configuration is invalid.**

**Common Causes:**
- Empty route path
- Invalid route parameters
- Malformed route configuration

**Example:**
```delphi
// Error: Empty path
TRouter4D.Link.&To('');  // ❌ Raises EInvalidRouteConfigException
```

**Handling:**
```delphi
procedure TMainForm.NavigateToRoute(const APath: string);
begin
  try
    TRouter4D.Link.&To(APath);
  except
    on E: EInvalidRouteConfigException do
    begin
      ShowMessage('Invalid route configuration: ' + E.Message);
      // Log the error for debugging
      Logger.LogError(E.Message);
    end;
  end;
end;
```

---

### EComponentInterfaceException

**Raised when a component doesn't implement required interface.**

**Common Cause:**
- Form doesn't implement `iRouter4DComponent`
- Missing `Render` and `UnRender` methods

**Example:**
```delphi
type
  TMyForm = class(TForm)  // ❌ Missing interface
    // ...
  end;

// Registration will fail
TRouter4D.Switch.Router('MyForm', TMyForm);
```

**Solution:**
```delphi
type
  TMyForm = class(TForm, iRouter4DComponent)  // ✅ Implements interface
  public
    function Render: TFMXObject;  // or TForm for VCL
    procedure UnRender;
  end;
```

**Error Message:**
```
Component "TMyForm" does not implement required interface "iRouter4DComponent"
```

---

## Best Practices

### 1. Specific Exception Handling

```delphi
try
  TRouter4D.Link.&To(RouteName);
except
  on E: ERouteNotFoundException do
    HandleMissingRoute(RouteName);
  on E: EInvalidContainerException do
    ReconfigureContainers;
  on E: ERouter4DException do
    LogGenericError(E);
end;
```

### 2. Global Exception Handler

```delphi
procedure TMainForm.ApplicationException(Sender: TObject; E: Exception);
begin
  if E is ERouter4DException then
  begin
    Logger.LogError(E.Message);
    ShowNotification('Navigation error: ' + E.Message);
  end
  else
    // Handle other exceptions
    Application.ShowException(E);
end;

// In FormCreate
Application.OnException := ApplicationException;
```

### 3. Validation Before Navigation

```delphi
function TRouteValidator.CanNavigate(const ARoute: string): Boolean;
begin
  Result := False;

  // Check if route exists
  if not Router4DHistory.RoutersListPersistent.ContainsKey(ARoute) then
  begin
    ShowMessage('Route not found: ' + ARoute);
    Exit;
  end;

  // Check if container is configured
  if not Assigned(Router4DHistory.MainRouter) then
  begin
    ShowMessage('Navigation system not initialized');
    Exit;
  end;

  Result := True;
end;

// Usage
if TRouteValidator.CanNavigate('Dashboard') then
  TRouter4D.Link.&To('Dashboard');
```

### 4. Graceful Degradation

```delphi
procedure TMainForm.SafeNavigate(const ARoute: string);
const
  FallbackRoute = 'Home';
begin
  try
    TRouter4D.Link.&To(ARoute);
  except
    on E: ERouteNotFoundException do
    begin
      Logger.LogWarning(Format('Route %s not found, fallback to %s', [ARoute, FallbackRoute]));
      TRouter4D.Link.&To(FallbackRoute);
    end;
    on E: ERouter4DException do
    begin
      Logger.LogError('Critical navigation error: ' + E.Message);
      ShowMessage('An error occurred. Returning to home.');
      TRouter4D.Link.&To(FallbackRoute);
    end;
  end;
end;
```

## Common Scenarios

### Scenario 1: User Enters Invalid URL/Route

```delphi
procedure TMainForm.HandleDeepLink(const AUrl: string);
var
  RouteName: string;
begin
  RouteName := ExtractRouteFromUrl(AUrl);

  try
    TRouter4D.Link.&To(RouteName);
  except
    on E: ERouteNotFoundException do
    begin
      Logger.LogWarning('Invalid deep link: ' + AUrl);
      ShowNotFound;
    end;
  end;
end;
```

### Scenario 2: Conditional Navigation

```delphi
procedure TMainForm.NavigateToProfile(AUserId: Integer);
begin
  try
    if AUserId <= 0 then
      raise EInvalidRouteConfigException.Create('Invalid user ID');

    TRouter4D.Link.&To('Profile',
      TProps.Create
        .PropInteger(AUserId)
        .Key('userId')
    );
  except
    on E: EInvalidRouteConfigException do
    begin
      ShowMessage('Cannot navigate: ' + E.Message);
    end;
  end;
end;
```

### Scenario 3: Initialization Check

```delphi
procedure TMainForm.EnsureRouterInitialized;
begin
  try
    // This will raise EInvalidContainerException if not initialized
    if not Assigned(Router4DHistory.MainRouter) then
      raise EInvalidContainerException.Create('MainRouter');
  except
    on E: EInvalidContainerException do
    begin
      Logger.LogCritical('Router not initialized: ' + E.Message);
      Application.MessageBox('Application initialization failed', 'Error', MB_OK);
      Application.Terminate;
    end;
  end;
end;
```

## Backward Compatibility

All exception improvements are backward compatible. Existing code that catches `Exception` will continue to work:

```delphi
// Old code still works
try
  TRouter4D.Link.&To('SomeRoute');
except
  on E: Exception do  // Catches Router4D exceptions too
    ShowMessage(E.Message);
end;
```

## Migration Guide

### Before Phase 2
```delphi
try
  TRouter4D.Link.&To('Dashboard');
except
  on E: Exception do
    ShowMessage('Generic error: ' + E.Message);
end;
```

### After Phase 2
```delphi
try
  TRouter4D.Link.&To('Dashboard');
except
  on E: ERouteNotFoundException do
    ShowMessage('Page not found');
  on E: EInvalidContainerException do
    ShowMessage('App not initialized correctly');
  on E: ERouter4DException do
    ShowMessage('Navigation error: ' + E.Message);
end;
```

## Summary

Custom exceptions in Router4D provide:
- ✅ **Clear error messages** with actionable information
- ✅ **Specific exception types** for targeted handling
- ✅ **Better debugging** with descriptive messages
- ✅ **Logging integration** for error tracking
- ✅ **Backward compatibility** with existing code

Use these exceptions to build more robust and user-friendly applications!
