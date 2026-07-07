unit SoldierDiaryOverviewState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.Soldier, Savegame.SoldierDiary,
  Savegame.SavedGame, Savegame.MissionStatistics,
  SoldierDiaryMissionState, SoldierDiaryPerformanceState,
  SoldierInfoState;

type
  TSoldierDiaryOverviewState = class(TState)
  private
    FBase: TBase;
    FSoldierId: Integer;
    FSoldierInfoState: TSoldierInfoState;
    FSoldier: TSoldier;
    FList: TList<TSoldier>;

    FBtnOk, FBtnPrev, FBtnNext, FBtnKills, FBtnMissions, FBtnCommendations: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtMission, FTxtRating, FTxtDate: TText;
    FLstDiary: TTextList;

    procedure LstDiaryInfoClick(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase; SoldierId: Integer; SoldierInfoState: TSoldierInfoState);
    destructor Destroy; override;
    procedure Init; override;
    procedure SetSoldierId(Soldier: Integer);
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnPrevClick(Sender: TObject; Action: TAction);
    procedure BtnNextClick(Sender: TObject; Action: TAction);
    procedure BtnKillsClick(Sender: TObject; Action: TAction);
    procedure BtnMissionsClick(Sender: TObject; Action: TAction);
    procedure BtnCommendationsClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSoldierDiaryOverviewState.Create(AOwner: TComponent; Base: TBase; SoldierId: Integer; SoldierInfoState: TSoldierInfoState);
begin
  inherited Create(AOwner);
  FBase := Base;
  FSoldierId := SoldierId;
  FSoldierInfoState := SoldierInfoState;

  if FBase = nil then
    FList := FGame.GetSavedGame.GetDeadSoldiers
  else
    FList := FBase.GetSoldiers;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnKills := TTextButton.Create(70, 16, 8, 176);
  FBtnMissions := TTextButton.Create(70, 16, 86, 176);
  FBtnCommendations := TTextButton.Create(70, 16, 164, 176);
  FBtnOk := TTextButton.Create(70, 16, 242, 176);
  FBtnPrev := TTextButton.Create(28, 14, 8, 8);
  FBtnNext := TTextButton.Create(28, 14, 284, 8);
  FTxtTitle := TText.Create(310, 16, 5, 8);
  FTxtMission := TText.Create(114, 9, 16, 36);
  FTxtRating := TText.Create(102, 9, 120, 36);
  FTxtDate := TText.Create(90, 9, 218, 36);
  FLstDiary := TTextList.Create(288, 120, 8, 44);

  SetInterface('soldierDiary');
  Add(FWindow, 'window', 'soldierDiary');
  Add(FBtnOk, 'button', 'soldierDiary');
  Add(FBtnKills, 'button', 'soldierDiary');
  Add(FBtnMissions, 'button', 'soldierDiary');
  Add(FBtnCommendations, 'button', 'soldierDiary');
  Add(FBtnPrev, 'button', 'soldierDiary');
  Add(FBtnNext, 'button', 'soldierDiary');
  Add(FTxtTitle, 'text1', 'soldierDiary');
  Add(FTxtMission, 'text2', 'soldierDiary');
  Add(FTxtRating, 'text2', 'soldierDiary');
  Add(FTxtDate, 'text2', 'soldierDiary');
  Add(FLstDiary, 'list', 'soldierDiary');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnKills.SetText(Translate('STR_COMBAT'));
  FBtnKills.OnMouseClick := BtnKillsClick;
  FBtnMissions.SetText(Translate('STR_PERFORMANCE'));
  FBtnMissions.OnMouseClick := BtnMissionsClick;
  FBtnCommendations.SetText(Translate('STR_AWARDS'));
  FBtnCommendations.OnMouseClick := BtnCommendationsClick;
  FBtnCommendations.Visible := not FGame.GetMod.GetCommendationsList.IsEmpty;

  if FBase = nil then
  begin
    FBtnPrev.OnMouseClick := BtnNextClick;
    FBtnPrev.OnKeyboardPress := BtnNextClick;
    FBtnNext.OnMouseClick := BtnPrevClick;
    FBtnNext.OnKeyboardPress := BtnPrevClick;
  end
  else
  begin
    FBtnPrev.OnMouseClick := BtnPrevClick;
    FBtnPrev.OnKeyboardPress := BtnPrevClick;
    FBtnNext.OnMouseClick := BtnNextClick;
    FBtnNext.OnKeyboardPress := BtnNextClick;
  end;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtMission.SetText(Translate('STR_MISSION'));
  FTxtRating.SetText(Translate('STR_RATING_UC'));
  FTxtDate.SetText(Translate('STR_DATE_UC'));

  FLstDiary.SetColumns([104, 98, 30, 25, 35]);
  FLstDiary.SetSelectable(True);
  FLstDiary.SetBackground(FWindow);
  FLstDiary.SetMargin(8);
  FLstDiary.OnMouseClick := LstDiaryInfoClick;
