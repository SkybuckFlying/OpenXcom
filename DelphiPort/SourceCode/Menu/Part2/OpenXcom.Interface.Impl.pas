unit OpenXcom.Interface.Impl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SDL2, OpenXcom.Interface, OpenXcom.Engine;

type
  { TSurface base implementation }
  TSurfaceImpl = class(TSurface)
  protected
    FSurface: PSDL_Surface;
    FVisible: Boolean;
    FX, FY, FWidth, FHeight: Integer;
    FColor: Byte;
    FHighContrast: Boolean;
  public
    constructor Create(AWidth, AHeight: Integer; AX, AY: Integer);
    destructor Destroy; override;
    procedure SetVisible(AVisible: Boolean);
    function GetVisible: Boolean;
    procedure SetX(AX: Integer);
    procedure SetY(AY: Integer);
    function GetX: Integer;
    function GetY: Integer;
    procedure SetWidth(AWidth: Integer);
    procedure SetHeight(AHeight: Integer);
    procedure SetColor(AColor: Byte);
    procedure SetHighContrast(AHigh: Boolean);
    procedure BlitTo(Dest: PSDL_Surface; DX, DY: Integer); virtual;
  end;

  { TWindow }
  TWindowImpl = class(TSurfaceImpl, TWindow)
  private
    FBackground: TSurface;
  public
    procedure SetBackground(ABg: TSurface);
  end;

  { TText }
  TTextImpl = class(TSurfaceImpl, TText)
  private
    FText: string;
    FFont: TFont;
    FAlign, FVAlign: Integer;
    FWordWrap: Boolean;
    FBig: Boolean;
    procedure Render;
  public
    procedure SetText(const AText: string);
    function GetText: string;
    procedure SetAlign(AAlign: Integer);
    procedure SetVerticalAlign(AVAlign: Integer);
    procedure SetWordWrap(AWrap: Boolean);
    procedure SetBig(ABig: Boolean);
    procedure SetFont(AFont: TFont);
    function GetTextWidth: Integer;
    function GetTextHeight: Integer;
  end;

  { TTextButton }
  TTextButtonImpl = class(TTextImpl, TTextButton)
  private
    FOnClick: TNotifyEvent;
    FGroup: TTextButton;
    FPressed: Boolean;
    FSoundPress: TSound;
  public
    procedure OnMouseClick(AEvent: TNotifyEvent);
    procedure OnKeyboardPress(AEvent: TNotifyEvent);
    procedure SetGroup(var Group: TTextButton);
    procedure SetPressed(APressed: Boolean);
    function GetPressed: Boolean;
    procedure SetTooltip(const ATooltip: string);
  end;

  { TToggleTextButton }
  TToggleTextButtonImpl = class(TTextButtonImpl, TToggleTextButton)
  public
    property Pressed: Boolean read GetPressed write SetPressed;
  end;

  { TTextList }
  TTextListImpl = class(TSurfaceImpl, TTextList)
  private
    FColumns: array of Integer;
    FRows: TStringList;
    FSelectedRow: Integer;
    FScrollPos: Integer;
    FColorNormal, FColorSecondary, FColorScrollbar: Byte;
    FArrowColumn: Integer;
  public
    constructor Create(AWidth, AHeight: Integer; AX, AY: Integer);
    destructor Destroy; override;
    procedure SetColumns(Count: Integer; const Widths: array of Integer);
    procedure AddRow(Count: Integer; const Texts: array of string);
    procedure ClearList;
    procedure SetCellText(Row, Col: Integer; const AText: string);
    procedure SetCellColor(Row, Col: Integer; AColor: Byte);
    procedure SetRowColor(Row: Integer; AColor: Byte);
    procedure SetSelectable(ASelectable: Boolean);
    procedure SetBackground(AWindow: TWindow);
    procedure SetMargin(AMargin: Integer);
    procedure SetArrowColumn(ACol, AType: Integer);
    procedure SetColor(AColor: Byte);
    procedure SetSecondaryColor(AColor: Byte);
    function GetSecondaryColor: Byte;
    function GetSelectedRow: Integer;
    function GetArrowsLeftEdge: Integer;
    function GetArrowsRightEdge: Integer;
    function GetScroll: Integer;
    procedure ScrollTo(APos: Integer);
    function GetVisibleRows: Integer;
    function GetNumTextLines(Row: Integer): Integer;
    function GetTextHeight(Row: Integer): Integer;
    function GetRowY(Row: Integer): Integer;
    procedure SetScrolling(AScrolling: Boolean);
    procedure OnMouseClick(AEvent: TNotifyEvent);
    procedure OnLeftArrowClick(AEvent: TNotifyEvent);
    procedure OnRightArrowClick(AEvent: TNotifyEvent);
    procedure OnMousePress(AEvent: TNotifyEvent);
    procedure OnMouseOver(AEvent: TNotifyEvent);
    procedure OnMouseOut(AEvent: TNotifyEvent);
    procedure OnMouseIn(AEvent: TNotifyEvent);
  end;

  { TArrowButton }
  TArrowButtonImpl = class(TSurfaceImpl, TArrowButton)
  private
    FShape: Integer;
  public
    procedure SetShape(AShape: Integer);
    procedure OnMouseClick(AEvent: TNotifyEvent);
  end;

  { TComboBox }
  TComboBoxImpl = class(TSurfaceImpl, TComboBox)
  private
    FOptions: TStringList;
    FSelected: Integer;
    FOnChange: TNotifyEvent;
    FListVisible: Boolean;
  public
    constructor Create(AOwner: TState; AWidth, AHeight: Integer; AX, AY: Integer);
    destructor Destroy; override;
    procedure SetOptions(const AOptions: TStringList; ATranslate: Boolean = False);
    procedure SetSelected(AIndex: Integer);
    function GetSelected: Integer;
    procedure SetTooltip(const ATooltip: string);
    procedure OnChange(AEvent: TNotifyEvent);
    procedure OnMouseIn(AEvent: TNotifyEvent);
    procedure OnMouseOut(AEvent: TNotifyEvent);
    procedure OnListMouseIn(AEvent: TNotifyEvent);
    procedure OnListMouseOut(AEvent: TNotifyEvent);
    procedure OnListMouseOver(AEvent: TNotifyEvent);
    function GetHoveredListIdx: Integer;
  end;

  { TSlider }
  TSliderImpl = class(TSurfaceImpl, TSlider)
  private
    FMin, FMax, FValue: Integer;
    FOnChange, FOnRelease: TNotifyEvent;
  public
    procedure SetRange(AMin, AMax: Integer);
    procedure SetValue(AValue: Integer);
    function GetValue: Integer;
    procedure SetTooltip(const ATooltip: string);
    procedure OnChange(AEvent: TNotifyEvent);
    procedure OnMouseRelease(AEvent: TNotifyEvent);
    procedure OnMouseIn(AEvent: TNotifyEvent);
    procedure OnMouseOut(AEvent: TNotifyEvent);
  end;

  { TFrame }
  TFrameImpl = class(TSurfaceImpl, TFrame)
  private
    FThickness: Integer;
  public
    procedure SetThickness(AThick: Integer);
  end;

  { TTextEdit }
  TTextEditImpl = class(TSurfaceImpl, TTextEdit)
  private
    FText: string;
    FConstraint: Integer;
    FOnChange: TNotifyEvent;
    FOnKeyPress: TKeyEvent;
    FFocused: Boolean;
  public
    procedure SetText(const AText: string);
    function GetText: string;
    procedure SetConstraint(AConstraint: Integer);
    procedure SetVisible(AVisible: Boolean);
    procedure SetFocus(AFocus: Boolean; ARedraw: Boolean);
    function IsFocused: Boolean;
    procedure OnChange(AEvent: TNotifyEvent);
    procedure OnKeyboardPress(AEvent: TNotifyEvent);
    procedure SetTooltip(const ATooltip: string);
    procedure SetColor(AColor: Byte);
  end;

