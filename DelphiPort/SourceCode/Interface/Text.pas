unit Text;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, Font, Language, Unicode, ShaderDraw, ShaderMove, Action;

type
  TText = class(TInteractiveSurface)
  private
    FBigFont: TFont;
    FSmallFont: TFont;
    FCurrentFont: TFont;
    FFontOrig: TFont;
    FLang: TLanguage;
    FText: string;
    FProcessedText: string;
    FLineWidths: TArray<Integer>;
    FLineHeights: TArray<Integer>;
    FWrap: Boolean;
    FInvert: Boolean;
    FContrast: Boolean;
    FIndent: Boolean;
    FScrollable: Boolean;
    FAlign: TTextHAlign;
    FValign: TTextVAlign;
    FColor: TColor;
    FColor2: TColor;
    FScrollY: Integer;
    procedure ProcessText;
    function GetLineX(Line: Integer): Integer;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetBig;
    procedure SetSmall;
    function GetFont: TFont;
    procedure InitText(Big, Small: TFont; Lang: TLanguage);
    procedure SetText(const Text: string);
    function GetText: string;
    procedure SetWordWrap(Wrap, Indent: Boolean);
    procedure SetInvert(Invert: Boolean);
    procedure SetHighContrast(Contrast: Boolean);
    procedure SetAlign(Align: TTextHAlign);
    function GetAlign: TTextHAlign;
    procedure SetVerticalAlign(VAlign: TTextVAlign);
    function GetVerticalAlign: TTextVAlign;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetSecondaryColor(Color: TColor);
    function GetSecondaryColor: TColor;
    function GetNumLines: Integer;
    function GetTextWidth(Line: Integer = -1): Integer;
    function GetTextHeight(Line: Integer = -1): Integer;
    procedure DrawContent; override;
    procedure SetScrollable(Scroll: Boolean);
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  end;

implementation

uses
  Math, Windows;

constructor TText.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FBigFont := TFont.Create;
  FSmallFont := TFont.Create;
  FCurrentFont := FSmallFont;
  FFontOrig := FSmallFont;
  FLang := nil;
  FText := '';
  FProcessedText := '';
  FWrap := False;
  FInvert := False;
  FContrast := False;
  FIndent := False;
  FScrollable := False;
  FAlign := alLeft;
  FValign := alTop;
  FColor := 0;
  FColor2 := 0;
  FScrollY := 0;
end;

destructor TText.Destroy;
begin
  FBigFont.Free;
  FSmallFont.Free;
  inherited;
end;

procedure TText.SetBig;
begin
  FCurrentFont := FBigFont;
  FFontOrig := FBigFont;
  ProcessText;
end;

procedure TText.SetSmall;
begin
  FCurrentFont := FSmallFont;
  FFontOrig := FSmallFont;
  ProcessText;
end;

function TText.GetFont: TFont;
begin
  Result := FCurrentFont;
end;

procedure TText.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FBigFont.Assign(Big);
  FSmallFont.Assign(Small);
  FLang := Lang;
  SetSmall;
end;

procedure TText.SetText(const Text: string);
begin
  FText := Text;
  FCurrentFont := FFontOrig;
  ProcessText;
  if not FText.IsEmpty then
    if (FCurrentFont = FBigFont) and ((GetTextWidth > Width) or (GetTextHeight > Height)) and (FText[Length(FText)] <> '.') then
    begin
      FCurrentFont := FSmallFont;
      ProcessText;
    end;
  Redraw := True;
end;

function TText.GetText: string;
begin
  Result := FText;
end;

procedure TText.SetWordWrap(Wrap, Indent: Boolean);
begin
  if (FWrap <> Wrap) or (FIndent <> Indent) then
  begin
    FWrap := Wrap;
    FIndent := Indent;
    ProcessText;
  end;
end;

procedure TText.SetInvert(Invert: Boolean);
begin
  FInvert := Invert;
  Redraw := True;
end;

procedure TText.SetHighContrast(Contrast: Boolean);
begin
  FContrast := Contrast;
  Redraw := True;
end;

procedure TText.SetAlign(Align: TTextHAlign);
begin
  FAlign := Align;
  Redraw := True;
