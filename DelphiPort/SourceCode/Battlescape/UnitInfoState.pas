unit UnitInfoState;

interface

uses
  Classes, SysUtils,
  Engine.State,
  Engine.Game,
  Engine.Surface,
  Engine.Action,
  Engine.Screen,
  Engine.Options,
  Interface.Text,
  Interface.TextButton,
  Interface.Bar,
  Interface.InteractiveSurface,
  Savegame.BattleUnit,
  Savegame.SavedBattleGame,
  Battlescape.BattlescapeState;

type
  TUnitInfoState = class(TState)
  private
    FBattleGame: TSavedBattleGame;
    FUnit: TBattleUnit;
    FParent: TBattlescapeState;
    FFromInventory: Boolean;
    FMindProbe: Boolean;
    FBg: TSurface;
    FExit: TInteractiveSurface;
    FTxtName: TText;
    FTxtTimeUnits, FTxtEnergy, FTxtHealth, FTxtFatalWounds, FTxtBravery, FTxtMorale,
      FTxtReactions, FTxtFiring, FTxtThrowing, FTxtMelee, FTxtStrength: TText;
    FTxtPsiStrength, FTxtPsiSkill: TText;
    FNumTimeUnits, FNumEnergy, FNumHealth, FNumFatalWounds, FNumBravery, FNumMorale,
      FNumReactions, FNumFiring, FNumThrowing, FNumMelee, FNumStrength: TText;
    FNumPsiStrength, FNumPsiSkill: TText;
    FBarTimeUnits, FBarEnergy, FBarHealth, FBarFatalWounds, FBarBravery, FBarMorale,
      FBarReactions, FBarFiring, FBarThrowing, FBarMelee, FBarStrength: TBar;
    FBarPsiStrength, FBarPsiSkill: TBar;
    FTxtFrontArmor, FTxtLeftArmor, FTxtRightArmor, FTxtRearArmor, FTxtUnderArmor: TText;
    FNumFrontArmor, FNumLeftArmor, FNumRightArmor, FNumRearArmor, FNumUnderArmor: TText;
    FBarFrontArmor, FBarLeftArmor, FBarRightArmor, FBarRearArmor, FBarUnderArmor: TBar;
    FBtnPrev, FBtnNext: TTextButton;
    procedure BtnPrevClick(Action: TAction);
    procedure BtnNextClick(Action: TAction);
    procedure ExitClick(Action: TAction);
  public
    constructor Create(Unit: TBattleUnit; Parent: TBattlescapeState; FromInventory, MindProbe: Boolean);
    destructor Destroy; override;
    procedure Init; override;
    procedure Handle(Action: TAction); override;
  end;

implementation

uses
  Engine.Mod,
  Engine.LocalizedText,
  Engine.Palette,
  Engine.Language,
  Mod.Mod,
  Mod.RuleInterface,
  Mod.Armor,
  Savegame.SavedGame,
  Savegame.Soldier,
  Battlescape.BattlescapeGame;

{ TUnitInfoState }

constructor TUnitInfoState.Create(Unit: TBattleUnit; Parent: TBattlescapeState; FromInventory, MindProbe: Boolean);
var
  YPos, Step: Integer;
