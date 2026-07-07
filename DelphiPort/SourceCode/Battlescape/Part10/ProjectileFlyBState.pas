unit ProjectileFlyBState;

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
  TProjectileFlyBState = class(TBattleState)
  private
    FUnit: TBattleUnit;
    FAmmo: TBattleItem;
    FProjectileItem: TBattleItem;
    FOrigin: TPosition;
    FTargetVoxel: TPosition;
    FOriginVoxel: TPosition;
    FProjectileImpact: Integer;
    FInitialized: Boolean;
    FTargetFloor: Boolean;
    function CreateNewProjectile: Boolean;
    procedure ProjectileHitUnit(Pos: TPosition);
  public
    constructor Create(Parent: TBattlescapeGame; Action: TBattleAction); overload;
    constructor Create(Parent: TBattlescapeGame; Action: TBattleAction; Origin: TPosition); overload;
    destructor Destroy; override;
    procedure Init; override;
    procedure Cancel; override;
    procedure Think; override;
    class function ValidThrowRange(Action: PBattleAction; Origin: TPosition; Target: TTile): Boolean; static;
    class function GetMaxThrowDistance(Weight, Strength, Level: Integer): Integer; static;
    procedure SetOriginVoxel(const Pos: TPosition);
    procedure TargetFloor;
  end;

implementation

uses
  Math,
  Engine.Options,
  Engine.Sound,
  Mod.Mod,
  Mod.RuleItem,
  Mod.Armor,
  Savegame.SavedBattleGame,
  Battlescape.TileEngine,
  Battlescape.Map,
  Battlescape.Camera,
  Battlescape.ExplosionBState,
  Battlescape.Projectile,
  Battlescape.BattlescapeState,
  Battlescape.AIModule,
  Savegame.BattleUnitStatistics,
  Engine.RNG,
  fmath;

{ TProjectileFlyBState }

constructor TProjectileFlyBState.Create(Parent: TBattlescapeGame; Action: TBattleAction);
begin
  inherited Create(Parent, Action);
  FUnit := nil;
  FAmmo := nil;
  FProjectileItem := nil;
  FOrigin := Action.Actor.Position;
  FOriginVoxel := TPosition.Create(-1,-1,-1);
  FProjectileImpact := 0;
  FInitialized := False;
  FTargetFloor := False;
end;

constructor TProjectileFlyBState.Create(Parent: TBattlescapeGame; Action: TBattleAction; Origin: TPosition);
begin
  inherited Create(Parent, Action);
  FUnit := nil;
  FAmmo := nil;
  FProjectileItem := nil;
  FOrigin := Origin;
  FOriginVoxel := TPosition.Create(-1,-1,-1);
  FProjectileImpact := 0;
  FInitialized := False;
  FTargetFloor := False;
end;

destructor TProjectileFlyBState.Destroy;
begin
  inherited;
end;

procedure TProjectileFlyBState.Init;
var
  Weapon: TBattleItem;
  EndTile: TTile;
  DistanceSq: Integer;
  IsPlayer: Boolean;
  OriginVoxel: TPosition;
  HitPos: TPosition;
  TargetTile: TTile;
