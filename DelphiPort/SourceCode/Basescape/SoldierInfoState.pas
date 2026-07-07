unit SoldierInfoState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.Bar, Interface.TextButton, Interface.Text, Interface.TextEdit,
  Engine.Surface, Savegame.SavedGame, Savegame.Base,
  Savegame.Craft, Savegame.Soldier, Engine.SurfaceSet,
  Mod.Armor, Menu.ErrorMessageState, SellState,
  SoldierArmorState, SackSoldierState, Mod.RuleInterface,
  Mod.RuleSoldier, Savegame.SoldierDeath,
  SoldierDiaryOverviewState;

type
  TSoldierInfoState = class(TState)
  private
    FBase: TBase;
    FSoldierId: Integer;
    FSoldier: TSoldier;
    FList: TList<TSoldier>;

    FBg, FRank: TSurface;
    FBtnOk, FBtnPrev, FBtnNext, FBtnArmor, FBtnSack, FBtnDiary: TTextButton;
    FTxtRank, FTxtMissions, FTxtKills, FTxtCraft, FTxtRecovery, FTxtPsionic, FTxtDead: TText;
    FEdtSoldier: TTextEdit;

    FTxtTimeUnits, FTxtStamina, FTxtHealth, FTxtBravery, FTxtReactions,
    FTxtFiring, FTxtThrowing, FTxtMelee, FTxtStrength, FTxtPsiStrength, FTxtPsiSkill: TText;
    FNumTimeUnits, FNumStamina, FNumHealth, FNumBravery, FNumReactions,
    FNumFiring, FNumThrowing, FNumMelee, FNumStrength, FNumPsiStrength, FNumPsiSkill: TText;
    FBarTimeUnits, FBarStamina, FBarHealth, FBarBravery, FBarReactions,
    FBarFiring, FBarThrowing, FBarMelee, FBarStrength, FBarPsiStrength, FBarPsiSkill: TBar;

    procedure EdtSoldierPress(Sender: TObject; Action: TAction);
    procedure EdtSoldierChange(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase; SoldierId: Integer);
    destructor Destroy; override;
    procedure Init; override;
    procedure SetSoldierId(Soldier: Integer);
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnPrevClick(Sender: TObject; Action: TAction);
    procedure BtnNextClick(Sender: TObject; Action: TAction);
    procedure BtnArmorClick(Sender: TObject; Action: TAction);
    procedure BtnSackClick(Sender: TObject; Action: TAction);
    procedure BtnDiaryClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSoldierInfoState.Create(AOwner: TComponent; Base: TBase; SoldierId: Integer);
