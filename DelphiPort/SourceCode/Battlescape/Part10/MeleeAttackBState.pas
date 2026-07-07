unit MeleeAttackBState;

interface

uses
  Classes, SysUtils,
  Battlescape.BattleState,
  Battlescape.BattlescapeGame,
  Battlescape.Position,
  Savegame.BattleUnit,
  Savegame.BattleItem,
  Savegame.Tile;

type
  TMeleeAttackBState = class(TBattleState)
  private
    FUnit: TBattleUnit;
    FTarget: TBattleUnit;
    FWeapon: TBattleItem;
    FAmmo: TBattleItem;
    FVoxel: TPosition;
    FInitialized: Boolean;
    procedure PerformMeleeAttack;
    procedure ResolveHit;
  public
    constructor Create(Parent: TBattlescapeGame; Action: TBattleAction);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
  end;

implementation

uses
  Engine.RNG,
  Engine.Sound,
  Mod.Mod,
  Mod.RuleItem,
  Mod.Armor,
  Savegame.SavedBattleGame,
  Battlescape.ExplosionBState,
  Battlescape.TileEngine,
  Battlescape.AIModule,
  Battlescape.BattlescapeState,
  Battlescape.Map,
  fmath;

{ TMeleeAttackBState }

constructor TMeleeAttackBState.Create(Parent: TBattlescapeGame; Action: TBattleAction);
begin
  inherited Create(Parent, Action);
  FUnit := nil;
  FTarget := nil;
  FWeapon := nil;
  FAmmo := nil;
  FVoxel := TPosition.Create(0,0,0);
  FInitialized := False;
end;

destructor TMeleeAttackBState.Destroy;
begin
  inherited;
end;

procedure TMeleeAttackBState.Init;
begin
  if FInitialized then Exit;
  FInitialized := True;

  FWeapon := FAction.Weapon;
  if FWeapon = nil then
  begin
    FParent.PopState;
    Exit;
  end;
  FAmmo := FWeapon.AmmoItem;
  if FAmmo = nil then
    FAmmo := FWeapon;

  if FParent.Save.GetTile(FAction.Target) = nil then
  begin
    FParent.PopState;
    Exit;
  end;

  FUnit := FAction.Actor;
  if FUnit.IsOut or (FUnit.Health = 0) or (FUnit.Health < FUnit.Stunlevel) then
  begin
    FParent.PopState;
    Exit;
  end;

  // Reaction fire
  if FUnit.Faction <> FParent.Save.Side then
  begin
    if (FAmmo = nil) or (FParent.Save.GetTile(FAction.Target).Unit = nil) or
       (FParent.Save.GetTile(FAction.Target).Unit.IsOut) or
       (FParent.Save.GetTile(FAction.Target).Unit <> FParent.Save.SelectedUnit) then
    begin
      FUnit.SetTimeUnits(FUnit.TimeUnits + FUnit.GetActionTUs(FAction.Type_, FAction.Weapon));
      FParent.PopState;
      Exit;
    end;
    FUnit.LookAt(FAction.Target, FUnit.TurretType <> -1);
    while FUnit.Status = STATUS_TURNING do
      FUnit.Turn;
  end;

  if (FUnit.Faction = FParent.Save.Side) and (FUnit.Faction <> FACTION_PLAYER) and
     (not FParent.DebugPlay) and Assigned(FUnit.AIModule) and Assigned(FUnit.AIModule.Target) then
    FTarget := FUnit.AIModule.Target
  else
    FTarget := FParent.Save.GetTile(FAction.Target).Unit;

  if FTarget <> nil then
  begin
    FVoxel := FAction.Target * TPosition.Create(16,16,24) +
              TPosition.Create(8, 8, FTarget.FloatHeight + FTarget.Height div 2 - FParent.Save.GetTile(FAction.Target).TerrainLevel);
  end;

  PerformMeleeAttack;
end;

