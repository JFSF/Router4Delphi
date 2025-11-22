# Router4D Layout System 📐

## Overview

O Sistema de Layout do Router4D permite controlar precisamente **onde** e **como** seus componentes são exibidos, incluindo:

✅ Posicionamento em zonas predefinidas (Top, Bottom, Left, Right, Center, etc.)
✅ Dimensões customizáveis (Width, Height) com valores absolutos ou percentuais
✅ Margens e Padding configuráveis
✅ Constraints (Min/Max Width/Height)
✅ Suporte para FMX e VCL
✅ API fluente e intuitiva

---

## 🎯 Zonas de Posicionamento

### Zonas Disponíveis

```delphi
TLayoutZone = (
  lzCenter,       // Centro do container
  lzTop,          // Topo (barra superior)
  lzBottom,       // Fundo (barra inferior)
  lzLeft,         // Esquerda (sidebar)
  lzRight,        // Direita (sidebar)
  lzTopLeft,      // Canto superior esquerdo
  lzTopRight,     // Canto superior direito
  lzBottomLeft,   // Canto inferior esquerdo
  lzBottomRight,  // Canto inferior direito
  lzFill,         // Preenche todo o container
  lzCustom        // Posição customizada (X, Y)
);
```

### Visualização das Zonas

```
┌─────────────────────────────────────┐
│  lzTopLeft    lzTop    lzTopRight   │
├──────────┬──────────────┬───────────┤
│          │              │           │
│  lzLeft  │   lzCenter   │  lzRight  │
│          │   ou lzFill  │           │
├──────────┴──────────────┴───────────┤
│ lzBottomLeft lzBottom lzBottomRight │
└─────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Configuração Simples

```delphi
uses
  Router4D,
  Router4D.Layout,
  Router4D.LayoutExtensions;

// Registrar layout para uma rota
LayoutRegistry.RegisterLayout('Dashboard',
  TLayoutConfig.Create
    .Zone(lzCenter)
    .Width(800)
    .Height(600)
);

// Navegar normalmente - layout é aplicado automaticamente
TRouter4D.Link.&To('Dashboard');
```

### 2. Configurações Pré-Definidas

```delphi
// Topo (60px de altura)
LayoutRegistry.RegisterLayout('Header',
  TLayoutConfig.TopBar(60));

// Rodapé (40px de altura)
LayoutRegistry.RegisterLayout('Footer',
  TLayoutConfig.BottomBar(40));

// Sidebar esquerda (200px de largura)
LayoutRegistry.RegisterLayout('Menu',
  TLayoutConfig.LeftSidebar(200));

// Sidebar direita (250px de largura)
LayoutRegistry.RegisterLayout('InfoPanel',
  TLayoutConfig.RightSidebar(250));

// Tela cheia
LayoutRegistry.RegisterLayout('MainContent',
  TLayoutConfig.FullScreen);

// Centro com 80% do tamanho
LayoutRegistry.RegisterLayout('Dialog',
  TLayoutConfig.CenterFill);
```

---

## 📏 Dimensões

### Tipos de Dimensão

```delphi
// Valores Absolutos (pixels)
TDimension.Absolute(800)     // 800 pixels

// Percentuais (% do container pai)
TDimension.Percentage(80)    // 80% do tamanho do pai

// Automático (usa tamanho do container/componente)
TDimension.Auto
```

### Exemplos de Uso

```delphi
// Largura absoluta de 800px
TLayoutConfig.Create
  .Width(800)

// Largura em percentual (80% do pai)
TLayoutConfig.Create
  .Width(TDimension.Percentage(80))

// Altura automática
TLayoutConfig.Create
  .Height(TDimension.Auto)

// Combinação
TLayoutConfig.Create
  .Width(TDimension.Percentage(90))   // 90% de largura
  .Height(TDimension.Absolute(500))   // 500px de altura
```

---

## 🎨 Margens e Padding

### Margem (Espaçamento Externo)

```delphi
// Margem uniforme (10px em todos os lados)
TLayoutConfig.Create.Margin(10)

