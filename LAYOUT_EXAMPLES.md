# Router4D Layout System - Exemplos Práticos

## 📚 Índice
1. [Setup Básico](#setup-básico)
2. [Layouts Comuns](#layouts-comuns)
3. [Aplicação Completa](#aplicação-completa)
4. [Layouts Responsivos](#layouts-responsivos)
5. [Dicas e Tricks](#dicas-e-tricks)

---

## Setup Básico

### Passo 1: Uses Necessários

```delphi
uses
  Router4D,
  Router4D.Layout,
  Router4D.LayoutExtensions,
  Router4D.Logger;
```

### Passo 2: Configuração Inicial

```delphi
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Habilitar logging (opcional, mas recomendado)
  SetRouter4DLogger(TRouter4DLogger.Create('app.log', True, False));
  Router4DLogger.MinLevel := llDebug;

  // Registrar rotas
  TRouter4D.Switch
    .Router('Header', THeaderForm)
    .Router('Sidebar', TSidebarForm)
    .Router('Content', TContentForm)
    .Router('Footer', TFooterForm);

  // Configurar layouts (mostrado abaixo)
  ConfigureLayouts;

  // Renderizar interface
  TRouter4D.Render<THeaderForm>.SetElement(pnlMain);
end;
```

---

## Layouts Comuns

### 1. Header Fixo (Barra Superior)

```delphi
LayoutRegistry.RegisterLayout('Header',
  TLayoutConfig.TopBar(70)
    .Padding(15)
);
```

**Uso:**
```
┌─────────────────────────────────┐
│          HEADER (70px)          │  ← Fixo no topo, 15px padding
├─────────────────────────────────┤
│                                 │
│          Content                │
│                                 │
└─────────────────────────────────┘
```

### 2. Sidebar Lateral

```delphi
// Sidebar Esquerda
LayoutRegistry.RegisterLayout('MenuLeft',
  TLayoutConfig.LeftSidebar(250)
    .Padding(10)
    .MinSize(200, 0)  // Mínimo 200px largura
);

// Sidebar Direita
LayoutRegistry.RegisterLayout('InfoPanel',
  TLayoutConfig.RightSidebar(300)
    .Padding(15)
    .MaxSize(400, 0)  // Máximo 400px largura
);
```

**Uso:**
```
┌──────┬─────────────────────┬──────┐
│      │                     │      │
│ Menu │      Content        │ Info │
│ 250px│                     │ 300px│
│      │                     │      │
└──────┴─────────────────────┴──────┘
```

### 3. Footer Fixo (Barra Inferior)

```delphi
LayoutRegistry.RegisterLayout('Footer',
  TLayoutConfig.BottomBar(40)
    .Padding(10)
);
```

### 4. Conteúdo Central

```delphi
// Preenche todo espaço disponível
LayoutRegistry.RegisterLayout('MainContent',
  TLayoutConfig.FullScreen
    .Padding(20)
);

// Centro com tamanho específico
LayoutRegistry.RegisterLayout('CenteredBox',
  TLayoutConfig.Create
    .Zone(lzCenter)
    .Width(800)
    .Height(600)
    .Margin(20)
);

// Centro responsivo (80% do tamanho)
LayoutRegistry.RegisterLayout('Dialog',
  TLayoutConfig.CenterFill  // 80% width e height por padrão
);
```

---

## Aplicação Completa

### Exemplo: Sistema de Gestão

```delphi
procedure TMainForm.ConfigureLayouts;
begin
  // ============================================
  // 1. HEADER - Barra de título e navegação
  // ============================================
  LayoutRegistry.RegisterLayout('Header',
    TLayoutConfig.TopBar(70)
      .Padding(TSpacing.Create(20, 15, 20, 15))
  );

  // ============================================
  // 2. SIDEBAR - Menu lateral
  // ============================================
  LayoutRegistry.RegisterLayout('Sidebar',
    TLayoutConfig.LeftSidebar(250)
      .Padding(10)
      .MinSize(200, 0)   // Não deixa ficar menor que 200px
      .MaxSize(350, 0)   // Não deixa ficar maior que 350px
  );

  // ============================================
  // 3. BREADCRUMB - Navegação hierárquica
  // ============================================
  LayoutRegistry.RegisterLayout('Breadcrumb',
    TLayoutConfig.TopBar(40)
      .Padding(TSpacing.Create(20, 10, 20, 10))
  );

  // ============================================
  // 4. CONTENT - Área principal
  // ============================================
  LayoutRegistry.RegisterLayout('MainContent',
    TLayoutConfig.FullScreen
      .Padding(20)
  );

  // ============================================
  // 5. FOOTER - Barra de status
  // ============================================
  LayoutRegistry.RegisterLayout('Footer',
    TLayoutConfig.BottomBar(30)
      .Padding(TSpacing.Create(20, 5, 20, 5))
  );

  // ============================================
  // 6. MODAL/DIALOG - Janelas modais
  // ============================================
  LayoutRegistry.RegisterLayout('Dialog',
    TLayoutConfig.Create
      .Zone(lzCenter)
      .Width(TDimension.Percentage(60))
      .Height(TDimension.Percentage(70))
      .MinSize(500, 400)
      .MaxSize(1000, 800)
      .Margin(20)
  );

  // ============================================
  // 7. NOTIFICATION - Notificação no canto
  // ============================================
  LayoutRegistry.RegisterLayout('Notification',
    TLayoutConfig.Create
      .Zone(lzTopRight)
      .Width(300)
      .Height(100)
      .Margin(TSpacing.Create(0, 80, 20, 0))  // Abaixo do header
  );
end;
```

**Estrutura Visual:**
```
┌────────────────────────────────────────────────┐
│              HEADER (70px)                     │
├──────────┬─────────────────────────────────────┤
│          │  BREADCRUMB (40px)                  │
│          ├─────────────────────────────────────┤
│ SIDEBAR  │                                     │
│  (250px) │          MAIN CONTENT               │
│          │          (preenche)                 │
│          │                                     │
├──────────┴─────────────────────────────────────┤
│              FOOTER (30px)                     │
└────────────────────────────────────────────────┘

[NOTIFICATION aparece no canto superior direito]
[DIALOG aparece centralizado quando ativado]
```

### Código de Inicialização

```delphi
procedure TMainForm.InitializeApp;
var
  Zones: TDictionary<TLayoutZone, TFMXObject>;
begin
  // Criar todas as zonas automaticamente
  Zones := TRouter4DLayoutHelper.CreateLayoutZones(pnlMain);
  try
    // Renderizar cada componente na zona apropriada
    TRouter4D.Render<THeaderForm>.SetElement(Zones[lzTop]);
    TRouter4D.Render<TFooterForm>.SetElement(Zones[lzBottom]);
    TRouter4D.Render<TSidebarForm>.SetElement(Zones[lzLeft]);
    TRouter4D.Render<TContentForm>.SetElement(Zones[lzFill]);
  finally
    // Não liberar Zones - os containers pertencem ao parent
  end;

  // Navegar para página inicial
  TRouter4D.Link.&To('MainContent');
end;
```

---

## Layouts Responsivos

### Adaptação por Resolução

```delphi
procedure TMainForm.ConfigureResponsiveLayout;
var
  ScreenWidth: Integer;
  SidebarConfig: TLayoutConfig;
begin
  ScreenWidth := Screen.Width;

  // ===========================================
  // Configuração baseada na resolução
  // ===========================================

  if ScreenWidth > 1920 then
  begin
    // Ultra HD / 4K
    SidebarConfig := TLayoutConfig.LeftSidebar(350)
      .Padding(20);
  end
  else if ScreenWidth > 1280 then
  begin
    // Full HD / Desktop
    SidebarConfig := TLayoutConfig.LeftSidebar(250)
      .Padding(15);
  end
  else if ScreenWidth > 800 then
  begin
    // Tablet Landscape
    SidebarConfig := TLayoutConfig.Create
      .Zone(lzLeft)
      .Width(TDimension.Percentage(30))
      .Padding(10);
  end
  else
  begin
    // Mobile / Tablet Portrait
    // Sidebar ocupa tela toda quando aberta
    SidebarConfig := TLayoutConfig.FullScreen
      .Padding(10);
  end;

  LayoutRegistry.RegisterLayout('Sidebar', SidebarConfig);
end;
```

### Adaptação por Orientação

```delphi
procedure TMainForm.OnScreenOrientationChanged;
begin
  if Screen.Width > Screen.Height then
  begin
    // Landscape - Layout horizontal
    LayoutRegistry.RegisterLayout('MainPanel',
      TLayoutConfig.Create
        .Zone(lzLeft)
        .Width(TDimension.Percentage(60))
    );

    LayoutRegistry.RegisterLayout('SidePanel',
      TLayoutConfig.Create
        .Zone(lzRight)
        .Width(TDimension.Percentage(40))
    );
  end
  else
  begin
    // Portrait - Layout vertical
    LayoutRegistry.RegisterLayout('MainPanel',
      TLayoutConfig.TopBar(
        Round(Screen.Height * 0.6)
      )
    );

    LayoutRegistry.RegisterLayout('SidePanel',
      TLayoutConfig.BottomBar(
        Round(Screen.Height * 0.4)
      )
    );
  end;

  // Re-aplicar layouts
  RefreshLayouts;
end;
```

---

## Dicas e Tricks

### 1. Layout Condicional

```delphi
function GetDashboardLayout: TLayoutConfig;
begin
  if UserPreferences.IsCompactMode then
    Result := TLayoutConfig.Create
      .Zone(lzFill)
      .Padding(5)
  else
    Result := TLayoutConfig.CenterFill
      .Padding(20);
end;

// Usar
LayoutRegistry.RegisterLayout('Dashboard', GetDashboardLayout);
```

### 2. Animação de Transição

```delphi
procedure TMainForm.ExpandSidebar;
var
  NewConfig: TLayoutConfig;
begin
  if FSidebarExpanded then
    NewConfig := TLayoutConfig.LeftSidebar(250)
  else
    NewConfig := TLayoutConfig.LeftSidebar(60);

  LayoutRegistry.RegisterLayout('Sidebar', NewConfig);

  // Re-aplicar com animação (se suportado pelo framework)
  TLayoutManager.Apply(SidebarComponent, NewConfig);

  FSidebarExpanded := not FSidebarExpanded;
end;
```

### 3. Multi-Monitor Support

```delphi
procedure TMainForm.MoveToSecondaryMonitor;
var
  SecondaryScreen: TScreen;
begin
  if Screen.MonitorCount > 1 then
  begin
    // Ajustar layout para monitor secundário
    LayoutRegistry.RegisterLayout('FullscreenVideo',
      TLayoutConfig.Create
        .Zone(lzFill)
        .Width(Screen.Monitors[1].Width)
        .Height(Screen.Monitors[1].Height)
    );
  end;
end;
```

### 4. Debug de Layout

```delphi
procedure TMainForm.DebugLayout(const ARouteName: string);
var
  Config: TLayoutConfig;
begin
  if not LayoutRegistry.HasLayout(ARouteName) then
  begin
    ShowMessage('Layout não registrado: ' + ARouteName);
    Exit;
  end;

  Config := LayoutRegistry.GetLayout(ARouteName);

  ShowMessage(Format(
    'Layout Debug:' + sLineBreak +
    'Zona: %d' + sLineBreak +
    'Largura: %.0f' + sLineBreak +
    'Altura: %.0f',
    [Ord(Config.LayoutZone),
     Config.WidthDim.Value,
     Config.HeightDim.Value]
  ));
end;
```

### 5. Layout Templates

```delphi
type
  TLayoutTemplate = class
  public
    class function AdminDashboard: TLayoutConfig;
    class function UserProfile: TLayoutConfig;
    class function LoginScreen: TLayoutConfig;
    class function ReportViewer: TLayoutConfig;
  end;

class function TLayoutTemplate.AdminDashboard: TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzFill)
    .Padding(20)
    .MinSize(1024, 768);
end;

class function TLayoutTemplate.LoginScreen: TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzCenter)
    .Width(400)
    .Height(500)
    .Margin(TSpacing.Zero);
end;

// Usar
LayoutRegistry.RegisterLayout('Admin', TLayoutTemplate.AdminDashboard);
LayoutRegistry.RegisterLayout('Login', TLayoutTemplate.LoginScreen);
```

### 6. Layout com Componente Dinâmico

```delphi
type
  TDashboardForm = class(TForm, iRouter4DComponent, iRouter4DLayoutComponent)
  private
    FIsExpanded: Boolean;
  public
    function GetLayoutConfig: TLayoutConfig;
  end;

function TDashboardForm.GetLayoutConfig: TLayoutConfig;
begin
  if FIsExpanded then
    Result := TLayoutConfig.FullScreen
  else
    Result := TLayoutConfig.Create
      .Zone(lzCenter)
      .Width(TDimension.Percentage(80))
      .Height(TDimension.Percentage(80));
end;

// Ao mudar estado
procedure TDashboardForm.ToggleExpanded;
begin
  FIsExpanded := not FIsExpanded;

  // Re-aplicar layout
  TLayoutManager.Apply(Self, GetLayoutConfig);
end;
```

### 7. Composição de Layouts

```delphi
procedure TMainForm.CreateCompositeLayout;
var
  Container: TLayout;
  HeaderConfig, ContentConfig: TLayoutConfig;
begin
  // Container principal
  Container := TLayoutManager.CreateContainer(pnlMain,
    TLayoutConfig.FullScreen);

  // Header dentro do container
  HeaderConfig := TLayoutConfig.TopBar(60);
  TLayoutManager.Apply(
    TLayoutManager.CreateContainer(Container, HeaderConfig),
    HeaderConfig
  );

  // Content dentro do container
  ContentConfig := TLayoutConfig.FullScreen;
  TLayoutManager.Apply(
    TLayoutManager.CreateContainer(Container, ContentConfig),
    ContentConfig
  );
end;
```

---

## Código Completo de Exemplo

```delphi
unit MainForm;

interface

uses
  System.SysUtils,
  FMX.Forms,
  FMX.Controls,
  FMX.Layouts,
  Router4D,
  Router4D.Layout,
  Router4D.LayoutExtensions,
  Router4D.Logger;

type
  TfrmMain = class(TForm)
    pnlMain: TLayout;
    procedure FormCreate(Sender: TObject);
  private
    procedure ConfigureLayouts;
    procedure RegisterRoutes;
    procedure InitializeUI;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Setup logging
  SetRouter4DLogger(TRouter4DLogger.Create);
  Router4DLogger.MinLevel := llInfo;

  // Configure tudo
  ConfigureLayouts;
  RegisterRoutes;
  InitializeUI;
end;

procedure TfrmMain.ConfigureLayouts;
begin
  // Header
  LayoutRegistry.RegisterLayout('Header',
    TLayoutConfig.TopBar(70).Padding(15));

  // Sidebar
  LayoutRegistry.RegisterLayout('Sidebar',
    TLayoutConfig.LeftSidebar(250)
      .Padding(10)
      .MinSize(200, 0)
      .MaxSize(350, 0));

  // Main Content
  LayoutRegistry.RegisterLayout('Content',
    TLayoutConfig.FullScreen.Padding(20));

  // Footer
  LayoutRegistry.RegisterLayout('Footer',
    TLayoutConfig.BottomBar(40).Padding(10));

  // Dialogs
  LayoutRegistry.RegisterLayout('Dialog',
    TLayoutConfig.CenterFill);
end;

procedure TfrmMain.RegisterRoutes;
begin
  TRouter4D.Switch
    .Router('Header', THeaderForm)
    .Router('Sidebar', TSidebarForm)
    .Router('Content', TContentForm)
    .Router('Footer', TFooterForm);
end;

procedure TfrmMain.InitializeUI;
var
  Zones: TDictionary<TLayoutZone, TFMXObject>;
begin
  Zones := TRouter4DLayoutHelper.CreateLayoutZones(pnlMain);
  try
    TRouter4D.Render<THeaderForm>.SetElement(Zones[lzTop]);
    TRouter4D.Render<TSidebarForm>.SetElement(Zones[lzLeft]);
    TRouter4D.Render<TContentForm>.SetElement(Zones[lzFill]);
    TRouter4D.Render<TFooterForm>.SetElement(Zones[lzBottom]);
  finally
    // Zones não precisa ser liberado
  end;
end;

end.
```

---

## 🎓 Resumo

O Sistema de Layout oferece:

✅ **9 zonas predefinidas** para posicionamento rápido
✅ **Dimensões flexíveis** (absolutas ou percentuais)
✅ **Margens e padding** totalmente configuráveis
✅ **Constraints** (min/max) para controle fino
✅ **Templates prontos** para casos comuns
✅ **Responsividade** nativa
✅ **API fluente** e intuitiva

**Comece a criar layouts profissionais agora!** 🚀
