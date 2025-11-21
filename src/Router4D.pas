unit Router4D;

{$I Router4D.inc}

interface

uses
  System.Generics.Collections,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  SysUtils,
  {$IFDEF HAS_FMX}
  FMX.Types,
  {$ELSE}
  Vcl.ExtCtrls,
  {$ENDIF}
  Router4D.Interfaces,
  Router4D.History,
  Router4D.Render,
  Router4D.Link;

type
  /// <summary>
  /// Main Router4D facade class - entry point for all routing operations
  /// </summary>
  TRouter4D = class(TInterfacedObject, iRouter4D)
    private
    public
      constructor Create;
      destructor Destroy; override;
      /// <summary>
      /// Creates a new Router4D instance
      /// </summary>
      class function New : iRouter4D;
      /// <summary>
      /// Configures the main render container with the initial form
      /// </summary>
      /// <typeparam name="T">The initial form class to render</typeparam>
      /// <returns>The render interface for configuration</returns>
      class function Render<T : class, constructor> : iRouter4DRender; overload;
      /// <summary>
      /// Configures the main render container with a specific initial route
      /// </summary>
      /// <typeparam name="T">The initial form class to render</typeparam>
      /// <param name="initialRoute">The route name to render initially</param>
      /// <returns>The render interface for configuration</returns>
      class function Render<T : class, constructor>(initialRoute:string) : iRouter4DRender; overload;
      /// <summary>
      /// Returns the navigation/link interface for routing operations
      /// </summary>
      /// <returns>The link interface for navigation</returns>
      class function Link : iRouter4DLink;
      /// <summary>
      /// Returns the switch interface for route registration
      /// </summary>
      /// <returns>The switch interface for route configuration</returns>
      class function Switch : iRouter4DSwitch;
      {$IFDEF HAS_FMX}
      /// <summary>
      /// Returns the sidebar interface for dynamic menu generation (FMX only)
      /// </summary>
      /// <returns>The sidebar interface for menu configuration</returns>
      class function SideBar : iRouter4DSidebar;
      {$ENDIF}
  end;

implementation

{ TRouter4Delphi }

uses
  Router4D.Utils,
  Router4D.Switch,
  Router4D.Sidebar;

constructor TRouter4D.Create;
begin

end;

destructor TRouter4D.Destroy;
begin

  inherited;
end;

class function TRouter4D.Link: iRouter4DLink;
begin
  Result := TRouter4DLink.New;
end;

class function TRouter4D.New: iRouter4D;
begin
  Result := Self.Create;
end;

class function TRouter4D.Render<T>(initialRoute:string): iRouter4DRender;
begin
  Router4DHistory
    .AddHistory(
      TPersistentClass(T).ClassName,
      TPersistentClass(T)
    );


  Result :=
    TRouter4DRender
      .New(
        Router4DHistory
          .addCacheHistory(initialRoute)
          .GetHistory(
            TPersistentClass(T)
              .ClassName
          )
      );
end;

class function TRouter4D.Render<T>: iRouter4DRender;
begin
  Router4DHistory
    .AddHistory(
      TPersistentClass(T).ClassName,
      TPersistentClass(T)
    );


  Result :=
    TRouter4DRender
      .New(
        Router4DHistory
          .GetHistory(
            TPersistentClass(T)
              .ClassName
          )
      );
end;
{$IFDEF HAS_FMX}
class function TRouter4D.SideBar: iRouter4DSidebar;
begin
  Result := TRouter4DSidebar.New;
end;
{$ENDIF}
class function TRouter4D.Switch: iRouter4DSwitch;
begin
  Result := TRouter4DSwitch.New;
end;

end.
