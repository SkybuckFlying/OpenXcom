unit ExplosionBState;

interface

uses
  System.SysUtils,
  BattleState, Position, Battlescape.BattlescapeGame,
  Savegame.BattleUnit, Savegame.BattleItem, Savegame.Tile,
  Mod.RuleItem, Mod.Mod, Engine.RNG, Engine.Sound;

type
  TExplosionBState = class(TBattleState)
  private
    FUnit: TBattleUnit;
    FCenter: TPosition;
    FItem: TBattleItem;
    FTile: TTile;
    FPower: Integer;
    FAreaOfEffect: Boolean;
    FLowerWeapon: Boolean;
    FCosmetic: Boolean;
    procedure Explode;
  public
    constructor Create(AParent: TBattlescapeGame; ACenter: TPosition; AItem: TBattleItem;
                       AUnit: TBattleUnit; ATile: TTile = nil; ALowerWeapon: Boolean = False;
                       ACosmetic: Boolean = False);
    destructor Destroy; override;
    procedure Init; override;
    procedure Cancel; override;
    procedure Think; override;
  end;

implementation

uses
  Battlescape.BattlescapeState, Battlescape.Map, Battlescape.Camera,
  Savegame.SavedBattleGame, TileEngine;

constructor TExplosionBState.Create(AParent: TBattlescapeGame; ACenter: TPosition; AItem: TBattleItem;
                                   AUnit: TBattleUnit; ATile: TTile; ALowerWeapon: Boolean; ACosmetic: Boolean);
begin
  inherited Create(AParent);
  FCenter := ACenter;
  FItem := AItem;
  FUnit := AUnit;
  FTile := ATile;
  FLowerWeapon := ALowerWeapon;
  FCosmetic := ACosmetic;
  FPower := 0;
  FAreaOfEffect := False;
end;

destructor TExplosionBState.Destroy;
begin
  inherited;
end;

procedure TExplosionBState.Init;
var
  Frame, FrameDelay, Counter, LowerLimit, I, X, Y: Integer;
  P, BlastPos: TPosition;
  Expl: TExplosion;
  Tile: TTile;
begin
  if FItem <> nil then
  begin
    FPower := FItem.GetRules.GetPower;
    if FItem.GetRules.IsStrengthApplied and (FUnit <> nil) then
      FPower := FPower + FUnit.GetBaseStats.Strength;
    FAreaOfEffect := (FItem.GetRules.GetBattleType <> BT_MELEE) and
                     (FItem.GetRules.GetExplosionRadius <> 0) and
                     (not FCosmetic);
  end
  else if FTile <> nil then
  begin
    FPower := FTile.GetExplosive;
    FAreaOfEffect := True;
  end
  else if (FUnit <> nil) and ((FUnit.GetSpecialAbility = SPECAB_EXPLODEONDEATH) or
                              (FUnit.GetSpecialAbility = SPECAB_BURN_AND_EXPLODE)) then
  begin
    FPower := FParent.GetMod.GetItem(FUnit.GetArmor.GetCorpseGeoscape, True).GetPower;
    FAreaOfEffect := True;
  end
  else
  begin
    FPower := 120;
    FAreaOfEffect := True;
  end;

  Tile := FParent.GetSave.GetTile(Position(FCenter.X div 16, FCenter.Y div 16, FCenter.Z div 24));

  if FAreaOfEffect then
  begin
    if FPower > 0 then
    begin
      Frame := Mod.EXPLOSION_OFFSET;
      if FItem <> nil then
        Frame := FItem.GetRules.GetHitAnimation;
      if FParent.GetDepth > 0 then
        Frame := Frame - Explosion.EXPLODE_FRAMES;
      FrameDelay := 0;
      Counter := Max(1, (FPower div 5) div 5);
      FParent.GetMap.SetBlastFlash(True);
      LowerLimit := Max(1, FPower div 5);
      for I := 0 to LowerLimit - 1 do
      begin
        X := RNG.Generate(-FPower div 2, FPower div 2);
        Y := RNG.Generate(-FPower div 2, FPower div 2);
        P := FCenter;
        P.X := P.X + X;
        P.Y := P.Y + Y;
        Expl := TExplosion.Create(P, Frame, FrameDelay, True);
        FParent.GetMap.GetExplosions.Add(Expl);
        if (I > 0) and (I mod Counter = 0) then
          Inc(FrameDelay);
      end;
      FParent.SetStateInterval(BattlescapeState.DEFAULT_ANIM_SPEED div 2);
      if FPower <= 80 then
        FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.SMALL_EXPLOSION).Play
      else
        FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.LARGE_EXPLOSION).Play;
      FParent.GetMap.GetCamera.CenterOnPosition(Tile.GetPosition, False);
    end
    else
      FParent.PopState;
  end
  else
  begin
    FParent.SetStateInterval(Max(1, (BattlescapeState.DEFAULT_ANIM_SPEED div 2) - (10 * FItem.GetRules.GetExplosionSpeed)));
    Frame := FItem.GetRules.GetHitAnimation;
    if FCosmetic then
      Frame := FItem.GetRules.GetMeleeAnimation;
    if Frame <> -1 then
    begin
      Expl := TExplosion.Create(FCenter, Frame, 0, False, FCosmetic);
      FParent.GetMap.GetExplosions.Add(Expl);
    end;
    FParent.GetMap.GetCamera.SetViewLevel(FCenter.Z div 24);
    if FCosmetic and (FParent.GetSave.GetSide = FACTION_HOSTILE) and (Tile <> nil) and
       (Tile.GetUnit <> nil) and (Tile.GetUnit.GetFaction = FACTION_PLAYER) then
      FParent.GetMap.GetCamera.CenterOnPosition(Tile.GetPosition, False);
    if (FItem <> nil) and (FItem.GetRules.GetHitSound <> -1) and (not FCosmetic) then
      FParent.GetMod.GetSoundByDepth(FParent.GetDepth, FItem.GetRules.GetHitSound).Play(-1,
        FParent.GetMap.GetSoundAngle(FCenter div Position(16,16,24)));
  end;