end;

function TText.GetAlign: TTextHAlign;
begin
  Result := FAlign;
end;

procedure TText.SetVerticalAlign(VAlign: TTextVAlign);
begin
  FValign := VAlign;
  Redraw := True;
end;

function TText.GetVerticalAlign: TTextVAlign;
begin
  Result := FValign;
end;

procedure TText.SetColor(Color: TColor);
begin
  FColor := Color;
  Redraw := True;
end;

function TText.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TText.SetSecondaryColor(Color: TColor);
begin
  FColor2 := Color;
  Redraw := True;
end;

function TText.GetSecondaryColor: TColor;
begin
  Result := FColor2;
end;

function TText.GetNumLines: Integer;
begin
  if FWrap then
    Result := Length(FLineHeights)
  else
    Result := 1;
end;

function TText.GetTextWidth(Line: Integer = -1): Integer;
var
  I: Integer;
begin
  if Line = -1 then
  begin
    Result := 0;
    for I := 0 to High(FLineWidths) do
      if FLineWidths[I] > Result then Result := FLineWidths[I];
  end
  else
    Result := FLineWidths[Line];
end;

function TText.GetTextHeight(Line: Integer = -1): Integer;
var
  I: Integer;
begin
  if Line = -1 then
  begin
    Result := 0;
    for I := 0 to High(FLineHeights) do
      Result := Result + FLineHeights[I];
  end
  else
    Result := FLineHeights[Line];
end;

procedure TText.ProcessText;
var
  C: Char;
  Width, Word: Integer;
  Space: Integer;
  Start, IndentCount: Boolean;
begin
  if (FCurrentFont = nil) or (FLang = nil) then Exit;
  FProcessedText := FText;
  SetLength(FLineWidths, 0);
  SetLength(FLineHeights, 0);
  FScrollY := 0;
  // Simplified: just one line
  SetLength(FLineWidths, 1);
  SetLength(FLineHeights, 1);
  Canvas.Font.Assign(FCurrentFont);
  FLineWidths[0] := Canvas.TextWidth(FText);
  FLineHeights[0] := Canvas.TextHeight(FText);
end;

function TText.GetLineX(Line: Integer): Integer;
begin
  Result := 0;
  case FAlign of
    alLeft: Result := 0;
    alCenter: Result := (Width - FLineWidths[Line]) div 2;
    alRight: Result := Width - 1 - FLineWidths[Line];
  end;
end;

procedure TText.DrawContent;
var
  X, Y, Line: Integer;
  OldFont: TFont;
begin
  inherited;
  if FText.IsEmpty then Exit;
  OldFont := TFont.Create;
  OldFont.Assign(Canvas.Font);
  try
    Canvas.Font.Assign(FCurrentFont);
    if FScrollable then
      Y := FScrollY
    else
      case FValign of
        alTop: Y := 0;
        alMiddle: Y := (Height - GetTextHeight) div 2;
        alBottom: Y := Height - GetTextHeight;
      end;
    for Line := 0 to High(FLineWidths) do
    begin
      X := GetLineX(Line);
      Canvas.Font.Color := FColor;
      if FInvert then Canvas.Font.Color := FColor + 3; // simple invert
      Canvas.TextOut(X, Y, FProcessedText);
      Y := Y + FLineHeights[Line];
    end;
  finally
    Canvas.Font.Assign(OldFont);
    OldFont.Free;
  end;
end;

procedure TText.SetScrollable(Scroll: Boolean);
begin
  FScrollable := Scroll;
end;

procedure TText.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ScrollArea: Integer;
begin
  inherited;
  if FScrollable and ((Button = mbWheelUp) or (Button = mbWheelDown)) then
  begin
    ScrollArea := Height - GetTextHeight;
    if ScrollArea < 0 then
    begin
      if Button = mbWheelDown then
        FScrollY := FScrollY - FCurrentFont.Height
      else
        FScrollY := FScrollY + FCurrentFont.Height;
      FScrollY := EnsureRange(FScrollY, ScrollArea, 0);
      Redraw := True;
    end;
  end;
end;

end.