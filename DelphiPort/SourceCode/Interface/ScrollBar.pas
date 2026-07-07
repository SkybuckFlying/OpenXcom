unit ScrollBar;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, TextList;

type
  TScrollBar = class(TInteractiveSurface)
  private
    FList: TTextList;
    FColor: TColor;
    FPressed: Boolean;
    FContrast: Boolean;
    FTrack: TSurface;
    FThumb: TSurface;
    FThumbRect: TRect;
    FOffset: Integer;
    FBg: TSurface;
    procedure DrawTrack;
    procedure DrawThumb;
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetX(X: Integer); override;
    procedure SetY(Y: Integer); override;
    procedure SetHeight(AHeight: Integer); override;
    procedure SetColor(Color: TColor);
    function GetColor: TColor;
    procedure SetHighContrast(Contrast: Boolean);
    procedure SetTextList(List: TTextList);
    procedure SetBackground(BG: TSurface);
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure Blit(Dest: TSurface); override;
    procedure Handle(Action: TAction; State: TState);
    procedure MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawContent; override;
  end;

implementation

uses
  Math, Palette;

constructor TScrollBar.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FColor := 0;
  FPressed := False;
  FContrast := False;
  FOffset := 0;
  FList := nil;

  FTrack := TSurface.Create(Self);
  FTrack.Width := Width - 2;
  FTrack.Height := Height;
  FTrack.Left := AX + 1;
  FTrack.Top := AY;

  FThumb := TSurface.Create(Self);
  FThumb.Width := Width;
  FThumb.Height := Height;
  FThumb.Left := AX;
  FThumb.Top := AY;
  FThumbRect := Rect(0, 0, 0, 0);
end;

destructor TScrollBar.Destroy;
begin
  FTrack.Free;
  FThumb.Free;
  inherited;
end;

procedure TScrollBar.SetX(X: Integer);
begin
  inherited SetX(X);
  FTrack.Left := X + 1;
  FThumb.Left := X;
end;

procedure TScrollBar.SetY(Y: Integer);
begin
  inherited SetY(Y);
  FTrack.Top := Y;
  FThumb.Top := Y;
end;

procedure TScrollBar.SetHeight(AHeight: Integer);
begin
  inherited SetHeight(AHeight);
  FTrack.Height := AHeight;
  FThumb.Height := AHeight;
  Redraw := True;
end;

procedure TScrollBar.SetColor(Color: TColor);
begin
  FColor := Color;
end;

function TScrollBar.GetColor: TColor;
begin
  Result := FColor;
end;

procedure TScrollBar.SetHighContrast(Contrast: Boolean);
begin
  FContrast := Contrast;
end;

procedure TScrollBar.SetTextList(List: TTextList);
begin
  FList := List;
end;

procedure TScrollBar.SetBackground(BG: TSurface);
begin
  FBg := BG;
end;

procedure TScrollBar.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  FTrack.SetPalette(Colors, FirstColor, NumColors);
  FThumb.SetPalette(Colors, FirstColor, NumColors);
end;

procedure TScrollBar.Blit(Dest: TSurface);
begin
  inherited Blit(Dest);
  if Visible and not Hidden then
  begin
    FTrack.Blit(Dest);
    FThumb.Blit(Dest);
    InvalidateSurface;
  end;
end;

procedure TScrollBar.Handle(Action: TAction; State: TState);
var
  CursorY, Y, Scroll: Integer;
  Scale: Double;
begin
  inherited Handle(Action, State);
  if FPressed and ((Action.Details.Button = mbLeft) or (Action.Details.MouseX <> -1)) then
  begin
    CursorY := Action.GetAbsoluteYMouse - Top;
    Y := EnsureRange(CursorY + FOffset, 0, Height - FThumbRect.Height + 1);
    if FList <> nil then
    begin
      Scale := FList.GetRows / Height;
      Scroll := Round(Y * Scale);
      FList.ScrollTo(Scroll);
    end;
  end;
end;

procedure TScrollBar.MousePress(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CursorY: Integer;
begin
  inherited;
  if Button = mbLeft then
  begin
    CursorY := Y;
    if (CursorY >= FThumbRect.Top) and (CursorY < FThumbRect.Top + FThumbRect.Height) then
      FOffset := FThumbRect.Top - CursorY
    else
      FOffset := -FThumbRect.Height div 2;
    FPressed := True;
  end
  else if Button = mbWheelUp then
  begin
    if FList <> nil then FList.ScrollUp(False, True);
  end
  else if Button = mbWheelDown then
  begin
    if FList <> nil then FList.ScrollDown(False, True);
  end;
end;

procedure TScrollBar.MouseRelease(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FPressed := False;
    FOffset := 0;
  end;
end;

procedure TScrollBar.DrawContent;
begin
  inherited;
  DrawTrack;
  DrawThumb;
end;

procedure TScrollBar.DrawTrack;
begin
  if FBg <> nil then
  begin
    FTrack.Copy(FBg);
    FTrack.OffsetBlock(-5);
  end;
end;

procedure TScrollBar.DrawThumb;
var
  Scale: Double;
  Rect: TRect;
  Color: TColor;
begin
  if FList = nil then Exit;
  Scale := Height / FList.GetRows;
  FThumbRect := Rect(0,
                     Round(FList.GetScroll * Scale),
                     Width,
                     Round(FList.GetVisibleRows * Scale));
  // Draw thumb
  FThumb.Clear;
  Rect := FThumbRect;
  Dec(Rect.Width);
  Dec(Rect.Height);
  Color := FColor + 2;
  FThumb.Canvas.Pen.Color := Color;
  FThumb.Canvas.Brush.Style := bsClear;
  FThumb.Canvas.Rectangle(Rect);
  // additional hollowing etc.
end;

end.