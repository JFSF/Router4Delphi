# Router4D Phase 3 - Advanced Features Guide

## Overview

Phase 3 introduces powerful enterprise-grade features to Router4D:

1. **Configuration System** - Centralized configuration management
2. **Route Guards** - Control access to routes with authentication, authorization, and validation
3. **Navigation Events** - Hook into navigation lifecycle
4. **Middleware Pipeline** - Execute logic before/during navigation
5. **Deep Links** - Support for parameterized URLs and routing patterns

---

## 1. Configuration System

### Overview
Centralized configuration for all Router4D settings with fluent API.

### Usage

```delphi
uses Router4D.Config;

// Get configuration instance
var Config := TRouter4DConfig.Instance;

// Set individual properties
Config.MaxFrameCache := 50;
Config.MaxHistoryCache := 20;
Config.EnableLogging := True;
Config.StrictMode := True;

// Or use fluent API
TRouter4DConfig.Instance
  .SetMaxFrameCache(50)
  .SetMaxHistoryCache(20)
  .SetEnableLogging(True)
  .SetStrictMode(True)
  .SetEnableAnimation(True)
  .SetDefaultAnimationDuration(300);
```

### Available Settings

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `MaxFrameCache` | Integer | 25 | Maximum cached form instances |
| `MaxHistoryCache` | Integer | 10 | Maximum history entries |
| `EnableLogging` | Boolean | False | Enable/disable logging |
| `StrictMode` | Boolean | True | Raise exceptions vs silent failures |
| `EnableAnimation` | Boolean | True | Enable/disable animations |
| `DefaultAnimationDuration` | Integer | 300 | Default animation duration (ms) |

### Reset to Defaults

```delphi
TRouter4DConfig.Instance.ResetToDefaults;
```

---

## 2. Route Guards

### Overview
Control access to routes with guard classes that implement `IRouteGuard`.

### Basic Usage

```delphi
uses Router4D.Guards;

// Add authentication guard to Admin route
RouteGuardManager.AddGuard('Admin',
  TAuthGuard.Create(
    function: Boolean
    begin
      Result := CurrentUser.IsAuthenticated;
    end,
    'Login' // Redirect route
  )
);

// Add role-based guard
RouteGuardManager.AddGuard('Admin',
  TRoleGuard.Create(
    ['Admin', 'SuperUser'],
    function(ARole: string): Boolean
    begin
      Result := CurrentUser.HasRole(ARole);
    end
  )
);

// Add confirmation guard (for unsaved changes)
RouteGuardManager.AddGuard('EditForm',
  TConfirmationGuard.Create(
    'You have unsaved changes. Leave anyway?',
    function(AMessage: string): Boolean
    begin
      Result := MessageDlg(AMessage, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
    end
  )
);
```

### Built-in Guards

#### TAuthGuard
Checks authentication before accessing route.

```delphi
var AuthGuard := TAuthGuard.Create(
  function: Boolean
  begin
    Result := UserService.IsLoggedIn;
  end,
  'Login' // Redirect if not authenticated
);
RouteGuardManager.AddGuard('Dashboard', AuthGuard);
```

#### TRoleGuard
Checks if user has required role.

```delphi
var RoleGuard := TRoleGuard.Create(
  ['Admin', 'Manager'], // Required roles (any of these)
  function(ARole: string): Boolean
  begin
    Result := UserService.HasRole(ARole);
  end
);
RouteGuardManager.AddGuard('AdminPanel', RoleGuard);
```

#### TConfirmationGuard
Asks for confirmation before leaving route.

```delphi
var ConfirmGuard := TConfirmationGuard.Create(
  'Discard unsaved changes?',
  function(AMessage: string): Boolean
  begin
    Result := Application.MessageBox(
      PChar(AMessage),
      'Confirm',
      MB_YESNO or MB_ICONQUESTION
    ) = IDYES;
  end
);
RouteGuardManager.AddGuard('EditForm', ConfirmGuard);
```

### Custom Guards

Implement `IRouteGuard` or extend `TRouteGuard`:

