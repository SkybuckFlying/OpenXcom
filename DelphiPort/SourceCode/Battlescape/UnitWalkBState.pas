unit UnitWalkBState;

interface

uses
  BattleState, BattlescapeGame, Position, Savegame.BattleUnit,
  Pathfinding, TileEngine, Savegame.SavedBattleGame, Mod.Mod,
  Engine.Sound, Engine.Options, Mod.Armor, Engine.Logger;

type
  TUnitWalkBState = class(TBattleState)
  private
    FTarget: TPosition;
    FUnit: TBattleUnit;
    FPathfinding: TPathfinding;
    FTerrain: TTileEngine;
    FFalling: Boolean;
    FBeforeFirstStep: Boolean;
    FNumUnitsSpotted: SizeInt;
    FPreMovementCost: Integer;
    procedure PostPathProcedures;
    procedure SetNormalWalkSpeed;
    procedure PlayMovementSound;
  public
    constructor Create(Parent: TBattlescapeGame; Action: TBattleAction);
    destructor Destroy; override;
    procedure Init; override;
    procedure Cancel; override;
    procedure Think; override;
  end;

implementation

constructor TUnitWalkBState.Create(Parent: TBattlescapeGame; Action: TBattleAction);
begin
  inherited Create(Parent, Action);
  FUnit := nil;
  FPathfinding := nil;
  FTerrain := nil;
  FFalling := False;
  FBeforeFirstStep := False;
  FNumUnitsSpotted := 0;
  FPreMovementCost := 0;
end;

destructor TUnitWalkBState.Destroy;
begin
  inherited;
end;

procedure TUnitWalkBState.Init;
begin
  FUnit := FAction.Actor;
  FNumUnitsSpotted := FUnit.GetUnitsSpottedThisTurn.Count;
  SetNormalWalkSpeed;
  FPathfinding := FParent.GetPathfinding;
  FTerrain := FParent.GetTileEngine;
  FTarget := FAction.Target;
  if Options.traceAI then Log(LOG_INFO, 'Walking from: ' + FUnit.GetPosition.ToString + ', to ' + FTarget.ToString);
  var dir := FPathfinding.GetStartDirection;
  if (not FAction.Strafe) and (dir <> -1) and (dir <> FUnit.GetDirection) then
    FBeforeFirstStep := True;
end;

procedure TUnitWalkBState.Think;
var
  unitSpotted: Boolean;
  size, i, j: Integer;
  onScreen: Boolean;
  tileBelow: TTile;
  onScreenBoundary: Boolean;
  largeCheck: Boolean;
  otherTileBelow: TTile;
  dir, tu, energy: Integer;
  dest: TPosition;
