unit ActionMenuState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.Action, Engine.Options,
  Battlescape.BattlescapeGame, Battlescape.ActionMenuItem,
  Savegame.BattleUnit, Savegame.BattleItem, Mod.RuleItem,
  Engine.LocalizedText, Engine.Unicode;

type
  TActionMenuState = class(TState)
  private
    FAction: TBattleAction;
    FActionMenu: array[0..5] of TActionMenuItem;
    procedure AddItem(BA: TBattleActionType; const AName: string; var ID: Integer);
    procedure BtnActionMenuItemClick(Sender: TObject);
  public
    constructor Create(var AAction: TBattleAction; AX, AY: Integer);
    destructor Destroy; override;
    procedure Handle(AAction: TAction); override;
    procedure Resize(var dX, dY: Integer); override;
  end;

implementation

uses
  Battlescape.PrimeGrenadeState, Battlescape.MedikitState, Battlescape.ScannerState,
  Savegame.SavedGame, Savegame.SavedBattleGame, Savegame.Tile,
  Pathfinding, TileEngine, Interface.Text;

constructor TActionMenuState.Create(var AAction: TBattleAction; AX, AY: Integer);
var
  I: Integer;
  Weapon: TRuleItem;
  ID: Integer;
begin
  inherited Create;
  FAction := AAction;
  _screen := False;

  Game.GetSavedGame.GetSavedBattle.SetPaletteByDepth(Self);

  for I := 0 to 5 do
  begin
    FActionMenu[I] := TActionMenuItem.Create(I, Game, AX, AY);
    Add(FActionMenu[I]);
    FActionMenu[I].SetVisible(False);
    FActionMenu[I].OnMouseClick := BtnActionMenuItemClick;
  end;

  ID := 0;
  Weapon := FAction.Weapon.GetRules;

  if not Weapon.IsFixed then
    AddItem(BA_THROW, 'STR_THROW', ID);

  if ((Weapon.GetBattleType = BT_GRENADE) or (Weapon.GetBattleType = BT_PROXIMITYGRENADE)) and
     (FAction.Weapon.GetFuseTimer = -1) then
    AddItem(BA_PRIME, 'STR_PRIME_GRENADE', ID);

  if Weapon.GetBattleType = BT_FIREARM then
  begin
    if (Weapon.GetWaypoints <> 0) or
       ((FAction.Weapon.GetAmmoItem <> nil) and (FAction.Weapon.GetAmmoItem.GetRules.GetWaypoints <> 0)) then
      AddItem(BA_LAUNCH, 'STR_LAUNCH_MISSILE', ID)
    else
    begin
      if Weapon.GetAccuracyAuto <> 0 then
        AddItem(BA_AUTOSHOT, 'STR_AUTO_SHOT', ID);
      if Weapon.GetAccuracySnap <> 0 then
        AddItem(BA_SNAPSHOT, 'STR_SNAP_SHOT', ID);
      if Weapon.GetAccuracyAimed <> 0 then
        AddItem(BA_AIMEDSHOT, 'STR_AIMED_SHOT', ID);
    end;
  end;

  if Weapon.GetTUMelee <> 0 then
  begin
    if (Weapon.GetBattleType = BT_MELEE) and (Weapon.GetDamageType = DT_STUN) then
      AddItem(BA_HIT, 'STR_STUN', ID)
    else
      AddItem(BA_HIT, 'STR_HIT_MELEE', ID);
  end
  else if Weapon.GetBattleType = BT_MEDIKIT then
    AddItem(BA_USE, 'STR_USE_MEDI_KIT', ID)
  else if Weapon.GetBattleType = BT_SCANNER then
    AddItem(BA_USE, 'STR_USE_SCANNER', ID)
  else if (Weapon.GetBattleType = BT_PSIAMP) and (FAction.Actor.GetBaseStats.PsiSkill > 0) then
  begin
    AddItem(BA_MINDCONTROL, 'STR_MIND_CONTROL', ID);
    AddItem(BA_PANIC, 'STR_PANIC_UNIT', ID);
  end
  else if Weapon.GetBattleType = BT_MINDPROBE then
    AddItem(BA_USE, 'STR_USE_MIND_PROBE', ID);
end;

destructor TActionMenuState.Destroy;
begin
  inherited;
end;

procedure TActionMenuState.AddItem(BA: TBattleActionType; const AName: string; var ID: Integer);
var
  S1, S2: string;
  Acc, TU: Integer;
begin
  Acc := FAction.Actor.GetFiringAccuracy(BA, FAction.Weapon);
  if BA = BA_THROW then
    Acc := Round(FAction.Actor.GetThrowingAccuracy);
  TU := FAction.Actor.GetActionTUs(BA, FAction.Weapon);

  if BA in [BA_THROW, BA_AIMEDSHOT, BA_SNAPSHOT, BA_AUTOSHOT, BA_LAUNCH, BA_HIT] then
    S1 := Tr('STR_ACCURACY_SHORT').Arg(Unicode.FormatPercentage(Acc));
  S2 := Tr('STR_TIME_UNITS_SHORT').Arg(TU);

  FActionMenu[ID].SetAction(BA, Tr(AName), S1, S2, TU);
  FActionMenu[ID].SetVisible(True);
  Inc(ID);
end;