end;

destructor TSoldierDiaryOverviewState.Destroy;
begin
  inherited;
end;

procedure TSoldierDiaryOverviewState.Init;
var
  missionStats: TList<TMissionStatistics>;
  mission: TMissionStatistics;
  row: Integer;
  wasOnMission: Boolean;
begin
  inherited;
  if FList.Count = 0 then
  begin
    FGame.PopState;
    Exit;
  end;
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  FSoldier := FList[FSoldierId];
  FTxtTitle.SetText(FSoldier.GetName);
  FLstDiary.ClearList;

  missionStats := FGame.GetSavedGame.GetMissionStatistics;
  row := 0;
  for mission in missionStats do
  begin
    wasOnMission := False;
    for id in FSoldier.GetDiary.GetMissionIdList do
      if mission.Id = id then
      begin
        wasOnMission := True;
        Break;
      end;
    if not wasOnMission then Continue;

    FLstDiary.AddRow([
      mission.GetMissionName(FGame.GetLanguage),
      mission.GetRatingString(FGame.GetLanguage),
      mission.Time.GetDayString(FGame.GetLanguage),
      Translate(mission.Time.GetMonthString),
      IntToStr(mission.Time.GetYear)
    ]);
    Inc(row);
  end;
  if (row > 0) and (FLstDiary.GetScroll >= row) then
    FLstDiary.ScrollTo(0);
end;

procedure TSoldierDiaryOverviewState.SetSoldierId(Soldier: Integer);
begin
  FSoldierId := Soldier;
end;

procedure TSoldierDiaryOverviewState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FSoldierInfoState.SetSoldierId(FSoldierId);
  FGame.PopState;
end;

procedure TSoldierDiaryOverviewState.BtnPrevClick(Sender: TObject; Action: TAction);
begin
  if FSoldierId = 0 then
    FSoldierId := FList.Count - 1
  else
    Dec(FSoldierId);
  Init;
end;

procedure TSoldierDiaryOverviewState.BtnNextClick(Sender: TObject; Action: TAction);
begin
  Inc(FSoldierId);
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  Init;
end;

procedure TSoldierDiaryOverviewState.BtnKillsClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierDiaryPerformanceState.Create(Self, FBase, FSoldierId, Self, DIARY_KILLS));
end;

procedure TSoldierDiaryOverviewState.BtnMissionsClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierDiaryPerformanceState.Create(Self, FBase, FSoldierId, Self, DIARY_MISSIONS));
end;

procedure TSoldierDiaryOverviewState.BtnCommendationsClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierDiaryPerformanceState.Create(Self, FBase, FSoldierId, Self, DIARY_COMMENDATIONS));
end;

procedure TSoldierDiaryOverviewState.LstDiaryInfoClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierDiaryMissionState.Create(Self, FSoldier, FLstDiary.GetSelectedRow));
end;

end.