// Margens customizadas
TLayoutConfig.Create.Margin(
  TSpacing.Create(10, 20, 10, 20)  // Left, Top, Right, Bottom
)

// Margens horizontais e verticais
TLayoutConfig.Create.Margin(
  TSpacing.Create(15, 10)  // Horizontal: 15, Vertical: 10
)
```

### Padding (Espaçamento Interno)

```delphi
// Padding uniforme
TLayoutConfig.Create.Padding(15)

// Padding customizado
TLayoutConfig.Create.Padding(
  TSpacing.Create(20, 10, 20, 10)
)
```

---

## 🔧 Configurações Avançadas

### Constraints (Min/Max)

```delphi
TLayoutConfig.Create
  .Zone(lzCenter)
  .Width(TDimension.Percentage(80))
  .Height(TDimension.Percentage(70))
  .MinSize(600, 400)  // Mínimo: 600x400
  .MaxSize(1200, 800) // Máximo: 1200x800
```

### Posição Customizada

```delphi
TLayoutConfig.Create
  .Position(100, 50)  // X: 100, Y: 50
  .Width(400)
  .Height(300)
```

### API Fluente Completa

```delphi
var Config := TLayoutConfig.Create
  .Zone(lzCenter)
  .Width(TDimension.Percentage(90))
  .Height(TDimension.Absolute(600))
  .Margin(20)
  .Padding(15)
  .MinSize(400, 300)
  .MaxSize(1000, 800);

LayoutRegistry.RegisterLayout('MyRoute', Config);
```

---

## 💼 Casos de Uso Comuns

### 1. Layout de Aplicação Típica

```delphi
// Header fixo no topo
LayoutRegistry.RegisterLayout('Header',
  TLayoutConfig.TopBar(70));

// Sidebar esquerda
LayoutRegistry.RegisterLayout('SideMenu',
  TLayoutConfig.LeftSidebar(220)
    .Padding(10));

// Conteúdo principal (preenche o resto)
LayoutRegistry.RegisterLayout('MainContent',
  TLayoutConfig.FullScreen
    .Margin(10));

// Footer fixo no fundo
LayoutRegistry.RegisterLayout('Footer',
  TLayoutConfig.BottomBar(50));
```

### 2. Dialog/Modal Centralizado

```delphi
LayoutRegistry.RegisterLayout('LoginDialog',
  TLayoutConfig.Create
    .Zone(lzCenter)
    .Width(400)
    .Height(300)
    .Margin(TSpacing.Zero)
);
```

### 3. Dashboard com Painéis

```delphi
// Painel de informações no topo
LayoutRegistry.RegisterLayout('InfoBar',
  TLayoutConfig.TopBar(100)
    .Padding(15));

// Gráficos na esquerda (40% da largura)
LayoutRegistry.RegisterLayout('Charts',
  TLayoutConfig.Create
    .Zone(lzLeft)
    .Width(TDimension.Percentage(40))
    .Padding(10));

// Detalhes na direita (preenche o resto)
LayoutRegistry.RegisterLayout('Details',
  TLayoutConfig.FullScreen
    .Padding(10));
```

### 4. Layout Responsivo

```delphi
// Desktop: Sidebar + Conteúdo
if Screen.Width > 1024 then
begin
  LayoutRegistry.RegisterLayout('Menu',
    TLayoutConfig.LeftSidebar(250));
  LayoutRegistry.RegisterLayout('Content',
    TLayoutConfig.FullScreen);
end
else // Mobile: Fullscreen
begin
  LayoutRegistry.RegisterLayout('Menu',
    TLayoutConfig.FullScreen);
  LayoutRegistry.RegisterLayout('Content',
    TLayoutConfig.FullScreen);
end;
```

### 5. Cantos da Tela

```delphi
// Logo no canto superior esquerdo
LayoutRegistry.RegisterLayout('Logo',
  TLayoutConfig.Create
    .Zone(lzTopLeft)
    .Width(150)
    .Height(50)
    .Margin(10));

// Notificações no canto superior direito
LayoutRegistry.RegisterLayout('Notifications',
  TLayoutConfig.Create
    .Zone(lzTopRight)
    .Width(300)
    .Height(400)
    .Margin(10));
