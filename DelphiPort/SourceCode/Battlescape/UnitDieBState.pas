unit UnitDieBState;

interface

uses
  Classes, SysUtils,
  Battlescape.BattleState,
  Battlescape.BattlescapeGame,
  Savegame.BattleUnit,
  Mod.RuleItem;

type
  TUnitDieBState = class(TBattleState)
  private
    FUnit: TBattleUnit;
    FDamageType: TItemDamageType;
    FNoSound: Boolean;
    FNoCorpse: Boolean;
    FExtraFrame: Integer;
    procedure ConvertUnitToCorpse;
    procedure PlayDeathSound;
  public
    constructor Create(Parent: TBattlescapeGame; Unit: TBattleUnit; DamageType: TItemDamageType; NoSound: Boolean = False; NoCorpse: Boolean = False);
    destructor Destroy; override;
    procedure Init; override;
    procedure Cancel; override;
    procedure Think; override;
  end;

implementation

uses
  Engine.Options,
  Engine.Sound,
  Engine.Language,
  Engine.RNG,
  Mod.Mod,
  Mod.Armor,
  Savegame.SavedBattleGame,
  Savegame.Tile,
  Savegame.Node,
  Battlescape.TileEngine,
  Battlescape.Map,
  Battlescape.BattlescapeState,
  Battlescape.InfoboxState,
  Battlescape.InfoboxOKState;

{ TUnitDieBState }

constructor TUnitDieBState.Create(Parent: TBattlescapeGame; Unit: TBattleUnit; DamageType: TItemDamageType; NoSound, NoCorpse: Boolean);
begin
  inherited Create(Parent);
  FUnit := Unit;
  FDamageType := DamageType;
  FNoSound := NoSound;
  FNoCorpse := NoCorpse;
  FExtraFrame := 0;

  if (DamageType = DT_HE) or (Unit.Status = STATUS_UNCONSCIOUS) then
  begin
    FUnit.Direction := 3;
    FUnit.StartFalling;
    while FUnit.Status = STATUS_COLLAPSING do
      FUnit.KeepFalling;
    if FParent.Save.IsBeforeGame then
    begin
      if not NoCorpse then ConvertUnitToCorpse;
      FExtraFrame := 3;
    end;
  end
  else
  begin
    if Unit.Faction = FACTION_PLAYER then
      FParent.Map.SetUnitDying(True);
    FParent.SetStateInterval(BattlescapeState.DEFAULT_ANIM_SPEED);
    if Unit.Direction <> 3 then
      FParent.SetStateInterval(BattlescapeState.DEFAULT_ANIM_SPEED div 3);
  end;

  Unit.ClearVisibleTiles;
  Unit.ClearVisibleUnits;
  Unit.FreePatrolTarget;

  if not FParent.Save.IsBeforeGame and (Unit.Faction = FACTION_HOSTILE) then
  begin
    // mark nodes as dangerous
  end;
end;

destructor TUnitDieBState.Destroy;
begin
  inherited;
end;

procedure TUnitDieBState.Init;
begin
  if Assigned(FParent.Save.BattleState) and (FUnit.Tile = nil) then
    FParent.PopState;
end;

procedure TUnitDieBState.Think;
begin
  if FExtraFrame = 3 then
  begin
    FParent.PopState;
    Exit;
  end;

  if (FUnit.Direction <> 3) and (FDamageType <> DT_HE) then
  begin
    FUnit.LookAt((FUnit.Direction + 1) mod 8);
    FUnit.Turn;
    if FUnit.Direction = 3 then
      FParent.SetStateInterval(BattlescapeState.DEFAULT_ANIM_SPEED);
  end
  else if FUnit.Status = STATUS_COLLAPSING then
    FUnit.KeepFalling
  else if not FUnit.IsOut then
  begin
    FUnit.StartFalling;
    if not FNoSound then PlayDeathSound;
    if FUnit.Respawn then
      while FUnit.Status = STATUS_COLLAPSING do
        FUnit.KeepFalling;
  end;

  if FExtraFrame = 2 then
  begin
    FParent.Map.SetUnitDying(False);
    FParent.TileEngine.CalculateUnitLighting;
    FParent.PopState;
    if FUnit.OriginalFaction = FACTION_PLAYER then
    begin
      if FUnit.Status = STATUS_DEAD then
      begin
        if (FDamageType = DT_NONE) and (FUnit.SpawnUnit = '') then
          FParent.Save.BattleState.Game.PushState(TInfoboxOKState.Create(FParent.Save.BattleState.Game.Language.GetString('STR_HAS_DIED_FROM_A_FATAL_WOUND', FUnit.Gender).Replace('%s', FUnit.Name(FParent.Save.BattleState.Game.Language))))
        else if Options.BattleNotifyDeath and (FUnit.GeoscapeSoldier <> nil) then
          FParent.Save.BattleState.Game.PushState(TInfoboxState.Create(FParent.Save.BattleState.Game.Language.GetString('STR_HAS_BEEN_KILLED', FUnit.Gender).Replace('%s', FUnit.Name(FParent.Save.BattleState.Game.Language))));
      end
      else
        FParent.Save.BattleState.Game.PushState(TInfoboxOKState.Create(FParent.Save.BattleState.Game.Language.GetString('STR_HAS_BECOME_UNCONSCIOUS', FUnit.Gender).Replace('%s', FUnit.Name(FParent.Save.BattleState.Game.Language))));
    end;
    if FParent.Save.Side = FACTION_PLAYER then
      FParent.AutoEndBattle;
  end
  else if FExtraFrame = 1 then
    FExtraFrame := 2
  else if FUnit.IsOut then
  begin
    FExtraFrame := 1;
    if not FNoSound and (FDamageType = DT_HE) and (FUnit.Status <> STATUS_UNCONSCIOUS) then
      PlayDeathSound;
    if (FUnit.Status = STATUS_UNCONSCIOUS) and not FUnit.Capturable then
      FUnit.InstaKill;
    if FUnit.TurnsSinceSpotted < 255 then
      FUnit.SetTurnsSinceSpotted(255);
    if FUnit.SpawnUnit <> '' then
      FParent.ConvertUnit(FUnit)
    else if not FNoCorpse then
      ConvertUnitToCorpse;
    if FUnit = FParent.Save.SelectedUnit then
      FParent.Save.SetSelectedUnit(nil);
  end;

  FParent.Map.CacheUnit(FUnit);
