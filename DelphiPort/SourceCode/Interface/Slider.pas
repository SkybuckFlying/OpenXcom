unit Slider;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, TextButton, Text, Frame, Font, Language;

type
  TSlider = class(TInteractiveSurface)
  private
    FFrame: TFrame;
    FTxtMinus: TText;
    FTxtPlus: TText;
    FButton: TTextButton;
    FPos: Double;
    FMin: Integer;
    FMax: Integer;
    FValue: Integer;
    FPressed: Boolean;
    FChange: TNotifyEvent;
    FThickness: Integer;
    FTextness: Integer;
    FMinX: Integer;
    FMaxX: Integer;
    FOffsetX: Integer;
    procedure SetPosition(Pos: Double);
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetX(X: Integer); override;
    procedure SetY(Y: Integer); override;
    procedure InitText(Big, Small: TFont; Lang: TLanguage);
    procedure SetHighContrast(Contrast: Boolean);
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure Handle(Action: TAction; State: TState);
    procedure SetRange(Min, Max: Integer);
    procedure SetValue(Value: Integer);
    function GetValue: Integer;
    procedure Blit(Dest: TSurface); override;
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure OnChange(Handler: TNotifyEvent);
  end;

implementation

uses
  Math;

constructor TSlider.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FPos := 0.0;
  FMin := 0;
  FMax := 100;
  FPressed := False;
  FOffsetX := 0;
  FThickness := 5;
  FTextness := 8;

  FTxtMinus := TText.Create(FTextness, Height - 2, AX - 1, AY, Self);
  FTxtPlus := TText.Create(FTextness, Height - 2, AX + Width - FTextness, AY, Self);
  FFrame := TFrame.Create(Width - FTextness*2, FThickness, AX + FTextness, AY + (Height - FThickness) div 2, Self);
  FFrame.SetThickness(FThickness);
  FButton := TTextButton.Create(10, Height, AX, AY, Self);

  FTxtMinus.SetAlign(alCenter);
  FTxtMinus.SetVerticalAlign(alMiddle);
  FTxtMinus.SetText('-');
  FTxtPlus.SetAlign(alCenter);
  FTxtPlus.SetVerticalAlign(alMiddle);
  FTxtPlus.SetText('+');

  FMinX := FFrame.Left;
  FMaxX := FFrame.Left + FFrame.Width - FButton.Width;
  SetValue(0);
end;

destructor TSlider.Destroy;
begin
  FTxtMinus.Free;
  FTxtPlus.Free;
  FFrame.Free;
  FButton.Free;
  inherited;
end;

procedure TSlider.SetX(X: Integer);
begin
  inherited SetX(X);
  FTxtMinus.Left := X - 1;
  FTxtPlus.Left := X + Width - FTextness;
  FFrame.Left := X + FTextness;
  FMinX := FFrame.Left;
  FMaxX := FFrame.Left + FFrame.Width - FButton.Width;
  SetValue(FValue);
end;

procedure TSlider.SetY(Y: Integer);
begin
  inherited SetY(Y);
  FTxtMinus.Top := Y;
  FTxtPlus.Top := Y;
  FFrame.Top := Y + (Height - FThickness) div 2;
  FButton.Top := Y;
end;

procedure TSlider.InitText(Big, Small: TFont; Lang: TLanguage);
begin
  FTxtMinus.InitText(Big, Small, Lang);
  FTxtPlus.InitText(Big, Small, Lang);
  FButton.InitText(Big, Small, Lang);
end;

procedure TSlider.SetHighContrast(Contrast: Boolean);
begin
  FTxtMinus.SetHighContrast(Contrast);
  FTxtPlus.SetHighContrast(Contrast);
  FFrame.SetHighContrast(Contrast);
  FButton.SetHighContrast(Contrast);
end;

procedure TSlider.SetColor(Color: TColor);
begin
  FTxtMinus.SetColor(Color);
  FTxtPlus.SetColor(Color);
  FFrame.SetColor(Color);
  FButton.SetColor(Color);
end;

function TSlider.GetColor: TColor;
begin
  Result := FButton.GetColor;
end;

procedure TSlider.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  FTxtMinus.SetPalette(Colors, FirstColor, NumColors);
  FTxtPlus.SetPalette(Colors, FirstColor, NumColors);
  FFrame.SetPalette(Colors, FirstColor, NumColors);
  FButton.SetPalette(Colors, FirstColor, NumColors);
end;

procedure TSlider.Handle(Action: TAction; State: TState);
var
  CursorX, ButtonX: Integer;
  Pos: Double;
begin
  inherited Handle(Action, State);
  if FPressed and ((Action.Details.Button = mbLeft) or (Action.Details.MouseX <> -1)) then
  begin
    CursorX := Action.GetAbsoluteXMouse;
    ButtonX := EnsureRange(CursorX + FOffsetX, FMinX, FMaxX);
    Pos := (ButtonX - FMinX) / (FMaxX - FMinX);
    FValue := FMin + Round((FMax - FMin) * Pos);
    SetValue(FValue);
    if Assigned(FChange) then FChange(Self);
  end;
end;

procedure TSlider.SetPosition(Pos: Double);
begin
  FPos := Pos;
  FButton.Left := Round(FMinX + (FMaxX - FMinX) * FPos);
end;

procedure TSlider.SetRange(Min, Max: Integer);
begin
  FMin := Min;
  FMax := Max;
  SetValue(FValue);
end;

procedure TSlider.SetValue(Value: Integer);
begin
  if FMin < FMax then
    FValue := EnsureRange(Value, FMin, FMax)
  else
    FValue := EnsureRange(Value, FMax, FMin);
  FPos := (FValue - FMin) / (FMax - FMin);
  SetPosition(FPos);
end;

function TSlider.GetValue: Integer;
begin
  Result := FValue;
end;

procedure TSlider.Blit(Dest: TSurface);
begin
  inherited Blit(Dest);
  if Visible and not Hidden then
  begin
    FTxtMinus.Blit(Dest);
    FTxtPlus.Blit(Dest);
    FFrame.Blit(Dest);
    FButton.Blit(Dest);
  end;
end;

procedure TSlider.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FPressed := True;
    if (X >= FButton.Left) and (X < FButton.Left + FButton.Width) then
      FOffsetX := FButton.Left - X
    else
      FOffsetX := -FButton.Width div 2;
  end;
end;

procedure TSlider.MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FPressed := False;
    FOffsetX := 0;
  end;
end;

procedure TSlider.OnChange(Handler: TNotifyEvent);
begin
  FChange := Handler;
end;

end.