```

---

## 🔄 Integração com Components

### Método 1: Via Registry (Recomendado)

```delphi
// No início da aplicação
LayoutRegistry.RegisterLayout('Dashboard',
  TLayoutConfig.CenterFill);

// Navegar - layout aplicado automaticamente
TRouter4D.Link.&To('Dashboard');
```

### Método 2: Via Interface iRouter4DLayoutComponent

```delphi
type
  TDashboardForm = class(TForm, iRouter4DComponent, iRouter4DLayoutComponent)
  public
    function Render: TFMXObject; // or TForm for VCL
    procedure UnRender;
    function GetLayoutConfig: TLayoutConfig;
  end;

function TDashboardForm.GetLayoutConfig: TLayoutConfig;
begin
  Result := TLayoutConfig.Create
    .Zone(lzCenter)
    .Width(TDimension.Percentage(90))
    .Height(TDimension.Percentage(85))
    .Margin(20);
end;
```

### Método 3: Aplicação Manual

```delphi
var
  Config: TLayoutConfig;
  Component: TControl;
begin
  Config := TLayoutConfig.TopBar(60);
  Component := MyHeaderComponent;

  TLayoutManager.Apply(Component, Config);
end;
```

---

## 🏗️ Criar Zonas de Layout

### Criar Containers para Todas as Zonas

```delphi
var
  Zones: TDictionary<TLayoutZone, TFMXObject>;
begin
  // Cria containers pré-configurados para cada zona
  Zones := TRouter4DLayoutHelper.CreateLayoutZones(MainPanel);

  // Usar os containers
  TRouter4D.Render<THeaderForm>.SetElement(Zones[lzTop]);
  TRouter4D.Render<TMenuForm>.SetElement(Zones[lzLeft]);
  TRouter4D.Render<TContentForm>.SetElement(Zones[lzFill]);
  TRouter4D.Render<TFooterForm>.SetElement(Zones[lzBottom]);
end;
```

---

## 📱 FMX vs VCL

### FMX (FireMonkey)

```delphi
// Suporte completo a todas as zonas
// Usa TAlignLayout internamente
// Suporta Margins e Padding nativos
// Transformações e animações disponíveis

TLayoutConfig.Create
  .Zone(lzTopLeft)  // Funciona perfeitamente
  .Width(200)
  .Height(100)
  .Margin(10)
  .Padding(5);
```

### VCL (Visual Component Library)

```delphi
// Suporte a zonas principais (Top, Bottom, Left, Right, Fill)
// Zonas de canto simuladas com posicionamento manual
// Usa TAlign internamente
// Margins aplicadas via posicionamento

TLayoutConfig.Create
  .Zone(lzTop)      // Funciona com TAlign
  .Height(60)
  .Margin(5);
```

---

## 🎯 Exemplos Completos

### Exemplo 1: Aplicação Master-Detail

```delphi
program MasterDetailApp;

uses
  Router4D,
  Router4D.Layout,
  Router4D.LayoutExtensions;

begin
  // Registrar layouts
  LayoutRegistry.RegisterLayout('Header',
    TLayoutConfig.TopBar(70)
      .Padding(15));

  LayoutRegistry.RegisterLayout('MasterList',
    TLayoutConfig.LeftSidebar(300)
      .Padding(10));

  LayoutRegistry.RegisterLayout('DetailView',
    TLayoutConfig.FullScreen
      .Padding(10)
      .Margin(TSpacing.Create(0, 0, 0, 0)));

  LayoutRegistry.RegisterLayout('StatusBar',
    TLayoutConfig.BottomBar(30));

  // Registrar rotas
  TRouter4D.Switch
    .Router('Header', THeaderForm)
    .Router('MasterList', TMasterListForm)
    .Router('DetailView', TDetailViewForm)
    .Router('StatusBar', TStatusBarForm);

  // Renderizar
  TRouter4D.Render<THeaderForm>.SetElement(TopPanel);
  TRouter4D.Render<TMasterListForm>.SetElement(LeftPanel);
  TRouter4D.Render<TDetailViewForm>.SetElement(MainPanel);
  TRouter4D.Render<TStatusBarForm>.SetElement(BottomPanel);