procedure TActionMenuState.Handle(AAction: TAction);
begin
  inherited;
  if (AAction.GetDetails.typ = SDL_MOUSEBUTTONDOWN) and
     (AAction.GetDetails.button.button = SDL_BUTTON_RIGHT) then
    Game.PopState
  else if (AAction.GetDetails.typ = SDL_KEYDOWN) and
          ((AAction.GetDetails.key.keysym.sym = Options.keyCancel) or
           (AAction.GetDetails.key.keysym.sym = Options.keyBattleUseLeftHand) or
           (AAction.GetDetails.key.keysym.sym = Options.keyBattleUseRightHand)) then
    Game.PopState;
end;

procedure TActionMenuState.BtnActionMenuItemClick(Sender: TObject);
var
  BtnID, I: Integer;
  Weapon: TRuleItem;
  WeaponUsable: string;
  TargetUnit: TBattleUnit;
  Units: TList<TBattleUnit>;
  Tile: TTile;
begin
  Game.GetSavedGame.GetSavedBattle.GetPathfinding.RemovePreview;

  BtnID := -1;
  for I := 0 to 5 do
    if Sender = FActionMenu[I] then
    begin
      BtnID := I;
      Break;
    end;

  if BtnID = -1 then Exit;

  FAction.aType := FActionMenu[BtnID].GetAction;
  FAction.TU := FActionMenu[BtnID].GetTUs;

  Weapon := FAction.Weapon.GetRules;

  if (FAction.aType <> BA_THROW) and
     (FAction.Actor.GetOriginalFaction = FACTION_PLAYER) and
     (not Game.GetSavedGame.IsResearched(Weapon.GetRequirements)) then
  begin
    FAction.Result := 'STR_UNABLE_TO_USE_ALIEN_ARTIFACT_UNTIL_RESEARCHED';
    Game.PopState;
    Exit;
  end;

  WeaponUsable := Game.GetSavedGame.GetSavedBattle.GetItemUsable(FAction.Weapon);
  if (FAction.aType <> BA_THROW) and (WeaponUsable <> '') then
  begin
    FAction.Result := WeaponUsable;
    Game.PopState;
    Exit;
  end;

  if FAction.aType = BA_PRIME then
  begin
    if Weapon.GetBattleType = BT_PROXIMITYGRENADE then
    begin
      FAction.Value := 0;
      Game.PopState;
    end
    else
      Game.PushState(TPrimeGrenadeState.Create(FAction, False, 0));
    Exit;
  end;

  if (FAction.aType = BA_USE) and (Weapon.GetBattleType = BT_MEDIKIT) then
  begin
    TargetUnit := nil;
    Units := Game.GetSavedGame.GetSavedBattle.GetUnits;
    for I := 0 to Units.Count - 1 do
    begin
      if (Units[I].GetPosition = FAction.Actor.GetPosition) and
         (Units[I] <> FAction.Actor) and
         (Units[I].GetStatus = STATUS_UNCONSCIOUS) and
         (Units[I].IsWoundable) then
      begin
        TargetUnit := Units[I];
        Break;
      end;
    end;
    if TargetUnit = nil then
    begin
      if Game.GetSavedGame.GetSavedBattle.GetTileEngine.ValidMeleeRange(
           FAction.Actor.GetPosition, FAction.Actor.GetDirection,
           FAction.Actor, nil, FAction.Target, False) then
      begin
        Tile := Game.GetSavedGame.GetSavedBattle.GetTile(FAction.Target);
        if (Tile <> nil) and (Tile.GetUnit <> nil) and (Tile.GetUnit.IsWoundable) then
          TargetUnit := Tile.GetUnit;
      end;
    end;
    if TargetUnit <> nil then
    begin
      Game.PopState;
      Game.PushState(TMedikitState.Create(TargetUnit, FAction));
    end
    else
    begin
      FAction.Result := 'STR_THERE_IS_NO_ONE_THERE';
      Game.PopState;
    end;
    Exit;
  end;

  if (FAction.aType = BA_USE) and (Weapon.GetBattleType = BT_SCANNER) then
  begin
    if FAction.Actor.SpendTimeUnits(FAction.TU) then
    begin
      Game.PopState;
      Game.PushState(TScannerState.Create(FAction));
    end
    else
    begin
      FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS';
      Game.PopState;
    end;
    Exit;
  end;

  if FAction.aType = BA_LAUNCH then
  begin
    if FAction.TU > FAction.Actor.GetTimeUnits then
      FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS'
    else if (FAction.Weapon.GetAmmoItem = nil) or
            (FAction.Weapon.GetAmmoItem.GetAmmoQuantity = 0) then
      FAction.Result := 'STR_NO_AMMUNITION_LOADED'
    else
      FAction.Targeting := True;
    Game.PopState;
    Exit;
  end;

  if FAction.aType = BA_HIT then
  begin
    if FAction.TU > FAction.Actor.GetTimeUnits then
      FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS'
    else if not Game.GetSavedGame.GetSavedBattle.GetTileEngine.ValidMeleeRange(
              FAction.Actor.GetPosition, FAction.Actor.GetDirection,
              FAction.Actor, nil, FAction.Target) then
      FAction.Result := 'STR_THERE_IS_NO_ONE_THERE';
    Game.PopState;
    if FAction.Result <> '' then
      FAction.aType := BA_NONE;
    Exit;
  end;

  FAction.Targeting := True;
  Game.PopState;
end;

procedure TActionMenuState.Resize(var dX, dY: Integer);
begin
  inherited;
  // reposition if needed
end;

end.