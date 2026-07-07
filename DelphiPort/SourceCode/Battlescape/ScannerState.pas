unit ScannerState;

interface

uses
  Classes, SysUtils,
  Engine.State,
  Engine.Game,
  Engine.InteractiveSurface,
  Engine.Action,
  Engine.Timer,
  Engine.Screen,
  Engine.Options,
  Savegame.BattleUnit,
  Battlescape.BattleAction,
  Battlescape.ScannerView;

type
  TScannerState = class(TState)
  private
    FBg: TInteractiveSurface;
    FScan: TSurface;
    FScannerView: TScannerView;
    FAction: PBattleAction;
    FTimerAnimate: TTimer;
    procedure Update;
    procedure Animate;
    procedure ExitClick(Action: TAction);
  public
    constructor Create(Action: PBattleAction);
    destructor Destroy; override;
    procedure Handle(Action: TAction); override;
    procedure Think; override;
  end;

implementation

uses
  Mod.Mod,
  Savegame.SavedGame,
  Savegame.SavedBattleGame;

{ TScannerState }

constructor TScannerState.Create(Action: PBattleAction);
begin
  inherited Create;
  FAction := Action;
  if Options.MaximizeInfoScreens then
  begin
    Options.BaseXResolution := Screen.ORIGINAL_WIDTH;
    Options.BaseYResolution := Screen.ORIGINAL_HEIGHT;
    FGame.Screen.ResetDisplay(False);
  end;

  FBg := TInteractiveSurface.Create(320, 200);
  FScan := TSurface.Create(320, 200);
  FScannerView := TScannerView.Create(152, 152, 56, 24, FGame, FAction.Actor);

  if FGame.Screen.DY > 50 then
    Screen := False;

  FGame.SavedGame.SavedBattle.SetPaletteByDepth(Self);

  Add(FScan);
  Add(FScannerView);
  Add(FBg);

  CenterAllSurfaces;

  FGame.Mod.Surface['DETBORD.PCK'].Blit(FBg);
  FGame.Mod.Surface['DETBORD2.PCK'].Blit(FScan);

  FBg.OnMouseClick := ExitClick;
  FBg.OnKeyboardPress(Options.KeyCancel, ExitClick);

  FTimerAnimate := TTimer.Create(125);
  FTimerAnimate.OnTimer := Animate;
  FTimerAnimate.Start;

  Update;
end;

destructor TScannerState.Destroy;
begin
  FTimerAnimate.Free;
  inherited;
end;

procedure TScannerState.Handle(Action: TAction);
begin
  inherited;
  if (Action.Details.Type_ = SDL_MOUSEBUTTONDOWN) and (Action.Details.Button.Button = SDL_BUTTON_RIGHT) then
    ExitClick(Action);
end;

procedure TScannerState.Update;
begin
  // FScannerView.Draw; // called by timer
end;

procedure TScannerState.Animate;
begin
  FScannerView.Animate;
end;

procedure TScannerState.Think;
begin
  inherited;
  FTimerAnimate.Think(Self, nil);
end;

procedure TScannerState.ExitClick(Action: TAction);
begin
  if Options.MaximizeInfoScreens then
  begin
    Screen.UpdateScale(Options.BattlescapeScale, Options.BaseXBattlescape, Options.BaseYBattlescape, True);
    FGame.Screen.ResetDisplay(False);
  end;
  FGame.PopState;
end;

end.