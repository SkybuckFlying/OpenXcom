unit UGame;

interface

uses
  SysUtils, Classes, SDL, UScreen, UCursor, ULanguage, USavedGame, UMod,
  UState, UAction, UOptions, UFileMap, UCrossPlatform, UFpsCounter;

type
  TGame = class
  private
    FScreen: TScreen;
    FCursor: TCursor;
    FLang: TLanguage;
    FSave: TSavedGame;
    FMod: TMod;
    FStates: TList<TState>;
    FDeleted: TList<TState>;
    FQuit: Boolean;
    FInit: Boolean;
    FMouseActive: Boolean;
    FTimeOfLastFrame: Cardinal;
    FTimeUntilNextFrame: Integer;
    FEvent: TSDL_Event;
    FFpsCounter: TFpsCounter;
    class var FVolumeGradient: Double;
    procedure ProcessEvents;
  public
    constructor Create(const Title: string);
    destructor Destroy; override;
    procedure Run;
    procedure Quit;
    procedure SetVolume(Sound, Music, UI: Integer);
    class function VolumeExponent(Volume: Integer): Double;
    function GetScreen: TScreen;
    function GetCursor: TCursor;
    function GetFpsCounter: TFpsCounter;
    procedure SetState(State: TState);
    procedure PushState(State: TState);
    procedure PopState;
    function GetLanguage: TLanguage;
    function GetSavedGame: TSavedGame;
    procedure SetSavedGame(Save: TSavedGame);
    function GetMod: TMod;
    procedure LoadMods;
    procedure SetMouseActive(Active: Boolean);
    function IsState(State: TState): Boolean;
    function IsQuitting: Boolean;
    procedure LoadLanguages;
    procedure InitAudio;
  end;

const
  VOLUME_GRADIENT = 10.0;

implementation

uses
  UException, ULogger, USound, UMusic, UCrossPlatform;

constructor TGame.Create(const Title: string);
begin
  // Initialize SDL, create screen, cursor, fps counter, language, etc.
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    raise EOpenXcom.Create(SDL_GetError);
  // Initialize other subsystems...
  FScreen := TScreen.Create;
  FCursor := TCursor.Create(9, 13);
  FFpsCounter := TFpsCounter.Create(15, 5, 0, 0);
  FLang := TLanguage.Create;
  FStates := TList<TState>.Create;
  FDeleted := TList<TState>.Create;
  FQuit := False;
  FInit := False;
  FMouseActive := True;
  FTimeOfLastFrame := SDL_GetTicks;
end;

destructor TGame.Destroy;
begin
  // Cleanup
  for var S in FStates do S.Free;
  for var S in FDeleted do S.Free;
  FStates.Free;
  FDeleted.Free;
  FCursor.Free;
  FScreen.Free;
  FFpsCounter.Free;
  FLang.Free;
  FSave.Free;
  FMod.Free;
  SDL_Quit;
  inherited;
end;

procedure TGame.Run;
var
  RunningState: (RUNNING, SLOWED, PAUSED);
begin
  RunningState := RUNNING;
  while not FQuit do
  begin
    // Clean deleted states
    while FDeleted.Count > 0 do
    begin
      FDeleted.Last.Free;
      FDeleted.Delete(FDeleted.Count-1);
    end;
    // Initialize state if needed
    if not FInit then
    begin
      FInit := True;
      FStates.Last.Init;
      FStates.Last.ResetAll;
      // Send mouse event to refresh
    end;
    // Process events
    while SDL_PollEvent(@FEvent) <> 0 do
    begin
      // Handle quit, resize, etc.
      if FEvent.type_ = SDL_QUIT then Quit;
      // Create action and send to state
      var Action := TAction.Create(@FEvent, FScreen.GetXScale, FScreen.GetYScale,
        FScreen.GetCursorTopBlackBand, FScreen.GetCursorLeftBlackBand);
      try
        FScreen.Handle(Action);
        FCursor.Handle(Action);
        FFpsCounter.Handle(Action);
        FStates.Last.Handle(Action);
      finally
        Action.Free;
      end;
    end;
    // Think
    if RunningState <> PAUSED then
    begin
      FStates.Last.Think;
      FFpsCounter.Think;
      // Delay handling
      // Render
      if FInit then
      begin
        FScreen.Clear;
        // Blit states from bottom to top
        for var I := 0 to FStates.Count-1 do
          FStates[I].Blit;
        FFpsCounter.Blit(FScreen.GetSurface);
        FCursor.Blit(FScreen.GetSurface);
        FScreen.Flip;
      end;
    end;
    SDL_Delay(1);
  end;
end;

procedure TGame.Quit;
begin
  // Save ironman if needed
  FQuit := True;
end;

procedure TGame.SetVolume(Sound, Music, UI: Integer);
begin
  // Implement using Mix_Volume etc.
end;

class function TGame.VolumeExponent(Volume: Integer): Double;
begin
  Result := (Exp(Ln(VOLUME_GRADIENT + 1.0) * Volume / 128.0) - 1.0) / VOLUME_GRADIENT;
end;

function TGame.GetScreen: TScreen;
begin
  Result := FScreen;
end;

function TGame.GetCursor: TCursor;
begin
  Result := FCursor;
end;

function TGame.GetFpsCounter: TFpsCounter;
begin
  Result := FFpsCounter;
end;

procedure TGame.SetState(State: TState);
begin
  while FStates.Count > 0 do PopState;
  PushState(State);
end;

procedure TGame.PushState(State: TState);
begin
  FStates.Add(State);
  FInit := False;
end;

procedure TGame.PopState;
begin
  if FStates.Count > 0 then
  begin
    FDeleted.Add(FStates.Last);
    FStates.Delete(FStates.Count-1);
    FInit := False;
  end;
end;

function TGame.GetLanguage: TLanguage;
begin
  Result := FLang;
end;

function TGame.GetSavedGame: TSavedGame;
begin
  Result := FSave;
end;

procedure TGame.SetSavedGame(Save: TSavedGame);
begin
  FSave.Free;
  FSave := Save;
end;

function TGame.GetMod: TMod;
begin
  Result := FMod;
end;

procedure TGame.LoadMods;
begin
  FMod.Free;
  FMod := TMod.Create;
  FMod.LoadAll(UFileMap.GetRulesets);
end;

procedure TGame.SetMouseActive(Active: Boolean);
begin
  FMouseActive := Active;
  FCursor.SetVisible(Active);
end;

function TGame.IsState(State: TState): Boolean;
begin
  Result := (FStates.Count > 0) and (FStates.Last = State);
end;

function TGame.IsQuitting: Boolean;
begin
  Result := FQuit;
end;

procedure TGame.LoadLanguages;
begin
  // Load language files
end;

procedure TGame.InitAudio;
begin
  // Initialize SDL_mixer
end;

end.