begin
  inherited Create(AOwner);
  FBase := Base;
  FSoldierId := SoldierId;

  if FBase = nil then
  begin
    FList := FGame.GetSavedGame.GetDeadSoldiers;
    if FSoldierId >= FList.Count then
      FSoldierId := 0
    else
      FSoldierId := FList.Count - (1 + FSoldierId);
  end
  else
    FList := FBase.GetSoldiers;

  FBg := TSurface.Create(320, 200, 0, 0);
  FRank := TSurface.Create(26, 23, 4, 4);
  FBtnPrev := TTextButton.Create(28, 14, 0, 33);
  FBtnOk := TTextButton.Create(48, 14, 30, 33);
  FBtnNext := TTextButton.Create(28, 14, 80, 33);
  FBtnArmor := TTextButton.Create(110, 14, 130, 33);
  FEdtSoldier := TTextEdit.Create(Self, 210, 16, 40, 9);
  FBtnSack := TTextButton.Create(60, 14, 260, 33);
  FBtnDiary := TTextButton.Create(60, 14, 260, 48);
  FTxtRank := TText.Create(130, 9, 0, 48);
  FTxtMissions := TText.Create(100, 9, 130, 48);
  FTxtKills := TText.Create(100, 9, 200, 48);
  FTxtCraft := TText.Create(130, 9, 0, 56);
  FTxtRecovery := TText.Create(180, 9, 130, 56);
  FTxtPsionic := TText.Create(150, 9, 0, 66);
  FTxtDead := TText.Create(150, 9, 130, 33);

  var yPos := 80;
  var step := 11;

  FTxtTimeUnits := TText.Create(120, 9, 6, yPos);
  FNumTimeUnits := TText.Create(18, 9, 131, yPos);
  FBarTimeUnits := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtStamina := TText.Create(120, 9, 6, yPos);
  FNumStamina := TText.Create(18, 9, 131, yPos);
  FBarStamina := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtHealth := TText.Create(120, 9, 6, yPos);
  FNumHealth := TText.Create(18, 9, 131, yPos);
  FBarHealth := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtBravery := TText.Create(120, 9, 6, yPos);
  FNumBravery := TText.Create(18, 9, 131, yPos);
  FBarBravery := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtReactions := TText.Create(120, 9, 6, yPos);
  FNumReactions := TText.Create(18, 9, 131, yPos);
  FBarReactions := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtFiring := TText.Create(120, 9, 6, yPos);
  FNumFiring := TText.Create(18, 9, 131, yPos);
  FBarFiring := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtThrowing := TText.Create(120, 9, 6, yPos);
  FNumThrowing := TText.Create(18, 9, 131, yPos);
  FBarThrowing := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtMelee := TText.Create(120, 9, 6, yPos);
  FNumMelee := TText.Create(18, 9, 131, yPos);
  FBarMelee := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtStrength := TText.Create(120, 9, 6, yPos);
  FNumStrength := TText.Create(18, 9, 131, yPos);
  FBarStrength := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtPsiStrength := TText.Create(120, 9, 6, yPos);
  FNumPsiStrength := TText.Create(18, 9, 131, yPos);
  FBarPsiStrength := TBar.Create(170, 7, 150, yPos);
  Inc(yPos, step);
  FTxtPsiSkill := TText.Create(120, 9, 6, yPos);
  FNumPsiSkill := TText.Create(18, 9, 131, yPos);
  FBarPsiSkill := TBar.Create(170, 7, 150, yPos);

  SetInterface('soldierInfo');
  Add(FBg);
  Add(FRank);
  Add(FBtnOk, 'button', 'soldierInfo');
  Add(FBtnPrev, 'button', 'soldierInfo');
  Add(FBtnNext, 'button', 'soldierInfo');
  Add(FBtnArmor, 'button', 'soldierInfo');
  Add(FEdtSoldier, 'text1', 'soldierInfo');
  Add(FBtnSack, 'button', 'soldierInfo');
  Add(FBtnDiary, 'button', 'soldierInfo');
  Add(FTxtRank, 'text1', 'soldierInfo');
  Add(FTxtMissions, 'text1', 'soldierInfo');
  Add(FTxtKills, 'text1', 'soldierInfo');
  Add(FTxtCraft, 'text1', 'soldierInfo');
  Add(FTxtRecovery, 'text1', 'soldierInfo');
  Add(FTxtPsionic, 'text2', 'soldierInfo');
  Add(FTxtDead, 'text2', 'soldierInfo');

  Add(FTxtTimeUnits, 'text2', 'soldierInfo');
  Add(FNumTimeUnits, 'numbers', 'soldierInfo');
  Add(FBarTimeUnits, 'barTUs', 'soldierInfo');
  Add(FTxtStamina, 'text2', 'soldierInfo');
  Add(FNumStamina, 'numbers', 'soldierInfo');
  Add(FBarStamina, 'barEnergy', 'soldierInfo');
  Add(FTxtHealth, 'text2', 'soldierInfo');
  Add(FNumHealth, 'numbers', 'soldierInfo');
  Add(FBarHealth, 'barHealth', 'soldierInfo');
  Add(FTxtBravery, 'text2', 'soldierInfo');
  Add(FNumBravery, 'numbers', 'soldierInfo');
  Add(FBarBravery, 'barBravery', 'soldierInfo');
  Add(FTxtReactions, 'text2', 'soldierInfo');
  Add(FNumReactions, 'numbers', 'soldierInfo');
  Add(FBarReactions, 'barReactions', 'soldierInfo');
  Add(FTxtFiring, 'text2', 'soldierInfo');
  Add(FNumFiring, 'numbers', 'soldierInfo');
  Add(FBarFiring, 'barFiring', 'soldierInfo');
  Add(FTxtThrowing, 'text2', 'soldierInfo');
  Add(FNumThrowing, 'numbers', 'soldierInfo');
  Add(FBarThrowing, 'barThrowing', 'soldierInfo');
  Add(FTxtMelee, 'text2', 'soldierInfo');
  Add(FNumMelee, 'numbers', 'soldierInfo');
  Add(FBarMelee, 'barMelee', 'soldierInfo');
  Add(FTxtStrength, 'text2', 'soldierInfo');
  Add(FNumStrength, 'numbers', 'soldierInfo');
  Add(FBarStrength, 'barStrength', 'soldierInfo');
  Add(FTxtPsiStrength, 'text2', 'soldierInfo');
  Add(FNumPsiStrength, 'numbers', 'soldierInfo');
  Add(FBarPsiStrength, 'barPsiStrength', 'soldierInfo');
  Add(FTxtPsiSkill, 'text2', 'soldierInfo');
  Add(FNumPsiSkill, 'numbers', 'soldierInfo');
  Add(FBarPsiSkill, 'barPsiSkill', 'soldierInfo');

  CenterAllSurfaces;

  FGame.GetMod.GetSurface('BACK06.SCR').Blit(FBg);
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

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

  FBtnArmor.SetText(Translate('STR_ARMOR'));
  FBtnArmor.OnMouseClick := BtnArmorClick;
  FEdtSoldier.SetBig;
  FEdtSoldier.OnChange := EdtSoldierChange;
  FEdtSoldier.OnMousePress := EdtSoldierPress;
  FBtnSack.SetText(Translate('STR_SACK'));
  FBtnSack.OnMouseClick := BtnSackClick;
  FBtnDiary.SetText(Translate('STR_DIARY'));
  FBtnDiary.OnMouseClick := BtnDiaryClick;
  FTxtPsionic.SetText(Translate('STR_IN_PSIONIC_TRAINING'));

  FTxtTimeUnits.SetText(Translate('STR_TIME_UNITS'));
  FBarTimeUnits.SetScale(1.0);
  FTxtStamina.SetText(Translate('STR_STAMINA'));
  FBarStamina.SetScale(1.0);
  FTxtHealth.SetText(Translate('STR_HEALTH'));
  FBarHealth.SetScale(1.0);
  FTxtBravery.SetText(Translate('STR_BRAVERY'));
  FBarBravery.SetScale(1.0);
  FTxtReactions.SetText(Translate('STR_REACTIONS'));
  FBarReactions.SetScale(1.0);
  FTxtFiring.SetText(Translate('STR_FIRING_ACCURACY'));
  FBarFiring.SetScale(1.0);
  FTxtThrowing.SetText(Translate('STR_THROWING_ACCURACY'));
  FBarThrowing.SetScale(1.0);
  FTxtMelee.SetText(Translate('STR_MELEE_ACCURACY'));
  FBarMelee.SetScale(1.0);
  FTxtStrength.SetText(Translate('STR_STRENGTH'));
  FBarStrength.SetScale(1.0);
  FTxtPsiStrength.SetText(Translate('STR_PSIONIC_STRENGTH'));
  FBarPsiStrength.SetScale(1.0);
  FTxtPsiSkill.SetText(Translate('STR_PSIONIC_SKILL'));
  FBarPsiSkill.SetScale(1.0);
