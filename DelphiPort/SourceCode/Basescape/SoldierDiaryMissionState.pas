unit SoldierDiaryMissionState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.SavedGame, Savegame.Soldier, Savegame.SoldierDiary,
  Savegame.MissionStatistics, Savegame.BattleUnitStatistics;

type
  TSoldierDiaryMissionState = class(TState)
  private
    FSoldier: TSoldier;
    FRowEntry: Integer;
    FBtnOk, FBtnPrev, FBtnNext: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtUFO, FTxtScore, FTxtKills, FTxtLocation, FTxtRace, FTxtDaylight, FTxtDaysWounded: TText;
    FTxtNoRecord: TText;
    FLstKills: TTextList;
  public
    constructor Create(AOwner: TComponent; Soldier: TSoldier; RowEntry: Integer);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnPrevClick(Sender: TObject; Action: TAction);
    procedure BtnNextClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSoldierDiaryMissionState.Create(AOwner: TComponent; Soldier: TSoldier; RowEntry: Integer);
begin
  inherited Create(AOwner);
  FSoldier := Soldier;
  FRowEntry := RowEntry;
  Screen := False;

  FWindow := TWindow.Create(Self, 300, 128, 10, 36, POPUP_HORIZONTAL);
  FBtnOk := TTextButton.Create(240, 16, 40, 140);
  FBtnPrev := TTextButton.Create(28, 14, 18, 44);
  FBtnNext := TTextButton.Create(28, 14, 274, 44);
  FTxtTitle := TText.Create(262, 9, 29, 44);
  FTxtUFO := TText.Create(262, 9, 29, 52);
  FTxtScore := TText.Create(180, 9, 29, 68);
  FTxtKills := TText.Create(120, 9, 169, 68);
  FTxtLocation := TText.Create(180, 9, 29, 76);
  FTxtRace := TText.Create(120, 9, 169, 76);
  FTxtDaylight := TText.Create(120, 9, 169, 84);
  FTxtDaysWounded := TText.Create(180, 9, 29, 84);
  FTxtNoRecord := TText.Create(240, 9, 29, 100);
  FLstKills := TTextList.Create(270, 32, 20, 100);

  SetInterface('soldierDiaryMission');
  Add(FWindow, 'window', 'soldierDiaryMission');
  Add(FBtnOk, 'button', 'soldierDiaryMission');
  Add(FBtnPrev, 'button', 'soldierDiaryMission');
  Add(FBtnNext, 'button', 'soldierDiaryMission');
  Add(FTxtTitle, 'text', 'soldierDiaryMission');
  Add(FTxtUFO, 'text', 'soldierDiaryMission');
  Add(FTxtScore, 'text', 'soldierDiaryMission');
  Add(FTxtKills, 'text', 'soldierDiaryMission');
  Add(FTxtLocation, 'text', 'soldierDiaryMission');
  Add(FTxtRace, 'text', 'soldierDiaryMission');
  Add(FTxtDaylight, 'text', 'soldierDiaryMission');
  Add(FTxtDaysWounded, 'text', 'soldierDiaryMission');
  Add(FTxtNoRecord, 'text', 'soldierDiaryMission');
  Add(FLstKills, 'list', 'soldierDiaryMission');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK16.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnPrev.SetText('<<');
  FBtnPrev.OnMouseClick := BtnPrevClick;
  FBtnPrev.OnKeyboardPress := BtnPrevClick;
  FBtnNext.SetText('>>');
  FBtnNext.OnMouseClick := BtnNextClick;
  FBtnNext.OnKeyboardPress := BtnNextClick;

  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtUFO.SetAlign(ALIGN_CENTER);
  FLstKills.SetColumns([60, 110, 100]);
end;

destructor TSoldierDiaryMissionState.Destroy;
begin
  inherited;
end;

procedure TSoldierDiaryMissionState.Init;
var
  missionStats: TList<TMissionStatistics>;
  missionId: Integer;
  mission: TMissionStatistics;
  daysWounded: Integer;
  kill: TBattleUnitKills;
  kills, stunOrKill: Integer;
begin
  inherited;
  if FSoldier.GetDiary.GetMissionIdList.IsEmpty then
  begin
    FGame.PopState;
    Exit;
  end;
  missionStats := FGame.GetSavedGame.GetMissionStatistics;
  missionId := FSoldier.GetDiary.GetMissionIdList[FRowEntry];
  if missionId >= missionStats.Count then
    missionId := 0;
  mission := missionStats[missionId];

  FLstKills.ClearList;
  FTxtTitle.SetText(Translate(mission.Type));
  if mission.IsUfoMission then
    FTxtUFO.SetText(Translate(mission.UFO))
  else
    FTxtUFO.SetText('');
  FTxtUFO.Visible := mission.IsUfoMission;
  FTxtScore.SetText(Translate('STR_SCORE_VALUE').Arg(mission.Score));
  FTxtLocation.SetText(Translate('STR_LOCATION').Arg(Translate(mission.GetLocationString)));
  FTxtRace.SetText(Translate('STR_RACE_TYPE').Arg(Translate(mission.AlienRace)));
  FTxtRace.Visible := (mission.AlienRace <> 'STR_UNKNOWN');
  FTxtDaylight.SetText(Translate('STR_DAYLIGHT_TYPE').Arg(Translate(mission.GetDaylightString)));
  daysWounded := mission.InjuryList[FSoldier.Id];
  FTxtDaysWounded.SetText(Translate('STR_DAYS_WOUNDED').Arg(daysWounded));
  FTxtDaysWounded.Visible := (daysWounded <> 0);

  kills := 0;
  stunOrKill := 0;
  for kill in FSoldier.GetDiary.GetKills do
  begin
    if kill.Mission <> missionId then Continue;
    case kill.Status of
      STATUS_DEAD: Inc(kills);
      STATUS_UNCONSCIOUS, STATUS_PANICKING, STATUS_TURNING: ; // fall through
    else
      stunOrKill := 1;
    end;
    FLstKills.AddRow([
      Translate(kill.GetKillStatusString),
      kill.GetUnitName(FGame.GetLanguage),
      Translate(kill.Weapon)
    ]);
  end;

  FTxtNoRecord.SetAlign(ALIGN_CENTER);
  FTxtNoRecord.SetText(Translate('STR_NO_RECORD'));
  FTxtNoRecord.Visible := (stunOrKill = 0);
  FTxtKills.SetText(Translate('STR_KILLS').Arg(kills));
end;

procedure TSoldierDiaryMissionState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TSoldierDiaryMissionState.BtnPrevClick(Sender: TObject; Action: TAction);
begin
  if FRowEntry = 0 then
    FRowEntry := FSoldier.GetDiary.GetMissionTotal - 1
  else
    Dec(FRowEntry);
  Init;
end;

procedure TSoldierDiaryMissionState.BtnNextClick(Sender: TObject; Action: TAction);
begin
  Inc(FRowEntry);
  if FRowEntry >= FSoldier.GetDiary.GetMissionTotal then
    FRowEntry := 0;
  Init;
end;

end.