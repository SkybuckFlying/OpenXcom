unit UnitFallBState;

interface

uses
  Classes, SysUtils,
  Battlescape.BattleState,
  Battlescape.BattlescapeGame,
  Savegame.BattleUnit,
  Savegame.Tile;

type
  TUnitFallBState = class(TBattleState)
  private
    FTerrain: TTileEngine;
    FTilesToFallInto: TList<TTile>;
    FUnitsToMove: TList<TBattleUnit>;
  public
    constructor Create(Parent: TBattlescapeGame);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
  end;

implementation

uses
  Engine.Options,
  Mod.Armor,
  Battlescape.TileEngine,
  Battlescape.Pathfinding,
  Battlescape.Map,
  Battlescape.Camera;

{ TUnitFallBState }

constructor TUnitFallBState.Create(Parent: TBattlescapeGame);
begin
  inherited Create(Parent);
  FTerrain := nil;
  FTilesToFallInto := TList<TTile>.Create;
  FUnitsToMove := TList<TBattleUnit>.Create;
end;

destructor TUnitFallBState.Destroy;
begin
  FTilesToFallInto.Free;
  FUnitsToMove.Free;
  inherited;
end;

procedure TUnitFallBState.Init;
begin
  FTerrain := FParent.TileEngine;
  if FParent.Save.Side = FACTION_PLAYER then
    FParent.SetStateInterval(Options.BattleXcomSpeed)
  else
    FParent.SetStateInterval(Options.BattleAlienSpeed);
end;

procedure TUnitFallBState.Think;
var
  Unit: TBattleUnit;
  LargeCheck: Boolean;
  Falling: Boolean;
  Size, X, Y: Integer;
  TileBelow: TTile;
  OnScreen: Boolean;
  UnitBelow: TBattleUnit;
  Destination: TPosition;
  TileDest: TTile;
  GroundVoxel: TPosition;
  EscapeTiles: TList<TTile>;
  BodySections: TList<TPosition>;
  Dir, XOff, YOff: Integer;
  Offset: TPosition;
  CanMoveToTile: Boolean;
  HasFloor: Boolean;
  UnitCanFly: Boolean;
  AlreadyTaken, AlreadyOccupied, AboutToBeOccupied: Boolean;
  Tile: TTile;
  TmpTile: TTile;
  Found: Boolean;
  BTile: TTile;
  OrigPos: TPosition;
  EndPos: TPosition;
  Section: TPosition;
  I: Integer;
