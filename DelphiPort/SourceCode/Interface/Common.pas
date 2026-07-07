unit Common;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.ExtCtrls,
  Winapi.Windows, Winapi.Messages;

type
  // Forward declarations used by many widgets
  TSurface = class;
  TInteractiveSurface = class;
  TText = class;
  TTextButton = class;
  TTextList = class;
  TComboBox = class;
  TWindow = class;
  TAction = class;
  TState = class;

  // ---------------------------------------------------------------------------
  // Minimal Action and State classes to mimic C++ event handling
  // ---------------------------------------------------------------------------
  TAction = class
  private
    FDetails: record
      MouseX, MouseY: Integer;
      Button: TMouseButton;
      Key: Word;
    end;
    FLeftBlackBand: Integer;
    FTopBlackBand: Integer;
    FXScale, FYScale: Double;
  public
    property Details;
    property LeftBlackBand: Integer read FLeftBlackBand write FLeftBlackBand;
    property TopBlackBand: Integer read FTopBlackBand write FTopBlackBand;
    property XScale: Double read FXScale write FXScale;
    property YScale: Double read FYScale write FYScale;
    function GetAbsoluteXMouse: Integer;
    function GetAbsoluteYMouse: Integer;
    function GetRelativeXMouse: Double;
    function GetRelativeYMouse: Double;
    // ... additional methods as needed
  end;

  TState = class
  private
    FModal: TSurface;
  public
    procedure setModal(Surface: TSurface);
    function isScreen: Boolean;
    procedure toggleScreen;
    procedure hideAll;
    procedure showAll;
  end;

  // ---------------------------------------------------------------------------
  // Base Surface – equivalent to SDL_Surface + drawing routines
  // ---------------------------------------------------------------------------
  TSurface = class(TGraphicControl)
  private
    FRedraw: Boolean;
    FVisible: Boolean;
    FHidden: Boolean;
    FPalette: array[0..255] of TColor;
    FPaletteSet: Boolean;
    FCropRect: TRect;
    function GetPalette: Pointer;
  protected
    procedure SetRedraw(Value: Boolean);
    procedure Paint; override;
    procedure DrawContent; virtual;
    function Lock: Boolean; virtual;
    procedure Unlock; virtual;
    procedure SetPixel(X, Y: Integer; Color: TColor);
    function GetPixel(X, Y: Integer): TColor;
    procedure DrawRect(const Rect: TRect; Color: TColor);
    procedure DrawLine(X1, Y1, X2, Y2: Integer; Color: TColor);
    procedure Offset(Delta: Integer; BaseColor: TColor = 0);
    procedure OffsetBlock(Delta: Integer);
    procedure InvertColor(MidColor: TColor);
    procedure BlitNShade(Source: TSurface; DX, DY: Integer; Shade: Integer);
    procedure Copy(Source: TSurface);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InvalidateSurface; virtual;
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); virtual;
    function GetColorFromPalette(Index: Integer): TColor;
    procedure SetCropRect(const R: TRect);
    function GetCropRect: PRect;
    procedure Blit(Dest: TSurface); overload;
    procedure Blit(Dest: TCanvas; X, Y: Integer); overload;
    // properties
    property Redraw: Boolean read FRedraw write SetRedraw;
    property Visible: Boolean read FVisible write FVisible;
    property Hidden: Boolean read FHidden write FHidden;
    property Palette[Index: Integer]: TColor read GetColorFromPalette;
  end;

  // ---------------------------------------------------------------------------
  // InteractiveSurface – adds mouse/keyboard events and focus handling
  // ---------------------------------------------------------------------------
  TInteractiveSurface = class(TSurface)
  private
    FOnMouseDown: TMouseEvent;
    FOnMouseUp: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseClick: TMouseEvent;
    FOnMousePress: TMouseEvent;
    FOnMouseRelease: TMouseEvent;
    FOnKeyDown: TKeyEvent;
    FOnKeyPress: TKeyPressEvent;
    FOnKeyUp: TKeyEvent;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseLeave: TNotifyEvent;
    FIsFocused: Boolean;
    FIsPressed: Boolean;
    FIsHovered: Boolean;
    FButtonGroup: TList; // generic group for radio buttons
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Click; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    function IsButtonHandled(Button: TMouseButton): Boolean; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetFocus; virtual;
    procedure Unpress(State: TState);
    procedure ToggleInvert(Value: Boolean);
    // Event setters
    procedure OnMouseClick(AHandler: TNotifyEvent);
    procedure OnMousePress(AHandler: TNotifyEvent);
    procedure OnMouseRelease(AHandler: TNotifyEvent);
    procedure SetGroup(Group: TList);
    // properties
    property IsFocused: Boolean read FIsFocused;
    property IsPressed: Boolean read FIsPressed write FIsPressed;
    property IsHovered: Boolean read FIsHovered;
  end;

  // Base classes for common UI elements
  TTextHAlign = (alLeft, alCenter, alRight);
  TTextVAlign = (alTop, alMiddle, alBottom);

  TFont = class(Vcl.Graphics.TFont); // just alias for convenience