end.
```

### Exemplo 2: Dashboard Complexo

```delphi
procedure SetupDashboardLayout;
begin
  // Título no topo
  LayoutRegistry.RegisterLayout('Title',
    TLayoutConfig.TopBar(80)
      .Padding(20));

  // Métricas principais (3 cards no topo)
  LayoutRegistry.RegisterLayout('Metrics',
    TLayoutConfig.TopBar(120)
      .Padding(10));

  // Gráfico principal (centro-esquerda, 60% largura)
  LayoutRegistry.RegisterLayout('MainChart',
    TLayoutConfig.Create
      .Zone(lzLeft)
      .Width(TDimension.Percentage(60))
      .Padding(10));

  // Informações adicionais (direita, 40% largura)
  LayoutRegistry.RegisterLayout('SideInfo',
    TLayoutConfig.Create
      .Zone(lzRight)
      .Width(TDimension.Percentage(40))
      .Padding(10));

  // Tabela de dados (fundo)
  LayoutRegistry.RegisterLayout('DataTable',
    TLayoutConfig.BottomBar(250)
      .Padding(10));
end;
```

### Exemplo 3: Dialog Customizado

```delphi
procedure ShowCustomDialog;
var
  DialogConfig: TLayoutConfig;
begin
  DialogConfig := TLayoutConfig.Create
    .Zone(lzCenter)
    .Width(500)
    .Height(400)
    .Margin(TSpacing.Zero)
    .MinSize(400, 300)
    .MaxSize(800, 600);

  LayoutRegistry.RegisterLayout('CustomDialog', DialogConfig);

  TRouter4D.Link.&To('CustomDialog');
end;
```

### Exemplo 4: Layout Dinâmico Baseado em Resolução

```delphi
procedure ConfigureResponsiveLayout;
var
  ScreenWidth: Integer;
  SidebarWidth: TDimension;
begin
  ScreenWidth := Screen.Width;

  // Ajustar sidebar baseado na resolução
  if ScreenWidth > 1920 then
    SidebarWidth := TDimension.Absolute(350)
  else if ScreenWidth > 1280 then
    SidebarWidth := TDimension.Absolute(250)
  else if ScreenWidth > 800 then
    SidebarWidth := TDimension.Percentage(30)
  else
    SidebarWidth := TDimension.Percentage(100); // Mobile: fullscreen

  LayoutRegistry.RegisterLayout('Sidebar',
    TLayoutConfig.Create
      .Zone(lzLeft)
      .Width(SidebarWidth)
      .Padding(10));

  TRouter4D.Link.&To('Sidebar');
end;
```

---

## 🐛 Troubleshooting

### Problema: Layout não está sendo aplicado

**Solução:**
```delphi
// 1. Verificar se layout está registrado
if LayoutRegistry.HasLayout('MyRoute') then
  ShowMessage('Layout registrado!')
else
  ShowMessage('Layout NÃO registrado!');

// 2. Habilitar logging
Router4DLogger.MinLevel := llDebug;

// 3. Aplicar manualmente se necessário
TLayoutManager.Apply(MyComponent, MyLayoutConfig);
```

### Problema: Dimensões não respondem

**Solução:**
```delphi
// Certifique-se de que o componente está dentro de um container
// Para percentuais funcionarem, precisa de um parent com tamanho definido

// Verificar:
if Assigned(MyComponent.Parent) then
  ShowMessage(Format('Parent: %d x %d',
    [MyComponent.Parent.Width, MyComponent.Parent.Height]));
```

### Problema: Zonas de canto não funcionam em VCL

**Solução:**
```delphi
// VCL não suporta nativamente todas as zonas
// Use posicionamento customizado:
TLayoutConfig.Create
  .Position(10, 10)  // Top-left manual
  .Width(150)
  .Height(100);
