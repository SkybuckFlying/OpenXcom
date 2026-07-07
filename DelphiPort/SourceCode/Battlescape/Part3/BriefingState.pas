unit BriefingState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.Action, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Craft, Savegame.Base, Mod.Mod, Engine.LocalizedText,
  Savegame.SavedBattleGame;

type
  TBriefingState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    FTxtTarget: TText;
    FTxtCraft: TText;
    FTxtBriefing: TText;
    FCutsceneId: string;
    FMusicId: string;
    procedure BtnOkClick(Sender: TObject);
  public
    constructor Create(ACraft: TCraft = nil; ABase: TBase = nil);
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

uses
  Battlescape.BattlescapeState, Battlescape.AliensCrashState,
  Battlescape.InventoryState, Battlescape.NextTurnState,
  Menu.CutsceneState, Mod.AlienDeployment, Savegame.Ufo;

constructor TBriefingState.Create(ACraft: TCraft; ABase: TBase);
var
  Mission: string;
  Deployment: TAlienDeployment;
  Ufo: TUfo;
  Data: TBriefingData;
begin
  inherited Create;
  Options.BaseXResolution := Options.BaseXGeoscape;
  Options.BaseYResolution := Options.BaseYGeoscape;
  Game.GetScreen.ResetDisplay(False);
  _screen := True;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(120, 18, 100, 164);
  FTxtTitle := TText.Create(300, 32, 16, 24);
  FTxtTarget := TText.Create(300, 17, 16, 40);
  FTxtCraft := TText.Create(300, 17, 16, 56);
  FTxtBriefing := TText.Create(274, 94, 16, 72);

  Mission := Game.GetSavedGame.GetSavedBattle.GetMissionType;
  Deployment := Game.GetMod.GetDeployment(Mission);

  if (Deployment = nil) and (ACraft <> nil) then
  begin
    Ufo := ACraft.GetDestination as TUfo;
    if Ufo <> nil then
      Deployment := Game.GetMod.GetDeployment(Ufo.GetRules.GetType);
  end;

  if Deployment = nil then
  begin
    SetPalette('PAL_GEOSCAPE', 0);
    FMusicId := 'GMDEFEND';
    FWindow.SetBackground(Game.GetMod.GetSurface('BACK16.SCR'));
  end
  else
  begin
    Data := Deployment.GetBriefingData;
    SetPalette('PAL_GEOSCAPE', Data.Palette);
    FWindow.SetBackground(Game.GetMod.GetSurface(Data.Background));
    FTxtCraft.SetY(56 + Data.TextOffset);
    FTxtBriefing.SetY(72 + Data.TextOffset);
    FTxtTarget.SetVisible(Data.ShowTarget);
    FTxtCraft.SetVisible(Data.ShowCraft);
    FCutsceneId := Data.Cutscene;
    FMusicId := Data.Music;
  end;

  Add(FWindow, 'window', 'briefing');
  Add(FBtnOk, 'button', 'briefing');
  Add(FTxtTitle, 'text', 'briefing');
  Add(FTxtTarget, 'text', 'briefing');
  Add(FTxtCraft, 'text', 'briefing');
  Add(FTxtBriefing, 'text', 'briefing');

  CenterAllSurfaces;

  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtTitle.SetBig;
  FTxtTarget.SetBig;
  FTxtCraft.SetBig;

  if ACraft <> nil then
  begin
    if ACraft.GetDestination <> nil then
      FTxtTarget.SetText(ACraft.GetDestination.GetName(Game.GetLanguage));
    FTxtCraft.SetText(Tr('STR_CRAFT_').Arg(ACraft.GetName(Game.GetLanguage)));
  end
  else if ABase <> nil then
    FTxtCraft.SetText(Tr('STR_BASE_UC_').Arg(ABase.GetName));

  FTxtTitle.SetText(Tr(Mission));
  FTxtBriefing.SetWordWrap(True);
  FTxtBriefing.SetText(Tr(Mission + '_BRIEFING'));

  if Mission = 'STR_BASE_DEFENSE' then
    ABase.SetRetaliationTarget(False);
end;

destructor TBriefingState.Destroy;
begin
  inherited;
end;

procedure TBriefingState.Init;
begin
  inherited;
  if FCutsceneId <> '' then
  begin
    Game.PushState(TCutsceneState.Create(FCutsceneId));
    FCutsceneId := '';
  end
  else
    Game.GetMod.PlayMusic(FMusicId);
end;

procedure TBriefingState.BtnOkClick(Sender: TObject);
var
  BS: TBattlescapeState;
  LiveAliens, LiveSoldiers: Integer;
begin
  Game.PopState;
  Options.BaseXResolution := Options.BaseXBattlescape;
  Options.BaseYResolution := Options.BaseYBattlescape;
  Game.GetScreen.ResetDisplay(False);
  BS := TBattlescapeState.Create;
  BS.GetBattleGame.TallyUnits(LiveAliens, LiveSoldiers);
  if LiveAliens > 0 then
  begin
    Game.PushState(BS);
    Game.GetSavedGame.GetSavedBattle.SetBattleState(BS);
    Game.PushState(TNextTurnState.Create(Game.GetSavedGame.GetSavedBattle, BS));
    Game.PushState(TInventoryState.Create(False, BS));
  end
  else
  begin
    Options.BaseXResolution := Options.BaseXGeoscape;
    Options.BaseYResolution := Options.BaseYGeoscape;
    Game.GetScreen.ResetDisplay(False);
    BS.Free;
    Game.PushState(TAliensCrashState.Create);
  end;
end;

end.