unit AbortMissionState;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Engine.State, Engine.Game, Engine.Action, Engine.Options,
  Interface.Window, Interface.Text, Interface.TextButton,
  Savegame.SavedBattleGame, Battlescape.BattlescapeState, Mod.Mod,
  Savegame.Tile, Engine.LocalizedText;

type
  TAbortMissionState = class(TState)
  private
    FWindow: TWindow;
    FTxtInEntrance: TText;
    FTxtInExit: TText;
    FTxtOutside: TText;
    FTxtAbort: TText;
    FBtnOk: TTextButton;
    FBtnCancel: TTextButton;
    FBattleGame: TSavedBattleGame;
    FBattlescapeState: TBattlescapeState;
    FInEntrance: Integer;
    FInExit: Integer;
    FOutside: Integer;
    procedure BtnOkClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
  public
    constructor Create(ABattleGame: TSavedBattleGame; AState: TBattlescapeState);
    destructor Destroy; override;
  end;

implementation

uses
  Mod.AlienDeployment, Mod.MapScript;

constructor TAbortMissionState.Create(ABattleGame: TSavedBattleGame; AState: TBattlescapeState);
var
  Deployment: TAlienDeployment;
  Scripts: TList<TMapScript>;
  ExitExists, CraftExists: Boolean;
  I: Integer;
  Tile: TTile;
  Unit: TBattleUnit;
begin
  inherited Create;
  FBattleGame := ABattleGame;
  FBattlescapeState := AState;
  FInEntrance := 0;
  FInExit := 0;
  FOutside := 0;
  _screen := False;

  FWindow := TWindow.Create(Self, 320, 144, 0, 0);
  FTxtInEntrance := TText.Create(304, 17, 16, 20);
  FTxtInExit := TText.Create(304, 17, 16, 40);
  FTxtOutside := TText.Create(304, 17, 16, 60);
  FTxtAbort := TText.Create(320, 17, 0, 80);
  FBtnOk := TTextButton.Create(120, 16, 16, 110);
  FBtnCancel := TTextButton.Create(120, 16, 184, 110);

  FBattleGame.SetPaletteByDepth(Self);

  Add(FWindow, 'messageWindowBorder', 'battlescape');
  Add(FTxtInEntrance, 'messageWindows', 'battlescape');
  Add(FTxtInExit, 'messageWindows', 'battlescape');
  Add(FTxtOutside, 'messageWindows', 'battlescape');
  Add(FTxtAbort, 'messageWindows', 'battlescape');
  Add(FBtnOk, 'messageWindowButtons', 'battlescape');
  Add(FBtnCancel, 'messageWindowButtons', 'battlescape');

  ExitExists := False;
  CraftExists := True;
  Deployment := Game.GetMod.GetDeployment(FBattleGame.GetMissionType);
  if Deployment <> nil then
  begin
    ExitExists := (Deployment.GetNextStage <> '') or
                  (Deployment.GetEscapeType = ESCAPE_EXIT) or
                  (Deployment.GetEscapeType = ESCAPE_EITHER);
    Scripts := Game.GetMod.GetMapScript(Deployment.GetScript);
    if Scripts <> nil then
    begin
      CraftExists := False;
      for I := 0 to Scripts.Count - 1 do
        if Scripts[I].GetType = MSC_ADDCRAFT then
        begin
          CraftExists := True;
          Break;
        end;
    end;
  end;

  if ExitExists then
  begin
    ExitExists := False;
    for I := 0 to FBattleGame.GetMapSizeXYZ - 1 do
    begin
      Tile := FBattleGame.GetTiles[I];
      if (Tile <> nil) and (Tile.GetMapData(O_FLOOR) <> nil) and
         (Tile.GetMapData(O_FLOOR).GetSpecialType = END_POINT) then
      begin
        ExitExists := True;
        Break;
      end;
    end;
  end;

  for Unit in FBattleGame.GetUnits do
  begin
    if Unit.GetOriginalFaction = FACTION_PLAYER then
    begin
      if (Unit.GetStatus <> STATUS_DEAD) and (Unit.GetStatus <> STATUS_IGNORE_ME) then
      begin
        Tile := FBattleGame.GetTile(Unit.GetPosition);
        if Tile <> nil then
        begin
          if (Tile.GetMapData(O_FLOOR) <> nil) and
             (Tile.GetMapData(O_FLOOR).GetSpecialType = START_POINT) then
            Inc(FInEntrance)
          else if (Tile.GetMapData(O_FLOOR) <> nil) and
                  (Tile.GetMapData(O_FLOOR).GetSpecialType = END_POINT) then
            Inc(FInExit)
          else
            Inc(FOutside);
        end;
      end;
    end;
  end;

  FWindow.SetHighContrast(True);
  FWindow.SetBackground(Game.GetMod.GetSurface('TAC00.SCR'));

  FTxtInEntrance.SetBig;
  FTxtInEntrance.SetHighContrast(True);
  if CraftExists then
    FTxtInEntrance.SetText(Tr('STR_UNITS_IN_CRAFT', FInEntrance))
  else
    FTxtInEntrance.SetText(Tr('STR_UNITS_IN_ENTRANCE', FInEntrance));

  FTxtInExit.SetBig;
  FTxtInExit.SetHighContrast(True);
  FTxtInExit.SetText(Tr('STR_UNITS_IN_EXIT', FInExit));

  FTxtOutside.SetBig;
  FTxtOutside.SetHighContrast(True);
  FTxtOutside.SetText(Tr('STR_UNITS_OUTSIDE', FOutside));

  if FBattleGame.GetMissionType = 'STR_BASE_DEFENSE' then
  begin
    FTxtInEntrance.SetVisible(False);
    FTxtInExit.SetVisible(False);
    FTxtOutside.SetVisible(False);
  end
  else if not ExitExists then
  begin
    FTxtInEntrance.SetY(26);
    FTxtOutside.SetY(54);
    FTxtInExit.SetVisible(False);
  end;

  FTxtAbort.SetBig;
  FTxtAbort.SetAlign(ALIGN_CENTER);
  FTxtAbort.SetHighContrast(True);
  FTxtAbort.SetText(Tr('STR_ABORT_MISSION_QUESTION'));

  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.SetHighContrast(True);
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);

  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.SetHighContrast(True);
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.keyCancel, BtnCancelClick);
  FBtnCancel.OnKeyboardPress(Options.keyBattleAbort, BtnCancelClick);

  CenterAllSurfaces;
end;

destructor TAbortMissionState.Destroy;
begin
  inherited;
end;

procedure TAbortMissionState.BtnOkClick(Sender: TObject);
begin
  Game.PopState;
  FBattleGame.SetAborted(True);
  FBattlescapeState.FinishBattle(True, FInExit);
end;

procedure TAbortMissionState.BtnCancelClick(Sender: TObject);
begin
  Game.PopState;
end;

end.