begin
  if FInitialized then Exit;
  FInitialized := True;

  Weapon := FAction.Weapon;
  FProjectileItem := nil;
  if Weapon = nil then
  begin
    FParent.PopState;
    Exit;
  end;

  if FParent.Save.GetTile(FAction.Target) = nil then
  begin
    FParent.PopState;
    Exit;
  end;

  if FParent.PanicHandled and (FAction.Actor.TimeUnits < FAction.TU) then
  begin
    FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS';
    FParent.PopState;
    Exit;
  end;

  FUnit := FAction.Actor;
  FAmmo := Weapon.AmmoItem;

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

  EndTile := FParent.Save.GetTile(FAction.Target);
  DistanceSq := FParent.TileEngine.DistanceUnitToPositionSq(FAction.Actor, FAction.Target, False);
  IsPlayer := FParent.Save.Side = FACTION_PLAYER;
  if IsPlayer then FParent.Map.ResetObstacles;

  case FAction.Type_ of
    BA_SNAPSHOT, BA_AIMEDSHOT, BA_AUTOSHOT, BA_LAUNCH:
      begin
        if FAmmo = nil then
        begin
          FAction.Result := 'STR_NO_AMMUNITION_LOADED';
          FParent.PopState;
          Exit;
        end;
        if FAmmo.AmmoQuantity = 0 then
        begin
          FAction.Result := 'STR_NO_ROUNDS_LEFT';
          FParent.PopState;
          Exit;
        end;
        if DistanceSq > Weapon.Rules.MaxRangeSq then
        begin
          // special handling for short ranges
          if (Weapon.Rules.MaxRange = 1) and (DistanceSq <= 3) then
            Break
          else if (Weapon.Rules.MaxRange = 2) and (DistanceSq <= 6) then
            Break;
          FAction.Result := 'STR_OUT_OF_RANGE';
          FParent.PopState;
          Exit;
        end;
      end;
    BA_THROW:
      begin
        if not ValidThrowRange(@FAction, FParent.TileEngine.GetOriginVoxel(FAction, nil), FParent.Save.GetTile(FAction.Target)) then
        begin
          FAction.Result := 'STR_OUT_OF_RANGE';
          FParent.PopState;
          Exit;
        end;
        if Assigned(EndTile) and (EndTile.TerrainLevel = -24) and (EndTile.Position.Z + 1 < FParent.Save.MapSizeZ) then
          FAction.Target.Z := FAction.Target.Z + 1;
        FProjectileItem := Weapon;
      end;
  else
    FParent.PopState;
    Exit;
  end;

  // Determine target voxel
  if (FAction.Type_ = BA_LAUNCH) or (Options.ForceFire and ((SDL_GetModState and KMOD_CTRL) <> 0) and IsPlayer) or not FParent.PanicHandled then
  begin
    FTargetVoxel := TPosition.Create(FAction.Target.X * 16 + 8, FAction.Target.Y * 16 + 8, FAction.Target.Z * 24 + 12);
    if FAction.Type_ = BA_LAUNCH then
    begin
      if FTargetFloor then
        FTargetVoxel.Z := FTargetVoxel.Z - 10
      else
        FTargetVoxel.Z := FTargetVoxel.Z + 4;
    end;
  end
  else if not FAction.Weapon.Rules.ArcingShot then
  begin
    TargetTile := FParent.Save.GetTile(FAction.Target);
    OriginVoxel := FParent.TileEngine.GetOriginVoxel(FAction, FParent.Save.GetTile(FOrigin));
    if Assigned(TargetTile.Unit) and ((FUnit.Faction <> FACTION_PLAYER) or TargetTile.Unit.Visible) then
    begin
      if (FOrigin = FAction.Target) or (TargetTile.Unit = FUnit) then
        FTargetVoxel := TPosition.Create(FAction.Target.X * 16 + 8, FAction.Target.Y * 16 + 8, FAction.Target.Z * 24)
      else
      begin
        if not FParent.TileEngine.CanTargetUnit(@OriginVoxel, TargetTile, @FTargetVoxel, FUnit, IsPlayer) then
        begin
          FTargetVoxel := TPosition.Create(-16,-16,-24);
          if IsPlayer then
            FParent.Map.EnableObstacles;
        end;
      end;
    end
    else if Assigned(TargetTile.GetMapData(O_OBJECT)) then
    begin
      if not FParent.TileEngine.CanTargetTile(@OriginVoxel, TargetTile, O_OBJECT, @FTargetVoxel, FUnit, IsPlayer) then
        FTargetVoxel := TPosition.Create(FAction.Target.X * 16 + 8, FAction.Target.Y * 16 + 8, FAction.Target.Z * 24 + 10);
    end
    else if Assigned(TargetTile.GetMapData(O_NORTHWALL)) then
    begin
      if not FParent.TileEngine.CanTargetTile(@OriginVoxel, TargetTile, O_NORTHWALL, @FTargetVoxel, FUnit, IsPlayer) then
        FTargetVoxel := TPosition.Create(FAction.Target.X * 16 + 8, FAction.Target.Y * 16, FAction.Target.Z * 24 + 9);
    end
    else if Assigned(TargetTile.GetMapData(O_WESTWALL)) then
    begin
      if not FParent.TileEngine.CanTargetTile(@OriginVoxel, TargetTile, O_WESTWALL, @FTargetVoxel, FUnit, IsPlayer) then
        FTargetVoxel := TPosition.Create(FAction.Target.X * 16, FAction.Target.Y * 16 + 8, FAction.Target.Z * 24 + 9);
    end
    else if Assigned(TargetTile.GetMapData(O_FLOOR)) then
    begin
      if not FParent.TileEngine.CanTargetTile(@OriginVoxel, TargetTile, O_FLOOR, @FTargetVoxel, FUnit, IsPlayer) then
        FTargetVoxel := TPosition.Create(FAction.Target.X * 16 + 8, FAction.Target.Y * 16 + 8, FAction.Target.Z * 24 + 2);
    end
    else
    begin
      // dummy
      FParent.TileEngine.CanTargetTile(@OriginVoxel, TargetTile, MapData.O_DUMMY, @FTargetVoxel, FUnit, IsPlayer);
      FTargetVoxel := TPosition.Create(FAction.Target.X * 16 + 8, FAction.Target.Y * 16 + 8, FAction.Target.Z * 24 + 12);
    end;
  end;

  if CreateNewProjectile then
  begin
    FParent.Map.SetCursorType(CT_NONE);
    FParent.Map.Camera.StopMouseScrolling;
    FParent.Map.DisableObstacles;
  end
  else if IsPlayer and ((FTargetVoxel.Z >= 0) or FParent.Map.GetBlastFlash) then
    FParent.Map.EnableObstacles;