procedure TMeleeAttackBState.PerformMeleeAttack;
begin
  FUnit.Aim(True);
  FUnit.SetCache(0);
  FParent.Map.CacheUnit(FUnit);

  if (FAmmo <> nil) and (FAmmo.Rules.MeleeAttackSound <> -1) then
    FParent.Mod.GetSoundByDepth(FParent.Depth, FAmmo.Rules.MeleeAttackSound).Play(-1, FParent.Map.GetSoundAngle(FAction.Target))
  else if (FWeapon.Rules.MeleeAttackSound <> -1) then
    FParent.Mod.GetSoundByDepth(FParent.Depth, FWeapon.Rules.MeleeAttackSound).Play(-1, FParent.Map.GetSoundAngle(FAction.Target));

  if not FParent.Save.DebugMode and (FWeapon.Rules.BattleType = BT_MELEE) and Assigned(FAmmo) and (not FAmmo.SpendBullet) then
  begin
    FParent.Save.RemoveItem(FAmmo);
    FAction.Weapon.SetAmmoItem(nil);
  end;

  FParent.Map.SetCursorType(CT_NONE);
  FParent.StatePushFront(TExplosionBState.Create(FParent, FVoxel, FAction.Weapon, FAction.Actor, 0, True, True));
end;

procedure TMeleeAttackBState.ResolveHit;
var
  DamageType: TItemDamageType;
  Power: Integer;
  DamagePos: TPosition;
begin
  if RNG.Percent(FUnit.GetFiringAccuracy(BA_HIT, FWeapon)) then
  begin
    if Assigned(FUnit.GeoscapeSoldier) and Assigned(FTarget) and (FTarget.OriginalFaction = FACTION_HOSTILE) then
      FUnit.AddMeleeExp;

    if (FWeapon.Rules.BattleType = BT_MELEE) and Assigned(FAmmo) and (FAmmo.Rules.ZombieUnit <> '') and
       Assigned(FTarget) and ((FTarget.GeoscapeSoldier <> nil) or (FTarget.UnitRules.Race = 'STR_CIVILIAN')) and
       (FTarget.SpawnUnit = '') then
    begin
      FTarget.Respawn := True;
      FTarget.SpawnUnit := FAmmo.Rules.ZombieUnit;
    end;

    DamageType := DT_STUN;
    Power := FWeapon.Rules.MeleePower;
    if (FWeapon.Rules.BattleType = BT_MELEE) and Assigned(FAmmo) then
    begin
      DamageType := FAmmo.Rules.DamageType;
      Power := FAmmo.Rules.Power;
    end;

    if FWeapon.Rules.IsStrengthApplied then
      Power := Power + FUnit.BaseStats.Strength;

    if FWeapon.Rules.MeleeHitSound <> -1 then
      FParent.Mod.GetSoundByDepth(FParent.Depth, FAction.Weapon.Rules.MeleeHitSound).Play(-1, FParent.Map.GetSoundAngle(FAction.Target));

    // Offset damage position slightly
    DamagePos := FUnit.Position - FAction.Target;
    DamagePos.X := Clamp(DamagePos.X, -1, 1);
    DamagePos.Y := Clamp(DamagePos.Y, -1, 1);
    DamagePos := FVoxel + DamagePos;

    FParent.Save.TileEngine.Hit(DamagePos, Power, DamageType, FUnit);
    FParent.CheckForCasualties(FAmmo, FUnit);
  end;
end;

procedure TMeleeAttackBState.Think;
begin
  FParent.Save.BattleState.ClearMouseScrollingState;

  if (FUnit.SpecialAbility = SPECAB_BURNFLOOR) or (FUnit.SpecialAbility = SPECAB_BURN_AND_EXPLODE) then
    FParent.Save.GetTile(FAction.Target).Ignite(15);

  ResolveHit;

  // Alien may continue attacking if it has enough TUs
  if (FUnit.Faction <> FACTION_PLAYER) and (FUnit.Faction = FParent.Save.Side) and
     (FUnit.TimeUnits >= FUnit.GetActionTUs(BA_HIT, FAction.Weapon) * 2) and
     Assigned(FTarget) and (FTarget.Health > 0) and (FTarget.Health > FTarget.Stunlevel) and
     Assigned(FWeapon.AmmoItem) then
  begin
    FUnit.SpendTimeUnits(FUnit.GetActionTUs(BA_HIT, FWeapon));
    PerformMeleeAttack;
  end
  else
  begin
    if FAction.CameraPosition.Z <> -1 then
    begin
      FParent.Map.Camera.SetMapOffset(FAction.CameraPosition);
      FParent.Map.Invalidate;
    end;

    if FUnit.Faction = FParent.Save.Side then
      FParent.CurrentAction.Type_ := BA_NONE;

    if (FParent.Save.Side = FACTION_PLAYER) or FParent.Save.DebugMode then
      FParent.SetupCursor;
    FParent.ConvertInfected;
    FParent.PopState;
  end;
end;

end.