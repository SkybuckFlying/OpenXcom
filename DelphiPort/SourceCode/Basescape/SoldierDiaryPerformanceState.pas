unit SoldierDiaryPerformanceState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Engine.SurfaceSet, Interface.TextButton, Interface.Window,
  Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.Soldier, Savegame.SoldierDiary,
  Mod.RuleCommendations, SoldierDiaryOverviewState;

type
  TSoldierDiaryDisplay = (DIARY_KILLS, DIARY_MISSIONS, DIARY_COMMENDATIONS);

  TSoldierDiaryPerformanceState = class(TState)
  private
    FBase: TBase;
    FSoldierId: Integer;
    FSoldierDiaryOverviewState: TSoldierDiaryOverviewState;
    FSoldier: TSoldier;
    FList: TList<TSoldier>;

    FBtnOk, FBtnPrev, FBtnNext, FBtnKills, FBtnMissions, FBtnCommendations: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtMedalName, FTxtMedalLevel, FTxtMedalInfo: TText;
    FLstPerformance, FLstKillTotals, FLstMissionTotals, FLstCommendations: TTextList;
    FCommendationsListEntry: TStringList;
    FCommendations, FCommendationDecorations: TList<TSurface>;
    FCommendationSprite, FCommendationDecoration: TSurfaceSet;
    FDisplay: TSoldierDiaryDisplay;
    FLastScrollPos: Integer;
    FGroup: TTextButton;

    procedure DrawSprites;
    procedure LstInfoMouseOver(Sender: TObject; Action: TAction);
    procedure LstInfoMouseOut(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase; SoldierId: Integer;
      SoldierDiaryOverviewState: TSoldierDiaryOverviewState; Display: TSoldierDiaryDisplay);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnPrevClick(Sender: TObject; Action: TAction);
    procedure BtnNextClick(Sender: TObject; Action: TAction);
    procedure BtnKillsToggle(Sender: TObject; Action: TAction);
    procedure BtnMissionsToggle(Sender: TObject; Action: TAction);
    procedure BtnCommendationsToggle(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSoldierDiaryPerformanceState.Create(AOwner: TComponent; Base: TBase; SoldierId: Integer;
  SoldierDiaryOverviewState: TSoldierDiaryOverviewState; Display: TSoldierDiaryDisplay);
var
  i: Integer;
begin
  inherited Create(AOwner);
  FBase := Base;
  FSoldierId := SoldierId;
  FSoldierDiaryOverviewState := SoldierDiaryOverviewState;
  FDisplay := Display;
  FLastScrollPos := 0;

  if FBase = nil then
    FList := FGame.GetSavedGame.GetDeadSoldiers
  else
    FList := FBase.GetSoldiers;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnPrev := TTextButton.Create(28, 14, 8, 8);
  FBtnNext := TTextButton.Create(28, 14, 284, 8);
  FBtnKills := TTextButton.Create(70, 16, 8, 176);
  FBtnMissions := TTextButton.Create(70, 16, 86, 176);
  FBtnCommendations := TTextButton.Create(70, 16, 164, 176);
  FBtnOk := TTextButton.Create(70, 16, 242, 176);
  FTxtTitle := TText.Create(310, 16, 5, 8);
  FLstPerformance := TTextList.Create(288, 128, 8, 28);
  FLstKillTotals := TTextList.Create(302, 9, 8, 164);
  FLstMissionTotals := TTextList.Create(302, 9, 8, 164);
  FTxtMedalName := TText.Create(120, 18, 16, 36);
  FTxtMedalLevel := TText.Create(120, 18, 186, 36);
  FTxtMedalInfo := TText.Create(280, 32, 20, 135);
  FLstCommendations := TTextList.Create(240, 80, 48, 52);

  FCommendations := TList<TSurface>.Create;
  FCommendationDecorations := TList<TSurface>.Create;
  for i := 0 to 9 do
  begin
    FCommendations.Add(TSurface.Create(31, 8, 16, 52 + 8*i));
    FCommendationDecorations.Add(TSurface.Create(31, 8, 16, 52 + 8*i));
  end;

  SetInterface('soldierDiaryPerformance');
  Add(FWindow, 'window', 'soldierDiaryPerformance');
  Add(FBtnOk, 'button', 'soldierDiaryPerformance');
  Add(FBtnKills, 'button', 'soldierDiaryPerformance');
  Add(FBtnMissions, 'button', 'soldierDiaryPerformance');
  Add(FBtnCommendations, 'button', 'soldierDiaryPerformance');
  Add(FBtnPrev, 'button', 'soldierDiaryPerformance');
  Add(FBtnNext, 'button', 'soldierDiaryPerformance');
  Add(FTxtTitle, 'text1', 'soldierDiaryPerformance');
  Add(FLstPerformance, 'list', 'soldierDiaryPerformance');
  Add(FLstKillTotals, 'text2', 'soldierDiaryPerformance');
  Add(FLstMissionTotals, 'text2', 'soldierDiaryPerformance');
  Add(FTxtMedalName, 'text2', 'soldierDiaryPerformance');
  Add(FTxtMedalLevel, 'text2', 'soldierDiaryPerformance');
  Add(FTxtMedalInfo, 'text2', 'soldierDiaryPerformance');
  Add(FLstCommendations, 'list', 'soldierDiaryPerformance');
  for i := 0 to 9 do
  begin
    Add(FCommendations[i]);
    Add(FCommendationDecorations[i]);
  end;
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnKills.SetText(Translate('STR_COMBAT'));
  FBtnKills.OnMouseClick := BtnKillsToggle;
  FBtnMissions.SetText(Translate('STR_PERFORMANCE'));
  FBtnMissions.OnMouseClick := BtnMissionsToggle;
  FBtnCommendations.SetText(Translate('STR_AWARDS'));
  FBtnCommendations.OnMouseClick := BtnCommendationsToggle;

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
  FLstPerformance.SetColumns([273, 15]);
  FLstPerformance.SetDot(True);
  FLstKillTotals.SetColumns([72, 72, 72, 86]);
  FLstMissionTotals.SetColumns([72, 72, 72, 86]);
  FTxtMedalName.SetText(Translate('STR_MEDAL_NAME'));
  FTxtMedalLevel.SetText(Translate('STR_MEDAL_DECOR_LEVEL'));
  FTxtMedalInfo.SetWordWrap(True);

  FLstCommendations.SetColumns([138, 100]);
  FLstCommendations.SetSelectable(True);
  FLstCommendations.SetBackground(FWindow);
  FLstCommendations.OnMouseOver := LstInfoMouseOver;
  FLstCommendations.OnMouseOut := LstInfoMouseOut;

  FBtnKills.SetGroup(@FGroup);
  FBtnMissions.SetGroup(@FGroup);
  FBtnCommendations.SetGroup(@FGroup);
  if FDisplay = DIARY_KILLS then
    FGroup := FBtnKills
  else if FDisplay = DIARY_MISSIONS then
    FGroup := FBtnMissions
  else
    FGroup := FBtnCommendations;
end;

destructor TSoldierDiaryPerformanceState.Destroy;
begin
  FCommendations.Free;
  FCommendationDecorations.Free;
  inherited;
end;

procedure TSoldierDiaryPerformanceState.Init;
var
  mapArray: array[0..2] of TDictionary<string, Integer>;
  titleArray: array[0..2] of string;
  i: Integer;
  pair: TPair<string, Integer>;
  commendation: TRuleCommendations;
  comm: TSoldierCommendations;
begin
  inherited;
  // clear sprites
  for i := 0 to 9 do
  begin
    FCommendations[i].Clear;
    FCommendationDecorations[i].Clear;
  end;
  FLstPerformance.ScrollTo(0);
  FLstKillTotals.ScrollTo(0);
  FLstMissionTotals.ScrollTo(0);
  FLstCommendations.ScrollTo(0);
  FLastScrollPos := 0;

  FLstPerformance.Visible := (FDisplay <> DIARY_COMMENDATIONS);
  FLstKillTotals.Visible := (FDisplay = DIARY_KILLS);
  FLstMissionTotals.Visible := (FDisplay = DIARY_MISSIONS);
  FTxtMedalName.Visible := (FDisplay = DIARY_COMMENDATIONS);
  FTxtMedalLevel.Visible := (FDisplay = DIARY_COMMENDATIONS);
  FTxtMedalInfo.Visible := (FDisplay = DIARY_COMMENDATIONS);
  FLstCommendations.Visible := (FDisplay = DIARY_COMMENDATIONS);
  FBtnCommendations.Visible := not FGame.GetMod.GetCommendationsList.IsEmpty;

  if FList.Count = 0 then
  begin
    FGame.PopState;
    Exit;
  end;
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  FSoldier := FList[FSoldierId];
  FLstKillTotals.ClearList;
  FLstMissionTotals.ClearList;
  FCommendationsListEntry := TStringList.Create;
  FTxtTitle.SetText(FSoldier.GetName);
  FLstPerformance.ClearList;
  FLstCommendations.ClearList;

  if FDisplay = DIARY_KILLS then
  begin
    mapArray[0] := FSoldier.GetDiary.GetAlienRaceTotal;
    mapArray[1] := FSoldier.GetDiary.GetAlienRankTotal;
    mapArray[2] := FSoldier.GetDiary.GetWeaponTotal;
    titleArray[0] := 'STR_NEUTRALIZATIONS_BY_RACE';
    titleArray[1] := 'STR_NEUTRALIZATIONS_BY_RANK';
    titleArray[2] := 'STR_NEUTRALIZATIONS_BY_WEAPON';

    for i := 0 to 2 do
    begin
      FLstPerformance.AddRow([Translate(titleArray[i])]);
      FLstPerformance.SetRowColor(FLstPerformance.GetRows-1, FLstPerformance.GetSecondaryColor);
      for pair in mapArray[i] do
        FLstPerformance.AddRow([Translate(pair.Key), IntToStr(pair.Value)]);
      if i <> 2 then FLstPerformance.AddRow(['']);
    end;

    if (FSoldier.GetCurrentStats.PsiSkill > 0) or
       (Options.PsiStrengthEval and FGame.GetSavedGame.IsResearched(FGame.GetMod.GetPsiRequirements)) then
      FLstKillTotals.AddRow([
        Translate('STR_KILLS').Arg(FSoldier.GetDiary.GetKillTotal),
        Translate('STR_STUNS').Arg(FSoldier.GetDiary.GetStunTotal),
        Translate('STR_DIARY_ACCURACY').Arg(FSoldier.GetDiary.GetAccuracy),
        Translate('STR_MINDCONTROLS').Arg(FSoldier.GetDiary.GetControlTotal)
      ])
    else
      FLstKillTotals.AddRow([
        Translate('STR_KILLS').Arg(FSoldier.GetDiary.GetKillTotal),
        Translate('STR_STUNS').Arg(FSoldier.GetDiary.GetStunTotal),
        Translate('STR_DIARY_ACCURACY').Arg(FSoldier.GetDiary.GetAccuracy)
      ]);
  end
  else if FDisplay = DIARY_MISSIONS then
  begin
    mapArray[0] := FSoldier.GetDiary.GetRegionTotal(FGame.GetSavedGame.GetMissionStatistics);
    mapArray[1] := FSoldier.GetDiary.GetTypeTotal(FGame.GetSavedGame.GetMissionStatistics);
    mapArray[2] := FSoldier.GetDiary.GetUFOTotal(FGame.GetSavedGame.GetMissionStatistics);
    titleArray[0] := 'STR_MISSIONS_BY_LOCATION';
    titleArray[1] := 'STR_MISSIONS_BY_TYPE';
    titleArray[2] := 'STR_MISSIONS_BY_UFO';

    for i := 0 to 2 do
    begin
      FLstPerformance.AddRow([Translate(titleArray[i])]);
      FLstPerformance.SetRowColor(FLstPerformance.GetRows-1, FLstPerformance.GetSecondaryColor);
      for pair in mapArray[i] do
        if pair.Key <> 'NO_UFO' then
          FLstPerformance.AddRow([Translate(pair.Key), IntToStr(pair.Value)]);
      if i <> 2 then FLstPerformance.AddRow(['']);
    end;

    FLstMissionTotals.AddRow([
      Translate('STR_MISSIONS').Arg(FSoldier.GetDiary.GetMissionTotal),
      Translate('STR_WINS').Arg(FSoldier.GetDiary.GetWinTotal(FGame.GetSavedGame.GetMissionStatistics)),
      Translate('STR_SCORE_VALUE').Arg(FSoldier.GetDiary.GetScoreTotal(FGame.GetSavedGame.GetMissionStatistics)),
      Translate('STR_DAYS_WOUNDED').Arg(FSoldier.GetDiary.GetDaysWoundedTotal)
    ]);
  end
  else if (FDisplay = DIARY_COMMENDATIONS) and (not FGame.GetMod.GetCommendationsList.IsEmpty) then
  begin
    for comm in FSoldier.GetDiary.GetSoldierCommendations do
    begin
      commendation := FGame.GetMod.GetCommendation(comm.GetType);
      if comm.GetNoun <> 'noNoun' then
      begin
        FLstCommendations.AddRow([Translate(comm.GetType).Arg(Translate(comm.GetNoun)), Translate(comm.GetDecorationDescription)]);
        FCommendationsListEntry.Add(Translate(commendation.GetDescription).Arg(Translate(comm.GetNoun)));
      end
      else
      begin
        FLstCommendations.AddRow([Translate(comm.GetType), Translate(comm.GetDecorationDescription)]);
        FCommendationsListEntry.Add(Translate(commendation.GetDescription));
      end;
    end;
    DrawSprites;
  end;
end;

procedure TSoldierDiaryPerformanceState.DrawSprites;
var
  i, scrollDepth, idx: Integer;
  comm: TSoldierCommendations;
  commendation: TRuleCommendations;
begin
  if FDisplay <> DIARY_COMMENDATIONS then Exit;

  FCommendationSprite := FGame.GetMod.GetSurfaceSet('Commendations');
  FCommendationDecoration := FGame.GetMod.GetSurfaceSet('CommendationDecorations');

  for i := 0 to 9 do
  begin
    FCommendations[i].Clear;
    FCommendationDecorations[i].Clear;
  end;

  scrollDepth := FLstCommendations.GetScroll;
  idx := 0;
  for comm in FSoldier.GetDiary.GetSoldierCommendations do
  begin
    if (idx < scrollDepth) or (idx - scrollDepth >= 10) then
    begin
      Inc(idx);
      Continue;
    end;
    commendation := FGame.GetMod.GetCommendation(comm.GetType);
    FCommendationSprite.GetFrame(commendation.GetSprite).SetX(0);
    FCommendationSprite.GetFrame(commendation.GetSprite).SetY(0);
    FCommendationSprite.GetFrame(commendation.GetSprite).Blit(FCommendations[idx - scrollDepth]);

    if comm.GetDecorationLevelInt <> 0 then
    begin
      FCommendationDecoration.GetFrame(comm.GetDecorationLevelInt).SetX(0);
      FCommendationDecoration.GetFrame(comm.GetDecorationLevelInt).SetY(0);
      FCommendationDecoration.GetFrame(comm.GetDecorationLevelInt).Blit(FCommendationDecorations[idx - scrollDepth]);
    end;
    Inc(idx);
  end;
end;

procedure TSoldierDiaryPerformanceState.Think;
begin
  inherited;
  if FLastScrollPos <> FLstCommendations.GetScroll then
  begin
    DrawSprites;
    FLastScrollPos := FLstCommendations.GetScroll;
  end;
end;

procedure TSoldierDiaryPerformanceState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FSoldierDiaryOverviewState.SetSoldierId(FSoldierId);
  FGame.PopState;
end;

procedure TSoldierDiaryPerformanceState.BtnPrevClick(Sender: TObject; Action: TAction);
begin
  if FSoldierId = 0 then
    FSoldierId := FList.Count - 1
  else
    Dec(FSoldierId);
  Init;
end;

procedure TSoldierDiaryPerformanceState.BtnNextClick(Sender: TObject; Action: TAction);
begin
  Inc(FSoldierId);
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  Init;
end;

procedure TSoldierDiaryPerformanceState.BtnKillsToggle(Sender: TObject; Action: TAction);
begin
  FDisplay := DIARY_KILLS;
  Init;
end;

procedure TSoldierDiaryPerformanceState.BtnMissionsToggle(Sender: TObject; Action: TAction);
begin
  FDisplay := DIARY_MISSIONS;
  Init;
end;

procedure TSoldierDiaryPerformanceState.BtnCommendationsToggle(Sender: TObject; Action: TAction);
begin
  FDisplay := DIARY_COMMENDATIONS;
  Init;
end;

procedure TSoldierDiaryPerformanceState.LstInfoMouseOver(Sender: TObject; Action: TAction);
var
  sel: Integer;
begin
  sel := FLstCommendations.GetSelectedRow;
  if (sel >= 0) and (sel < FCommendationsListEntry.Count) then
    FTxtMedalInfo.SetText(FCommendationsListEntry[sel])
  else
    FTxtMedalInfo.SetText('');
end;

procedure TSoldierDiaryPerformanceState.LstInfoMouseOut(Sender: TObject; Action: TAction);
begin
  FTxtMedalInfo.SetText('');
end;

end.