implementation

{ TAction }

function TAction.GetAbsoluteXMouse: Integer;
begin
  Result := FDetails.MouseX;
end;

function TAction.GetAbsoluteYMouse: Integer;
begin
  Result := FDetails.MouseY;
end;

function TAction.GetRelativeXMouse: Double;
begin
  Result := (FDetails.MouseX - FLeftBlackBand) / FXScale;
end;

function TAction.GetRelativeYMouse: Double;
begin
  Result := (FDetails.MouseY - FTopBlackBand) / FYScale;
end;

{ TState }

procedure TState.setModal(Surface: TSurface);
begin
  FModal := Surface;
end;

function TState.isScreen: Boolean;
begin
  Result := False; // simplified
end;

procedure TState.toggleScreen;
begin
  // simplified
end;

procedure TState.hideAll;
begin
  // simplified
end;

procedure TState.showAll;
begin
  // simplified
end;

{ TSurface }

constructor TSurface.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRedraw := True;
  FVisible := True;
  FHidden := False;
  FPaletteSet := False;
  FCropRect := Rect(0, 0, 0, 0);
  Width := 0;
  Height := 0;
  ControlStyle := ControlStyle + [csOpaque];
end;

destructor TSurface.Destroy;
begin
  inherited;
end;

procedure TSurface.SetRedraw(Value: Boolean);
begin
  FRedraw := Value;
  if FRedraw then Invalidate;
end;

procedure TSurface.Paint;
begin
  inherited;
  if FVisible and not FHidden then
    DrawContent;
end;

procedure TSurface.DrawContent;
begin
  // overridden in descendants
end;

function TSurface.Lock: Boolean;
begin
  Result := True; // Canvas is always locked implicitly
end;

procedure TSurface.Unlock;
begin
  // nothing
end;

procedure TSurface.SetPixel(X, Y: Integer; Color: TColor);
begin
  if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
    Canvas.Pixels[X, Y] := Color;
end;

function TSurface.GetPixel(X, Y: Integer): TColor;
begin
  if (X >= 0) and (X < Width) and (Y >= 0) and (Y < Height) then
    Result := Canvas.Pixels[X, Y]
  else
    Result := 0;
end;

procedure TSurface.DrawRect(const Rect: TRect; Color: TColor);
begin
  Canvas.Pen.Color := Color;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(Rect);
end;

procedure TSurface.DrawLine(X1, Y1, X2, Y2: Integer; Color: TColor);
begin
  Canvas.Pen.Color := Color;
  Canvas.MoveTo(X1, Y1);
  Canvas.LineTo(X2, Y2);
end;

procedure TSurface.Offset(Delta: Integer; BaseColor: TColor = 0);
var
  X, Y: Integer;
  C: TColor;
begin
  if not FPaletteSet then Exit;
  for Y := 0 to Height - 1 do
    for X := 0 to Width - 1 do
    begin
      C := Canvas.Pixels[X, Y];
      if C <> 0 then // skip transparent
        Canvas.Pixels[X, Y] := FPalette[ (C and $FF) + Delta ]; // simplistic
    end;
end;

procedure TSurface.OffsetBlock(Delta: Integer);
begin
  Offset(Delta);
end;

procedure TSurface.InvertColor(MidColor: TColor);
var
  X, Y: Integer;
  C: TColor;
begin
  for Y := 0 to Height - 1 do
    for X := 0 to Width - 1 do
    begin
      C := Canvas.Pixels[X, Y];
      if C <> 0 then
        Canvas.Pixels[X, Y] := MidColor + (MidColor - C); // simplistic invert
    end;