```delphi
type
  TMyCustomGuard = class(TRouteGuard)
  public
    constructor Create;
    function CanActivate(const AContext: TRouteContext): Boolean; override;
    function CanDeactivate(const AContext: TRouteContext): Boolean; override;
  end;

constructor TMyCustomGuard.Create;
begin
  inherited Create('MyCustomGuard');
end;

function TMyCustomGuard.CanActivate(const AContext: TRouteContext): Boolean;
begin
  // Your custom logic
  Result := SomeCondition;
  if not Result then
    Router4DLogger.LogWarning('Access denied: ' + AContext.ToRoute);
end;

function TMyCustomGuard.CanDeactivate(const AContext: TRouteContext): Boolean;
begin
  // Your custom logic
  Result := True;
end;
```

### Global Guards

Apply guards to ALL routes:

```delphi
// This guard runs for every navigation
RouteGuardManager.AddGlobalGuard(
  TAuthGuard.Create(
    function: Boolean
    begin
      Result := UserService.IsLoggedIn;
    end
  )
);
```

---

## 3. Navigation Events

### Overview
Hook into navigation lifecycle to track, log, or cancel navigation.

### Event Types

```delphi
uses Router4D.Events;

// Before navigation (cancellable)
NavigationEvents.OnBeforeNavigate := procedure(Sender: TObject;
  EventData: TNavigationEventData; var Cancel: Boolean)
begin
  if not ConfirmNavigation(EventData.FromRoute, EventData.ToRoute) then
    Cancel := True;
end;

// After successful navigation
NavigationEvents.OnAfterNavigate := procedure(Sender: TObject;
  EventData: TNavigationEventData)
begin
  LogNavigation(EventData.FromRoute, EventData.ToRoute);
  UpdateBreadcrumb(EventData.ToRoute);
end;

// Navigation error
NavigationEvents.OnNavigationError := procedure(Sender: TObject;
  EventData: TNavigationEventData)
begin
  ShowMessage('Navigation failed: ' + EventData.ToRoute);
end;

// Navigation cancelled
NavigationEvents.OnNavigationCancelled := procedure(Sender: TObject;
  EventData: TNavigationEventData; var Cancel: Boolean)
begin
  LogCancellation(EventData.FromRoute, EventData.ToRoute);
end;
```

### Navigation History

```delphi
// Get navigation history
var History := NavigationEvents.GetNavigationHistory;
for var Event in History do
begin
  Memo1.Lines.Add(Format('%s: %s -> %s',
    [FormatDateTime('hh:nn:ss', Event.Timestamp),
     Event.FromRoute,
     Event.ToRoute]));
end;

// Clear history
NavigationEvents.ClearHistory;

// Configure history size
NavigationEvents.MaxHistorySize := 100;
```

### Use Cases

#### Analytics Tracking

```delphi
NavigationEvents.OnAfterNavigate := procedure(Sender: TObject;
  EventData: TNavigationEventData)
begin
  GoogleAnalytics.TrackPageView(EventData.ToRoute);
end;
```

#### User Confirmation

```delphi
NavigationEvents.OnBeforeNavigate := procedure(Sender: TObject;
  EventData: TNavigationEventData; var Cancel: Boolean)
begin
  if HasUnsavedChanges then
  begin
    Cancel := MessageDlg('Discard changes?', mtConfirmation,
      [mbYes, mbNo], 0) <> mrYes;
  end;
end;
```

#### Performance Monitoring

```delphi
var StartTime: TDateTime;

NavigationEvents.OnBeforeNavigate := procedure(Sender: TObject;
  EventData: TNavigationEventData; var Cancel: Boolean)
begin
  StartTime := Now;
end;

NavigationEvents.OnAfterNavigate := procedure(Sender: TObject;
  EventData: TNavigationEventData)
begin
  var Duration := MilliSecondsBetween(Now, StartTime);
  PerformanceMonitor.LogNavigationTime(EventData.ToRoute, Duration);
end;
```

---