begin
  inherited Create;
  FUnit := Unit;
  FParent := Parent;
  FFromInventory := FromInventory;
  FMindProbe := MindProbe;

  if Options.MaximizeInfoScreens then
  begin
    Options.BaseXResolution := Screen.ORIGINAL_WIDTH;
    Options.BaseYResolution := Screen.ORIGINAL_HEIGHT;
    FGame.Screen.ResetDisplay(False);
  end;

  FBattleGame := FGame.SavedGame.SavedBattle;

  FBg := TSurface.Create(320, 200, 0, 0);
  FExit := TInteractiveSurface.Create(320, 180, 0, 20);
  FTxtName := TText.Create(288, 17, 16, 4);

  YPos := 38;
  Step := 9;

  FTxtTimeUnits := TText.Create(140, 9, 8, YPos);
  FNumTimeUnits := TText.Create(18, 9, 150, YPos);
  FBarTimeUnits := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtEnergy := TText.Create(140, 9, 8, YPos);
  FNumEnergy := TText.Create(18, 9, 150, YPos);
  FBarEnergy := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtHealth := TText.Create(140, 9, 8, YPos);
  FNumHealth := TText.Create(18, 9, 150, YPos);
  FBarHealth := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtFatalWounds := TText.Create(140, 9, 8, YPos);
  FNumFatalWounds := TText.Create(18, 9, 150, YPos);
  FBarFatalWounds := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtBravery := TText.Create(140, 9, 8, YPos);
  FNumBravery := TText.Create(18, 9, 150, YPos);
  FBarBravery := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtMorale := TText.Create(140, 9, 8, YPos);
  FNumMorale := TText.Create(18, 9, 150, YPos);
  FBarMorale := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtReactions := TText.Create(140, 9, 8, YPos);
  FNumReactions := TText.Create(18, 9, 150, YPos);
  FBarReactions := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtFiring := TText.Create(140, 9, 8, YPos);
  FNumFiring := TText.Create(18, 9, 150, YPos);
  FBarFiring := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtThrowing := TText.Create(140, 9, 8, YPos);
  FNumThrowing := TText.Create(18, 9, 150, YPos);
  FBarThrowing := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtMelee := TText.Create(140, 9, 8, YPos);
  FNumMelee := TText.Create(18, 9, 150, YPos);
  FBarMelee := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtStrength := TText.Create(140, 9, 8, YPos);
  FNumStrength := TText.Create(18, 9, 150, YPos);
  FBarStrength := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtPsiStrength := TText.Create(140, 9, 8, YPos);
  FNumPsiStrength := TText.Create(18, 9, 150, YPos);
  FBarPsiStrength := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtPsiSkill := TText.Create(140, 9, 8, YPos);
  FNumPsiSkill := TText.Create(18, 9, 150, YPos);
  FBarPsiSkill := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtFrontArmor := TText.Create(140, 9, 8, YPos);
  FNumFrontArmor := TText.Create(18, 9, 150, YPos);
  FBarFrontArmor := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtLeftArmor := TText.Create(140, 9, 8, YPos);
  FNumLeftArmor := TText.Create(18, 9, 150, YPos);
  FBarLeftArmor := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtRightArmor := TText.Create(140, 9, 8, YPos);
  FNumRightArmor := TText.Create(18, 9, 150, YPos);
  FBarRightArmor := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtRearArmor := TText.Create(140, 9, 8, YPos);
  FNumRearArmor := TText.Create(18, 9, 150, YPos);
  FBarRearArmor := TBar.Create(150, 5, 170, YPos+1);
  Inc(YPos, Step);

  FTxtUnderArmor := TText.Create(140, 9, 8, YPos);
  FNumUnderArmor := TText.Create(18, 9, 150, YPos);
  FBarUnderArmor := TBar.Create(150, 5, 170, YPos+1);

  if not FMindProbe then
  begin
    FBtnPrev := TTextButton.Create(14, 18, 2, 2);
    FBtnNext := TTextButton.Create(14, 18, 304, 2);
  end;

  SetPalette('PAL_BATTLESCAPE');

  Add(FBg);
  Add(FExit);
  Add(FTxtName, 'textName', 'stats', nil);

  Add(FTxtTimeUnits); Add(FNumTimeUnits); Add(FBarTimeUnits, 'barTUs', 'stats', nil);
  Add(FTxtEnergy); Add(FNumEnergy); Add(FBarEnergy, 'barEnergy', 'stats', nil);
  Add(FTxtHealth); Add(FNumHealth); Add(FBarHealth, 'barHealth', 'stats', nil);
  Add(FTxtFatalWounds); Add(FNumFatalWounds); Add(FBarFatalWounds, 'barWounds', 'stats', nil);
  Add(FTxtBravery); Add(FNumBravery); Add(FBarBravery, 'barBravery', 'stats', nil);
  Add(FTxtMorale); Add(FNumMorale); Add(FBarMorale, 'barMorale', 'stats', nil);
  Add(FTxtReactions); Add(FNumReactions); Add(FBarReactions, 'barReactions', 'stats', nil);
  Add(FTxtFiring); Add(FNumFiring); Add(FBarFiring, 'barFiring', 'stats', nil);
  Add(FTxtThrowing); Add(FNumThrowing); Add(FBarThrowing, 'barThrowing', 'stats', nil);
  Add(FTxtMelee); Add(FNumMelee); Add(FBarMelee, 'barMelee', 'stats', nil);
  Add(FTxtStrength); Add(FNumStrength); Add(FBarStrength, 'barStrength', 'stats', nil);
  Add(FTxtPsiStrength); Add(FNumPsiStrength); Add(FBarPsiStrength, 'barPsiStrength', 'stats', nil);
  Add(FTxtPsiSkill); Add(FNumPsiSkill); Add(FBarPsiSkill, 'barPsiSkill', 'stats', nil);
  Add(FTxtFrontArmor); Add(FNumFrontArmor); Add(FBarFrontArmor, 'barFrontArmor', 'stats', nil);
  Add(FTxtLeftArmor); Add(FNumLeftArmor); Add(FBarLeftArmor, 'barLeftArmor', 'stats', nil);
  Add(FTxtRightArmor); Add(FNumRightArmor); Add(FBarRightArmor, 'barRightArmor', 'stats', nil);
  Add(FTxtRearArmor); Add(FNumRearArmor); Add(FBarRearArmor, 'barRearArmor', 'stats', nil);
  Add(FTxtUnderArmor); Add(FNumUnderArmor); Add(FBarUnderArmor, 'barUnderArmor', 'stats', nil);

  if not FMindProbe then
  begin
    Add(FBtnPrev, 'button', 'stats');
    Add(FBtnNext, 'button', 'stats');
  end;

  CenterAllSurfaces;

  FGame.Mod.Surface['UNIBORD.PCK'].Blit(FBg);

  FExit.OnMouseClick := ExitClick;
  FExit.OnKeyboardPress(Options.KeyCancel, ExitClick);
  FExit.OnKeyboardPress(Options.KeyBattleStats, ExitClick);

  Uint8 color := FGame.Mod.Interface['stats'].Element['text'].Color;
  Uint8 color2 := FGame.Mod.Interface['stats'].Element['text'].Color2;

  FTxtName.Align := ALIGN_CENTER;
  FTxtName.Big := True;
  FTxtName.HighContrast := True;

  procedure InitText(Txt: TText; const S: string);
  begin
    Txt.Color := color;
    Txt.HighContrast := True;
    Txt.Text := Tr(S);
  end;

  InitText(FTxtTimeUnits, 'STR_TIME_UNITS');
  FNumTimeUnits.Color := color2; FNumTimeUnits.HighContrast := True;
  FBarTimeUnits.Scale := 1.0;

  InitText(FTxtEnergy, 'STR_ENERGY');
  FNumEnergy.Color := color2; FNumEnergy.HighContrast := True;
  FBarEnergy.Scale := 1.0;

  InitText(FTxtHealth, 'STR_HEALTH');
  FNumHealth.Color := color2; FNumHealth.HighContrast := True;
  FBarHealth.Scale := 1.0;

  InitText(FTxtFatalWounds, 'STR_FATAL_WOUNDS');
  FNumFatalWounds.Color := color2; FNumFatalWounds.HighContrast := True;
  FBarFatalWounds.Scale := 1.0;

  InitText(FTxtBravery, 'STR_BRAVERY');
  FNumBravery.Color := color2; FNumBravery.HighContrast := True;
  FBarBravery.Scale := 1.0;

  InitText(FTxtMorale, 'STR_MORALE');
  FNumMorale.Color := color2; FNumMorale.HighContrast := True;
  FBarMorale.Scale := 1.0;

  InitText(FTxtReactions, 'STR_REACTIONS');
  FNumReactions.Color := color2; FNumReactions.HighContrast := True;
  FBarReactions.Scale := 1.0;

  InitText(FTxtFiring, 'STR_FIRING_ACCURACY');
  FNumFiring.Color := color2; FNumFiring.HighContrast := True;
  FBarFiring.Scale := 1.0;

  InitText(FTxtThrowing, 'STR_THROWING_ACCURACY');
  FNumThrowing.Color := color2; FNumThrowing.HighContrast := True;
  FBarThrowing.Scale := 1.0;

  InitText(FTxtMelee, 'STR_MELEE_ACCURACY');
  FNumMelee.Color := color2; FNumMelee.HighContrast := True;
  FBarMelee.Scale := 1.0;

  InitText(FTxtStrength, 'STR_STRENGTH');
  FNumStrength.Color := color2; FNumStrength.HighContrast := True;
  FBarStrength.Scale := 1.0;

  InitText(FTxtPsiStrength, 'STR_PSIONIC_STRENGTH');
  FNumPsiStrength.Color := color2; FNumPsiStrength.HighContrast := True;
  FBarPsiStrength.Scale := 1.0;

  InitText(FTxtPsiSkill, 'STR_PSIONIC_SKILL');
  FNumPsiSkill.Color := color2; FNumPsiSkill.HighContrast := True;
  FBarPsiSkill.Scale := 1.0;

  InitText(FTxtFrontArmor, 'STR_FRONT_ARMOR_UC');
  FNumFrontArmor.Color := color2; FNumFrontArmor.HighContrast := True;
  FBarFrontArmor.Scale := 1.0;

  InitText(FTxtLeftArmor, 'STR_LEFT_ARMOR_UC');
  FNumLeftArmor.Color := color2; FNumLeftArmor.HighContrast := True;
  FBarLeftArmor.Scale := 1.0;

  InitText(FTxtRightArmor, 'STR_RIGHT_ARMOR_UC');
  FNumRightArmor.Color := color2; FNumRightArmor.HighContrast := True;
  FBarRightArmor.Scale := 1.0;

  InitText(FTxtRearArmor, 'STR_REAR_ARMOR_UC');
  FNumRearArmor.Color := color2; FNumRearArmor.HighContrast := True;
  FBarRearArmor.Scale := 1.0;

  InitText(FTxtUnderArmor, 'STR_UNDER_ARMOR_UC');
  FNumUnderArmor.Color := color2; FNumUnderArmor.HighContrast := True;
  FBarUnderArmor.Scale := 1.0;

  if not FMindProbe then
  begin
    FBtnPrev.Text := '<<';
    FBtnPrev.OnMouseClick := BtnPrevClick;
    FBtnPrev.OnKeyboardPress(Options.KeyBattlePrevUnit, BtnPrevClick);
    FBtnNext.Text := '>>';
    FBtnNext.OnMouseClick := BtnNextClick;
    FBtnNext.OnKeyboardPress(Options.KeyBattleNextUnit, BtnNextClick);
  end;

  Init;
