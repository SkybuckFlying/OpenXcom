unit Cursor;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, Action;

type
  TCursor = class(TSurface)
  private
    FColor: TColor;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure Handle(Action: TAction);
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure DrawContent; override;
  end;

implementation

uses
  Winapi.Windows, Math;

constructor TCursor.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FColor := 0;
end;

destructor TCursor.Destroy;
begin
  inherited;
end;

procedure TCursor.Handle(Action: TAction);
begin
  if Action.Details.MouseX <> -1 then
  begin
    Left := Round((Action.Details.MouseX - Action.LeftBlackBand) / Action.XScale);
    Top := Round((Action.Details.MouseY - Action.TopBlackBand) / Action.YScale);
  end;
end;

procedure TCursor.SetColor(Color: TColor);
begin
  FColor := Color;
  Redraw := True;
end;

function TCursor.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TCursor.DrawContent;
var
  X1, Y1, X2, Y2, I: Integer;
  Color: TColor;
begin
  inherited;
  Color := FColor;
  X1 := 0; Y1 := 0; X2 := Width - 1; Y2 := Height - 1;
  for I := 0 to 3 do
  begin
    DrawLine(X1, Y1, X1, Y2, Color);
    DrawLine(X1, Y1, X2, Width - 1, Color);
    Inc(X1);
    Inc(Y1, 2);
    Dec(Y2);
    Dec(X2);
    Color := Color + 1;
  end;
  SetPixel(4, 8, Color - 1);
end;

end.