end;

procedure TSurface.BlitNShade(Source: TSurface; DX, DY: Integer; Shade: Integer);
begin
  // Simplified: just blit with offset
  Source.Blit(Canvas, DX, DY);
end;

procedure TSurface.Copy(Source: TSurface);
begin
  Canvas.Draw(0, 0, Source.Canvas);
end;

procedure TSurface.InvalidateSurface;
begin
  Redraw := True;
end;

procedure TSurface.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
var
  I: Integer;
begin
  for I := 0 to NumColors - 1 do
    if FirstColor + I <= 255 then
      FPalette[FirstColor + I] := Colors[I];
  FPaletteSet := True;
end;

function TSurface.GetColorFromPalette(Index: Integer): TColor;
begin
  if (Index >= 0) and (Index <= 255) then
    Result := FPalette[Index]
  else
    Result := 0;
end;

procedure TSurface.SetCropRect(const R: TRect);
begin
  FCropRect := R;
end;

function TSurface.GetCropRect: PRect;
begin
  Result := @FCropRect;
end;

procedure TSurface.Blit(Dest: TSurface);
begin
  Dest.Canvas.Draw(0, 0, Canvas);
end;

procedure TSurface.Blit(Dest: TCanvas; X, Y: Integer);
begin
  Dest.Draw(X, Y, Canvas);
end;

function TSurface.GetPalette: Pointer;
begin
  Result := @FPalette;
end;

{ TInteractiveSurface }

constructor TInteractiveSurface.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csClickEvents, csDoubleClicks];
  TabStop := True;
  FIsFocused := False;
  FIsPressed := False;
  FIsHovered := False;
  FButtonGroup := nil;
end;

destructor TInteractiveSurface.Destroy;
begin
  inherited;
end;

procedure TInteractiveSurface.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if IsButtonHandled(Button) then
  begin
    FIsPressed := True;
    if Assigned(FOnMouseDown) then FOnMouseDown(Self, Button, Shift, X, Y);
  end;
end;

procedure TInteractiveSurface.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if IsButtonHandled(Button) then
  begin
    FIsPressed := False;
    if Assigned(FOnMouseUp) then FOnMouseUp(Self, Button, Shift, X, Y);
  end;
end;

procedure TInteractiveSurface.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Assigned(FOnMouseMove) then FOnMouseMove(Self, Shift, X, Y);
end;

procedure TInteractiveSurface.Click;
begin
  inherited;
  if Assigned(FOnMouseClick) then FOnMouseClick(Self, mbLeft, [], Mouse.CursorPos.X - Left, Mouse.CursorPos.Y - Top);
end;

procedure TInteractiveSurface.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Assigned(FOnKeyDown) then FOnKeyDown(Self, Key, Shift);
end;

procedure TInteractiveSurface.KeyPress(var Key: Char);
begin
  inherited;
  if Assigned(FOnKeyPress) then FOnKeyPress(Self, Key);
end;

procedure TInteractiveSurface.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Assigned(FOnKeyUp) then FOnKeyUp(Self, Key, Shift);
end;

procedure TInteractiveSurface.DoEnter;
begin
  inherited;
  FIsFocused := True;
end;

procedure TInteractiveSurface.DoExit;
begin
  inherited;
  FIsFocused := False;
end;

function TInteractiveSurface.IsButtonHandled(Button: TMouseButton): Boolean;
begin
  Result := True; // default, override if needed
end;

procedure TInteractiveSurface.SetFocus;
begin
  if CanFocus then
    Windows.SetFocus(Handle);
end;

procedure TInteractiveSurface.Unpress(State: TState);
begin
  FIsPressed := False;
  Invalidate;
end;

procedure TInteractiveSurface.ToggleInvert(Value: Boolean);
begin
  // if needed
end;

procedure TInteractiveSurface.OnMouseClick(AHandler: TNotifyEvent);
begin
  FOnMouseClick := AHandler;
end;

procedure TInteractiveSurface.OnMousePress(AHandler: TNotifyEvent);
begin
  FOnMousePress := AHandler;
end;

procedure TInteractiveSurface.OnMouseRelease(AHandler: TNotifyEvent);
begin
  FOnMouseRelease := AHandler;
end;

procedure TInteractiveSurface.SetGroup(Group: TList);
begin
  FButtonGroup := Group;
end;

end.