begin
  unitSpotted := False;
  size := FUnit.GetArmor.GetSize - 1;
  onScreen := FUnit.GetVisible and FParent.GetMap.GetCamera.IsOnScreen(FUnit.GetPosition, True, size, False);

  if FUnit.IsKneeled then
  begin
    if FParent.Kneel(FUnit) then
    begin
      FUnit.SetCache(0);
      FTerrain.CalculateFOV(FUnit);
      FParent.GetMap.CacheUnit(FUnit);
      Exit;
    end
    else
    begin
      FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS';
      FPathfinding.AbortPath;
      FParent.PopState;
      Exit;
    end;
  end;

  if FUnit.IsOut then
  begin
    FPathfinding.AbortPath;
    FParent.PopState;
    Exit;
  end;

  if (FUnit.GetStatus = STATUS_WALKING) or (FUnit.GetStatus = STATUS_FLYING) then
  begin
    tileBelow := FParent.GetSave.GetTile(FUnit.GetPosition + TPosition.Create(0,0,-1));
    if (FParent.GetSave.GetTile(FUnit.GetDestination).GetUnit = nil) or
       (FParent.GetSave.GetTile(FUnit.GetDestination).GetUnit = FUnit) then
    begin
      onScreenBoundary := FUnit.GetVisible and FParent.GetMap.GetCamera.IsOnScreen(FUnit.GetPosition, True, size, True);
      FUnit.KeepWalking(tileBelow, onScreenBoundary);
      PlayMovementSound;
    end
    else if not FFalling then
    begin
      FUnit.LookAt(FUnit.GetDestination, (FUnit.GetTurretType <> -1));
      FPathfinding.AbortPath;
    end;

    if FUnit.GetPosition <> FUnit.GetLastPosition then
    begin
      largeCheck := True;
      for i := size downto 0 do
        for j := size downto 0 do
        begin
          otherTileBelow := FParent.GetSave.GetTile(FUnit.GetPosition + TPosition.Create(i,j,-1));
          if (not FParent.GetSave.GetTile(FUnit.GetPosition + TPosition.Create(i,j,0)).HasNoFloor(otherTileBelow)) or (FUnit.GetMovementType = MT_FLY) then
            largeCheck := False;
          FParent.GetSave.GetTile(FUnit.GetLastPosition + TPosition.Create(i,j,0)).SetUnit(nil);
        end;
      for i := size downto 0 do
        for j := size downto 0 do
          FParent.GetSave.GetTile(FUnit.GetPosition + TPosition.Create(i,j,0)).SetUnit(FUnit, FParent.GetSave.GetTile(FUnit.GetPosition + TPosition.Create(i,j,-1)));

      FFalling := largeCheck and (FUnit.GetPosition.Z <> 0) and FUnit.GetTile.HasNoFloor(tileBelow) and (FUnit.GetMovementType <> MT_FLY) and (FUnit.GetWalkingPhase = 0);

      if FFalling then
      begin
        for i := size downto 0 do
          for j := size downto 0 do
          begin
            otherTileBelow := FParent.GetSave.GetTile(FUnit.GetPosition + TPosition.Create(i,j,-1));
            if (otherTileBelow <> nil) and (otherTileBelow.GetUnit <> nil) then
            begin
              FFalling := False;
              FPathfinding.DequeuePath;
              FParent.GetSave.AddFallingUnit(FUnit);
              FParent.StatePushFront(TUnitFallBState.Create(FParent));
              Exit;
            end;
          end;
      end;

      if (not FParent.GetMap.GetCamera.IsOnScreen(FUnit.GetPosition, True, size, False)) and (FUnit.GetFaction <> FACTION_PLAYER) and FUnit.GetVisible then
        FParent.GetMap.GetCamera.CenterOnPosition(FUnit.GetPosition);
      FParent.GetMap.GetCamera.SetViewLevel(FUnit.GetPosition.Z);
    end;

    if FUnit.GetStatus = STATUS_STANDING then
    begin
      FParent.GetSave.GetBattleState.UpdateSoldierInfo;
      if (not FFalling) and ((FUnit.GetSpecialAbility = SPECAB_BURNFLOOR) or (FUnit.GetSpecialAbility = SPECAB_BURN_AND_EXPLODE)) then
      begin
        FUnit.GetTile.Ignite(1);
        var posHere := FUnit.GetPosition;
        var voxelHere := (posHere * TPosition.Create(16,16,24)) + TPosition.Create(8,8, -FUnit.GetTile.GetTerrainLevel);
        FParent.GetTileEngine.Hit(voxelHere, FUnit.GetBaseStats.Strength, DT_IN, FUnit);
        if FUnit.GetStatus <> STATUS_STANDING then
        begin
          FPathfinding.AbortPath;
          Exit;
        end;
      end;

      FTerrain.CalculateUnitLighting;
      if FUnit.GetFaction <> FACTION_PLAYER then
        FUnit.SetVisible(False);
      FTerrain.CalculateFOV(FUnit.GetPosition);
      unitSpotted := (not FFalling) and (not FAction.Desperate) and FParent.GetPanicHandled and (FNumUnitsSpotted <> FUnit.GetUnitsSpottedThisTurn.Count);

      if FParent.CheckForProximityGrenades(FUnit) then
      begin
        FParent.PopState;
        Exit;
      end;
      if unitSpotted then
      begin
        FUnit.SetCache(0);
        FParent.GetMap.CacheUnit(FUnit);
        FPathfinding.AbortPath;
        FParent.PopState;
        Exit;
      end;
      if not FFalling then
      begin
        if FTerrain.CheckReactionFire(FUnit) then
        begin
          FUnit.SetCache(0);
          FParent.GetMap.CacheUnit(FUnit);
          FPathfinding.AbortPath;
          FParent.PopState;
          Exit;
        end;
      end;
    end
    else if onScreen then
    begin
      if FPathfinding.GetStrafeMove then
      begin
        var dirTemp := FUnit.GetDirection;
        FUnit.SetDirection(FUnit.GetFaceDirection);
        FParent.GetMap.CacheUnit(FUnit);
        FUnit.SetDirection(dirTemp);
      end
      else
        FParent.GetMap.CacheUnit(FUnit);
    end;
  end;

  if (FUnit.GetStatus = STATUS_STANDING) or (FUnit.GetStatus = STATUS_PANICKING) then
  begin
    if unitSpotted and (not FAction.Desperate) and (FUnit.GetCharging = 0) and (not FFalling) then
    begin
      if Options.traceAI then Log(LOG_INFO, 'Uh-oh! Company!');
      FUnit.SetHiding(False);
      FParent.GetMap.CacheUnit(FUnit);
      PostPathProcedures;
      Exit;
    end;

    if onScreen or FParent.GetSave.GetDebugMode then
      SetNormalWalkSpeed
    else
      FParent.SetStateInterval(0);

    dir := FPathfinding.GetStartDirection;
    if FFalling then
      dir := Pathfinding.DIR_DOWN;

    if dir <> -1 then
    begin
      if FPathfinding.GetStrafeMove then
        FUnit.SetFaceDirection(FUnit.GetDirection);

      tu := FPathfinding.GetTUCost(FUnit.GetPosition, dir, dest, FUnit, 0, False);
      if (FUnit.GetFaction <> FACTION_PLAYER) and
         (FUnit.GetSpecialAbility < SPECAB_BURNFLOOR) and
         (FParent.GetSave.GetTile(dest) <> nil) and
         (FParent.GetSave.GetTile(dest).GetFire > 0) then
        tu := tu - 32;
      if FFalling then
        tu := 0;
      energy := tu;
      if dir >= Pathfinding.DIR_UP then
        energy := 0
      else if FAction.Run then
      begin
        tu := Trunc(tu * 0.75);
        energy := Trunc(energy * 1.5);
      end;
      if tu > FUnit.GetTimeUnits then
      begin
        if FParent.GetPanicHandled and (tu < 255) then
          FAction.Result := 'STR_NOT_ENOUGH_TIME_UNITS';
        FPathfinding.AbortPath;
        FUnit.SetCache(0);
        FParent.GetMap.CacheUnit(FUnit);
        FParent.PopState;
        Exit;
      end;

      if (energy div 2) > FUnit.GetEnergy then
      begin
        if FParent.GetPanicHandled then
          FAction.Result := 'STR_NOT_ENOUGH_ENERGY';
        FPathfinding.AbortPath;
        FUnit.SetCache(0);
        FParent.GetMap.CacheUnit(FUnit);
        FParent.PopState;
        Exit;
      end;

      if FParent.GetPanicHandled and (not FParent.CheckReservedTU(FUnit, tu)) then
      begin
        FPathfinding.AbortPath;
        FUnit.SetCache(0);
        FParent.GetMap.CacheUnit(FUnit);
        Exit;
      end;

      if (dir <> FUnit.GetDirection) and (dir < Pathfinding.DIR_UP) and (not FPathfinding.GetStrafeMove) then
      begin
        FUnit.LookAt(dir);
        FUnit.SetCache(0);
        FParent.GetMap.CacheUnit(FUnit);
        Exit;
      end;

      if dir < Pathfinding.DIR_UP then
      begin
        var door := FTerrain.UnitOpensDoor(FUnit, False, dir);
        if door = 3 then
          Exit;
        if door = 0 then
          FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.DOOR_OPEN).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition));
        if door = 1 then
        begin
          FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.SLIDING_DOOR_OPEN).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition));
          Exit;
        end;
      end;

      for i := size downto 0 do
        for j := size downto 0 do
        begin
          var unitInMyWay := FParent.GetSave.GetTile(dest + TPosition.Create(i,j,0)).GetUnit;
          var unitBelowMyWay: TBattleUnit := nil;
          var belowDest := FParent.GetSave.GetTile(dest + TPosition.Create(i,j,-1));
          if belowDest <> nil then
            unitBelowMyWay := belowDest.GetUnit;
          if (not FFalling) and
             (((unitInMyWay <> nil) and (unitInMyWay <> FUnit)) or
              ((belowDest <> nil) and (unitBelowMyWay <> nil) and (unitBelowMyWay <> FUnit) and
               ((-belowDest.GetTerrainLevel + unitBelowMyWay.GetFloatHeight + unitBelowMyWay.GetHeight) >= 28))) then
          begin
            FAction.TU := 0;
            FPathfinding.AbortPath;
            FUnit.SetCache(0);
            FParent.GetMap.CacheUnit(FUnit);
            FParent.PopState;
            Exit;
          end;
        end;

      dir := FPathfinding.DequeuePath;
      if FFalling then
        dir := Pathfinding.DIR_DOWN;

      if FUnit.SpendTimeUnits(tu) then
      begin
        if FUnit.SpendEnergy(energy) then
        begin
          tileBelow := FParent.GetSave.GetTile(FUnit.GetPosition + TPosition.Create(0,0,-1));
          FUnit.StartWalking(dir, dest, tileBelow, onScreen);
          FBeforeFirstStep := False;
        end;
      end;

      if onScreen then
      begin
        if FPathfinding.GetStrafeMove then
        begin
          var dirTemp := FUnit.GetDirection;
          FUnit.SetDirection(FUnit.GetFaceDirection);
          FParent.GetMap.CacheUnit(FUnit);
          FUnit.SetDirection(dirTemp);
        end
        else
          FParent.GetMap.CacheUnit(FUnit);
      end;
    end
    else
    begin
      PostPathProcedures;
      Exit;
    end;
  end;

  if FUnit.GetStatus = STATUS_TURNING then
  begin
    if FBeforeFirstStep then
      Inc(FPreMovementCost);
    FUnit.Turn;
    FTerrain.CalculateFOV(FUnit);
    unitSpotted := (not FFalling) and (not FAction.Desperate) and FParent.GetPanicHandled and (FNumUnitsSpotted <> FUnit.GetUnitsSpottedThisTurn.Count);
    FUnit.SetCache(0);
    FParent.GetMap.CacheUnit(FUnit);
    if unitSpotted and (not FAction.Desperate) and (FUnit.GetCharging = 0) and (not FFalling) then
    begin
      if FBeforeFirstStep then
        FUnit.SpendTimeUnits(FPreMovementCost);
      if Options.traceAI then Log(LOG_INFO, 'Egads! A turn reveals new units! I must pause!');
      FUnit.SetHiding(False);
      FPathfinding.AbortPath;
      FUnit.AbortTurn;
      FUnit.SetCache(0);
      FParent.GetMap.CacheUnit(FUnit);
      FParent.PopState;
    end;
  end;