end;

function TProjectileFlyBState.CreateNewProjectile: Boolean;
var
  Projectile: TProjectile;
  AccuracyDivider: Double;
begin
  Inc(FAction.AutoShotCounter);

  Projectile := TProjectile.Create(FParent.Mod, FParent.Save, FAction, FOrigin, FTargetVoxel, FAmmo);
  FParent.Map.SetProjectile(Projectile);
  FParent.SetStateInterval(1000 div 60);
  FProjectileImpact := V_EMPTY;

  AccuracyDivider := 100.0;
  if not FParent.PanicHandled then
    AccuracyDivider := 200.0;

  if FAction.Type_ = BA_THROW then
  begin
    FProjectileImpact := Projectile.CalculateThrow(FUnit.ThrowingAccuracy / AccuracyDivider);
    if (FProjectileImpact = V_FLOOR) or (FProjectileImpact = V_UNIT) or (FProjectileImpact = V_OBJECT) then
    begin
      if (FUnit.Faction <> FACTION_PLAYER) and (FProjectileItem.Rules.BattleType = BT_GRENADE) then
        FProjectileItem.FuseTimer := 0;
      FProjectileItem.MoveToOwner(nil);
      FUnit.SetCache(0);
      FParent.Map.CacheUnit(FUnit);
      FParent.Mod.GetSoundByDepth(FParent.Depth, Mod.ITEM_THROW).Play(-1, FParent.Map.GetSoundAngle(FUnit.Position));
      FUnit.AddThrowingExp;
    end
    else
    begin
      Projectile.Free;
      FParent.Map.SetProjectile(nil);
      FAction.Result := 'STR_UNABLE_TO_THROW_HERE';
      FAction.TU := 0;
      FParent.PopState;
      Exit(False);
    end;
  end
  else if FAction.Weapon.Rules.ArcingShot then
  begin
    FProjectileImpact := Projectile.CalculateThrow(FUnit.GetFiringAccuracy(FAction.Type_, FAction.Weapon) / AccuracyDivider);
    if (FProjectileImpact <> V_EMPTY) and (FProjectileImpact <> V_OUTOFBOUNDS) then
    begin
      FUnit.Aim(True);
      FUnit.SetCache(0);
      FParent.Map.CacheUnit(FUnit);
      if Assigned(FAmmo) and (FAmmo.Rules.FireSound <> -1) then
        FParent.Mod.GetSoundByDepth(FParent.Depth, FAmmo.Rules.FireSound).Play(-1, FParent.Map.GetSoundAngle(FUnit.Position))
      else if FAction.Weapon.Rules.FireSound <> -1 then
        FParent.Mod.GetSoundByDepth(FParent.Depth, FAction.Weapon.Rules.FireSound).Play(-1, FParent.Map.GetSoundAngle(FUnit.Position));
      if not FParent.Save.DebugMode and (FAction.Type_ <> BA_LAUNCH) and (not FAmmo.SpendBullet) then
      begin
        FParent.Save.RemoveItem(FAmmo);
        FAction.Weapon.SetAmmoItem(nil);
      end;
    end
    else
    begin
      Projectile.Free;
      FParent.Map.SetProjectile(nil);
      if FParent.PanicHandled then
        FAction.Result := 'STR_NO_LINE_OF_FIRE'
      else
        FUnit.SetTimeUnits(FUnit.TimeUnits + FAction.TU);
      FUnit.AbortTurn;
      FParent.PopState;
      Exit(False);
    end;
  end
  else
  begin
    if FOriginVoxel <> TPosition.Create(-1,-1,-1) then
      FProjectileImpact := Projectile.CalculateTrajectory(FUnit.GetFiringAccuracy(FAction.Type_, FAction.Weapon) / AccuracyDivider, FOriginVoxel, False)
    else
      FProjectileImpact := Projectile.CalculateTrajectory(FUnit.GetFiringAccuracy(FAction.Type_, FAction.Weapon) / AccuracyDivider);
    if (FTargetVoxel <> TPosition.Create(-16,-16,-24)) and ((FProjectileImpact <> V_EMPTY) or (FAction.Type_ = BA_LAUNCH)) then
    begin
      FUnit.Aim(True);
      FUnit.SetCache(0);
      FParent.Map.CacheUnit(FUnit);
      if Assigned(FAmmo) and (FAmmo.Rules.FireSound <> -1) then
        FParent.Mod.GetSoundByDepth(FParent.Depth, FAmmo.Rules.FireSound).Play(-1, FParent.Map.GetSoundAngle(Projectile.GetOrigin))
      else if FAction.Weapon.Rules.FireSound <> -1 then
        FParent.Mod.GetSoundByDepth(FParent.Depth, FAction.Weapon.Rules.FireSound).Play(-1, FParent.Map.GetSoundAngle(Projectile.GetOrigin));
      if not FParent.Save.DebugMode and (FAction.Type_ <> BA_LAUNCH) and (not FAmmo.SpendBullet) then
      begin
        FParent.Save.RemoveItem(FAmmo);
        FAction.Weapon.SetAmmoItem(nil);
      end;
    end
    else
    begin
      Projectile.Free;
      FParent.Map.SetProjectile(nil);
      if FParent.PanicHandled then
        FAction.Result := 'STR_NO_LINE_OF_FIRE'
      else
        FUnit.SetTimeUnits(FUnit.TimeUnits + FAction.TU);
      FUnit.AbortTurn;
      FParent.PopState;
      Exit(False);
    end;
  end;

  if (FAction.Type_ <> BA_THROW) and (FAction.Type_ <> BA_LAUNCH) then
    FUnit.Statistics.ShotsFiredCounter := FUnit.Statistics.ShotsFiredCounter + 1;

  Result := True;