## 4. Middleware Pipeline

### Overview
Execute logic in a pipeline before navigation occurs. Similar to ASP.NET Core middleware.

### Basic Usage

```delphi
uses Router4D.Middleware;

// Add global middleware (runs for all routes)
MiddlewarePipeline.AddMiddleware(TLoggingMiddleware.Create);
MiddlewarePipeline.AddMiddleware(TTimingMiddleware.Create);
MiddlewarePipeline.AddMiddleware(
  TAuthMiddleware.Create(
    function: Boolean
    begin
      Result := UserService.IsAuthenticated;
    end
  )
);

// Add route-specific middleware
MiddlewarePipeline.AddRouteMiddleware('Admin',
  TValidationMiddleware.Create(
    function(AContext: TMiddlewareContext): Boolean
    begin
      Result := CurrentUser.IsAdmin;
      if not Result then
        AContext.Abort('Admin access required');
    end
  )
);
```

### Built-in Middleware

#### TLoggingMiddleware
Logs all navigation.

```delphi
MiddlewarePipeline.AddMiddleware(TLoggingMiddleware.Create);
// Output: [Middleware] Navigation: Home -> Dashboard
```

#### TTimingMiddleware
Measures navigation time.

```delphi
MiddlewarePipeline.AddMiddleware(TTimingMiddleware.Create);
// Output: [Middleware] Navigation time: 45 ms
```

#### TAuthMiddleware
Checks authentication.

```delphi
MiddlewarePipeline.AddMiddleware(
  TAuthMiddleware.Create(
    function: Boolean
    begin
      Result := Session.IsAuthenticated;
    end,
    'Login' // Redirect route
  )
);
```

#### TValidationMiddleware
Custom validation logic.

```delphi
MiddlewarePipeline.AddMiddleware(
  TValidationMiddleware.Create(
    function(AContext: TMiddlewareContext): Boolean
    begin
      Result := ValidateNavigation(AContext.RouteContext.ToRoute);
      if not Result then
        AContext.Abort('Validation failed');
    end
  )
);
```

### Custom Middleware

```delphi
type
  TRateLimitMiddleware = class(TMiddleware)
  private
    FLastRequest: TDateTime;
    FMinInterval: Integer; // milliseconds
  public
    constructor Create(AMinInterval: Integer);
    function Execute(const AContext: TMiddlewareContext): Boolean; override;
  end;

constructor TRateLimitMiddleware.Create(AMinInterval: Integer);
begin
  inherited Create('RateLimitMiddleware');
  FMinInterval := AMinInterval;
  FLastRequest := 0;
end;

function TRateLimitMiddleware.Execute(const AContext: TMiddlewareContext): Boolean;
var
  LElapsed: Integer;
begin
  LElapsed := MilliSecondsBetween(Now, FLastRequest);

  if LElapsed < FMinInterval then
  begin
    AContext.Abort(Format('Rate limit: wait %d ms', [FMinInterval - LElapsed]));
    Exit(False);
  end;

  FLastRequest := Now;
  Result := True;
end;

// Usage
MiddlewarePipeline.AddMiddleware(TRateLimitMiddleware.Create(1000)); // Max 1 request/second
```

### Middleware Context

Access and share data between middleware:

```delphi
// In first middleware
AContext.Data.AddOrSetValue('UserId', 123);
AContext.Data.AddOrSetValue('StartTime', Now);

// In second middleware
var UserId := AContext.Data['UserId'].AsInteger;
var StartTime := AContext.Data['StartTime'].AsType<TDateTime>;
```

### Execution Order

1. Global middleware (in order added)
2. Route-specific middleware (in order added)
3. If any middleware returns `False` or calls `AContext.Abort()`, pipeline stops

---

## 5. Deep Links with Parameters

### Overview
Support for parameterized URLs like `users/:id/posts/:postId`.

### Register Patterns