end;

destructor TUnitInfoState.Destroy;
begin
  inherited;
end;

procedure TUnitInfoState.Init;
var
  SS: TStringStream;
begin
  inherited;
  SS := TStringStream.Create;
  try
    SS.WriteString(IntToStr(FUnit.TimeUnits));
    FNumTimeUnits.Text := SS.DataString;
    FBarTimeUnits.Max := FUnit.BaseStats.TU;
    FBarTimeUnits.Value := FUnit.TimeUnits;

    SS.Size := 0;
    if FUnit.UnitType = 'SOLDIER' then
      SS.WriteString(Tr(FUnit.RankString) + ' ');
    SS.WriteString(FUnit.Name(FGame.Language, BattlescapeGame.DebugPlay));
    FTxtName.Big := True;
    FTxtName.Text := SS.DataString;

    SS.Size := 0;
    SS.WriteString(IntToStr(FUnit.Energy));
    FNumEnergy.Text := SS.DataString;
    FBarEnergy.Max := FUnit.BaseStats.Stamina;
    FBarEnergy.Value := FUnit.Energy;

    SS.Size := 0;
    SS.WriteString(IntToStr(FUnit.Health));
    FNumHealth.Text := SS.DataString;
    FBarHealth.Max := FUnit.BaseStats.Health;
    FBarHealth.Value := FUnit.Health;
    FBarHealth.Value2 := FUnit.Stunlevel;

    SS.Size := 0;
    SS.WriteString(IntToStr(FUnit.FatalWounds));
    FNumFatalWounds.Text := SS.DataString;
    FBarFatalWounds.Max := FUnit.FatalWounds;
    FBarFatalWounds.Value := FUnit.FatalWounds;

    SS.Size := 0;
    SS.WriteString(IntToStr(FUnit.BaseStats.Bravery));
    FNumBravery.Text := SS.DataString;
    FBarBravery.Max := FUnit.BaseStats.Bravery;
    FBarBravery.Value := FUnit.BaseStats.Bravery;

    SS.Size := 0;
    SS.WriteString(IntToStr(FUnit.Morale));
    FNumMorale.Text := SS.DataString;
    FBarMorale.Max := 100;
    FBarMorale.Value := FUnit.Morale;

    SS.Size := 0;
    SS.WriteString(IntToStr(FUnit.BaseStats.Reactions));
    FNumReactions.Text := SS.DataString;
    FBarReactions.Max := FUnit.BaseStats.Reactions;
    FBarReactions.Value := FUnit.BaseStats.Reactions;

    SS.Size := 0;
    SS.WriteString(IntToStr((FUnit.BaseStats.Firing * FUnit.Health) div FUnit.BaseStats.Health));
    FNumFiring.Text := SS.DataString;
    FBarFiring.Max := FUnit.BaseStats.Firing;
    FBarFiring.Value := (FUnit.BaseStats.Firing * FUnit.Health) div FUnit.BaseStats.Health;

    SS.Size := 0;
    SS.WriteString(IntToStr((FUnit.BaseStats.Throwing * FUnit.Health) div FUnit.BaseStats.Health));
    FNumThrowing.Text := SS.DataString;
    FBarThrowing.Max := FUnit.BaseStats.Throwing;
    FBarThrowing.Value := (FUnit.BaseStats.Throwing * FUnit.Health) div FUnit.BaseStats.Health;

    SS.Size := 0;
    SS.WriteString(IntToStr((FUnit.BaseStats.Melee * FUnit.Health) div FUnit.BaseStats.Health));
    FNumMelee.Text := SS.DataString;
    FBarMelee.Max := FUnit.BaseStats.Melee;
    FBarMelee.Value := (FUnit.BaseStats.Melee * FUnit.Health) div FUnit.BaseStats.Health;

    SS.Size := 0;
    SS.WriteString(IntToStr(FUnit.BaseStats.Strength));
    FNumStrength.Text := SS.DataString;
    FBarStrength.Max := FUnit.BaseStats.Strength;
    FBarStrength.Value := FUnit.BaseStats.Strength;

    if (FUnit.BaseStats.PsiSkill > 0) or (Options.PsiStrengthEval and FGame.SavedGame.IsResearched(FGame.Mod.PsiRequirements)) then
    begin
      SS.Size := 0; SS.WriteString(IntToStr(FUnit.BaseStats.PsiStrength));
      FNumPsiStrength.Text := SS.DataString;
      FBarPsiStrength.Max := FUnit.BaseStats.PsiStrength;
      FBarPsiStrength.Value := FUnit.BaseStats.PsiStrength;
      FTxtPsiStrength.Visible := True; FNumPsiStrength.Visible := True; FBarPsiStrength.Visible := True;
    end
    else
    begin
      FTxtPsiStrength.Visible := False; FNumPsiStrength.Visible := False; FBarPsiStrength.Visible := False;
    end;

    if FUnit.BaseStats.PsiSkill > 0 then
    begin
      SS.Size := 0; SS.WriteString(IntToStr(FUnit.BaseStats.PsiSkill));
      FNumPsiSkill.Text := SS.DataString;
      FBarPsiSkill.Max := FUnit.BaseStats.PsiSkill;
      FBarPsiSkill.Value := FUnit.BaseStats.PsiSkill;
      FTxtPsiSkill.Visible := True; FNumPsiSkill.Visible := True; FBarPsiSkill.Visible := True;
    end
    else
    begin
      FTxtPsiSkill.Visible := False; FNumPsiSkill.Visible := False; FBarPsiSkill.Visible := False;
    end;

    SS.Size := 0; SS.WriteString(IntToStr(FUnit.GetArmor(SIDE_FRONT)));
    FNumFrontArmor.Text := SS.DataString;
    FBarFrontArmor.Max := FUnit.GetMaxArmor(SIDE_FRONT);
    FBarFrontArmor.Value := FUnit.GetArmor(SIDE_FRONT);

    SS.Size := 0; SS.WriteString(IntToStr(FUnit.GetArmor(SIDE_LEFT)));
    FNumLeftArmor.Text := SS.DataString;
    FBarLeftArmor.Max := FUnit.GetMaxArmor(SIDE_LEFT);
    FBarLeftArmor.Value := FUnit.GetArmor(SIDE_LEFT);

    SS.Size := 0; SS.WriteString(IntToStr(FUnit.GetArmor(SIDE_RIGHT)));
    FNumRightArmor.Text := SS.DataString;
    FBarRightArmor.Max := FUnit.GetMaxArmor(SIDE_RIGHT);
    FBarRightArmor.Value := FUnit.GetArmor(SIDE_RIGHT);

    SS.Size := 0; SS.WriteString(IntToStr(FUnit.GetArmor(SIDE_REAR)));
    FNumRearArmor.Text := SS.DataString;
    FBarRearArmor.Max := FUnit.GetMaxArmor(SIDE_REAR);
    FBarRearArmor.Value := FUnit.GetArmor(SIDE_REAR);

    SS.Size := 0; SS.WriteString(IntToStr(FUnit.GetArmor(SIDE_UNDER)));
    FNumUnderArmor.Text := SS.DataString;
    FBarUnderArmor.Max := FUnit.GetMaxArmor(SIDE_UNDER);
    FBarUnderArmor.Value := FUnit.GetArmor(SIDE_UNDER);
  finally
    SS.Free;
  end;