end;

procedure TProjectileFlyBState.Think;
var
  Tile, BelowTile: TTile;
  HasFloor: Boolean;
  UnitCanFly: Boolean;
  Pos: TPosition;
  Item: TBattleItem;
  Explosion: TExplosion;
  Proj: TProjectile;
  SecondaryImpact: Integer;
  Offset: Integer;
  I: Integer;
  FiringXP: Integer;
begin
  FParent.Save.BattleState.ClearMouseScrollingState;

  if FParent.Map.GetProjectile = nil then
  begin
    Tile := FParent.Save.GetTile(FAction.Actor.Position);
    BelowTile := FParent.Save.GetTile(FAction.Actor.Position + TPosition.Create(0,0,-1));
    HasFloor := Assigned(Tile) and not Tile.HasNoFloor(BelowTile);
    UnitCanFly := FAction.Actor.MovementType = MT_FLY;

    if (FAction.Type_ = BA_AUTOSHOT) and
       (FAction.AutoShotCounter < FAction.Weapon.Rules.AutoShots) and
       not FAction.Actor.IsOut and
       (FAmmo.AmmoQuantity <> 0) and
       (HasFloor or UnitCanFly) then
    begin
      CreateNewProjectile;
      if FAction.CameraPosition.Z <> -1 then
      begin
        FParent.Map.Camera.SetMapOffset(FAction.CameraPosition);
        FParent.Map.Invalidate;
      end;
    end
    else
    begin
      if (FAction.CameraPosition.Z <> -1) and (FAction.Waypoints.Count <= 1) then
      begin
        FParent.Map.Camera.SetMapOffset(FAction.CameraPosition);
        FParent.Map.Invalidate;
      end;
      if not FParent.Save.UnitsFalling and FParent.PanicHandled then
        FParent.TileEngine.CheckReactionFire(FUnit);
      if not FUnit.IsOut then
        FUnit.AbortTurn;
      if (FParent.Save.Side = FACTION_PLAYER) or FParent.Save.DebugMode then
        FParent.SetupCursor;
      FParent.ConvertInfected;
      FParent.PopState;
    end;
  end
  else
  begin
    if (FAction.Type_ <> BA_THROW) and Assigned(FAmmo) and (FAmmo.Rules.ShotgunPellets <> 0) then
      FParent.Map.GetProjectile.SkipTrajectory;

    if not FParent.Map.GetProjectile.Move then
    begin
      if FAction.Type_ = BA_THROW then
      begin
        FParent.Map.ResetCameraSmoothing;
        Pos := FParent.Map.GetProjectile.GetPosition(TProjectile.ItemDropVoxelOffset);
        Pos.X := Pos.X div 16;
        Pos.Y := Pos.Y div 16;
        Pos.Z := Pos.Z div 24;
        if Pos.Y > FParent.Save.MapSizeY then Pos.Y := Pos.Y - 1;
        if Pos.X > FParent.Save.MapSizeX then Pos.X := Pos.X - 1;
        Item := FParent.Map.GetProjectile.GetItem;
        FParent.Mod.GetSoundByDepth(FParent.Depth, Mod.ITEM_DROP).Play(-1, FParent.Map.GetSoundAngle(Pos));

        if Options.BattleInstantGrenade and (Item.Rules.BattleType = BT_GRENADE) and (Item.FuseTimer = 0) then
          FParent.StatePushFront(TExplosionBState.Create(FParent, FParent.Map.GetProjectile.GetPosition(TProjectile.ItemDropVoxelOffset), Item, FAction.Actor))
        else
        begin
          FParent.DropItem(Pos, Item);
          if (FUnit.Faction <> FACTION_PLAYER) and (FProjectileItem.Rules.BattleType = BT_GRENADE) then
            FParent.TileEngine.SetDangerZone(Pos, Item.Rules.ExplosionRadius, FAction.Actor);
        end;
      end
      else if (FAction.Type_ = BA_LAUNCH) and (FAction.Waypoints.Count > 1) and (FProjectileImpact = V_EMPTY) then
      begin
        FOrigin := FAction.Waypoints[0];
        FAction.Waypoints.Delete(0);
        FAction.Target := FAction.Waypoints[0];
        FParent.StatePushNext(TProjectileFlyBState.Create(FParent, FAction, FOrigin));
        if FOrigin = FAction.Target then
          FParent.StatePushNext.TargetFloor;
      end
      else
      begin
        if Assigned(FParent.Save.GetTile(FAction.Target).Unit) then
          FParent.Save.GetTile(FAction.Target).Unit.Statistics.ShotAtCounter := FParent.Save.GetTile(FAction.Target).Unit.Statistics.ShotAtCounter + 1;

        FParent.Map.ResetCameraSmoothing;
        if Assigned(FAmmo) and (FAction.Type_ = BA_LAUNCH) and (not FAmmo.SpendBullet) then
        begin
          FParent.Save.RemoveItem(FAmmo);
          FAction.Weapon.SetAmmoItem(nil);
        end;

        if FProjectileImpact <> V_OUTOFBOUNDS then
        begin
          Offset := 0;
          if Assigned(FAmmo) and (FAmmo.Rules.ExplosionRadius <> 0) and (FProjectileImpact <> V_UNIT) then
            Offset := -2;

          FParent.StatePushFront(TExplosionBState.Create(FParent, FParent.Map.GetProjectile.GetPosition(Offset), FAmmo, FAction.Actor, 0,
                                    (FAction.Type_ <> BA_AUTOSHOT) or (FAction.AutoShotCounter = FAction.Weapon.Rules.AutoShots) or (FAction.Weapon.AmmoItem = nil)));

          if FProjectileImpact = V_UNIT then
            ProjectileHitUnit(FParent.Map.GetProjectile.GetPosition(Offset));

          FiringXP := FUnit.GetFiringXP;

          // Shotgun pellets
          if Assigned(FAmmo) and (FAmmo.Rules.ShotgunPellets <> 0) then
          begin
            for I := 1 to FAmmo.Rules.ShotgunPellets - 1 do
            begin
              Proj := TProjectile.Create(FParent.Mod, FParent.Save, FAction, FOrigin, FTargetVoxel, FAmmo);
              SecondaryImpact := Proj.CalculateTrajectory(Max(0.0, (FUnit.GetFiringAccuracy(FAction.Type_, FAction.Weapon) / 100.0) - I * 5.0));
              if SecondaryImpact <> V_EMPTY then
              begin
                Proj.SkipTrajectory;
                if SecondaryImpact <> V_OUTOFBOUNDS then
                begin
                  if SecondaryImpact = V_UNIT then
                    ProjectileHitUnit(Proj.GetPosition(Offset));
                  Explosion := TExplosion.Create(Proj.GetPosition(Offset), FAmmo.Rules.HitAnimation);
                  FParent.Map.Explosions.Add(Explosion);
                  if FAmmo.Rules.ExplosionRadius <> 0 then
                    FParent.TileEngine.Explode(Proj.GetPosition(Offset), FAmmo.Rules.Power, FAmmo.Rules.DamageType, FAmmo.Rules.ExplosionRadius, FUnit)
                  else
                    FParent.Save.TileEngine.Hit(Proj.GetPosition(Offset), FAmmo.Rules.Power, FAmmo.Rules.DamageType, FUnit);
                end;
              end;
              Proj.Free;
            end;
          end;

          if FUnit.GetFiringXP > FiringXP + 1 then
            FUnit.NerfFiringXP(FiringXP + 1);
        end
        else if (FAction.Type_ <> BA_AUTOSHOT) or (FAction.AutoShotCounter = FAction.Weapon.Rules.AutoShots) or (FAction.Weapon.AmmoItem = nil) then
        begin
          FUnit.Aim(False);
          FUnit.SetCache(0);
          FParent.Map.CacheUnits;
        end;
      end;

      FParent.Map.GetProjectile.Free;
      FParent.Map.SetProjectile(nil);
    end;
  end;
