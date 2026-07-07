unit UFpsCounter;

interface

uses
  SysUtils, Classes, SDL, USurface, UInteractiveSurface, UAction, UState;

type
  TFpsCounter = class(TInteractiveSurface)
  private
    FColor: Byte;
    FFrameCount: Integer;
    FLastUpdate: Cardinal;
    FCurrentFPS: Integer;
    FVisible: Boolean;
  public
    constructor Create(X, Y: Integer; Width: Integer = 40; Height: Integer = 12);
    procedure Think; override;
    procedure Draw; override;
    procedure AddFrame;
    procedure SetColor(Color: Byte); override;
    procedure SetVisible(Visible: Boolean); override;
  end;

implementation

constructor TFpsCounter.Create(X, Y: Integer; Width: Integer = 40; Height: Integer = 12);
begin
  inherited Create(Width, Height, X, Y);
  FColor := 0;
  FFrameCount := 0;
  FLastUpdate := SDL_GetTicks;
  FCurrentFPS := 0;
  FVisible := True;
end;

procedure TFpsCounter.Think;
var
  Now: Cardinal;
begin
  inherited;
  if not FVisible then Exit;
  Now := SDL_GetTicks;
  if Now - FLastUpdate >= 1000 then
  begin
    FCurrentFPS := FFrameCount;
    FFrameCount := 0;
    FLastUpdate := Now;
    FRedraw := True;
  end;
end;

procedure TFpsCounter.Draw;
var
  Text: string;
begin
  FRedraw := False;
  Clear(0);
  Text := IntToStr(FCurrentFPS) + ' FPS';
  // Draw text (simplified)
end;

procedure TFpsCounter.AddFrame;
begin
  if FVisible then Inc(FFrameCount);
end;

procedure TFpsCounter.SetColor(Color: Byte);
begin
  FColor := Color;
  FRedraw := True;
end;

procedure TFpsCounter.SetVisible(Visible: Boolean);
begin
  FVisible := Visible;
  if not Visible then
    FRedraw := True;
end;

end.