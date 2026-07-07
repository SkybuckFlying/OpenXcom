unit Window;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, Timer, State, Sound;

type
  TWindowPopup = (wpNone, wpHorizontal, wpVertical, wpBoth);

  TWindow = class(TSurface)
  private
    const
      POPUP_SPEED = 0.05;
    FDX, FDY: Integer;
    FBg: TSurface;
    FColor: TColor;
    FPopup: TWindowPopup;
    FPopupStep: Double;
    FTimer: TTimer;
    FState: TState;
    FContrast: Boolean;
    FScreen: Boolean;
    FThinBorder: Boolean;
    class var SoundPopup: array[0..2] of TObject;
    procedure Popup(Sender: TObject);
  public
    constructor Create(State: TState; AWidth, AHeight, AX, AY: Integer; Popup: TWindowPopup = wpNone; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetBackground(BG: TSurface);
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetHighContrast(Contrast: Boolean);
    procedure Think;
    procedure DrawContent; override;
    procedure SetDX(DX: Integer);
    procedure SetDY(DY: Integer);
    procedure SetThinBorder;
  end;

implementation

uses
  Math, RNG;

constructor TWindow.Create(State: TState; AWidth, AHeight, AX, AY: Integer; Popup: TWindowPopup = wpNone; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FDX := -AX;
  FDY := -AY;
  FColor := 0;
  FPopup := Popup;
  FPopupStep := 0.0;
  FState := State;
  FContrast := False;
  FScreen := False;
  FThinBorder := False;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 10;
  FTimer.OnTimer := Popup;

  if Popup = wpNone then
    FPopupStep := 1.0
  else
  begin
    Hidden := True;
    FTimer.Enabled := True;
    if FState <> nil then
    begin
      FScreen := FState.IsScreen;
      if FScreen then FState.ToggleScreen;
    end;
  end;
end;

destructor TWindow.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TWindow.SetBackground(BG: TSurface);
begin
  FBg := BG;
  Redraw := True;
end;

procedure TWindow.SetColor(Color: TColor);
begin
  FColor := Color;
  Redraw := True;
end;

function TWindow.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TWindow.SetHighContrast(Contrast: Boolean);
begin
  FContrast := Contrast;
  Redraw := True;
end;

procedure TWindow.Popup(Sender: TObject);
begin
  if FPopupStep = 0.0 then
  begin
    // play sound
  end;
  if FPopupStep < 1.0 then
    FPopupStep := FPopupStep + POPUP_SPEED
  else
  begin
    if FScreen then FState.ToggleScreen;
    FState.ShowAll;
    FPopupStep := 1.0;
    FTimer.Enabled := False;
  end;
  Redraw := True;
end;

procedure TWindow.Think;
begin
  inherited;
  if Hidden and (FPopupStep < 1.0) then
  begin
    FState.HideAll;
    Hidden := False;
  end;
  if FTimer.Enabled then
    Popup(Self);
end;

procedure TWindow.DrawContent;
var
  Rect: TRect;
  Color: TColor;
  I: Integer;
  Mul: Integer;
begin
  inherited;
  Rect := Bounds(0, 0, Width, Height);
  if (FPopup = wpHorizontal) or (FPopup = wpBoth) then
  begin
    Rect.Left := Round((Width - Width * FPopupStep) / 2);
    Rect.Width := Round(Width * FPopupStep);
  end;
  if (FPopup = wpVertical) or (FPopup = wpBoth) then
  begin
    Rect.Top := Round((Height - Height * FPopupStep) / 2);
    Rect.Height := Round(Height * FPopupStep);
  end;

  Mul := 1;
  if FContrast then Mul := 2;
  if FThinBorder then
  begin
    Color := FColor + 1 * Mul;
    for I := 0 to 4 do
    begin
      Canvas.Pen.Color := Color;
      Canvas.Brush.Style := bsClear;
      Canvas.Rectangle(Rect);
      if (I mod 2) = 0 then
      begin
        Inc(Rect.Left);
        Inc(Rect.Top);
      end;
      Dec(Rect.Width);
      Dec(Rect.Height);
      case I of
        0: begin
             Color := FColor + 5 * Mul;
             Canvas.Pixels[Rect.Width, 0] := Color;
           end;
        1: Color := FColor + 2 * Mul;
        2: begin
             Color := FColor + 4 * Mul;
             Canvas.Pixels[Rect.Width+1, 1] := Color;
           end;
        3: Color := FColor + 3 * Mul;
      end;
    end;
  end
  else
  begin
    Color := FColor + 3 * Mul;
    for I := 0 to 4 do
    begin
      Canvas.Pen.Color := Color;
      Canvas.Brush.Style := bsClear;
      Canvas.Rectangle(Rect);
      if I < 2 then
        Color := Color - 1 * Mul
      else
        Color := Color + 1 * Mul;
      InflateRect(Rect, -1, -1);
      if Rect.Width < 2 then Rect.Width := 1;
      if Rect.Height < 2 then Rect.Height := 1;
    end;
  end;

  // Draw background
  if FBg <> nil then
  begin
    FBg.GetCropRect.Left := Rect.Left - FDX;
    FBg.GetCropRect.Top := Rect.Top - FDY;
    FBg.GetCropRect.Width := Rect.Width;
    FBg.GetCropRect.Height := Rect.Height;
    FBg.Left := Rect.Left;
    FBg.Top := Rect.Top;
    FBg.Blit(Self);
  end;
end;

procedure TWindow.SetDX(DX: Integer);
begin
  FDX := DX;
end;

procedure TWindow.SetDY(DY: Integer);
begin
  FDY := DY;
end;

procedure TWindow.SetThinBorder;
begin
  FThinBorder := True;
end;

end.