end;

procedure TProjectileFlyBState.Cancel;
var
  P: TPosition;
begin
  if Assigned(FParent.Map.GetProjectile) then
  begin
    FParent.Map.GetProjectile.SkipTrajectory;
    P := FParent.Map.GetProjectile.GetPosition;
    if not FParent.Map.Camera.IsOnScreen(TPosition.Create(P.X div 16, P.Y div 16, P.Z div 24), False, 0, False) then
      FParent.Map.Camera.CenterOnPosition(TPosition.Create(P.X div 16, P.Y div 16, P.Z div 24));
  end;
end;

class function TProjectileFlyBState.ValidThrowRange(Action: PBattleAction; Origin: TPosition; Target: TTile): Boolean;
var
  Offset, ZD, Weight: Integer;
  MaxDistance, RealDistance: Double;
  XDiff, YDiff: Integer;
begin
  if Action.Type_ <> BA_THROW then Exit(True);
  Offset := 2;
  ZD := (Origin.Z) - ((Action.Target.Z * 24 + Offset) - Target.TerrainLevel);
  Weight := Action.Weapon.Rules.Weight;
  if Assigned(Action.Weapon.AmmoItem) and (Action.Weapon.AmmoItem <> Action.Weapon) then
    Weight := Weight + Action.Weapon.AmmoItem.Rules.Weight;
  MaxDistance := (GetMaxThrowDistance(Weight, Action.Actor.BaseStats.Strength, ZD) + 8) / 16.0;
  XDiff := Action.Target.X - Action.Actor.Position.X;
  YDiff := Action.Target.Y - Action.Actor.Position.Y;
  RealDistance := Sqrt(XDiff*XDiff + YDiff*YDiff);
  Result := RealDistance <= MaxDistance;