end;

procedure TUnitDieBState.Cancel;
begin
  // no cancel
end;

procedure TUnitDieBState.ConvertUnitToCorpse;
var
  LastPos: TPosition;
  Size, I: Integer;
  X, Y: Integer;
  DropItems: Boolean;
  ItemsToKeep: TList<TBattleItem>;
  It: TBattleItem;
  CorpseRules: TRuleItem;
  Corpse: TBattleItem;
  Carrying: Boolean;
begin
  LastPos := FUnit.Position;
  Size := FUnit.Armor.Size;
  DropItems := FUnit.HasInventory and (not Options.WeaponSelfDestruction or (FUnit.OriginalFaction <> FACTION_HOSTILE) or (FUnit.Status = STATUS_UNCONSCIOUS));

  if not FNoSound then
    FParent.Save.BattleState.ShowPsiButton(False);

  if LastPos <> TPosition.Create(-1,-1,-1) then
    FParent.Save.RemoveUnconsciousBodyItem(FUnit);

  if DropItems then
  begin
    ItemsToKeep := TList<TBattleItem>.Create;
    try
      for It in FUnit.Inventory do
      begin
        FParent.DropItem(LastPos, It);
        if not It.Rules.IsFixed then
          It.Owner := nil
        else
          ItemsToKeep.Add(It);
      end;
      FUnit.Inventory.Clear;
      for It in ItemsToKeep do
        FUnit.Inventory.Add(It);
    finally
      ItemsToKeep.Free;
    end;
  end;

  FUnit.Tile := nil;

  if LastPos = TPosition.Create(-1,-1,-1) then
  begin
    Carrying := False;
    for It in FParent.Save.Items do
      if It.Unit = FUnit then
      begin
        CorpseRules := FParent.Mod.GetItem(FUnit.Armor.CorpseBattlescape[0], True);
        It.ConvertToCorpse(CorpseRules);
        Carrying := True;
        Break;
      end;
    if Carrying then Exit;
  end;

  I := Size * Size - 1;
  for Y := Size - 1 downto 0 do
    for X := Size - 1 downto 0 do
    begin
      Corpse := TBattleItem.Create(FParent.Mod.GetItem(FUnit.Armor.CorpseBattlescape[I], True), FParent.Save.CurrentItemId);
      Corpse.Unit := FUnit;
      if FParent.Save.GetTile(LastPos + TPosition.Create(X,Y,0)).Unit = FUnit then
        FParent.Save.GetTile(LastPos + TPosition.Create(X,Y,0)).Unit := nil;
      FParent.DropItem(LastPos + TPosition.Create(X,Y,0), Corpse, True);
      Dec(I);
    end;
end;

procedure TUnitDieBState.PlayDeathSound;
var
  Sounds: TList<Integer>;
  I: Integer;
begin
  Sounds := FUnit.DeathSounds;
  if Sounds.Count > 0 then
  begin
    I := Sounds[RNG.Generate(0, Sounds.Count - 1)];
    if I >= 0 then
      FParent.Mod.GetSoundByDepth(FParent.Depth, I).Play(-1, FParent.Map.GetSoundAngle(FUnit.Position));
  end;
end;

end.