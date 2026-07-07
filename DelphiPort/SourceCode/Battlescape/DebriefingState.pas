unit DebriefingState;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Math,
  System.Classes, System.Types,
  Engine.State, Engine.Game, Engine.Action, Engine.Options,
  Engine.Screen, Engine.LocalizedText, Engine.Palette, Engine.Sound,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Interface.Bar, Interface.NumberText,
  Mod.Mod, Mod.RuleItem, Mod.RuleCountry, Mod.RuleCraft, Mod.RuleRegion,
  Mod.RuleUfo, Mod.Armor, Mod.AlienDeployment, Mod.RuleCommendations,
  Savegame.SavedGame, Savegame.SavedBattleGame, Savegame.Tile,
  Savegame.BattleUnit, Savegame.BattleItem, Savegame.Soldier,
  Savegame.SoldierDiary, Savegame.Base, Savegame.Craft, Savegame.Ufo,
  Savegame.MissionSite, Savegame.AlienBase, Savegame.AlienMission,
  Savegame.Country, Savegame.Region, Savegame.ItemContainer,
  Savegame.Vehicle, Savegame.BaseFacility, Savegame.MissionStatistics,
  Savegame.BattleUnitStatistics,
  Menu.ErrorMessageState, Menu.MainMenuState, Menu.SaveGameState,
  Basescape.ManageAlienContainmentState, Basescape.SellState,
  Battlescape.PromotionsState, Battlescape.CommendationState,
  Battlescape.CommendationLateState, Battlescape.CannotReequipState;

type
  TDebriefingStat = record
    Item: string;
    Qty: Integer;
    Score: Integer;
    Recovery: Boolean;
  end;

  TReequipStat = record
    Item: string;
    Qty: Integer;
    Craft: string;
  end;

  TRecoveryItem = record
    Name: string;
    Value: Integer;
  end;

  TSoldierStatsEntry = record
    Name: string;
    TU, Stamina, Health, Bravery, Reactions, Firing, Throwing, Melee,
    Strength, PsiStrength, PsiSkill: Integer;
  end;

  TDebriefingState = class(TState)
  private
    FRegion: TRegion;
    FCountry: TCountry;
    FBase: TBase;
    FStats: TList<TDebriefingStat>;
    FSoldierStats: TList<TSoldierStatsEntry>;
    FBtnOk, FBtnStats: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtItem, FTxtQuantity, FTxtScore, FTxtRecovery, FTxtRating: TText;
    FTxtSoldier, FTxtTU, FTxtStamina, FTxtHealth, FTxtBravery, FTxtReactions,
    FTxtFiring, FTxtThrowing, FTxtMelee, FTxtStrength, FTxtPsiStrength, FTxtPsiSkill: TText;
    FTxtTooltip: TText;
    FLstStats, FLstRecovery, FLstTotal, FLstSoldierStats: TTextList;
    FCurrentTooltip: string;
    FMissingItems: TList<TReequipStat>;
    FRounds: TDictionary<TRuleItem, Integer>;
    FRecoveryStats: TDictionary<Integer, TRecoveryItem>;
    FPositiveScore, FNoContainment, FManageContainment, FDestroyBase, FInitDone: Boolean;
    FShowSoldierStats: Boolean;
    FLimitsEnforced: Integer;
    FMissionStatistics: TMissionStatistics;
    FSoldiersCommended, FDeadSoldiersCommended: TList<TSoldier>;
    FPromotions: Boolean;
    procedure AddStat(const AName: string; AQuantity, AScore: Integer);
    procedure PrepareDebriefing;
    procedure RecoverItems(AFrom: TList<TBattleItem>; ABase: TBase);
    procedure RecoverAlien(AFrom: TBattleUnit; ABase: TBase);
    procedure ReequipCraft(ABase: TBase; ACraft: TCraft; AVehicleItemsCanBeDestroyed: Boolean);
    procedure ApplyVisibility;
    function MakeSoldierString(AStat: Integer): string;
    procedure BtnOkClick(Sender: TObject);
    procedure BtnStatsClick(Sender: TObject);
    procedure TxtTooltipIn(AAction: TAction);
    procedure TxtTooltipOut(AAction: TAction);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

uses
  Engine.Logger, Engine.CrossPlatform, Engine.FileMap,
  Savegame.Soldier, Savegame.SoldierDiary, Mod.RuleCommendations;

{ TDebriefingState }

constructor TDebriefingState.Create;
var
  I: Integer;