```delphi
uses Router4D.DeepLinks;

// Register patterns
DeepLinkManager.RegisterPattern('users/:id', 'UserDetail');
DeepLinkManager.RegisterPattern('users/:id/posts', 'UserPosts');
DeepLinkManager.RegisterPattern('posts/:postId', 'PostDetail');
DeepLinkManager.RegisterPattern('posts/:postId/comments/:commentId', 'CommentDetail');
```

### Match URLs

```delphi
var
  RouteName: string;
  Params: TRouteParams;
begin
  if DeepLinkManager.MatchURL('users/123', RouteName, Params) then
  begin
    // RouteName = 'UserDetail'
    // Params.Get('id') = '123'
    // Params.GetInt('id') = 123

    TRouter4D.Link.&To(RouteName,
      TProps.Create.PropInteger(Params.GetInt('id')).Key('userId')
    );
  end;
end;
```

### Extract Parameters

```delphi
// URL: posts/456/comments/789?sort=date&order=asc
var Params := Pattern.ExtractParams('posts/456/comments/789?sort=date&order=asc');

// Path parameters
Params.Get('postId'); // '456'
Params.GetInt('postId'); // 456
Params.GetInt('commentId'); // 789

// Query parameters
Params.GetQuery('sort'); // 'date'
Params.GetQuery('order'); // 'asc'
Params.GetQueryInt('page', 1); // 1 (default)

// Check existence
if Params.Has('postId') then
  ShowMessage('PostId: ' + Params.Get('postId'));

if Params.HasQuery('sort') then
  ShowMessage('Sort: ' + Params.GetQuery('sort'));
```

### Build URLs

```delphi
var Params := TRouteParams.Create;
try
  Params.FParams.Add('id', '123');
  Params.FParams.Add('postId', '456');

  var URL := DeepLinkManager.BuildURL('UserPosts', Params);
  // URL = 'users/123/posts/456'
finally
  Params.Free;
end;
```

### Convert to TProps

```delphi
var Params := Pattern.ExtractParams('users/123');
var Props := Params.ToProps; // Converts all parameters to TProps
try
  TRouter4D.Link.&To('UserDetail', Props);
finally
  Params.Free;
  Props.Free;
end;
```

### Deep Link Handler

Complete example:

```delphi
procedure TMainForm.HandleDeepLink(const AURL: string);
var
  RouteName: string;
  Params: TRouteParams;
begin
  if DeepLinkManager.MatchURL(AURL, RouteName, Params) then
  begin
    try
      var Props := Params.ToProps;
      try
        TRouter4D.Link.&To(RouteName, Props);
      finally
        Props.Free;
      end;
    finally
      Params.Free;
    end;
  end
  else
  begin
    ShowMessage('Invalid URL: ' + AURL);
    TRouter4D.Link.&To('Home');
  end;
end;

// Usage
HandleDeepLink('users/123/posts/456');
HandleDeepLink('posts/789?sort=date&page=2');
```

---

## Complete Integration Example

Here's how to use all Phase 3 features together:

```delphi
program MyApp;

uses
  Router4D,
  Router4D.Config,
  Router4D.Guards,
  Router4D.Events,
  Router4D.Middleware,
  Router4D.DeepLinks,
  Router4D.Logger;

begin
  // 1. Configure Router4D
  TRouter4DConfig.Instance
    .SetMaxFrameCache(50)
    .SetMaxHistoryCache(20)
    .SetEnableLogging(True)
    .SetStrictMode(True);

  // 2. Setup logging
  SetRouter4DLogger(TRouter4DLogger.Create('app.log', True, True));
  Router4DLogger.MinLevel := llInfo;

  // 3. Register routes
  TRouter4D.Switch
    .Router('Home', THomeForm)
    .Router('Login', TLoginForm)
    .Router('Dashboard', TDashboardForm)
    .Router('Admin', TAdminForm)
    .Router('UserDetail', TUserDetailForm);

  // 4. Register deep link patterns
  DeepLinkManager.RegisterPattern('users/:id', 'UserDetail');
  DeepLinkManager.RegisterPattern('admin/settings', 'Admin');

  // 5. Add guards
  RouteGuardManager.AddGuard('Dashboard',
    TAuthGuard.Create(
      function: Boolean
      begin
        Result := AppServices.Auth.IsAuthenticated;
      end,
      'Login'
    )
  );

  RouteGuardManager.AddGuard('Admin',
    TRoleGuard.Create(
      ['Admin'],
      function(ARole: string): Boolean
      begin
        Result := AppServices.Auth.HasRole(ARole);
      end
    )
  );

  // 6. Add middleware
  MiddlewarePipeline.AddMiddleware(TLoggingMiddleware.Create);
  MiddlewarePipeline.AddMiddleware(TTimingMiddleware.Create);
  MiddlewarePipeline.AddMiddleware(
    TAuthMiddleware.Create(
      function: Boolean
      begin
        Result := AppServices.Auth.IsAuthenticated;
      end
    )
  );

  // 7. Setup navigation events
  NavigationEvents.OnBeforeNavigate := procedure(Sender: TObject;
    EventData: TNavigationEventData; var Cancel: Boolean)
  begin
    if HasUnsavedChanges then
      Cancel := not ConfirmLeave;
  end;

  NavigationEvents.OnAfterNavigate := procedure(Sender: TObject;
    EventData: TNavigationEventData)
  begin
    GoogleAnalytics.TrackPageView(EventData.ToRoute);
    UpdateUI;
  end;

  // 8. Initialize router
  TRouter4D.Render<THomeForm>.SetElement(MainPanel);

  // 9. Navigate
  TRouter4D.Link.&To('Dashboard');
end.
```

---

## Best Practices

### 1. Configuration
- Configure Router4D at application startup
- Use fluent API for readability
- Don't change configuration after initialization

### 2. Guards
- Use guards for authentication and authorization
- Keep guard logic simple and fast
- Combine multiple guards when needed
- Use global guards for app-wide rules

### 3. Events
- Use events for analytics and tracking
- Keep event handlers lightweight
- Don't perform heavy operations in event handlers
- Consider async operations for slow tasks

### 4. Middleware
- Order matters - authentication before authorization
- Keep middleware focused (single responsibility)
- Use middleware for cross-cutting concerns
- Avoid heavy processing in middleware

### 5. Deep Links
- Register patterns at startup
- Use descriptive parameter names
- Validate parameters before use
- Handle invalid URLs gracefully

---

## Performance Considerations

| Feature | Overhead | Notes |
|---------|----------|-------|
| Configuration | Minimal | Singleton, one-time setup |
| Guards | Low | Only runs when navigating |
| Events | Low | Event handlers should be fast |
| Middleware | Low-Medium | Depends on middleware logic |
| Deep Links | Low | Regex matching is cached |

---

## Troubleshooting

### Guards Not Working
- Check if guards are registered correctly
- Verify guard logic returns expected values
- Enable logging to see guard execution

### Events Not Firing
- Ensure events are assigned before navigation
- Check if navigation is actually occurring
- Look for exceptions in event handlers

### Middleware Blocking Navigation
- Check middleware return values
- Look for `AContext.Abort()` calls
- Enable debug logging

### Deep Links Not Matching
- Verify pattern syntax (use `:param` for parameters)
- Check for typos in route names
- Test patterns individually

---

## Migration from Phase 2

All Phase 3 features are **opt-in** and **backward compatible**:

- Existing code works without changes
- New features must be explicitly enabled
- No performance impact if not used
- Gradual migration is supported

```delphi
// Phase 2 code still works
TRouter4D.Switch.Router('Home', THomeForm);
TRouter4D.Render<THomeForm>.SetElement(MainPanel);
TRouter4D.Link.&To('Dashboard');

// Add Phase 3 features as needed
RouteGuardManager.AddGuard('Dashboard', TAuthGuard.Create(...));
```

---

## What's Next?

Upcoming features being considered:
- Lazy loading of routes
- Route prefetching
- Nested routers
- State persistence
- Animation transitions
- Route metadata

Contribute ideas at: https://github.com/JFSF/Router4Delphi
