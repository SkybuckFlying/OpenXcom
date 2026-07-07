unit Frame;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common;

type
  TFrame = class(TSurface)
  private
    FColor: TColor;
    FBg: TColor;
    FThickness: Integer;
    FContrast: Boolean;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetBorderColor(Color: TColor);
    procedure SetSecondaryColor(BG: TColor);
    function GetSecondaryColor: TColor;
    procedure SetHighContrast(Contrast: Boolean);
    procedure SetThickness(Thickness: Integer);
    procedure DrawContent; override;
  end;

implementation

uses
  Palette;

constructor TFrame.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FColor := 0;
  FBg := 0;
  FThickness := 5;
  FContrast := False;
end;

destructor TFrame.Destroy;
begin
  inherited;
end;

procedure TFrame.SetColor(Color: TColor);
begin
  FColor := Color;
  Redraw := True;
end;

function TFrame.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TFrame.SetBorderColor(Color: TColor);
begin
  SetColor(Color);
end;

procedure TFrame.SetSecondaryColor(BG: TColor);
begin
  FBg := BG;
  Redraw := True;
end;

function TFrame.GetSecondaryColor: TColor;
begin
  Result := FBg;
end;

procedure TFrame.SetHighContrast(Contrast: Boolean);
begin
  FContrast := Contrast;
  Redraw := True;
end;

procedure TFrame.SetThickness(Thickness: Integer);
begin
  FThickness := Thickness;
  Redraw := True;
end;

procedure TFrame.DrawContent;
var
  Rect: TRect;
  Color: TColor;
  I: Integer;
  Mul: Integer;
begin
  inherited;
  Rect := Bounds(0, 0, Width, Height);
  Mul := 1;
  if FContrast then Mul := 2;

  Color := FColor + ((1 + FThickness) * Mul) div 2;
  // Draw border
  for I := 0 to FThickness - 1 do
  begin
    Canvas.Pen.Color := Color;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(Rect);
    if I < FThickness div 2 then
      Color := Color - 1 * Mul
    else
      Color := Color + 1 * Mul;
    InflateRect(Rect, -1, -1);
    if Rect.Width < 2 then Rect.Width := 1;
    if Rect.Height < 2 then Rect.Height := 1;
  end;
  // Fill inner background
  Canvas.Brush.Color := FBg;
  Canvas.FillRect(Rect);
end;

end.