end;

procedure TUnitWalkBState.Cancel;
begin
  if (FParent.GetSave.GetSide = FACTION_PLAYER) and FParent.GetPanicHandled then
    FPathfinding.AbortPath;
end;

procedure TUnitWalkBState.PostPathProcedures;
var
  dir: Integer;
begin
  FAction.TU := 0;
  if FUnit.GetFaction <> FACTION_PLAYER then
  begin
    dir := FAction.FinalFacing;
    if FAction.FinalAction then
      FUnit.DontReselect;
    if FUnit.GetCharging <> 0 then
    begin
      dir := FParent.GetTileEngine.GetDirectionTo(FUnit.GetPosition, FUnit.GetCharging.GetPosition);
      if FParent.GetTileEngine.ValidMeleeRange(FUnit, FAction.Actor.GetCharging, dir) then
      begin
        var action: TBattleAction;
        action.Actor := FUnit;
        action.Target := FUnit.GetCharging.GetPosition;
        action.Weapon := FUnit.GetMeleeWeapon;
        action.Type_ := BA_HIT;
        action.TU := FUnit.GetActionTUs(action.Type_, action.Weapon);
        action.Targeting := True;
        FUnit.SetCharging(0);
        FParent.StatePushBack(TMeleeAttackBState.Create(FParent, action));
      end;
    end
    else if FUnit.IsHiding then
    begin
      dir := FUnit.GetDirection + 4;
      FUnit.SetHiding(False);
      FUnit.DontReselect;
    end;
    if dir <> -1 then
    begin
      if dir >= 8 then
        dir := dir - 8;
      FUnit.LookAt(dir);
      while FUnit.GetStatus = STATUS_TURNING do
      begin
        FUnit.Turn;
        FParent.GetTileEngine.CalculateFOV(FUnit);
      end;
    end;
  end
  else if not FParent.GetPanicHandled then
    FUnit.SetTimeUnits(0);

  FUnit.SetCache(0);
  FTerrain.CalculateUnitLighting;
  FTerrain.CalculateFOV(FUnit);
  FParent.GetMap.CacheUnit(FUnit);
  if not FFalling then
    FParent.PopState;