begin
  Unit := nil;
  try
    I := 0;
    while I < FParent.Save.FallingUnits.Count do
    begin
      Unit := FParent.Save.FallingUnits[I];
      if Unit.Status = STATUS_TURNING then Unit.AbortTurn;

      LargeCheck := True;
      Size := Unit.Armor.Size - 1;
      if (Unit.Health = 0) or (Unit.Stunlevel >= Unit.Health) then
      begin
        FParent.Save.FallingUnits.Delete(I);
        Continue;
      end;

      OnScreen := Unit.Visible and FParent.Map.Camera.IsOnScreen(Unit.Position, True, Size, False);
      TileBelow := FParent.Save.GetTile(Unit.Position + TPosition.Create(0,0,-1));

      for X := Size downto 0 do
        for Y := Size downto 0 do
          if not FParent.Save.GetTile(Unit.Position + TPosition.Create(X,Y,0)).HasNoFloor(FParent.Save.GetTile(Unit.Position + TPosition.Create(X,Y,-1))) or (Unit.MovementType = MT_FLY) then
            LargeCheck := False;

      if (Unit.Status = STATUS_WALKING) or (Unit.Status = STATUS_FLYING) then
      begin
        Unit.KeepWalking(TileBelow, True);
        FParent.Map.CacheUnit(Unit);
        if Unit.Position <> Unit.LastPosition then
        begin
          for X := Size downto 0 do
            for Y := Size downto 0 do
              if FParent.Save.GetTile(Unit.LastPosition + TPosition.Create(X,Y,0)).Unit = Unit then
                FParent.Save.GetTile(Unit.LastPosition + TPosition.Create(X,Y,0)).Unit := nil;
          for X := Size downto 0 do
            for Y := Size downto 0 do
              FParent.Save.GetTile(Unit.Position + TPosition.Create(X,Y,0)).Unit := Unit;
        end;
        Inc(I);
        Continue;
      end;

      Falling := LargeCheck and (Unit.Position.Z <> 0) and Unit.Tile.HasNoFloor(TileBelow) and (Unit.MovementType <> MT_FLY) and (Unit.WalkingPhase = 0);

      if Falling then
      begin
        for X := Unit.Armor.Size - 1 downto 0 do
          for Y := Unit.Armor.Size - 1 downto 0 do
            FTilesToFallInto.Add(FParent.Save.GetTile(Unit.Position + TPosition.Create(X,Y,-1)));

        for X := 0 to Unit.Armor.Size - 1 do
          for Y := 0 to Unit.Armor.Size - 1 do
          begin
            UnitBelow := FParent.Save.GetTile(Unit.Position + TPosition.Create(X,Y,-1)).Unit;
            if Assigned(UnitBelow) and not FParent.Save.FallingUnits.Contains(UnitBelow) and not FUnitsToMove.Contains(UnitBelow) then
              FUnitsToMove.Add(UnitBelow);
          end;
      end;

      Falling := LargeCheck and (Unit.Position.Z <> 0) and Unit.Tile.HasNoFloor(TileBelow) and (Unit.MovementType <> MT_FLY) and (Unit.WalkingPhase = 0);

      if Unit.Status = STATUS_STANDING then
      begin
        if Falling then
        begin
          Destination := Unit.Position + TPosition.Create(0,0,-1);
          TileDest := FParent.Save.GetTile(Destination);
          Unit.StartWalking(Pathfinding.DIR_DOWN, Destination, TileDest, OnScreen);
          Unit.Cache := nil;
          FParent.Map.CacheUnit(Unit);
          Inc(I);
        end
        else
        begin
          if (Unit.SpecialAbility = SPECAB_BURNFLOOR) or (Unit.SpecialAbility = SPECAB_BURN_AND_EXPLODE) then
          begin
            Unit.Tile.Ignite(1);
            GroundVoxel := (Unit.Position * TPosition.Create(16,16,24)) + TPosition.Create(8,8, -Unit.Tile.TerrainLevel);
            FParent.TileEngine.Hit(GroundVoxel, Unit.BaseStats.Strength, DT_IN, Unit);
            if Unit.Status <> STATUS_STANDING then
              FParent.Pathfinding.AbortPath;
          end;
          FTerrain.CalculateUnitLighting;
          FParent.Map.CacheUnit(Unit);
          Unit.Cache := nil;
          FTerrain.CalculateFOV(Unit);
          FParent.CheckForProximityGrenades(Unit);
          if Unit.Status = STATUS_STANDING then
          begin
            if FParent.TileEngine.CheckReactionFire(Unit) then
              FParent.Pathfinding.AbortPath;
            FParent.Save.FallingUnits.Delete(I);
          end
          else Inc(I);
        end;
      end
      else Inc(I);
    end;

    // Move units out of the way
    if FUnitsToMove.Count > 0 then
    begin
      EscapeTiles := TList<TTile>.Create;
      BodySections := TList<TPosition>.Create;
      try
        for Unit in FUnitsToMove do
        begin
          Found := False;
          BodySections.Clear;
          for X := 0 to Unit.Armor.Size - 1 do
            for Y := 0 to Unit.Armor.Size - 1 do
              BodySections.Add(Unit.Position + TPosition.Create(X,Y,0));

          for Dir := 0 to Pathfinding.DIR_UP - 1 do
          begin
            Pathfinding.DirectionToVector(Dir, Offset);
            DestPos := Unit.Position + Offset;
            if FParent.Pathfinding.GetTUCost(Unit.Position, Dir, DestPos, Unit, nil, False) = 255 then Continue;

            CanMoveToTile := True;
            for Section in BodySections do
            begin
              EndPos := Section + Offset;
              Tile := FParent.Save.GetTile(EndPos);
              if Tile = nil then begin CanMoveToTile := False; Break; end;
              AlreadyTaken := EscapeTiles.Contains(Tile);
              AlreadyOccupied := Assigned(Tile.Unit) and (Tile.Unit <> Unit);
              AboutToBeOccupied := FTilesToFallInto.Contains(Tile);
              HasFloor := not Tile.HasNoFloor(FParent.Save.GetTile(EndPos + TPosition.Create(0,0,-1)));
              UnitCanFly := Unit.MovementType = MT_FLY;
              if AlreadyTaken or AlreadyOccupied or AboutToBeOccupied or (not HasFloor and not UnitCanFly) then
              begin
                CanMoveToTile := False;
                Break;
              end;
            end;

            if CanMoveToTile then
            begin
              if FParent.Save.AddFallingUnit(Unit) then
              begin
                Found := True;
                for X := 0 to Unit.Armor.Size - 1 do
                  for Y := 0 to Unit.Armor.Size - 1 do
                    EscapeTiles.Add(FParent.Save.GetTile(Tile.Position + TPosition.Create(X,Y,0)));
                BTile := FParent.Save.GetTile(Section + TPosition.Create(0,0,-1));
                Unit.StartWalking(Dir, Unit.Position + Offset, BTile,
                  Unit.Visible and FParent.Map.Camera.IsOnScreen(Unit.Position, True, Unit.Armor.Size - 1, False));
                Break;
              end;
            end;
          end;

          if not Found then
          begin
            Unit.KnockOut(FParent);
            FUnitsToMove.Remove(Unit);
          end;
        end;
        FParent.CheckForCasualties(nil, nil);
      finally
        EscapeTiles.Free;
        BodySections.Free;
      end;
    end;

    if FParent.Save.FallingUnits.Count = 0 then
    begin
      FTilesToFallInto.Clear;
      FUnitsToMove.Clear;
      FParent.PopState;
    end;
  except
    // handle exceptions
  end;
end;

end.