end;

procedure TExplosionBState.Think;
var
  I: TExplosion;
begin
  if not FParent.GetMap.GetBlastFlash then
  begin
    if FParent.GetMap.GetExplosions.Count = 0 then
      Explode
    else
    begin
      I := FParent.GetMap.GetExplosions.First;
      while I <> nil do
      begin
        if not I.Animate then
        begin
          FParent.GetMap.GetExplosions.Remove(I);
          I.Free;
          if FParent.GetMap.GetExplosions.Count = 0 then
          begin
            Explode;
            Exit;
          end;
        end;
        I := FParent.GetMap.GetExplosions.First;
      end;
    end;
  end;
end;

procedure TExplosionBState.Cancel;
begin
  // cannot cancel
end;

procedure TExplosionBState.Explode;
var
  TerrainExplosion: Boolean;
  Save: TSavedBattleGame;
  Victim: TBattleUnit;
  DT: TItemDamageType;
  P: TPosition;
  Tile: TTile;
begin
  TerrainExplosion := False;
  Save := FParent.GetSave;

  if FItem <> nil then
  begin
    if FUnit = nil then
      FUnit := FItem.GetPreviousOwner;
    Victim := nil;
    if FAreaOfEffect then
      Save.GetTileEngine.Explode(FCenter, FPower, FItem.GetRules.GetDamageType,
                                 FItem.GetRules.GetExplosionRadius, FUnit)
    else if not FCosmetic then
    begin
      Victim := Save.GetTileEngine.Hit(FCenter, FPower, FItem.GetRules.GetDamageType, FUnit);
    end;
    if (FItem.GetRules.GetZombieUnit <> '') and (Victim <> nil) and
       (Victim.GetArmor.GetSize = 1) and
       ((Victim.GetGeoscapeSoldier <> nil) or (Victim.GetUnitRules.GetRace = 'STR_CIVILIAN')) and
       (Victim.GetSpawnUnit = '') then
    begin
      Victim.SetRespawn(True);
      Victim.SetSpawnUnit(FItem.GetRules.GetZombieUnit);
    end;
  end;

  if FTile <> nil then
  begin
    case FTile.GetExplosiveType of
      0: DT := DT_HE;
      5: DT := DT_IN;
      6: DT := DT_STUN;
      else DT := DT_SMOKE;
    end;
    if DT <> DT_HE then
      FTile.SetExplosive(0, 0, True);
    Save.GetTileEngine.Explode(FCenter, FPower, DT, FPower div 10);
    TerrainExplosion := True;
  end;

  if (FTile = nil) and (FItem = nil) then
  begin
    if (FUnit <> nil) and ((FUnit.GetSpecialAbility = SPECAB_EXPLODEONDEATH) or
                           (FUnit.GetSpecialAbility = SPECAB_BURN_AND_EXPLODE)) then
      Save.GetTileEngine.Explode(FCenter, FPower, DT_HE,
                                 FParent.GetMod.GetItem(FUnit.GetArmor.GetCorpseGeoscape, True).GetExplosionRadius)
    else
      Save.GetTileEngine.Explode(FCenter, FPower, DT_HE, 6);
    TerrainExplosion := True;
  end;

  if not FCosmetic then
    FParent.CheckForCasualties(FItem, FUnit, False, TerrainExplosion);

  if (FUnit <> nil) and (not FUnit.IsOut) and FLowerWeapon then
  begin
    FUnit.Aim(False);
    FUnit.SetCache(0);
  end;

  FParent.GetMap.CacheUnits;
  FParent.PopState;

  Tile := Save.GetTileEngine.CheckForTerrainExplosions;
  if Tile <> nil then
  begin
    P := Position(Tile.GetPosition.X * 16, Tile.GetPosition.Y * 16, Tile.GetPosition.Z * 24);
    P := P + Position(8,8,0);
    FParent.StatePushFront(TExplosionBState.Create(FParent, P, nil, FUnit, Tile));
  end;

  if (FItem <> nil) and ((FItem.GetRules.GetBattleType = BT_GRENADE) or
                         (FItem.GetRules.GetBattleType = BT_PROXIMITYGRENADE)) then
    FParent.GetSave.RemoveItem(FItem);
end;

end.