end;

procedure TUnitWalkBState.SetNormalWalkSpeed;
begin
  if FUnit.GetFaction = FACTION_PLAYER then
    FParent.SetStateInterval(Options.battleXcomSpeed)
  else
    FParent.SetStateInterval(Options.battleAlienSpeed);
end;

procedure TUnitWalkBState.PlayMovementSound;
var
  size: Integer;
  tile, tileBelow: TTile;
begin
  size := FUnit.GetArmor.GetSize - 1;
  if (not FUnit.GetVisible and not FParent.GetSave.GetDebugMode) or
     (not FParent.GetMap.GetCamera.IsOnScreen(FUnit.GetPosition, True, size, False)) then
    Exit;

  if FUnit.GetMoveSound <> -1 then
  begin
    if FUnit.GetWalkingPhase = 0 then
      FParent.GetMod.GetSoundByDepth(FParent.GetDepth, FUnit.GetMoveSound).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition));
  end
  else
  begin
    if FUnit.GetStatus = STATUS_WALKING then
    begin
      tile := FUnit.GetTile;
      tileBelow := FParent.GetSave.GetTile(tile.GetPosition + TPosition.Create(0,0,-1));
      if FUnit.GetWalkingPhase = 3 then
        if tile.GetFootstepSound(tileBelow) > -1 then
          FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.WALK_OFFSET + (tile.GetFootstepSound(tileBelow)*2)).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition));
      if FUnit.GetWalkingPhase = 7 then
        if tile.GetFootstepSound(tileBelow) > -1 then
          FParent.GetMod.GetSoundByDepth(FParent.GetDepth, 1 + Mod.WALK_OFFSET + (tile.GetFootstepSound(tileBelow)*2)).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition));
    end
    else if FUnit.GetMovementType = MT_FLY then
      if (FUnit.GetWalkingPhase = 1) and (not FFalling) then
        FParent.GetMod.GetSoundByDepth(FParent.GetDepth, Mod.FLYING_SOUND).Play(-1, FParent.GetMap.GetSoundAngle(FUnit.GetPosition));
  end;
end;

end.