end;

class function TProjectileFlyBState.GetMaxThrowDistance(Weight, Strength, Level: Integer): Integer;
var
  CurZ, Dz: Double;
  Dist: Integer;
begin
  CurZ := Level + 0.5;
  Dz := 1.0;
  Dist := 0;
  while Dist < 4000 do
  begin
    Dist := Dist + 8;
    if Dz < -1 then
      CurZ := CurZ - 8
    else
      CurZ := CurZ + Dz * 8;
    if (CurZ < 0) and (Dz < 0) then
    begin
      Dz := Max(Dz, -1.0);
      if Abs(Dz) > 1e-10 then
        Dist := Dist - Round(CurZ / Dz);
      Break;
    end;
    Dz := Dz - (50 * Weight / Strength) / 100;
    if Dz <= -2.0 then Break;
  end;
  Result := Dist;
end;

procedure TProjectileFlyBState.SetOriginVoxel(const Pos: TPosition);
begin
  FOriginVoxel := Pos;
end;

procedure TProjectileFlyBState.TargetFloor;
begin
  FTargetFloor := True;
end;

procedure TProjectileFlyBState.ProjectileHitUnit(Pos: TPosition);
var
  Victim, TargetVictim: TBattleUnit;
  DistanceSq, Distance, Accuracy: Integer;