end;

procedure TUnitInfoState.Handle(Action: TAction);
begin
  inherited;
  if Action.Details.Type_ = SDL_MOUSEBUTTONDOWN then
  begin
    if Action.Details.Button.Button = SDL_BUTTON_RIGHT then
      ExitClick(Action)
    else if Action.Details.Button.Button = SDL_BUTTON_X1 then
      if not FMindProbe then BtnNextClick(Action)
    else if Action.Details.Button.Button = SDL_BUTTON_X2 then
      if not FMindProbe then BtnPrevClick(Action);
  end;
end;

procedure TUnitInfoState.BtnPrevClick(Action: TAction);
begin
  if Assigned(FParent) then
    FParent.SelectPreviousPlayerUnit(False, False, FFromInventory)
  else
    FBattleGame.SelectPreviousPlayerUnit(False, False, True);
  FUnit := FBattleGame.SelectedUnit;
  if FUnit <> nil then Init
  else ExitClick(Action);
end;

procedure TUnitInfoState.BtnNextClick(Action: TAction);
begin
  if Assigned(FParent) then
    FParent.SelectNextPlayerUnit(False, False, FFromInventory)
  else
    FBattleGame.SelectNextPlayerUnit(False, False, True);
  FUnit := FBattleGame.SelectedUnit;
  if FUnit <> nil then Init
  else ExitClick(Action);
end;

procedure TUnitInfoState.ExitClick(Action: TAction);
begin
  if not FFromInventory and Options.MaximizeInfoScreens then
  begin
    Screen.UpdateScale(Options.BattlescapeScale, Options.BaseXBattlescape, Options.BaseYBattlescape, True);
    FGame.Screen.ResetDisplay(False);
  end;
  FGame.PopState;
end;

end.