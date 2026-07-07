unit FpsCounter;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics,
  Common, NumberText, Timer, Action, Options;

type
  TFpsCounter = class(TSurface)
  private
    FText: TNumberText;
    FTimer: TTimer;
    FFrames: Integer;
    procedure Update(Sender: TObject);
  public
    constructor Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    procedure SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer); override;
    procedure SetColor(Color: TColor);
    procedure Handle(Action: TAction);
    procedure Think;
    procedure DrawContent; override;
    procedure AddFrame;
  end;

implementation

uses
  Math;

constructor TFpsCounter.Create(AWidth, AHeight, AX, AY: Integer; AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AWidth;
  Height := AHeight;
  Left := AX;
  Top := AY;
  FFrames := 0;
  Visible := Options.FpsCounter;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 1000;
  FTimer.OnTimer := Update;
  FTimer.Enabled := True;

  FText := TNumberText.Create(AWidth, AHeight, AX, AY, Self);
end;

destructor TFpsCounter.Destroy;
begin
  FText.Free;
  FTimer.Free;
  inherited;
end;

procedure TFpsCounter.SetPalette(const Colors: array of TColor; FirstColor, NumColors: Integer);
begin
  inherited SetPalette(Colors, FirstColor, NumColors);
  FText.SetPalette(Colors, FirstColor, NumColors);
end;

procedure TFpsCounter.SetColor(Color: TColor);
begin
  FText.SetColor(Color);
end;

procedure TFpsCounter.Handle(Action: TAction);
begin
  if (Action.Details.Key = Options.KeyFps) and (Action.Details.KeyDown) then
  begin
    Visible := not Visible;
    Options.FpsCounter := Visible;
  end;
end;

procedure TFpsCounter.Think;
begin
  // timer does update
end;

procedure TFpsCounter.Update(Sender: TObject);
var
  FPS: Integer;
begin
  FPS := Round(FFrames / (FTimer.Interval / 1000));
  FText.SetValue(FPS);
  FFrames := 0;
  Redraw := True;
end;

procedure TFpsCounter.DrawContent;
begin
  inherited;
  FText.Blit(Self);
end;

procedure TFpsCounter.AddFrame;
begin
  Inc(FFrames);
end;

end.