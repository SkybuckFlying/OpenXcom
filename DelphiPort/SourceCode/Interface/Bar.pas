unit Bar;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common;

type
  TBar = class(TSurface)
  private
    FColor: TColor;
    FColor2: TColor;
    FBorderColor: TColor;
    FScale: Double;
    FMax: Double;
    FValue: Double;
    FValue2: Double;
    FSecondOnTop: Boolean;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetSecondaryColor(Color: TColor);
    function GetSecondaryColor: TColor;
    procedure SetScale(Scale: Double);
    function GetScale: Double;
    procedure SetMax(Max: Double);
    function GetMax: Double;
    procedure SetValue(Value: Double);
    function GetValue: Double;
    procedure SetValue2(Value: Double);
    function GetValue2: Double;
    procedure SetSecondValueOnTop(OnTop: Boolean);
    procedure DrawContent; override;
    procedure SetBorderColor(Color: TColor);
  end;

implementation

constructor TBar.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FColor := 0;
  FColor2 := 0;
  FBorderColor := 0;
  FScale := 0;
  FMax := 0;
  FValue := 0;
  FValue2 := 0;
  FSecondOnTop := True;
end;

destructor TBar.Destroy;
begin
  inherited;
end;

procedure TBar.SetColor(Color: TColor);
begin
  FColor := Color;
  Redraw := True;
end;

function TBar.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TBar.SetSecondaryColor(Color: TColor);
begin
  FColor2 := Color;
  Redraw := True;
end;

function TBar.GetSecondaryColor: TColor;
begin
  Result := FColor2;
end;

procedure TBar.SetScale(Scale: Double);
begin
  FScale := Scale;
  Redraw := True;
end;

function TBar.GetScale: Double;
begin
  Result := FScale;
end;

procedure TBar.SetMax(Max: Double);
begin
  FMax := Max;
  Redraw := True;
end;

function TBar.GetMax: Double;
begin
  Result := FMax;
end;

procedure TBar.SetValue(Value: Double);
begin
  FValue := Max(0, Value);
  Redraw := True;
end;

function TBar.GetValue: Double;
begin
  Result := FValue;
end;

procedure TBar.SetValue2(Value: Double);
begin
  FValue2 := Max(0, Value);
  Redraw := True;
end;

function TBar.GetValue2: Double;
begin
  Result := FValue2;
end;

procedure TBar.SetSecondValueOnTop(OnTop: Boolean);
begin
  FSecondOnTop := OnTop;
end;

procedure TBar.SetBorderColor(Color: TColor);
begin
  FBorderColor := Color;
end;

procedure TBar.DrawContent;
var
  Rect: TRect;
  W: Integer;
begin
  inherited;
  // Draw border
  Rect := Bounds(0, 0, Width, Height);
  if FBorderColor <> 0 then
    Canvas.Pen.Color := FBorderColor
  else
    Canvas.Pen.Color := FColor + 4; // simplified palette offset
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(Rect);

  // Fill inner background
  Canvas.Brush.Color := 0;
  Canvas.FillRect(Rect(1, 1, Width-1, Height-1));

  // Draw values
  if FSecondOnTop then
  begin
    W := Round(FScale * FValue);
    Canvas.Brush.Color := FColor;
    Canvas.FillRect(Rect(1, 1, 1 + W, Height-1));
    W := Round(FScale * FValue2);
    Canvas.Brush.Color := FColor2;
    Canvas.FillRect(Rect(1, 1, 1 + W, Height-1));
  end
  else
  begin
    W := Round(FScale * FValue2);
    Canvas.Brush.Color := FColor2;
    Canvas.FillRect(Rect(1, 1, 1 + W, Height-1));
    W := Round(FScale * FValue);
    Canvas.Brush.Color := FColor;
    Canvas.FillRect(Rect(1, 1, 1 + W, Height-1));
  end;
end;

end.