begin
  inherited Create;
  Options.BaseXResolution := Options.BaseXGeoscape;
  Options.BaseYResolution := Options.BaseYGeoscape;
  FGame.GetScreen.ResetDisplay(False);
  FGame.GetCursor.Visible := True;
  FLimitsEnforced := IfThen(Options.StorageLimitsEnforced, 1, 0);

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(40, 12, 16, 180);
  FBtnStats := TTextButton.Create(40, 12, 264, 180);
  FTxtTitle := TText.Create(300, 17, 16, 8);
  FTxtItem := TText.Create(180, 9, 16, 24);
  FTxtQuantity := TText.Create(60, 9, 200, 24);
  FTxtScore := TText.Create(55, 9, 270, 24);
  FTxtRecovery := TText.Create(180, 9, 16, 60);
  FTxtRating := TText.Create(200, 9, 64, 180);
  FLstStats := TTextList.Create(290, 80, 16, 32);
  FLstRecovery := TTextList.Create(290, 80, 16, 32);
  FLstTotal := TTextList.Create(290, 9, 16, 12);

  // Second page (soldier stats)
  FTxtSoldier := TText.Create(90, 9, 16, 24);
  FTxtTU := TText.Create(18, 9, 106, 24);
  FTxtStamina := TText.Create(18, 9, 124, 24);
  FTxtHealth := TText.Create(18, 9, 142, 24);
  FTxtBravery := TText.Create(18, 9, 160, 24);
  FTxtReactions := TText.Create(18, 9, 178, 24);
  FTxtFiring := TText.Create(18, 9, 196, 24);
  FTxtThrowing := TText.Create(18, 9, 214, 24);
  FTxtMelee := TText.Create(18, 9, 232, 24);
  FTxtStrength := TText.Create(18, 9, 250, 24);
  FTxtPsiStrength := TText.Create(18, 9, 268, 24);
  FTxtPsiSkill := TText.Create(18, 9, 286, 24);
  FLstSoldierStats := TTextList.Create(288, 128, 16, 32);
  FTxtTooltip := TText.Create(200, 9, 64, 180);

  ApplyVisibility;

  SetInterface('debriefing');

  Add(FWindow, 'window', 'debriefing');
  Add(FBtnOk, 'button', 'debriefing');
  Add(FBtnStats, 'button', 'debriefing');
  Add(FTxtTitle, 'heading', 'debriefing');
  Add(FTxtItem, 'text', 'debriefing');
  Add(FTxtQuantity, 'text', 'debriefing');
  Add(FTxtScore, 'text', 'debriefing');
  Add(FTxtRecovery, 'text', 'debriefing');
  Add(FTxtRating, 'text', 'debriefing');
  Add(FLstStats, 'list', 'debriefing');
  Add(FLstRecovery, 'list', 'debriefing');
  Add(FLstTotal, 'totals', 'debriefing');

  Add(FTxtSoldier, 'text', 'debriefing');
  Add(FTxtTU, 'text', 'debriefing');
  Add(FTxtStamina, 'text', 'debriefing');
  Add(FTxtHealth, 'text', 'debriefing');
  Add(FTxtBravery, 'text', 'debriefing');
  Add(FTxtReactions, 'text', 'debriefing');
  Add(FTxtFiring, 'text', 'debriefing');
  Add(FTxtThrowing, 'text', 'debriefing');
  Add(FTxtMelee, 'text', 'debriefing');
  Add(FTxtStrength, 'text', 'debriefing');
  Add(FTxtPsiStrength, 'text', 'debriefing');
  Add(FTxtPsiSkill, 'text', 'debriefing');
  Add(FLstSoldierStats, 'list', 'debriefing');
  Add(FTxtTooltip, 'text', 'debriefing');

  CenterAllSurfaces;

  FWindow.SetBackground(FMod.GetSurface('BACK01.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FBtnStats.OnMouseClick := BtnStatsClick;

  FTxtTitle.Big := True;

  FTxtItem.Text := Tr('STR_LIST_ITEM');
  FTxtQuantity.Text := Tr('STR_QUANTITY_UC');
  FTxtQuantity.Align := ALIGN_RIGHT;
  FTxtScore.Text := Tr('STR_SCORE');

  FLstStats.Columns := [224, 30, 64];
  FLstStats.Dot := True;
  FLstRecovery.Columns := [224, 30, 64];
  FLstRecovery.Dot := True;
  FLstTotal.Columns := [254, 64];
  FLstTotal.Dot := True;

  // Second page
  FTxtSoldier.Text := Tr('STR_NAME_UC');
  FTxtTU.Align := ALIGN_CENTER;
  FTxtTU.Text := Tr('STR_TIME_UNITS_ABBREVIATION');
  FTxtTU.Tooltip := 'STR_TIME_UNITS';
  FTxtTU.OnMouseIn := TxtTooltipIn;
  FTxtTU.OnMouseOut := TxtTooltipOut;

  FTxtStamina.Align := ALIGN_CENTER;
  FTxtStamina.Text := Tr('STR_STAMINA_ABBREVIATION');
  FTxtStamina.Tooltip := 'STR_STAMINA';
  FTxtStamina.OnMouseIn := TxtTooltipIn;
  FTxtStamina.OnMouseOut := TxtTooltipOut;

  FTxtHealth.Align := ALIGN_CENTER;
  FTxtHealth.Text := Tr('STR_HEALTH_ABBREVIATION');
  FTxtHealth.Tooltip := 'STR_HEALTH';
  FTxtHealth.OnMouseIn := TxtTooltipIn;
  FTxtHealth.OnMouseOut := TxtTooltipOut;

  FTxtBravery.Align := ALIGN_CENTER;
  FTxtBravery.Text := Tr('STR_BRAVERY_ABBREVIATION');
  FTxtBravery.Tooltip := 'STR_BRAVERY';
  FTxtBravery.OnMouseIn := TxtTooltipIn;
  FTxtBravery.OnMouseOut := TxtTooltipOut;

  FTxtReactions.Align := ALIGN_CENTER;
  FTxtReactions.Text := Tr('STR_REACTIONS_ABBREVIATION');
  FTxtReactions.Tooltip := 'STR_REACTIONS';
  FTxtReactions.OnMouseIn := TxtTooltipIn;
  FTxtReactions.OnMouseOut := TxtTooltipOut;

  FTxtFiring.Align := ALIGN_CENTER;
  FTxtFiring.Text := Tr('STR_FIRING_ACCURACY_ABBREVIATION');
  FTxtFiring.Tooltip := 'STR_FIRING_ACCURACY';
  FTxtFiring.OnMouseIn := TxtTooltipIn;
  FTxtFiring.OnMouseOut := TxtTooltipOut;

  FTxtThrowing.Align := ALIGN_CENTER;
  FTxtThrowing.Text := Tr('STR_THROWING_ACCURACY_ABBREVIATION');
  FTxtThrowing.Tooltip := 'STR_THROWING_ACCURACY';
  FTxtThrowing.OnMouseIn := TxtTooltipIn;
  FTxtThrowing.OnMouseOut := TxtTooltipOut;

  FTxtMelee.Align := ALIGN_CENTER;
  FTxtMelee.Text := Tr('STR_MELEE_ACCURACY_ABBREVIATION');
  FTxtMelee.Tooltip := 'STR_MELEE_ACCURACY';
  FTxtMelee.OnMouseIn := TxtTooltipIn;
  FTxtMelee.OnMouseOut := TxtTooltipOut;

  FTxtStrength.Align := ALIGN_CENTER;
  FTxtStrength.Text := Tr('STR_STRENGTH_ABBREVIATION');
  FTxtStrength.Tooltip := 'STR_STRENGTH';
  FTxtStrength.OnMouseIn := TxtTooltipIn;
  FTxtStrength.OnMouseOut := TxtTooltipOut;

  FTxtPsiStrength.Align := ALIGN_CENTER;
  FTxtPsiStrength.Text := Tr('STR_PSIONIC_STRENGTH_ABBREVIATION');
  FTxtPsiStrength.Tooltip := 'STR_PSIONIC_STRENGTH';
  FTxtPsiStrength.OnMouseIn := TxtTooltipIn;
  FTxtPsiStrength.OnMouseOut := TxtTooltipOut;

  FTxtPsiSkill.Align := ALIGN_CENTER;
  FTxtPsiSkill.Text := Tr('STR_PSIONIC_SKILL_ABBREVIATION');
  FTxtPsiSkill.Tooltip := 'STR_PSIONIC_SKILL';
  FTxtPsiSkill.OnMouseIn := TxtTooltipIn;
  FTxtPsiSkill.OnMouseOut := TxtTooltipOut;

  FLstSoldierStats.Columns := [90, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 0];
  FLstSoldierStats.Align := ALIGN_CENTER;
  FLstSoldierStats.Align(ALIGN_LEFT, 0);
  FLstSoldierStats.Dot := True;

  FStats := TList<TDebriefingStat>.Create;
  FSoldierStats := TList<TSoldierStatsEntry>.Create;
  FMissingItems := TList<TReequipStat>.Create;
  FRounds := TDictionary<TRuleItem, Integer>.Create;
  FRecoveryStats := TDictionary<Integer, TRecoveryItem>.Create;
  FSoldiersCommended := TList<TSoldier>.Create;
  FDeadSoldiersCommended := TList<TSoldier>.Create;
  FMissionStatistics := TMissionStatistics.Create;
  FInitDone := False;
  FShowSoldierStats := False;
  FPositiveScore := True;
  FNoContainment := False;
  FManageContainment := False;
  FDestroyBase := False;
  FPromotions := False;
end;

destructor TDebriefingState.Destroy;
var
  Stat: TDebriefingStat;
begin
  for Stat in FStats do Stat.Free;
  FStats.Free;
  FSoldierStats.Free;
  FMissingItems.Free;
  FRounds.Free;
  FRecoveryStats.Free;
  FSoldiersCommended.Free;
  FDeadSoldiersCommended.Free;
  FMissionStatistics.Free;
  inherited;
end;

procedure TDebriefingState.Init;
var
  Stat: TDebriefingStat;
  Entry: TSoldierStatsEntry;
  Total, StatsY, RecoveryY, CiviliansSaved, CiviliansDead, AliensKilled, AliensStunned: Integer;
  Rating: string;
  Save: TSavedGame;
  Battle: TSavedBattleGame;
  BestScoreID, BestScore: array[0..6] of Integer;
  BestOverallScorersID, BestOverallScore: Integer;
  Soldier: TSoldier;
  DeadUnit, KillerUnit: TBattleUnit;
  Kill: TBattleUnitKills;
  KillTurn, PostMortemKills, Rank, Score: Integer;
  SoldierAlienKills, SoldierAlienStuns: Integer;
  Participants: TList<TSoldier>;
begin
  inherited;
  if FInitDone then Exit;
  FInitDone := True;

  PrepareDebriefing;

  // Populate soldier stats
  for Entry in FSoldierStats do
    FLstSoldierStats.AddRow(13, [Entry.Name,
                                 MakeSoldierString(Entry.TU),
                                 MakeSoldierString(Entry.Stamina),
                                 MakeSoldierString(Entry.Health),
                                 MakeSoldierString(Entry.Bravery),
                                 MakeSoldierString(Entry.Reactions),
                                 MakeSoldierString(Entry.Firing),
                                 MakeSoldierString(Entry.Throwing),
                                 MakeSoldierString(Entry.Melee),
                                 MakeSoldierString(Entry.Strength),
                                 MakeSoldierString(Entry.PsiStrength),
                                 MakeSoldierString(Entry.PsiSkill),
                                 '']);

  Total := 0; StatsY := 0; RecoveryY := 0;
  CiviliansSaved := 0; CiviliansDead := 0; AliensKilled := 0; AliensStunned := 0;

  for Stat in FStats do
  begin
    if Stat.Qty = 0 then Continue;
    Total := Total + Stat.Score;
    if Stat.Recovery then
    begin
      FLstRecovery.AddRow(3, [Tr(Stat.Item), IntToStr(Stat.Qty), IntToStr(Stat.Score)]);
      RecoveryY := RecoveryY + 8;
    end
    else
    begin
      FLstStats.AddRow(3, [Tr(Stat.Item), IntToStr(Stat.Qty), IntToStr(Stat.Score)]);
      StatsY := StatsY + 8;
    end;
    if Stat.Item = 'STR_CIVILIANS_SAVED' then CiviliansSaved := Stat.Qty;
    if Stat.Item = 'STR_CIVILIANS_KILLED_BY_XCOM_OPERATIVES' then CiviliansDead := CiviliansDead + Stat.Qty;
    if Stat.Item = 'STR_CIVILIANS_KILLED_BY_ALIENS' then CiviliansDead := CiviliansDead + Stat.Qty;
    if Stat.Item = 'STR_ALIENS_KILLED' then AliensKilled := AliensKilled + Stat.Qty;
    if Stat.Item = 'STR_LIVE_ALIENS_RECOVERED' then AliensStunned := AliensStunned + Stat.Qty;
  end;

  if (CiviliansSaved > 0) and (CiviliansDead = 0) and FMissionStatistics.Success then
    FMissionStatistics.ValiantCrux := True;

  FLstTotal.AddRow(2, [Tr('STR_TOTAL_UC'), IntToStr(Total)]);

  if FRegion <> nil then FRegion.AddActivityXcom(Total);
  if FCountry <> nil then FCountry.AddActivityXcom(Total);

  if RecoveryY > 0 then
  begin
    FTxtRecovery.Y := FLstStats.Y + StatsY + 5;
    FLstRecovery.Y := FTxtRecovery.Y + 8;
    FLstTotal.Y := FLstRecovery.Y + RecoveryY + 5;
  end
  else
  begin
    FTxtRecovery.Text := '';
    FLstTotal.Y := FLstStats.Y + StatsY + 5;
  end;

  if Total <= -200 then Rating := 'STR_RATING_TERRIBLE'
  else if Total <= 0 then Rating := 'STR_RATING_POOR'
  else if Total <= 200 then Rating := 'STR_RATING_OK'
  else if Total <= 500 then Rating := 'STR_RATING_GOOD'
  else Rating := 'STR_RATING_EXCELLENT';
  FMissionStatistics.Rating := Rating;
  FMissionStatistics.Score := Total;
  FTxtRating.Text := Tr('STR_RATING').Arg(Tr(Rating));

  Save := FGame.GetSavedGame;
  Battle := Save.GetSavedBattle;
  FMissionStatistics.Daylight := Battle.GetGlobalShade;
  FMissionStatistics.ID := Save.GetMissionStatistics.Count;
  Save.GetMissionStatistics.Add(FMissionStatistics);

  // Award Best-of commendations
  FillChar(BestScoreID, SizeOf(BestScoreID), 0);
  FillChar(BestScore, SizeOf(BestScore), 0);
  BestOverallScorersID := 0;
  BestOverallScore := 0;

  for DeadUnit in Battle.GetUnits do
  begin
    if (DeadUnit.GetGeoscapeSoldier = nil) or (DeadUnit.GetStatus <> STATUS_DEAD) then Continue;
    KillTurn := -1;
    for KillerUnit in Battle.GetUnits do
      for Kill in KillerUnit.GetStatistics.Kills do
        if Kill.ID = DeadUnit.GetId then
        begin
          KillTurn := Kill.Turn;
          Break;
        end;
    PostMortemKills := 0;
    if KillTurn <> -1 then
      for Kill in DeadUnit.GetStatistics.Kills do
        if (Kill.Turn > KillTurn) and (Kill.Faction = FACTION_HOSTILE) then
          Inc(PostMortemKills);
    DeadUnit.GetGeoscapeSoldier.GetDiary.AwardPostMortemKill(PostMortemKills);

    Rank := Ord(DeadUnit.GetGeoscapeSoldier.Rank);
    if Rank = Ord(RANK_ROOKIE) then Continue;

    for Soldier in Save.GetDeadSoldiers do
    begin
      Score := Soldier.GetDiary.GetScoreTotal(Save.GetMissionStatistics);
      if Soldier.GetId = DeadUnit.GetId then
        Score := Score + FMissionStatistics.Score;
      if Score > BestScore[Rank] then
      begin
        BestScoreID[Rank] := DeadUnit.GetId;
        BestScore[Rank] := Score;
        if Score > BestOverallScore then
        begin
          BestOverallScorersID := DeadUnit.GetId;
          BestOverallScore := Score;
        end;
      end;
    end;
  end;

  // Award best-of commendations to dead soldiers
  for DeadUnit in Battle.GetUnits do
  begin
    if (DeadUnit.GetGeoscapeSoldier = nil) or (DeadUnit.GetStatus <> STATUS_DEAD) then Continue;
    if DeadUnit.GetId = BestScoreID[Ord(DeadUnit.GetGeoscapeSoldier.Rank)] then
      DeadUnit.GetGeoscapeSoldier.GetDiary.AwardBestOfRank(BestScore[Ord(DeadUnit.GetGeoscapeSoldier.Rank)]);
    if DeadUnit.GetId = BestOverallScorersID then
      DeadUnit.GetGeoscapeSoldier.GetDiary.AwardBestOverall(BestOverallScore);
  end;

  // Process living soldiers
  for var Unit in Battle.GetUnits do
    if Unit.GetGeoscapeSoldier <> nil then
    begin
      SoldierAlienKills := 0;
      SoldierAlienStuns := 0;
      for Kill in Unit.GetStatistics.Kills do
        if Kill.Faction = FACTION_HOSTILE then
        begin
          if Kill.Status = STATUS_DEAD then Inc(SoldierAlienKills);
          if Kill.Status = STATUS_UNCONSCIOUS then Inc(SoldierAlienStuns);
        end;

      if (AliensKilled > 0) and (AliensKilled = SoldierAlienKills) and FMissionStatistics.Success and
         (AliensStunned = SoldierAlienStuns) then
        Unit.GetStatistics.NikeCross := True;
      if (AliensStunned > 0) and (AliensStunned = SoldierAlienStuns) and FMissionStatistics.Success and
         (AliensKilled = 0) then
        Unit.GetStatistics.MercyCross := True;

      Unit.GetStatistics.DaysWounded := Unit.GetGeoscapeSoldier.WoundRecovery;
      FMissionStatistics.InjuryList[Unit.GetGeoscapeSoldier.Id] := Unit.GetGeoscapeSoldier.WoundRecovery;

      // Martyr medal
      if (Unit.GetMurdererId = Unit.GetId) and (Unit.GetStatistics.Kills.Count > 0) then
      begin
        var MartyrKills := 0;
        var MartyrTurn := -1;
        for Kill in Unit.GetStatistics.Kills do
          if Kill.ID = Unit.GetId then
          begin
            MartyrTurn := Kill.Turn;
            Break;
          end;
        for Kill in Unit.GetStatistics.Kills do
          if (Kill.Turn = MartyrTurn) and (Kill.Faction = FACTION_HOSTILE) then
            Inc(MartyrKills);
        if MartyrKills > 0 then
          Unit.GetStatistics.Martyr := Min(MartyrKills, 10);
      end;

      Unit.GetStatistics.Delta := Unit.GetGeoscapeSoldier.GetCurrentStats - Unit.GetGeoscapeSoldier.GetInitStats;
      Unit.GetGeoscapeSoldier.GetDiary.UpdateDiary(Unit.GetStatistics, Save.GetMissionStatistics, FMod);
      if (not Unit.GetStatistics.MIA) and (not Unit.GetStatistics.KIA) and
         Unit.GetGeoscapeSoldier.GetDiary.ManageCommendations(FMod, Save.GetMissionStatistics) then
        FSoldiersCommended.Add(Unit.GetGeoscapeSoldier)
      else if Unit.GetStatistics.MIA or Unit.GetStatistics.KIA then
      begin
        Unit.GetGeoscapeSoldier.GetDiary.ManageCommendations(FMod, Save.GetMissionStatistics);
        FDeadSoldiersCommended.Add(Unit.GetGeoscapeSoldier);
      end;
    end;

  FPositiveScore := (Total > 0);

  Participants := TList<TSoldier>.Create;
  try
    for var Unit in Battle.GetUnits do
      if Unit.GetGeoscapeSoldier <> nil then
        Participants.Add(Unit.GetGeoscapeSoldier);
    FPromotions := Save.HandlePromotions(Participants);
  finally
    Participants.Free;
  end;

  Save.SetBattleGame(nil);

  if FPositiveScore then
    FMod.PlayMusic(Mod.DEBRIEF_MUSIC_GOOD)
  else
    FMod.PlayMusic(Mod.DEBRIEF_MUSIC_BAD);

  if FNoContainment then
  begin
    FGame.PushState(TErrorMessageState.Create(Tr('STR_ALIEN_DIES_NO_ALIEN_CONTAINMENT_FACILITY'),
                   FPalette, FMod.GetInterface('debriefing').GetElement('errorMessage').Color,
                   'BACK01.SCR', FMod.GetInterface('debriefing').GetElement('errorPalette').Color));
    FNoContainment := False;
  end;
end;

procedure TDebriefingState.ApplyVisibility;
begin
  FTxtItem.Visible := not FShowSoldierStats;
  FTxtQuantity.Visible := not FShowSoldierStats;
  FTxtScore.Visible := not FShowSoldierStats;
  FTxtRecovery.Visible := not FShowSoldierStats;
  FTxtRating.Visible := not FShowSoldierStats;
  FLstStats.Visible := not FShowSoldierStats;
  FLstRecovery.Visible := not FShowSoldierStats;
  FLstTotal.Visible := not FShowSoldierStats;

  FTxtSoldier.Visible := FShowSoldierStats;
  FTxtTU.Visible := FShowSoldierStats;
  FTxtStamina.Visible := FShowSoldierStats;
  FTxtHealth.Visible := FShowSoldierStats;
  FTxtBravery.Visible := FShowSoldierStats;
  FTxtReactions.Visible := FShowSoldierStats;
  FTxtFiring.Visible := FShowSoldierStats;
  FTxtThrowing.Visible := FShowSoldierStats;
  FTxtMelee.Visible := FShowSoldierStats;
  FTxtStrength.Visible := FShowSoldierStats;
  FTxtPsiStrength.Visible := FShowSoldierStats;
  FTxtPsiSkill.Visible := FShowSoldierStats;
  FLstSoldierStats.Visible := FShowSoldierStats;
  FTxtTooltip.Visible := FShowSoldierStats;

  FBtnStats.Text := IfThen(FShowSoldierStats, Tr('STR_SCORE'), Tr('STR_STATS'));
end;

function TDebriefingState.MakeSoldierString(AStat: Integer): string;
begin
  if AStat = 0 then Result := ''
  else Result := Unicode.TOK_COLOR_FLIP + '+' + IntToStr(AStat) + Unicode.TOK_COLOR_FLIP;
end;

procedure TDebriefingState.AddStat(const AName: string; AQuantity, AScore: Integer);
var
  Found: Boolean;
  Stat: TDebriefingStat;
begin
  Found := False;
  for Stat in FStats do
    if Stat.Item = AName then
    begin
      Stat.Qty := Stat.Qty + AQuantity;
      Stat.Score := Stat.Score + AScore;
      Found := True;
      Break;
    end;
  if not Found then
  begin
    Stat.Item := AName;
    Stat.Qty := AQuantity;
    Stat.Score := AScore;
    Stat.Recovery := False;
    FStats.Add(Stat);
  end;
end;

procedure TDebriefingState.PrepareDebriefing;
var
  Save: TSavedGame;
  Battle: TSavedBattleGame;
  Deploy: TAlienDeployment;
  Craft: TCraft;
  Base: TBase;
  Target: string;
  PlayersInExitArea, PlayersSurvived, PlayersUnconscious, PlayersInEntryArea, PlayersMIA: Integer;
  DeadSoldiers: Integer;
  ObjectiveCompleteText, ObjectiveFailedText: string;
  ObjectiveCompleteScore, ObjectiveFailedScore: Integer;
  Region: TRegion;
  Country: TCountry;
  Ufo: TUfo;
  BaseFac: TBaseFacility;
  MissionSite: TMissionSite;
  AlienBase: TAlienBase;
  Unit: TBattleUnit;
  Soldier: TSoldier;
  Kill: TBattleUnitKills;
  Value, I, J: Integer;
  Item: TBattleItem;
  GroundInv: TRuleInventory;
  TakeToNextStage, CarryToNextStage, RemoveFromGame: TList<TBattleItem>;
  AliensAlive: Integer;
  StatIncrease: TUnitStats;
  TankRule: TRuleItem;
  AmmoItem: TBattleItem;
  Total, ClipSize, AmmoPerVehicle, BAQty, CanBeAdded: Integer;
  Missing: Integer;
  Stat: TDebriefingStat;
  RecoveryItem: TRecoveryItem;
  SpecialType: Integer;
begin
  Save := FGame.GetSavedGame;
  Battle := Save.GetSavedBattle;
  Deploy := FMod.GetDeployment(Battle.GetMissionType);
  Craft := nil;
  Base := nil;
  Target := '';

  // Initialize recovery stats
  for var ItemType in FMod.GetItemsList do
  begin
    var Rule := FMod.GetItem(ItemType);
    if Rule.GetSpecialType > 1 then
    begin
      RecoveryItem.Name := ItemType;
      RecoveryItem.Value := Rule.GetRecoveryPoints;
      FRecoveryStats.AddOrSetValue(Rule.GetSpecialType, RecoveryItem);
      FMissionStatistics.LootValue := RecoveryItem.Value;
    end;
  end;

  // Add stats
  FStats.Add(TDebriefingStat.Create('STR_ALIENS_KILLED', False));
  FStats.Add(TDebriefingStat.Create('STR_ALIEN_CORPSES_RECOVERED', False));
  FStats.Add(TDebriefingStat.Create('STR_LIVE_ALIENS_RECOVERED', False));
  FStats.Add(TDebriefingStat.Create('STR_ALIEN_ARTIFACTS_RECOVERED', False));

  if Deploy <> nil then
  begin
    if Deploy.GetObjectiveCompleteInfo(ObjectiveCompleteText, ObjectiveCompleteScore) then
      FStats.Add(TDebriefingStat.Create(ObjectiveCompleteText, False));
    if Deploy.GetObjectiveFailedInfo(ObjectiveFailedText, ObjectiveFailedScore) then
      FStats.Add(TDebriefingStat.Create(ObjectiveFailedText, False));
  end;

  FStats.Add(TDebriefingStat.Create('STR_CIVILIANS_KILLED_BY_ALIENS', False));
  FStats.Add(TDebriefingStat.Create('STR_CIVILIANS_KILLED_BY_XCOM_OPERATIVES', False));
  FStats.Add(TDebriefingStat.Create('STR_CIVILIANS_SAVED', False));
  FStats.Add(TDebriefingStat.Create('STR_XCOM_OPERATIVES_KILLED', False));
  FStats.Add(TDebriefingStat.Create('STR_XCOM_OPERATIVES_MISSING_IN_ACTION', False));
  FStats.Add(TDebriefingStat.Create('STR_TANKS_DESTROYED', False));
  FStats.Add(TDebriefingStat.Create('STR_XCOM_CRAFT_LOST', False));

  for var Pair in FRecoveryStats do
    FStats.Add(TDebriefingStat.Create(Pair.Value.Name, True));

  FMissionStatistics.Time := Save.GetTime;
  FMissionStatistics.Type := Battle.GetMissionType;
  FStats.Add(TDebriefingStat.Create(FMod.GetAlienFuelName, True));

  // Find base and craft
  for Base in Save.GetBases do
  begin
    for Craft in Base.GetCrafts do
      if Craft.IsInBattlescape then
      begin
        for Region in Save.GetRegions do
          if Region.GetRules.InsideRegion(Craft.Longitude, Craft.Latitude) then
          begin
            FRegion := Region;
            FMissionStatistics.Region := Region.GetRules.GetType;
            Break;
          end;
        for Country in Save.GetCountries do
          if Country.GetRules.InsideCountry(Craft.Longitude, Craft.Latitude) then
          begin
            FCountry := Country;
            FMissionStatistics.Country := Country.GetRules.GetType;
            Break;
          end;
        if Craft.GetDestination <> nil then
        begin
          FMissionStatistics.MarkerName := Craft.GetDestination.GetMarkerName;
          FMissionStatistics.MarkerId := Craft.GetDestination.GetMarkerId;
          Target := Craft.GetDestination.GetType;
          if Craft.GetDestination is TAlienBase then Target := 'STR_ALIEN_BASE';
          if Craft.GetDestination is TMissionSite then Target := 'STR_MISSION_SITE';
        end;
        Craft.ReturnToBase;
        Craft.SetMissionComplete(True);
        Craft.SetInBattlescape(False);
      end
      else if Craft.GetDestination <> nil then
      begin
        Ufo := Craft.GetDestination as TUfo;
        if (Ufo <> nil) and Ufo.IsInBattlescape then Craft.ReturnToBase;
        var MS := Craft.GetDestination as TMissionSite;
        if (MS <> nil) and MS.IsInBattlescape then Craft.ReturnToBase;
      end;
    if Base.IsInBattlescape then
    begin
      Target := Base.GetType;
      Base.SetInBattlescape(False);
      Base.CleanupDefenses(False);
      for Region in Save.GetRegions do
        if Region.GetRules.InsideRegion(Base.Longitude, Base.Latitude) then
        begin
          FRegion := Region;
          FMissionStatistics.Region := Region.GetRules.GetType;
          Break;
        end;
      for Country in Save.GetCountries do
        if Country.GetRules.InsideCountry(Base.Longitude, Base.Latitude) then
        begin
          FCountry := Country;
          FMissionStatistics.Country := Country.GetRules.GetType;
          Break;
        end;
      for Ufo in Save.GetUfos do
        if AreSame(Ufo.Longitude, Base.Longitude) and AreSame(Ufo.Latitude, Base.Latitude) then
        begin
          FMissionStatistics.Ufo := Ufo.GetRules.GetType;
          FMissionStatistics.AlienRace := Ufo.GetAlienRace;
          Break;
        end;
      if Battle.IsAborted then FDestroyBase := True;
      I := 0;
      while I < Base.GetFacilities.Count do
      begin
        BaseFac := Base.GetFacilities[I];
        if Battle.GetModuleMap[BaseFac.X][BaseFac.Y].Second = 0 then
        begin
          Base.DestroyFacility(I);
          I := 0;
        end
        else
          Inc(I);
      end;
      Base.DestroyDisconnectedFacilities;
    end;
  end;

  // Mission site disappears
  for I := 0 to Save.GetMissionSites.Count - 1 do
    if Save.GetMissionSites[I].IsInBattlescape then
    begin
      FMissionStatistics.AlienRace := Save.GetMissionSites[I].GetAlienRace;
      Save.GetMissionSites[I].Free;
      Save.GetMissionSites.Delete(I);
      Break;
    end;

  // Process units
  DeadSoldiers := 0;
  PlayersInExitArea := 0;
  PlayersSurvived := 0;
  PlayersUnconscious := 0;
  PlayersInEntryArea := 0;
  PlayersMIA := 0;

  for Unit in Battle.GetUnits do
  begin
    if Unit.GetOriginalFaction = FACTION_PLAYER then
    begin
      if Unit.GetStatus <> STATUS_DEAD then
      begin
        if (Unit.GetStatus = STATUS_UNCONSCIOUS) or (Unit.GetFaction = FACTION_HOSTILE) then
          Inc(PlayersUnconscious)
        else if Unit.GetStatus = STATUS_IGNORE_ME then
        begin
          if Unit.GetStunLevel >= Unit.GetHealth then
            Inc(PlayersUnconscious);
        end
        else if Unit.IsInExitArea(END_POINT) then
          Inc(PlayersInExitArea)
        else if Unit.IsInExitArea(START_POINT) then
          Inc(PlayersInEntryArea)
        else if Battle.IsAborted then
          Inc(PlayersMIA);
        Inc(PlayersSurvived);
      end
      else
        Inc(DeadSoldiers);
    end;
  end;

  if PlayersUnconscious + PlayersMIA = PlayersSurvived then
  begin
    PlayersSurvived := PlayersMIA;
    for Unit in Battle.GetUnits do
      if (Unit.GetOriginalFaction = FACTION_PLAYER) and (Unit.GetStatus <> STATUS_DEAD) then
        if (Unit.GetStatus = STATUS_UNCONSCIOUS) or (Unit.GetFaction = FACTION_HOSTILE) or
           ((Unit.GetStatus = STATUS_IGNORE_ME) and (Unit.GetStunLevel >= Unit.GetHealth)) then
          Unit.InstaKill;
  end;

  // UFO processing
  for I := 0 to Save.GetUfos.Count - 1 do
    if Save.GetUfos[I].IsInBattlescape then
    begin
      Ufo := Save.GetUfos[I];
      FMissionStatistics.Ufo := Ufo.GetRules.GetType;
      if Save.GetMonthsPassed <> -1 then
        FMissionStatistics.AlienRace := Ufo.GetAlienRace;
      FTxtRecovery.Text := Tr('STR_UFO_RECOVERY');
      Ufo.SetInBattlescape(False);
      if (Ufo.GetStatus = Ufo.LANDED) and (Battle.IsAborted or (PlayersSurvived = 0)) then
        Ufo.SecondsRemaining := 5
      else
      begin
        Ufo.Free;
        Save.GetUfos.Delete(I);
      end;
      Break;
    end;

  // Check success based on escape type
  var Success := False;
  if Deploy <> nil then
  begin
    if Deploy.GetEscapeType <> ESCAPE_NONE then
    begin
      if Deploy.GetEscapeType <> ESCAPE_EXIT then
        Success := PlayersInEntryArea > 0;
      if Deploy.GetEscapeType <> ESCAPE_ENTRY then
        Success := Success or (PlayersInExitArea > 0);
    end;
  end;

  // Lone survivor medal
  if PlayersSurvived = 1 then
  begin
    for Unit in Battle.GetUnits do
      if (Unit.GetStatus <> STATUS_DEAD) and (Unit.GetOriginalFaction = FACTION_PLAYER) and
         (not Unit.GetStatistics.HasFriendlyFired) and (DeadSoldiers > 0) then
        Unit.GetStatistics.LoneSurvivor := True;
    if DeadSoldiers = 0 then
      for Unit in Battle.GetUnits do
        if (Unit.GetStatus <> STATUS_DEAD) and (Unit.GetOriginalFaction = FACTION_PLAYER) then
          Unit.GetStatistics.IronMan := True;
  end;

  // Alien base processing
  for I := 0 to Save.GetAlienBases.Count - 1 do
    if Save.GetAlienBases[I].IsInBattlescape then
    begin
      AlienBase := Save.GetAlienBases[I];
      FTxtRecovery.Text := Tr('STR_ALIEN_BASE_RECOVERY');
      var DestroyAlienBase := True;
      if Battle.IsAborted or (PlayersSurvived = 0) then
        if not Battle.AllObjectivesDestroyed then
          DestroyAlienBase := False;
      if Deploy <> nil then
        if not Deploy.GetNextStage.IsEmpty then
        begin
          FMissionStatistics.AlienRace := AlienBase.GetAlienRace;
          DestroyAlienBase := False;
        end;
      Success := DestroyAlienBase;
      if DestroyAlienBase then
      begin
        if ObjectiveCompleteText <> '' then
          AddStat(ObjectiveCompleteText, 1, ObjectiveCompleteScore);
        // Remove supply missions
        for var AM in Save.GetAlienMissions do
          if AM.GetAlienBase = AlienBase then AM.SetAlienBase(nil);
        AlienBase.Free;
        Save.GetAlienBases.Delete(I);
        Break;
      end
      else
        AlienBase.SetInBattlescape(False);
    end;

  // Process individual units
  for Unit in Battle.GetUnits do
  begin
    var Status := Unit.GetStatus;
    var Faction := Unit.GetFaction;
    var OldFaction := Unit.GetOriginalFaction;
    var Value := Unit.GetValue;
    Soldier := Save.GetSoldier(Unit.GetId);

    if (Unit.GetTile = nil) and (Unit.GetPosition = Position(-1,-1,-1)) then
    begin
      for Item in Battle.GetItems do
        if (Item.GetUnit = Unit) then
        begin
          if Item.GetOwner <> nil then
            Unit.SetPosition(Item.GetOwner.GetPosition)
          else if Item.GetTile <> nil then
            Unit.SetPosition(Item.GetTile.GetPosition);
        end;
    end;

    if Status = STATUS_DEAD then
    begin
      if (OldFaction = FACTION_HOSTILE) and (Unit.KilledBy = FACTION_PLAYER) then
        AddStat('STR_ALIENS_KILLED', 1, Value)
      else if OldFaction = FACTION_PLAYER then
      begin
        if Soldier <> nil then
        begin
          AddStat('STR_XCOM_OPERATIVES_KILLED', 1, -Value);
          Unit.UpdateGeoscapeStats(Soldier);
          Unit.GetStatistics.KIA := True;
          Save.KillSoldier(Soldier);
        end
        else
          AddStat('STR_TANKS_DESTROYED', 1, -Value);
      end
      else if OldFaction = FACTION_NEUTRAL then
      begin
        if Unit.KilledBy = FACTION_PLAYER then
          AddStat('STR_CIVILIANS_KILLED_BY_XCOM_OPERATIVES', 1, -Value - (2 * (Value div 3)))
        else
          AddStat('STR_CIVILIANS_KILLED_BY_ALIENS', 1, -Value);
      end;
    end
    else
    begin
      if OldFaction = FACTION_PLAYER then
      begin
        if ((Unit.IsInExitArea(START_POINT) or (Unit.GetStatus = STATUS_IGNORE_ME)) and
            ((Battle.GetMissionType <> 'STR_BASE_DEFENSE') or Success)) or
           (not Battle.IsAborted) or
           (Battle.IsAborted and Unit.IsInExitArea(END_POINT)) then
        begin
          Unit.PostMissionProcedures(Save, StatIncrease);
          if Unit.GetGeoscapeSoldier <> nil then
          begin
            var Entry: TSoldierStatsEntry;
            Entry.Name := Unit.GetGeoscapeSoldier.GetName;
            Entry.TU := StatIncrease.TU;
            Entry.Stamina := StatIncrease.Stamina;
            Entry.Health := StatIncrease.Health;
            Entry.Bravery := StatIncrease.Bravery;
            Entry.Reactions := StatIncrease.Reactions;
            Entry.Firing := StatIncrease.Firing;
            Entry.Throwing := StatIncrease.Throwing;
            Entry.Melee := StatIncrease.Melee;
            Entry.Strength := StatIncrease.Strength;
            Entry.PsiStrength := StatIncrease.PsiStrength;
            Entry.PsiSkill := StatIncrease.PsiSkill;
            FSoldierStats.Add(Entry);
          end;
          Inc(PlayersInExitArea);
          RecoverItems(Unit.GetInventory, Base);
          if Soldier <> nil then
            Soldier.CalcStatString(FMod.GetStatStrings,
              Options.PsiStrengthEval and Save.IsResearched(FMod.GetPsiRequirements))
          else
          begin
            Base.GetStorageItems.AddItem(Unit.GetType);
            TankRule := FMod.GetItem(Unit.GetType, True);
            if Unit.GetItem('STR_RIGHT_HAND') <> nil then
            begin
              AmmoItem := Unit.GetItem('STR_RIGHT_HAND').GetAmmoItem;
              if (not TankRule.GetCompatibleAmmo.IsEmpty) and (AmmoItem <> nil) and (AmmoItem.GetAmmoQuantity > 0) then
              begin
                Total := AmmoItem.GetAmmoQuantity;
                if TankRule.GetClipSize > 0 then Total := Total div AmmoItem.GetRules.GetClipSize;
                Base.GetStorageItems.AddItem(TankRule.GetCompatibleAmmo[0], Total);
              end;
            end;
            if Unit.GetItem('STR_LEFT_HAND') <> nil then
            begin
              var SecRule := Unit.GetItem('STR_LEFT_HAND').GetRules;
              AmmoItem := Unit.GetItem('STR_LEFT_HAND').GetAmmoItem;
              if (not SecRule.GetCompatibleAmmo.IsEmpty) and (AmmoItem <> nil) and (AmmoItem.GetAmmoQuantity > 0) then
              begin
                Total := AmmoItem.GetAmmoQuantity;
                if SecRule.GetClipSize > 0 then Total := Total div AmmoItem.GetRules.GetClipSize;
                Base.GetStorageItems.AddItem(SecRule.GetCompatibleAmmo[0], Total);
              end;
            end;
          end;
        end
        else
        begin
          AddStat('STR_XCOM_OPERATIVES_MISSING_IN_ACTION', 1, -Value);
          Dec(PlayersSurvived);
          if Soldier <> nil then
          begin
            Unit.UpdateGeoscapeStats(Soldier);
            Unit.GetStatistics.MIA := True;
            Save.KillSoldier(Soldier);
          end;
        end;
      end
      else if (OldFaction = FACTION_HOSTILE) and
              (not Battle.IsAborted or Unit.IsInExitArea(START_POINT)) and
              (not FDestroyBase) and
              (Faction = FACTION_PLAYER) and
              ((not Unit.IsOut) or (Unit.GetStatus = STATUS_IGNORE_ME)) then
      begin
        if Unit.GetTile <> nil then
          for Item in Unit.GetInventory do
            if not Item.GetRules.IsFixed then
              Unit.GetTile.AddItem(Item, FMod.GetInventory('STR_GROUND', True));
        RecoverAlien(Unit, Base);
      end
      else if OldFaction = FACTION_NEUTRAL then
      begin
        if Battle.IsAborted or (PlayersSurvived = 0) then
          AddStat('STR_CIVILIANS_KILLED_BY_ALIENS', 1, -Unit.GetValue)
        else
          AddStat('STR_CIVILIANS_SAVED', 1, Unit.GetValue);
      end;
    end;
  end;

  // Craft lost
  var LostCraft := False;
  if (Craft <> nil) and (((PlayersInExitArea = 0) and Battle.IsAborted) or (PlayersSurvived = 0)) then
  begin
    AddStat('STR_XCOM_CRAFT_LOST', 1, -Craft.GetRules.GetScore);
    Base.RemoveCraft(Craft, False);
    Craft.Free;
    Craft := nil;
    LostCraft := True;
    PlayersSurvived := 0;
    Success := False;
  end;

  if (Battle.IsAborted or (PlayersSurvived = 0)) and (Target = 'STR_BASE') then
  begin
    for Craft in Base.GetCrafts do
      AddStat('STR_XCOM_CRAFT_LOST', 1, -Craft.GetRules.GetScore);
    PlayersSurvived := 0;
    Success := False;
  end;

  // Recovery
  if (not Battle.IsAborted or Success) and (PlayersSurvived > 0) then
  begin
    if Target = 'STR_BASE' then
      FTxtTitle.Text := Tr('STR_BASE_IS_SAVED')
    else if Target = 'STR_UFO' then
      FTxtTitle.Text := Tr('STR_UFO_IS_RECOVERED')
    else if Target = 'STR_ALIEN_BASE' then
      FTxtTitle.Text := Tr('STR_ALIEN_BASE_DESTROYED')
    else
    begin
      FTxtTitle.Text := Tr('STR_ALIENS_DEFEATED');
      if ObjectiveCompleteText <> '' then
      begin
        var VictoryStat := 0;
        if Deploy <> nil then
        begin
          if Deploy.GetEscapeType <> ESCAPE_EXIT then VictoryStat := PlayersInEntryArea;
          if Deploy.GetEscapeType <> ESCAPE_ENTRY then VictoryStat := VictoryStat + PlayersInExitArea;
        end
        else VictoryStat := 1;
        AddStat(ObjectiveCompleteText, VictoryStat, ObjectiveCompleteScore);
      end;
    end;

    if not Battle.IsAborted then
    begin
      RecoverItems(Battle.GetConditionalRecoveredItems, Base);
      var NonRecoverType := 0;
      if Deploy <> nil then NonRecoverType := Deploy.GetObjectiveType;
      for I := 0 to Battle.GetMapSizeXYZ - 1 do
      begin
        for var Part := O_FLOOR to O_OBJECT do
          if Battle.GetTiles[I].GetMapData(TilePart(Part)) <> nil then
          begin
            SpecialType := Battle.GetTiles[I].GetMapData(TilePart(Part)).GetSpecialType;
            if (SpecialType <> NonRecoverType) and FRecoveryStats.ContainsKey(SpecialType) then
            begin
              var Rec := FRecoveryStats[SpecialType];
              AddStat(Rec.Name, 1, Rec.Value);
            end;
          end;
        RecoverItems(Battle.GetTiles[I].GetInventory, Base);
      end;
    end
    else
    begin
      for I := 0 to Battle.GetMapSizeXYZ - 1 do
        if Battle.GetTiles[I].GetMapData(O_FLOOR) <> nil then
          if Battle.GetTiles[I].GetMapData(O_FLOOR).GetSpecialType = START_POINT then
            RecoverItems(Battle.GetTiles[I].GetInventory, Base);
    end;
  end
  else
  begin
    if LostCraft then
      FTxtTitle.Text := Tr('STR_CRAFT_IS_LOST')
    else if Target = 'STR_BASE' then
    begin
      FTxtTitle.Text := Tr('STR_BASE_IS_LOST');
      FDestroyBase := True;
    end
    else if Target = 'STR_UFO' then
      FTxtTitle.Text := Tr('STR_UFO_IS_NOT_RECOVERED')
    else if Target = 'STR_ALIEN_BASE' then
      FTxtTitle.Text := Tr('STR_ALIEN_BASE_STILL_INTACT')
    else
    begin
      FTxtTitle.Text := Tr('STR_TERROR_CONTINUES');
      if ObjectiveFailedText <> '' then
        AddStat(ObjectiveFailedText, 1, ObjectiveFailedScore);
    end;

    if (PlayersSurvived > 0) and (not FDestroyBase) then
      for I := 0 to Battle.GetMapSizeXYZ - 1 do
        if Battle.GetTiles[I].GetMapData(O_FLOOR) <> nil then
          if Battle.GetTiles[I].GetMapData(O_FLOOR).GetSpecialType = START_POINT then
            RecoverItems(Battle.GetTiles[I].GetInventory, Base);
  end;

  // Recover items
  if PlayersSurvived > 0 then
  begin
    var AADivider := IfThen(Target = 'STR_UFO', 10, 150);
    for Stat in FStats do
    begin
      if Stat.Item = FRecoveryStats[ALIEN_ALLOYS].Name then
      begin
        Stat.Qty := Stat.Qty div AADivider;
        Stat.Score := Stat.Score div AADivider;
      end;
      if Stat.Recovery and (Stat.Qty > 0) then
        Base.GetStorageItems.AddItem(Stat.Item, Stat.Qty);
    end;
    RecoverItems(Battle.GetGuaranteedRecoveredItems, Base);
  end;

  // Calculate clips
  for var Pair in FRounds do
  begin
    Total := Pair.Value div Pair.Key.GetClipSize;
    if Total > 0 then
      Base.GetStorageItems.AddItem(Pair.Key.GetType, Total);
  end;

  // Reequip craft
  if Craft <> nil then
    ReequipCraft(Base, Craft, True);

  if Target = 'STR_BASE' then
  begin
    if not FDestroyBase then
    begin
      for Craft in Base.GetCrafts do
        if Craft.GetStatus <> 'STR_OUT' then
          ReequipCraft(Base, Craft, False);
      for var V in Base.GetVehicles do V.Free;
      Base.GetVehicles.Clear;
    end
    else if Save.GetMonthsPassed <> -1 then
    begin
      for I := 0 to Save.GetBases.Count - 1 do
        if Save.GetBases[I] = Base then
        begin
          Base.Free;
          Save.GetBases.Delete(I);
          Base := nil;
          Break;
        end;
    end;

    if FRegion <> nil then
    begin
      var AM := Save.FindAlienMission(FRegion.GetRules.GetType, OBJECTIVE_RETALIATION);
      I := 0;
      while I < Save.GetUfos.Count do
        if Save.GetUfos[I].GetMission = AM then
        begin
          Save.GetUfos[I].Free;
          Save.GetUfos.Delete(I);
        end
        else Inc(I);
      for I := 0 to Save.GetAlienMissions.Count - 1 do
        if Save.GetAlienMissions[I] = AM then
        begin
          Save.GetAlienMissions[I].Free;
          Save.GetAlienMissions.Delete(I);
          Break;
        end;
    end;
  end;

  FMissionStatistics.Success := Success;
  FBase := Base;
end;

procedure TDebriefingState.RecoverItems(AFrom: TList<TBattleItem>; ABase: TBase);
var
  Item: TBattleItem;
  CorpseUnit: TBattleUnit;
  Rule: TRuleItem;
begin
  for Item in AFrom do
  begin
    if Item.GetRules.GetName = FMod.GetAlienFuelName then
      AddStat(FMod.GetAlienFuelName, FMod.GetAlienFuelQuantity, Item.GetRules.GetRecoveryPoints)
    else
    begin
      if Item.GetRules.IsRecoverable and (not Item.GetXCOMProperty) then
      begin
        if Item.GetRules.GetBattleType = BT_CORPSE then
        begin
          CorpseUnit := Item.GetUnit;
          if CorpseUnit.GetStatus = STATUS_DEAD then
          begin
            ABase.GetStorageItems.AddItem(CorpseUnit.GetArmor.GetCorpseGeoscape, 1);
            AddStat('STR_ALIEN_CORPSES_RECOVERED', 1, Item.GetRules.GetRecoveryPoints);
          end
          else if (CorpseUnit.GetStatus = STATUS_UNCONSCIOUS) or
                  ((CorpseUnit.GetStatus = STATUS_IGNORE_ME) and
                   (CorpseUnit.GetHealth > 0) and (CorpseUnit.GetHealth < CorpseUnit.GetStunLevel)) then
          begin
            if CorpseUnit.GetOriginalFaction = FACTION_HOSTILE then
              RecoverAlien(CorpseUnit, ABase);
          end;
        end
        else if not FGame.GetSavedGame.IsResearched(Item.GetRules.GetRequirements) then
          AddStat('STR_ALIEN_ARTIFACTS_RECOVERED', 1, Item.GetRules.GetRecoveryPoints);
      end;

      if (not Item.GetRules.IsFixed) and Item.GetRules.IsRecoverable then
      begin
        case Item.GetRules.GetBattleType of
          BT_CORPSE: ;
          BT_AMMO:
            FRounds.AddOrSetValue(Item.GetRules, FRounds.GetValueOrDefault(Item.GetRules, 0) + Item.GetAmmoQuantity);
          BT_FIREARM, BT_MELEE:
            begin
              var Clip := Item.GetAmmoItem;
              if (Clip <> nil) and (Clip.GetRules.GetClipSize > 0) and (Clip <> Item) then
                FRounds.AddOrSetValue(Clip.GetRules, FRounds.GetValueOrDefault(Clip.GetRules, 0) + Clip.GetAmmoQuantity);
              ABase.GetStorageItems.AddItem(Item.GetRules.GetType, 1);
            end;
          else
            ABase.GetStorageItems.AddItem(Item.GetRules.GetType, 1);
        end;
        if Item.GetRules.GetBattleType = BT_NONE then
          for Craft in ABase.GetCrafts do
            Craft.ReuseItem(Item.GetRules.GetType);
      end;
    end;
  end;
end;

procedure TDebriefingState.RecoverAlien(AFrom: TBattleUnit; ABase: TBase);
var
  NewUnit: TBattleUnit;
begin
  if not AFrom.GetSpawnUnit.IsEmpty then
  begin
    NewUnit := FGame.GetSavedGame.GetSavedBattle.ConvertUnit(AFrom, FGame.GetSavedGame, FMod);
    NewUnit.ConvertToFaction(FACTION_PLAYER);
    Exit;
  end;

  var TypeName := AFrom.GetType;
  if ABase.GetAvailableContainment = 0 then
  begin
    FNoContainment := True;
    if not AFrom.GetArmor.GetCorpseBattlescape.IsEmpty then
    begin
      var CorpseRule := FMod.GetItem(AFrom.GetArmor.GetCorpseBattlescape[0]);
      if CorpseRule <> nil then
      begin
        AddStat('STR_ALIEN_CORPSES_RECOVERED', 1, CorpseRule.GetRecoveryPoints);
        ABase.GetStorageItems.AddItem(AFrom.GetArmor.GetCorpseGeoscape, 1);
      end;
    end;
  end
  else
  begin
    var Research := FMod.GetResearch(TypeName);
    if (Research <> nil) and (not FGame.GetSavedGame.IsResearched(TypeName)) then
      AddStat('STR_LIVE_ALIENS_RECOVERED', 1, AFrom.GetValue * 2)
    else
      AddStat('STR_LIVE_ALIENS_RECOVERED', 1, 10);
    ABase.GetStorageItems.AddItem(TypeName, 1);
    FManageContainment := ABase.GetAvailableContainment - (ABase.GetUsedContainment * FLimitsEnforced) < 0;
  end;
end;

procedure TDebriefingState.ReequipCraft(ABase: TBase; ACraft: TCraft; AVehicleItemsCanBeDestroyed: Boolean);
var
  CraftItems: TDictionary<string, Integer>;
  Pair: TPair<string, Integer>;
  Qty, Missing: Integer;
  CraftVehicles: TItemContainer;
  VehicleType: string;
  TankRule: TRuleItem;
  Size, CanBeAdded, BAQty, AmmoPerVehicle, ClipSize: Integer;
begin
  CraftItems := TDictionary<string, Integer>.Create(ACraft.GetItems.GetContents);
  try
    for Pair in CraftItems do
    begin
      Qty := ABase.GetStorageItems.GetItem(Pair.Key);
      if Qty >= Pair.Value then
        ABase.GetStorageItems.RemoveItem(Pair.Key, Pair.Value)
      else
      begin
        Missing := Pair.Value - Qty;
        ABase.GetStorageItems.RemoveItem(Pair.Key, Qty);
        ACraft.GetItems.RemoveItem(Pair.Key, Missing);
        var Stat: TReequipStat;
        Stat.Item := Pair.Key;
        Stat.Qty := Missing;
        Stat.Craft := ACraft.GetName(FGame.GetLanguage);
        FMissingItems.Add(Stat);
      end;
    end;
  finally
    CraftItems.Free;
  end;

  CraftVehicles := TItemContainer.Create;
  try
    for var V in ACraft.GetVehicles do
      CraftVehicles.AddItem(V.GetRules.GetType);
    if AVehicleItemsCanBeDestroyed then
      for var V in ACraft.GetVehicles do V.Free;
    ACraft.GetVehicles.Clear;

    for var Pair in CraftVehicles.GetContents do
    begin
      Qty := ABase.GetStorageItems.GetItem(Pair.Key);
      TankRule := FMod.GetItem(Pair.Key, True);
      var UnitRule := FMod.GetUnit(TankRule.GetType);
      if UnitRule <> nil then
        Size := FMod.GetArmor(UnitRule.GetArmor, True).GetSize * FMod.GetArmor(UnitRule.GetArmor, True).GetSize
      else
        Size := 4;
      CanBeAdded := Min(Qty, Pair.Value);
      if Qty < Pair.Value then
      begin
        Missing := Pair.Value - Qty;
        var Stat: TReequipStat;
        Stat.Item := Pair.Key;
        Stat.Qty := Missing;
        Stat.Craft := ACraft.GetName(FGame.GetLanguage);
        FMissingItems.Add(Stat);
      end;
      if TankRule.GetCompatibleAmmo.IsEmpty then
      begin
        for var I := 1 to CanBeAdded do
          ACraft.GetVehicles.Add(TVehicle.Create(TankRule, TankRule.GetClipSize, Size));
        ABase.GetStorageItems.RemoveItem(Pair.Key, CanBeAdded);
      end
      else
      begin
        var Ammo := FMod.GetItem(TankRule.GetCompatibleAmmo[0], True);
        if (Ammo.GetClipSize > 0) and (TankRule.GetClipSize > 0) then
        begin
          ClipSize := TankRule.GetClipSize;
          AmmoPerVehicle := ClipSize div Ammo.GetClipSize;
        end
        else
        begin
          ClipSize := Ammo.GetClipSize;
          AmmoPerVehicle := ClipSize;
        end;
        BAQty := ABase.GetStorageItems.GetItem(Ammo.GetType);
        if BAQty < Pair.Value * AmmoPerVehicle then
        begin
          Missing := (Pair.Value * AmmoPerVehicle) - BAQty;
          var Stat: TReequipStat;
          Stat.Item := Ammo.GetType;
          Stat.Qty := Missing;
          Stat.Craft := ACraft.GetName(FGame.GetLanguage);
          FMissingItems.Add(Stat);
        end;
        CanBeAdded := Min(CanBeAdded, BAQty div AmmoPerVehicle);
        if CanBeAdded > 0 then
        begin
          for var I := 1 to CanBeAdded do
          begin
            ACraft.GetVehicles.Add(TVehicle.Create(TankRule, ClipSize, Size));
            ABase.GetStorageItems.RemoveItem(Ammo.GetType, AmmoPerVehicle);
          end;
          ABase.GetStorageItems.RemoveItem(Pair.Key, CanBeAdded);
        end;
      end;
    end;
  finally
    CraftVehicles.Free;
  end;
end;

procedure TDebriefingState.BtnOkClick(Sender: TObject);
begin
  FGame.PopState;
  if FGame.GetSavedGame.GetMonthsPassed = -1 then
    FGame.SetState(TMainMenuState.Create)
  else
  begin
    if FDeadSoldiersCommended.Count > 0 then
      FGame.PushState(TCommendationLateState.Create(FDeadSoldiersCommended));
    if FSoldiersCommended.Count > 0 then
      FGame.PushState(TCommendationState.Create(FSoldiersCommended));
    if not FDestroyBase then
    begin
      if FPromotions then
        FGame.PushState(TPromotionsState.Create);
      if FMissingItems.Count > 0 then
        FGame.PushState(TCannotReequipState.Create(FMissingItems));
      if FManageContainment then
      begin
        FGame.PushState(TManageAlienContainmentState.Create(FBase, OPT_BATTLESCAPE));
        FGame.PushState(TErrorMessageState.Create(Tr('STR_CONTAINMENT_EXCEEDED').Arg(FBase.GetName),
                       FPalette, FMod.GetInterface('debriefing').GetElement('errorMessage').Color,
                       'BACK01.SCR', FMod.GetInterface('debriefing').GetElement('errorPalette').Color));
      end;
      if (not FManageContainment) and Options.StorageLimitsEnforced and FBase.StoresOverfull then
      begin
        FGame.PushState(TSellState.Create(FBase, OPT_BATTLESCAPE));
        FGame.PushState(TErrorMessageState.Create(Tr('STR_STORAGE_EXCEEDED').Arg(FBase.GetName),
                       FPalette, FMod.GetInterface('debriefing').GetElement('errorMessage').Color,
                       'BACK01.SCR', FMod.GetInterface('debriefing').GetElement('errorPalette').Color));
      end;
    end;
    if FGame.GetSavedGame.IsIronman then
      FGame.PushState(TSaveGameState.Create(OPT_GEOSCAPE, SAVE_IRONMAN, FPalette))
    else if Options.Autosave then
      FGame.PushState(TSaveGameState.Create(OPT_GEOSCAPE, SAVE_AUTO_GEOSCAPE, FPalette));
  end;
end;

procedure TDebriefingState.BtnStatsClick(Sender: TObject);
begin
  FShowSoldierStats := not FShowSoldierStats;
  ApplyVisibility;
end;

procedure TDebriefingState.TxtTooltipIn(AAction: TAction);
begin
  FCurrentTooltip := AAction.GetSender.Tooltip;
  FTxtTooltip.Text := Tr(FCurrentTooltip);
end;

procedure TDebriefingState.TxtTooltipOut(AAction: TAction);
begin
  if FCurrentTooltip = AAction.GetSender.Tooltip then
    FTxtTooltip.Text := '';
end;

end.