end;

destructor TSoldierInfoState.Destroy;
begin
  inherited;
end;

procedure TSoldierInfoState.Init;
var
  initial, current, withArmor: TUnitStats;
  texture: TSurfaceSet;
  craft: string;
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
  FEdtSoldier.SetBig;
  FEdtSoldier.SetText(FSoldier.GetName);
  initial := FSoldier.GetInitStats;
  current := FSoldier.GetCurrentStats;
  withArmor := current + FSoldier.GetArmor.GetStats;

  texture := FGame.GetMod.GetSurfaceSet('BASEBITS.PCK');
  texture.GetFrame(FSoldier.GetRankSprite).SetX(0);
  texture.GetFrame(FSoldier.GetRankSprite).SetY(0);
  texture.GetFrame(FSoldier.GetRankSprite).Blit(FRank);

  FNumTimeUnits.SetText(IntToStr(withArmor.TU));
  FBarTimeUnits.SetMax(current.TU);
  FBarTimeUnits.SetValue(withArmor.TU);
  FBarTimeUnits.SetValue2(Min(withArmor.TU, initial.TU));

  FNumStamina.SetText(IntToStr(withArmor.Stamina));
  FBarStamina.SetMax(current.Stamina);
  FBarStamina.SetValue(withArmor.Stamina);
  FBarStamina.SetValue2(Min(withArmor.Stamina, initial.Stamina));

  FNumHealth.SetText(IntToStr(withArmor.Health));
  FBarHealth.SetMax(current.Health);
  FBarHealth.SetValue(withArmor.Health);
  FBarHealth.SetValue2(Min(withArmor.Health, initial.Health));

  FNumBravery.SetText(IntToStr(withArmor.Bravery));
  FBarBravery.SetMax(current.Bravery);
  FBarBravery.SetValue(withArmor.Bravery);
  FBarBravery.SetValue2(Min(withArmor.Bravery, initial.Bravery));

  FNumReactions.SetText(IntToStr(withArmor.Reactions));
  FBarReactions.SetMax(current.Reactions);
  FBarReactions.SetValue(withArmor.Reactions);
  FBarReactions.SetValue2(Min(withArmor.Reactions, initial.Reactions));

  FNumFiring.SetText(IntToStr(withArmor.Firing));
  FBarFiring.SetMax(current.Firing);
  FBarFiring.SetValue(withArmor.Firing);
  FBarFiring.SetValue2(Min(withArmor.Firing, initial.Firing));

  FNumThrowing.SetText(IntToStr(withArmor.Throwing));
  FBarThrowing.SetMax(current.Throwing);
  FBarThrowing.SetValue(withArmor.Throwing);
  FBarThrowing.SetValue2(Min(withArmor.Throwing, initial.Throwing));

  FNumMelee.SetText(IntToStr(withArmor.Melee));
  FBarMelee.SetMax(current.Melee);
  FBarMelee.SetValue(withArmor.Melee);
  FBarMelee.SetValue2(Min(withArmor.Melee, initial.Melee));

  FNumStrength.SetText(IntToStr(withArmor.Strength));
  FBarStrength.SetMax(current.Strength);
  FBarStrength.SetValue(withArmor.Strength);
  FBarStrength.SetValue2(Min(withArmor.Strength, initial.Strength));

  if FSoldier.GetArmor.GetType = FSoldier.GetRules.GetArmor then
    FBtnArmor.SetText(Translate('STR_ARMOR_').Arg(Translate(FSoldier.GetArmor.GetType)))
  else
    FBtnArmor.SetText(Translate(FSoldier.GetArmor.GetType));

  FBtnSack.Visible := (FGame.GetSavedGame.GetMonthsPassed > -1) and
    not ((FSoldier.GetCraft <> nil) and (FSoldier.GetCraft.GetStatus = 'STR_OUT'));

  FTxtRank.SetText(Translate('STR_RANK_').Arg(Translate(FSoldier.GetRankString)));
  FTxtMissions.SetText(Translate('STR_MISSIONS').Arg(FSoldier.GetMissions));
  FTxtKills.SetText(Translate('STR_KILLS').Arg(FSoldier.GetKills));

  if FSoldier.GetCraft = nil then
    craft := Translate('STR_NONE_UC')
  else
    craft := FSoldier.GetCraft.GetName(FGame.GetLanguage);
  FTxtCraft.SetText(Translate('STR_CRAFT_').Arg(craft));

  if FSoldier.GetWoundRecovery > 0 then
    FTxtRecovery.SetText(Translate('STR_WOUND_RECOVERY').Arg(Translate('STR_DAY', FSoldier.GetWoundRecovery)))
  else
    FTxtRecovery.SetText('');

  FTxtPsionic.Visible := FSoldier.IsInPsiTraining;

  if (current.PsiSkill > 0) or (Options.PsiStrengthEval and FGame.GetSavedGame.IsResearched(FGame.GetMod.GetPsiRequirements)) then
  begin
    FNumPsiStrength.SetText(IntToStr(withArmor.PsiStrength));
    FBarPsiStrength.SetMax(current.PsiStrength);
    FBarPsiStrength.SetValue(withArmor.PsiStrength);
    FBarPsiStrength.SetValue2(Min(withArmor.PsiStrength, initial.PsiStrength));
    FTxtPsiStrength.Visible := True;
    FNumPsiStrength.Visible := True;
    FBarPsiStrength.Visible := True;
  end
  else
  begin
    FTxtPsiStrength.Visible := False;
    FNumPsiStrength.Visible := False;
    FBarPsiStrength.Visible := False;
  end;

  if current.PsiSkill > 0 then
  begin
    FNumPsiSkill.SetText(IntToStr(withArmor.PsiSkill));
    FBarPsiSkill.SetMax(current.PsiSkill);
    FBarPsiSkill.SetValue(withArmor.PsiSkill);
    FBarPsiSkill.SetValue2(Min(withArmor.PsiSkill, initial.PsiSkill));
    FTxtPsiSkill.Visible := True;
    FNumPsiSkill.Visible := True;
    FBarPsiSkill.Visible := True;
  end
  else
  begin
    FTxtPsiSkill.Visible := False;
    FNumPsiSkill.Visible := False;
    FBarPsiSkill.Visible := False;
  end;

  if FBase = nil then
  begin
    FBtnArmor.Visible := False;
    FBtnSack.Visible := False;
    FTxtCraft.Visible := False;
    FTxtDead.Visible := True;
    if (FSoldier.GetDeath <> nil) and (FSoldier.GetDeath.GetCause <> nil) then
      FTxtDead.SetText(Translate('STR_KILLED_IN_ACTION', FSoldier.GetGender))
    else
      FTxtDead.SetText(Translate('STR_MISSING_IN_ACTION', FSoldier.GetGender));
  end
  else
    FTxtDead.Visible := False;
