unit UTimer;

interface

uses
  SDL, UState, USurface;

type
  TStateHandler = procedure of object;
  TSurfaceHandler = procedure of object;

  TTimer = class
  private
    FStart: UInt32;
    FFrameSkipStart: UInt32;
    FInterval: Integer;
    FRunning: Boolean;
    FFrameSkipping: Boolean;
    FStateHandler: TStateHandler;
    FSurfaceHandler: TSurfaceHandler;
  public
    class var MaxFrameSkip: Integer;
    class var GameSlowSpeed: UInt32;
    constructor Create(Interval: UInt32; FrameSkipping: Boolean = False);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function GetTime: UInt32;
    function IsRunning: Boolean;
    procedure Think(State: TState; Surface: TSurface);
    procedure SetInterval(Interval: UInt32);
    procedure OnTimer(Handler: TStateHandler); overload;
    procedure OnTimer(Handler: TSurfaceHandler); overload;
  end;

implementation

uses
  SysUtils, UOptions, UGame;

class var TTimer.MaxFrameSkip := 8;
class var TTimer.GameSlowSpeed := 1;

constructor TTimer.Create(Interval: UInt32; FrameSkipping: Boolean);
begin
  FStart := 0;
  FFrameSkipStart := 0;
  FInterval := Interval;
  FRunning := False;
  FFrameSkipping := FrameSkipping;
  FStateHandler := nil;
  FSurfaceHandler := nil;
end;

destructor TTimer.Destroy;
begin
  inherited;
end;

procedure TTimer.Start;
begin
  FStart := SDL_GetTicks;
  FFrameSkipStart := FStart;
  FRunning := True;
end;

procedure TTimer.Stop;
begin
  FRunning := False;
end;

function TTimer.GetTime: UInt32;
begin
  if FRunning then
    Result := SDL_GetTicks - FStart
  else
    Result := 0;
end;

function TTimer.IsRunning: Boolean;
begin
  Result := FRunning;
end;

procedure TTimer.Think(State: TState; Surface: TSurface);
var
  Now, Elapsed: Int64;
  Game: TGame;
begin
  if not FRunning then Exit;
  Now := SDL_GetTicks;
  Elapsed := Now - FFrameSkipStart;
  if Elapsed >= FInterval then
  begin
    var Skipped := 0;
    while (Skipped <= MaxFrameSkip) and (Elapsed >= FInterval) do
    begin
      if Assigned(FStateHandler) and (State <> nil) then
        FStateHandler();
      FFrameSkipStart := FFrameSkipStart + FInterval;
      Elapsed := Now - FFrameSkipStart;
      Inc(Skipped);
      if not FFrameSkipping then Break;
      Game := TState.FGame;
      if (Game <> nil) and not Game.IsState(State) then Break;
    end;
    if Assigned(FSurfaceHandler) and (Surface <> nil) then
      FSurfaceHandler();
    FStart := SDL_GetTicks;
    if FStart > FFrameSkipStart then
      FFrameSkipStart := FStart;
  end;
end;

procedure TTimer.SetInterval(Interval: UInt32);
begin
  FInterval := Interval;
end;

procedure TTimer.OnTimer(Handler: TStateHandler);
begin
  FStateHandler := Handler;
end;

procedure TTimer.OnTimer(Handler: TSurfaceHandler);
begin
  FSurfaceHandler := Handler;
end;

initialization
  TTimer.MaxFrameSkip := UOptions.maxFrameSkip;
end.