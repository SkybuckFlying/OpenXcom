unit NumberText;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common;

type
  TNumberText = class(TSurface)
  private
    FValue: Integer;
    FChars: array[0..9] of TSurface;
    FBorderedChars: array[0..9] of TSurface;
    FBordered: Boolean;
    FColor: TColor;
    procedure BuildChars;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetValue(Value: Integer);
    function GetValue: Integer;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure DrawContent; override;
    procedure SetBordered(Bordered: Boolean);
  end;

implementation

constructor TNumberText.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FValue := 0;
  FBordered := False;
  FColor := 0;
  BuildChars;
end;

destructor TNumberText.Destroy;
var
  I: Integer;
begin
  for I := 0 to 9 do
  begin
    FChars[I].Free;
    FBorderedChars[I].Free;
  end;
  inherited;
end;

procedure TNumberText.BuildChars;
var
  I: Integer;
begin
  // Simplified: create small 3x5 bitmaps for each digit
  for I := 0 to 9 do
  begin
    FChars[I] := TSurface.Create(Self);
    FChars[I].Width := 3;
    FChars[I].Height := 5;
    // Set pixels for digit I (hardcoded for brevity)
    FBorderedChars[I] := TSurface.Create(Self);
    FBorderedChars[I].Width := 5;
    FBorderedChars[I].Height := 7;
    // copy with border
  end;
end;

procedure TNumberText.SetValue(Value: Integer);
begin
  FValue := Value;
  Redraw := True;
end;

function TNumberText.GetValue: Integer;
begin
  Result := FValue;
end;

procedure TNumberText.SetColor(Color: TColor);
begin
  FColor := Color;
  Redraw := True;
end;

function TNumberText.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TNumberText.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
var
  I: Integer;
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  for I := 0 to 9 do
  begin
    FChars[I].SetPalette(Colors, FirstColor, NumColors);
    FBorderedChars[I].SetPalette(Colors, FirstColor, NumColors);
  end;
end;

procedure TNumberText.DrawContent;
var
  S: string;
  I: Integer;
  X, Y: Integer;
begin
  inherited;
  S := IntToStr(FValue);
  X := 0;
  Y := 0;
  for I := 1 to Length(S) do
  begin
    if FBordered then
      FBorderedChars[Ord(S[I]) - Ord('0')].Blit(Canvas, X, Y)
    else
      FChars[Ord(S[I]) - Ord('0')].Blit(Canvas, X, Y);
    Inc(X, 4); // spacing
  end;
  // Offset by color (simple tint)
  // not implemented
end;

procedure TNumberText.SetBordered(Bordered: Boolean);
begin
  FBordered := Bordered;
end;

end.