end;

procedure TSoldierInfoState.EdtSoldierPress(Sender: TObject; Action: TAction);
begin
  if FBase = nil then
    FEdtSoldier.SetFocus(False);
end;

procedure TSoldierInfoState.EdtSoldierChange(Sender: TObject; Action: TAction);
begin
  FSoldier.SetName(FEdtSoldier.GetText);
end;

procedure TSoldierInfoState.SetSoldierId(Soldier: Integer);
begin
  FSoldierId := Soldier;
end;

procedure TSoldierInfoState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
  if (FGame.GetSavedGame.GetMonthsPassed > -1) and Options.StorageLimitsEnforced and (FBase <> nil) and FBase.StoresOverfull then
  begin
    FGame.PushState(TSellState.Create(Self, FBase));
    FGame.PushState(TErrorMessageState.Create(Self,
      Translate('STR_STORAGE_EXCEEDED').Arg(FBase.GetName),
      FPalette,
      FGame.GetMod.GetInterface('soldierInfo').GetElement('errorMessage').Color,
      'BACK01.SCR',
      FGame.GetMod.GetInterface('soldierInfo').GetElement('errorPalette').Color));
  end;
end;

procedure TSoldierInfoState.BtnPrevClick(Sender: TObject; Action: TAction);
begin
  if FSoldierId = 0 then
    FSoldierId := FList.Count - 1
  else
    Dec(FSoldierId);
  Init;
end;

procedure TSoldierInfoState.BtnNextClick(Sender: TObject; Action: TAction);
begin
  Inc(FSoldierId);
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  Init;
end;

procedure TSoldierInfoState.BtnArmorClick(Sender: TObject; Action: TAction);
begin
  if (FSoldier.GetCraft = nil) or (FSoldier.GetCraft.GetStatus <> 'STR_OUT') then
    FGame.PushState(TSoldierArmorState.Create(Self, FBase, FSoldierId));
end;

procedure TSoldierInfoState.BtnSackClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSackSoldierState.Create(Self, FBase, FSoldierId));
end;

procedure TSoldierInfoState.BtnDiaryClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TSoldierDiaryOverviewState.Create(Self, FBase, FSoldierId, Self));
end;

end.