implementation

{ TSurfaceImpl }
constructor TSurfaceImpl.Create(AWidth, AHeight: Integer; AX, AY: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FX := AX;
  FY := AY;
  FSurface := SDL_CreateRGBSurface(0, AWidth, AHeight, 32, 0,0,0,0);
  FVisible := True;
  FColor := 0;
end;

destructor TSurfaceImpl.Destroy;
begin
  SDL_FreeSurface(FSurface);
  inherited;
end;

procedure TSurfaceImpl.SetVisible(AVisible: Boolean);
begin
  FVisible := AVisible;
end;

function TSurfaceImpl.GetVisible: Boolean;
begin
  Result := FVisible;
end;

procedure TSurfaceImpl.SetX(AX: Integer); begin FX := AX; end;
procedure TSurfaceImpl.SetY(AY: Integer); begin FY := AY; end;
function TSurfaceImpl.GetX: Integer; begin Result := FX; end;
function TSurfaceImpl.GetY: Integer; begin Result := FY; end;
procedure TSurfaceImpl.SetWidth(AWidth: Integer); begin FWidth := AWidth; end;
procedure TSurfaceImpl.SetHeight(AHeight: Integer); begin FHeight := AHeight; end;
procedure TSurfaceImpl.SetColor(AColor: Byte); begin FColor := AColor; end;
procedure TSurfaceImpl.SetHighContrast(AHigh: Boolean); begin FHighContrast := AHigh; end;
procedure TSurfaceImpl.BlitTo(Dest: PSDL_Surface; DX, DY: Integer); begin end;

{ TWindowImpl }
procedure TWindowImpl.SetBackground(ABg: TSurface);
begin
  FBackground := ABg;
end;

{ TTextImpl }
procedure TTextImpl.SetText(const AText: string);
begin
  FText := AText;
  Render;
end;

function TTextImpl.GetText: string;
begin
  Result := FText;
end;

procedure TTextImpl.SetAlign(AAlign: Integer); begin FAlign := AAlign; end;
procedure TTextImpl.SetVerticalAlign(AVAlign: Integer); begin FVAlign := AVAlign; end;
procedure TTextImpl.SetWordWrap(AWrap: Boolean); begin FWordWrap := AWrap; end;
procedure TTextImpl.SetBig(ABig: Boolean); begin FBig := ABig; end;
procedure TTextImpl.SetFont(AFont: TFont); begin FFont := AFont; end;
function TTextImpl.GetTextWidth: Integer; begin Result := 0; end;
function TTextImpl.GetTextHeight: Integer; begin Result := 0; end;
procedure TTextImpl.Render; begin end;

{ TTextButtonImpl }
procedure TTextButtonImpl.OnMouseClick(AEvent: TNotifyEvent); begin FOnClick := AEvent; end;
procedure TTextButtonImpl.OnKeyboardPress(AEvent: TNotifyEvent); begin end;
procedure TTextButtonImpl.SetGroup(var Group: TTextButton); begin Group := Self; end;
procedure TTextButtonImpl.SetPressed(APressed: Boolean); begin FPressed := APressed; end;
function TTextButtonImpl.GetPressed: Boolean; begin Result := FPressed; end;
procedure TTextButtonImpl.SetTooltip(const ATooltip: string); begin end;

{ TToggleTextButtonImpl } // no extra code

{ TTextListImpl }
constructor TTextListImpl.Create(AWidth, AHeight: Integer; AX, AY: Integer);
begin
  inherited;
  FRows := TStringList.Create;
  FSelectedRow := -1;
  FScrollPos := 0;
  FColorNormal := 0;
  FColorSecondary := 1;
  FColorScrollbar := 2;
end;

destructor TTextListImpl.Destroy;
begin
  FRows.Free;
  inherited;
end;

procedure TTextListImpl.SetColumns(Count: Integer; const Widths: array of Integer);
begin
  SetLength(FColumns, Count);
  for var i := 0 to Count-1 do FColumns[i] := Widths[i];
end;

procedure TTextListImpl.AddRow(Count: Integer; const Texts: array of string);
var
  S: string;
  i: Integer;
begin
  S := '';
  for i := 0 to Count-1 do
  begin
    if i > 0 then S := S + #9;
    S := S + Texts[i];
  end;
  FRows.Add(S);
end;

procedure TTextListImpl.ClearList;
begin
  FRows.Clear;
end;

procedure TTextListImpl.SetCellText(Row, Col: Integer; const AText: string);
var
  S: string;
  Parts: TStringList;
begin
  if (Row < 0) or (Row >= FRows.Count) then Exit;
  S := FRows[Row];
  Parts := TStringList.Create;
  try
    Parts.Delimiter := #9;
    Parts.DelimitedText := S;
    if Col < Parts.Count then Parts[Col] := AText;
    FRows[Row] := Parts.DelimitedText;
  finally
    Parts.Free;
  end;
end;

procedure TTextListImpl.SetCellColor(Row, Col: Integer; AColor: Byte); begin end;
procedure TTextListImpl.SetRowColor(Row: Integer; AColor: Byte); begin end;
procedure TTextListImpl.SetSelectable(ASelectable: Boolean); begin end;
procedure TTextListImpl.SetBackground(AWindow: TWindow); begin end;
procedure TTextListImpl.SetMargin(AMargin: Integer); begin end;
procedure TTextListImpl.SetArrowColumn(ACol, AType: Integer); begin FArrowColumn := ACol; end;
procedure TTextListImpl.SetColor(AColor: Byte); begin FColorNormal := AColor; end;
procedure TTextListImpl.SetSecondaryColor(AColor: Byte); begin FColorSecondary := AColor; end;
function TTextListImpl.GetSecondaryColor: Byte; begin Result := FColorSecondary; end;
function TTextListImpl.GetSelectedRow: Integer; begin Result := FSelectedRow; end;
function TTextListImpl.GetArrowsLeftEdge: Integer; begin Result := 0; end;
function TTextListImpl.GetArrowsRightEdge: Integer; begin Result := 0; end;
function TTextListImpl.GetScroll: Integer; begin Result := FScrollPos; end;
procedure TTextListImpl.ScrollTo(APos: Integer); begin FScrollPos := APos; end;
function TTextListImpl.GetVisibleRows: Integer; begin Result := 10; end;
function TTextListImpl.GetNumTextLines(Row: Integer): Integer; begin Result := 1; end;
function TTextListImpl.GetTextHeight(Row: Integer): Integer; begin Result := 12; end;
function TTextListImpl.GetRowY(Row: Integer): Integer; begin Result := Row * 12; end;
procedure TTextListImpl.SetScrolling(AScrolling: Boolean); begin end;
procedure TTextListImpl.OnMouseClick(AEvent: TNotifyEvent); begin end;
procedure TTextListImpl.OnLeftArrowClick(AEvent: TNotifyEvent); begin end;
procedure TTextListImpl.OnRightArrowClick(AEvent: TNotifyEvent); begin end;
procedure TTextListImpl.OnMousePress(AEvent: TNotifyEvent); begin end;
procedure TTextListImpl.OnMouseOver(AEvent: TNotifyEvent); begin end;
procedure TTextListImpl.OnMouseOut(AEvent: TNotifyEvent); begin end;
procedure TTextListImpl.OnMouseIn(AEvent: TNotifyEvent); begin end;

{ TArrowButtonImpl }
procedure TArrowButtonImpl.SetShape(AShape: Integer); begin FShape := AShape; end;
procedure TArrowButtonImpl.OnMouseClick(AEvent: TNotifyEvent); begin end;

{ TComboBoxImpl }
constructor TComboBoxImpl.Create(AOwner: TState; AWidth, AHeight: Integer; AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FOptions := TStringList.Create;
  FSelected := 0;
end;

destructor TComboBoxImpl.Destroy;
begin
  FOptions.Free;
  inherited;
end;

procedure TComboBoxImpl.SetOptions(const AOptions: TStringList; ATranslate: Boolean = False);
begin
  FOptions.Assign(AOptions);
end;

procedure TComboBoxImpl.SetSelected(AIndex: Integer);
begin
  FSelected := AIndex;
end;

function TComboBoxImpl.GetSelected: Integer;
begin
  Result := FSelected;
end;

procedure TComboBoxImpl.SetTooltip(const ATooltip: string); begin end;
procedure TComboBoxImpl.OnChange(AEvent: TNotifyEvent); begin FOnChange := AEvent; end;
procedure TComboBoxImpl.OnMouseIn(AEvent: TNotifyEvent); begin end;
procedure TComboBoxImpl.OnMouseOut(AEvent: TNotifyEvent); begin end;
procedure TComboBoxImpl.OnListMouseIn(AEvent: TNotifyEvent); begin end;
procedure TComboBoxImpl.OnListMouseOut(AEvent: TNotifyEvent); begin end;
procedure TComboBoxImpl.OnListMouseOver(AEvent: TNotifyEvent); begin end;
function TComboBoxImpl.GetHoveredListIdx: Integer; begin Result := -1; end;

{ TSliderImpl }
procedure TSliderImpl.SetRange(AMin, AMax: Integer);
begin
  FMin := AMin;
  FMax := AMax;
end;

procedure TSliderImpl.SetValue(AValue: Integer);
begin
  FValue := AValue;
end;

function TSliderImpl.GetValue: Integer;
begin
  Result := FValue;
end;

procedure TSliderImpl.SetTooltip(const ATooltip: string); begin end;
procedure TSliderImpl.OnChange(AEvent: TNotifyEvent); begin FOnChange := AEvent; end;
procedure TSliderImpl.OnMouseRelease(AEvent: TNotifyEvent); begin FOnRelease := AEvent; end;
procedure TSliderImpl.OnMouseIn(AEvent: TNotifyEvent); begin end;
procedure TSliderImpl.OnMouseOut(AEvent: TNotifyEvent); begin end;

{ TFrameImpl }
procedure TFrameImpl.SetThickness(AThick: Integer);
begin
  FThickness := AThick;
end;

{ TTextEditImpl }
procedure TTextEditImpl.SetText(const AText: string);
begin
  FText := AText;
end;

function TTextEditImpl.GetText: string;
begin
  Result := FText;
end;

procedure TTextEditImpl.SetConstraint(AConstraint: Integer);
begin
  FConstraint := AConstraint;
end;

procedure TTextEditImpl.SetVisible(AVisible: Boolean);
begin
  inherited;
end;

procedure TTextEditImpl.SetFocus(AFocus: Boolean; ARedraw: Boolean);
begin
  FFocused := AFocus;
end;

function TTextEditImpl.IsFocused: Boolean;
begin
  Result := FFocused;
end;

procedure TTextEditImpl.OnChange(AEvent: TNotifyEvent);
begin
  FOnChange := AEvent;
end;

procedure TTextEditImpl.OnKeyboardPress(AEvent: TNotifyEvent);
begin
  FOnKeyPress := AEvent;
end;

procedure TTextEditImpl.SetTooltip(const ATooltip: string); begin end;
procedure TTextEditImpl.SetColor(AColor: Byte); begin end;

end.