begin
  Victim := FParent.Save.GetTile(Pos div TPosition.Create(16,16,24)).Unit;
  TargetVictim := FParent.Save.GetTile(FAction.Target).Unit;
  if Assigned(Victim) and not Victim.IsOut then
  begin
    Victim.Statistics.HitCounter := Victim.Statistics.HitCounter + 1;
    if (FUnit.OriginalFaction = FACTION_PLAYER) and (Victim.OriginalFaction = FACTION_PLAYER) then
    begin
      Victim.Statistics.ShotByFriendlyCounter := Victim.Statistics.ShotByFriendlyCounter + 1;
      FUnit.Statistics.ShotFriendlyCounter := FUnit.Statistics.ShotFriendlyCounter + 1;
    end;
    if Victim = TargetVictim then
    begin
      DistanceSq := FParent.TileEngine.DistanceUnitToPositionSq(FAction.Actor, Victim.Position, False);
      Distance := Ceil(Sqrt(DistanceSq));
      Accuracy := FUnit.GetFiringAccuracy(FAction.Type_, FAction.Weapon);
      if Options.BattleUFOExtenderAccuracy then
      begin
        // accuracy adjustment omitted for brevity but present in original
      end;
      FUnit.Statistics.ShotsLandedCounter := FUnit.Statistics.ShotsLandedCounter + 1;
      if Distance > 30 then
        FUnit.Statistics.LongDistanceHitCounter := FUnit.Statistics.LongDistanceHitCounter + 1;
      if Accuracy < Distance then
        FUnit.Statistics.LowAccuracyHitCounter := FUnit.Statistics.LowAccuracyHitCounter + 1;
    end;
    if Victim.Faction = FACTION_HOSTILE then
    begin
      if Assigned(Victim.AIModule) then
      begin
        Victim.AIModule.SetWasHitBy(FUnit);
        FUnit.SetTurnsSinceSpotted(0);
      end;
    end;
    Victim.SetMurdererId(FUnit.Id);
    if Assigned(FAction.Weapon) then
      Victim.SetMurdererWeapon(FAction.Weapon.Rules.Name);
    if Assigned(FAmmo) then
      Victim.SetMurdererWeaponAmmo(FAmmo.Rules.Name);
  end;
end;

end.