```

---

## 📊 Comparação de Abordagens

| Abordagem | Vantagens | Desvantagens |
|-----------|-----------|--------------|
| **Registry** | Centralizado, fácil manutenção | Configuração separada do componente |
| **Interface** | Encapsulado no componente | Cada form precisa implementar |
| **Manual** | Controle total | Mais código, menos automático |

---

## 🎓 Best Practices

### 1. Use o Registry para Layouts Globais
```delphi
// Bom: Layouts consistentes em toda app
LayoutRegistry.RegisterLayout('Header', TLayoutConfig.TopBar(70));
LayoutRegistry.RegisterLayout('Footer', TLayoutConfig.BottomBar(50));
```

### 2. Use Interface para Componentes Dinâmicos
```delphi
// Bom: Componentes que mudam layout baseado em estado
function TMyForm.GetLayoutConfig: TLayoutConfig;
begin
  if FIsFullscreen then
    Result := TLayoutConfig.FullScreen
  else
    Result := TLayoutConfig.CenterFill;
end;
```

### 3. Use Percentuais para Responsividade
```delphi
// Bom: Adapta a diferentes resoluções
TLayoutConfig.Create
  .Width(TDimension.Percentage(90))
  .Height(TDimension.Percentage(80));

// Evite: Valores fixos podem não funcionar em todas as resoluções
TLayoutConfig.Create
  .Width(1920)  // ❌ Pode ser muito grande em telas pequenas
  .Height(1080);
```

### 4. Defina Constraints para Usabilidade
```delphi
// Bom: Garante usabilidade em qualquer tamanho
TLayoutConfig.Create
  .Width(TDimension.Percentage(90))
  .MinSize(600, 400)   // Não menor que isso
  .MaxSize(1400, 900); // Não maior que isso
```

### 5. Use Configurações Pré-Definidas
```delphi
// Bom: Reutilização e consistência
TLayoutConfig.TopBar(60);
TLayoutConfig.LeftSidebar(250);
TLayoutConfig.CenterFill;

// Evite: Recriar a mesma configuração várias vezes
```

---

## 🚀 Performance

| Operação | Overhead | Notas |
|----------|----------|-------|
| Registro de Layout | Mínimo | Uma vez na inicialização |
| Aplicação de Layout | Baixo | Durante renderização |
| Lookup no Registry | Muito baixo | Dictionary lookup O(1) |
| Cálculo de Dimensões | Mínimo | Operações matemáticas simples |

---

## 📝 API Reference

### TLayoutConfig

**Métodos de Configuração:**
- `Zone(TLayoutZone)` - Define zona de posicionamento
- `Width(TDimension)` - Define largura
- `Height(TDimension)` - Define altura
- `Margin(TSpacing)` - Define margem
- `Padding(TSpacing)` - Define padding
- `Position(X, Y)` - Posição customizada
- `MinSize(W, H)` - Tamanho mínimo
- `MaxSize(W, H)` - Tamanho máximo

**Configurações Pré-Definidas:**
- `CenterFill` - Centro, 80% do tamanho
- `TopBar(Height)` - Barra superior
- `BottomBar(Height)` - Barra inferior
- `LeftSidebar(Width)` - Sidebar esquerda
- `RightSidebar(Width)` - Sidebar direita
- `FullScreen` - Tela cheia

### LayoutRegistry

- `RegisterLayout(Route, Config)` - Registra layout
- `GetLayout(Route)` - Obtém layout
- `HasLayout(Route)` - Verifica se existe
- `UnregisterLayout(Route)` - Remove layout
- `Clear` - Limpa todos

### TLayoutManager

- `Apply(Component, Config)` - Aplica layout
- `CreateContainer(Parent, Config)` - Cria container com layout

---

## 🎉 Conclusão

O Sistema de Layout do Router4D oferece:

✅ **Flexibilidade** - Múltiplas formas de configurar
✅ **Simplicidade** - API fluente e intuitiva
✅ **Poder** - Controle total sobre posicionamento
✅ **Responsividade** - Suporte a percentuais
✅ **Consistência** - Layouts centralizados
✅ **Performance** - Overhead mínimo

**Comece agora a criar layouts profissionais com Router4D!** 🚀
