unit TileEngine;

interface

uses
  Classes, SysUtils, SDL2,
  Battlescape.Position,
  Savegame.SavedBattleGame,
  Savegame.Tile,
  Savegame.BattleUnit,
  Savegame.BattleItem,
  Mod.RuleItem,
  Mod.MapData,
  Battlescape.BattleAction;

type
  TTileEngine = class
  private const
    MAX_VIEW_DISTANCE = 20;
    MAX_VIEW_DISTANCE_SQR = MAX_VIEW_DISTANCE * MAX_VIEW_DISTANCE;
    MAX_VOXEL_VIEW_DISTANCE = MAX_VIEW_DISTANCE * 16;
  private
    FSave: TSavedBattleGame;
    FVoxelData: TList<Word>;
    FPersonalLighting: Boolean;
    FCacheTile: TTile;
    FCacheTileBelow: TTile;
    FCacheTilePos: TPosition;

    procedure AddLight(Center: TPosition; Power, Layer: Integer);
    function Blockage(Tile: TTile; Part: Integer; DamageType: TItemDamageType; Direction: Integer = -1; CheckingFromOrigin: Boolean = False): Integer;
    function CanTargetUnit(OriginVoxel: PPosition; Tile: TTile; ScanVoxel: PPosition; ExcludeUnit: TBattleUnit; RememberObstacles: Boolean; PotentialUnit: TBattleUnit = nil): Boolean;
    function CanTargetTile(OriginVoxel: PPosition; Tile: TTile; Part: Integer; ScanVoxel: PPosition; ExcludeUnit: TBattleUnit; RememberObstacles: Boolean): Boolean;
    function GetOriginVoxel(var Action: TBattleAction; Tile: TTile): TPosition;
    procedure CheckAdjacentDoors(const Pos: TPosition; Part: Integer);
    procedure VoxelCheckFlush;
    function VoxelCheck(Voxel: TPosition; ExcludeUnit: TBattleUnit; ExcludeAllUnits: Boolean = False; OnlyVisible: Boolean = False; ExcludeAllBut: TBattleUnit = nil): Integer;
    function GetSpottingUnits(Unit: TBattleUnit): TList<TPair<TBattleUnit, Integer>>;
    function GetReactor(Spotters: TList<TPair<TBattleUnit, Integer>>; var AttackType: Integer; Unit: TBattleUnit): TBattleUnit;
    function DetermineReactionType(Unit, Target: TBattleUnit): Integer;
    function TryReaction(Unit, Target: TBattleUnit; AttackType: Integer): Boolean;
    function Detonate(Tile: TTile): Boolean;
  public
    constructor Create(Save: TSavedBattleGame; VoxelData: TList<Word>);
    destructor Destroy; override;

    procedure CalculateSunShading; overload;
    procedure CalculateSunShading(Tile: TTile); overload;
    procedure CalculateTerrainLighting;
    procedure CalculateUnitLighting;
    function CalculateFOV(Unit: TBattleUnit): Boolean; overload;
    procedure CalculateFOV(Position: TPosition); overload;
    function CheckReactionFire(Unit: TBattleUnit): Boolean;
    function Hit(Center: TPosition; Power: Integer; DamageType: TItemDamageType; Unit: TBattleUnit): TBattleUnit;
    procedure Explode(Center: TPosition; Power: Integer; DamageType: TItemDamageType; MaxRadius: Integer; Unit: TBattleUnit = nil);
    function CheckForTerrainExplosions: TTile;
    function UnitOpensDoor(Unit: TBattleUnit; RClick: Boolean = False; Dir: Integer = -1): Integer;
    function CloseUfoDoors: Integer;
    function CalculateLine(Origin, Target: TPosition; StoreTrajectory: Boolean; Trajectory: TList<TPosition>; ExcludeUnit: TBattleUnit; DoVoxelCheck: Boolean = True; OnlyVisible: Boolean = False; ExcludeAllBut: TBattleUnit = nil): Integer;
    function CalculateParabola(Origin, Target: TPosition; StoreTrajectory: Boolean; Trajectory: TList<TPosition>; ExcludeUnit: TBattleUnit; Curvature: Double; const Delta: TPosition): Integer;
    function GetSightOriginVoxel(CurrentUnit: TBattleUnit): TPosition;
    function Visible(CurrentUnit: TBattleUnit; Tile: TTile): Boolean;
    procedure TogglePersonalLighting;
    function DistanceUnitToPositionSq(Unit: TBattleUnit; const Pos: TPosition; ConsiderZ: Boolean): Integer;
    function Distance(Pos1, Pos2: TPosition): Integer;
    function DistanceSq(Pos1, Pos2: TPosition; ConsiderZ: Boolean = True): Integer;
    function HorizontalBlockage(StartTile, EndTile: TTile; DamageType: TItemDamageType; SkipObject: Boolean = False): Integer;
    function VerticalBlockage(StartTile, EndTile: TTile; DamageType: TItemDamageType; SkipObject: Boolean = False): Integer;
    function ApplyGravity(T: TTile): TTile;
    procedure ItemDrop(T: TTile; Item: TBattleItem; Mod_: TMod; NewItem: Boolean = False; RemoveItem: Boolean = False);
    function ValidMeleeRange(Attacker, Target: TBattleUnit; Dir: Integer): Boolean; overload;
    function ValidMeleeRange(const Pos: TPosition; Direction: Integer; Attacker, Target: TBattleUnit; Dest: PPosition; PreferEnemy: Boolean = True): Boolean; overload;
    function FaceWindow(Position: TPosition): Integer;
    function CheckVoxelExposure(OriginVoxel: PPosition; Tile: TTile; ExcludeUnit, ExcludeAllBut: TBattleUnit): Integer;
    function CastedShade(Voxel: TPosition): Integer;
    function IsVoxelVisible(Voxel: TPosition): Boolean;
    function ValidateThrow(var Action: TBattleAction; OriginVoxel, TargetVoxel: TPosition; Curve: PDouble = nil; VoxelType: PInteger = nil; Forced: Boolean = False): Boolean;
    procedure RecalculateFOV;
    function GetDirectionTo(Origin, Target: TPosition): Integer;
    procedure SetDangerZone(const Pos: TPosition; Radius: Integer; Unit: TBattleUnit);
  end;

implementation

uses
  Math,
  Engine.RNG,
  Engine.Options,
  Mod.Armor,
  Mod.Unit_,
  Battlescape.Pathfinding,
  Battlescape.Map,
  Battlescape.Camera,
  Battlescape.BattlescapeState,
  Battlescape.BattlescapeGame,
  Battlescape.Projectile,
  Battlescape.ExplosionBState,
  Battlescape.MeleeAttackBState,
  Battlescape.ProjectileFlyBState,
  Battlescape.AIModule;

const
  heightFromCenter: array[0..10] of Integer = (0, -2, 2, -4, 4, -6, 6, -8, 8, -12, 12);

{ TTileEngine }

constructor TTileEngine.Create(Save: TSavedBattleGame; VoxelData: TList<Word>);
begin
  FSave := Save;
  FVoxelData := VoxelData;
  FPersonalLighting := True;
  FCacheTile := nil;
  FCacheTileBelow := nil;
  FCacheTilePos := TPosition.Create(-1,-1,-1);
end;

destructor TTileEngine.Destroy;
begin
  inherited;
end;

procedure TTileEngine.CalculateSunShading;
var
  I: Integer;
begin
  for I := 0 to FSave.MapSizeXYZ - 1 do
  begin
    FSave.Tiles[I].ResetLight(0);
    CalculateSunShading(FSave.Tiles[I]);
  end;
end;

procedure TTileEngine.CalculateSunShading(Tile: TTile);
var
  Power, Block, X, Y, Z: Integer;
begin
  Power := 15 - FSave.GlobalShade;
  if FSave.GlobalShade <= 4 then
  begin
    Block := 0;
    X := Tile.Position.X;
    Y := Tile.Position.Y;
    for Z := FSave.MapSizeZ - 1 downto Tile.Position.Z + 1 do
    begin
      Block := Block + Blockage(FSave.GetTile(TPosition.Create(X,Y,Z)), O_FLOOR, DT_NONE);
      Block := Block + Blockage(FSave.GetTile(TPosition.Create(X,Y,Z)), O_OBJECT, DT_NONE, Pathfinding.DIR_DOWN);
    end;
    if Block > 0 then Power := Power - 2;
  end;
  Tile.AddLight(Power, 0);
end;

procedure TTileEngine.AddLight(Center: TPosition; Power, Layer: Integer);
var
  X, Y, Z: Integer;
  Dist: Integer;
begin
  for X := 0 to Power do
    for Y := 0 to Power do
      for Z := 0 to FSave.MapSizeZ - 1 do
      begin
        Dist := Round(Sqrt(X*X + Y*Y));
        if FSave.GetTile(TPosition.Create(Center.X + X, Center.Y + Y, Z)) <> nil then
          FSave.GetTile(TPosition.Create(Center.X + X, Center.Y + Y, Z)).AddLight(Power - Dist, Layer);
        if FSave.GetTile(TPosition.Create(Center.X - X, Center.Y - Y, Z)) <> nil then
          FSave.GetTile(TPosition.Create(Center.X - X, Center.Y - Y, Z)).AddLight(Power - Dist, Layer);
        if FSave.GetTile(TPosition.Create(Center.X - X, Center.Y + Y, Z)) <> nil then
          FSave.GetTile(TPosition.Create(Center.X - X, Center.Y + Y, Z)).AddLight(Power - Dist, Layer);
        if FSave.GetTile(TPosition.Create(Center.X + X, Center.Y - Y, Z)) <> nil then
          FSave.GetTile(TPosition.Create(Center.X + X, Center.Y - Y, Z)).AddLight(Power - Dist, Layer);
      end;
end;

procedure TTileEngine.CalculateTerrainLighting;
const
  FIRE_LIGHT_POWER = 15;
var
  I: Integer;
  Tile: TTile;
  Item: TBattleItem;
begin
  for I := 0 to FSave.MapSizeXYZ - 1 do
    FSave.Tiles[I].ResetLight(1);
  for I := 0 to FSave.MapSizeXYZ - 1 do
  begin
    Tile := FSave.Tiles[I];
    if Assigned(Tile.GetMapData(O_FLOOR)) and (Tile.GetMapData(O_FLOOR).LightSource > 0) then
      AddLight(Tile.Position, Tile.GetMapData(O_FLOOR).LightSource, 1);
    if Assigned(Tile.GetMapData(O_OBJECT)) and (Tile.GetMapData(O_OBJECT).LightSource > 0) then
      AddLight(Tile.Position, Tile.GetMapData(O_OBJECT).LightSource, 1);
    if Tile.Fire > 0 then
      AddLight(Tile.Position, FIRE_LIGHT_POWER, 1);
    for Item in Tile.Inventory do
      if (Item.Rules.BattleType = BT_FLARE) then
        AddLight(Tile.Position, Item.Rules.Power, 1);
  end;
end;

procedure TTileEngine.CalculateUnitLighting;
const
  PERSONAL_LIGHT_POWER = 15;
  FIRE_LIGHT_POWER = 15;
var
  I: Integer;
  Unit: TBattleUnit;
begin
  for I := 0 to FSave.MapSizeXYZ - 1 do
    FSave.Tiles[I].ResetLight(2);
  for Unit in FSave.Units do
  begin
    if FPersonalLighting and (Unit.Faction = FACTION_PLAYER) and not Unit.IsOut then
      AddLight(Unit.Position, PERSONAL_LIGHT_POWER, 2);
    if Unit.Fire > 0 then
      AddLight(Unit.Position, FIRE_LIGHT_POWER, 2);
  end;
end;

function TTileEngine.CalculateFOV(Unit: TBattleUnit): Boolean;
var
  Center, Test, Pos: TPosition;
  Direction: Integer;
  Swap: Boolean;
  SignX, SignY: array[0..7] of Integer;
  Y1, Y2, X, Y, Z, Size, XO, YO: Integer;
  Trajectory: TList<TPosition>;
  VisibleUnit: TBattleUnit;
  Tst: Integer;
  TSize: Integer;
  I: Integer;
  OldNumVisibleUnits: Integer;
begin
  OldNumVisibleUnits := Unit.UnitsSpottedThisTurn.Count;
  Center := Unit.Position;
  if Options.Strafe and (Unit.TurretType > -1) then
    Direction := Unit.TurretDirection
  else
    Direction := Unit.Direction;
  Swap := (Direction = 0) or (Direction = 4);
  SignX[0] := 1; SignX[1] := 1; SignX[2] := 1; SignX[3] := 1; SignX[4] := -1; SignX[5] := -1; SignX[6] := -1; SignX[7] := -1;
  SignY[0] := -1; SignY[1] := -1; SignY[2] := -1; SignY[3] := 1; SignY[4] := 1; SignY[5] := 1; SignY[6] := -1; SignY[7] := -1;

  Unit.ClearVisibleUnits;
  Unit.ClearVisibleTiles;

  if Unit.IsOut then Exit(False);

  Pos := Unit.Position;
  if (Unit.Height + Unit.FloatHeight - FSave.GetTile(Unit.Position).TerrainLevel) >= 24 + 4 then
    if Assigned(FSave.GetTile(Pos + TPosition.Create(0,0,1))) and FSave.GetTile(Pos + TPosition.Create(0,0,1)).HasNoFloor(nil) then
      Pos.Z := Pos.Z + 1;

  Trajectory := TList<TPosition>.Create;
  try
    for X := 0 to MAX_VIEW_DISTANCE do
    begin
      if Direction mod 2 = 1 then
      begin
        Y1 := 0;
        Y2 := MAX_VIEW_DISTANCE;
      end
      else
      begin
        Y1 := -X;
        Y2 := X;
      end;
      for Y := Y1 to Y2 do
        for Z := 0 to FSave.MapSizeZ - 1 do
        begin
          if X*X + Y*Y <= MAX_VIEW_DISTANCE_SQR then
          begin
            Test.Z := Z;
            Test.X := Center.X + SignX[Direction] * IfThen(Swap, Y, X);
            Test.Y := Center.Y + SignY[Direction] * IfThen(Swap, X, Y);
            if FSave.GetTile(Test) <> nil then
            begin
              VisibleUnit := FSave.GetTile(Test).Unit;
              if Assigned(VisibleUnit) and not VisibleUnit.IsOut and Visible(Unit, FSave.GetTile(Test)) then
              begin
                if Unit.Faction = FACTION_PLAYER then
                begin
                  VisibleUnit.Tile.SetVisible(+1);
                  VisibleUnit.Visible := True;
                end;
                if ((VisibleUnit.Faction = FACTION_HOSTILE) and (Unit.Faction = FACTION_PLAYER)) or
                   ((VisibleUnit.Faction <> FACTION_HOSTILE) and (Unit.Faction = FACTION_HOSTILE)) then
                begin
                  Unit.AddToVisibleUnits(VisibleUnit);
                  Unit.AddToVisibleTiles(VisibleUnit.Tile);
                  if (Unit.Faction = FACTION_HOSTILE) and (VisibleUnit.Faction <> FACTION_HOSTILE) then
                    VisibleUnit.SetTurnsSinceSpotted(0);
                end;
              end;

              if Unit.Faction = FACTION_PLAYER then
              begin
                Size := Unit.Armor.Size;
                for XO := 0 to Size - 1 do
                  for YO := 0 to Size - 1 do
                  begin
                    Trajectory.Clear;
                    Tst := CalculateLine(Pos + TPosition.Create(XO,YO,0), Test, True, Trajectory, Unit, False);
                    if Tst > 127 then TSize := Trajectory.Count - 1
                    else TSize := Trajectory.Count;
                    for I := 0 to TSize - 1 do
                    begin
                      FSave.GetTile(Trajectory[I]).SetVisible(+1);
                      FSave.GetTile(Trajectory[I]).SetDiscovered(True, 2);
                      if Assigned(FSave.GetTile(TPosition.Create(Trajectory[I].X + 1, Trajectory[I].Y, Trajectory[I].Z))) then
                        FSave.GetTile(TPosition.Create(Trajectory[I].X + 1, Trajectory[I].Y, Trajectory[I].Z)).SetDiscovered(True, 0);
                      if Assigned(FSave.GetTile(TPosition.Create(Trajectory[I].X, Trajectory[I].Y + 1, Trajectory[I].Z))) then
                        FSave.GetTile(TPosition.Create(Trajectory[I].X, Trajectory[I].Y + 1, Trajectory[I].Z)).SetDiscovered(True, 1);
                    end;
                  end;
              end;
            end;
          end;
        end;
    end;
  finally
    Trajectory.Free;
  end;

  if (Unit.UnitsSpottedThisTurn.Count > OldNumVisibleUnits) and (Unit.VisibleUnits.Count > 0) then
    Result := True
  else Result := False;
end;

procedure TTileEngine.CalculateFOV(Position: TPosition);
var
  Unit: TBattleUnit;
begin
  for Unit in FSave.Units do
    if DistanceSq(Position, Unit.Position) <= MAX_VIEW_DISTANCE_SQR then
      CalculateFOV(Unit);
end;

function TTileEngine.GetSightOriginVoxel(CurrentUnit: TBattleUnit): TPosition;
var
  TileAbove: TTile;
begin
  Result := TPosition.Create((CurrentUnit.Position.X * 16) + 8,
                             (CurrentUnit.Position.Y * 16) + 8,
                             CurrentUnit.Position.Z * 24);
  Result.Z := Result.Z - FSave.GetTile(CurrentUnit.Position).TerrainLevel;
  Result.Z := Result.Z + CurrentUnit.Height + CurrentUnit.FloatHeight - 1;
  TileAbove := FSave.GetTile(CurrentUnit.Position + TPosition.Create(0,0,1));
  if (CurrentUnit.Armor.Size > 1) then
  begin
    Result.X := Result.X + 8;
    Result.Y := Result.Y + 8;
    Result.Z := Result.Z + 1;
  end;
  if (Result.Z >= (CurrentUnit.Position.Z + 1) * 24) and (not Assigned(TileAbove) or not TileAbove.HasNoFloor(nil)) then
    while Result.Z >= (CurrentUnit.Position.Z + 1) * 24 do
      Result.Z := Result.Z - 1;
end;

function TTileEngine.Visible(CurrentUnit: TBattleUnit; Tile: TTile): Boolean;
var
  OriginVoxel, ScanVoxel: TPosition;
  Trajectory: TList<TPosition>;
  T: TTile;
  VisibleDistance: Integer;
  UnitSeen: Boolean;
  I: Integer;
begin
  if (Tile = nil) or (Tile.Unit = nil) then Exit(False);

  if (CurrentUnit.Faction = FACTION_PLAYER) and
     (Distance(CurrentUnit.Position, Tile.Position) > 9) and
     (Tile.Shade > MAX_DARKNESS_TO_SEE_UNITS) then
    Exit(False);

  if Distance(CurrentUnit.Position, Tile.Position) > MAX_VIEW_DISTANCE then
    Exit(False);

  if CurrentUnit.Faction = Tile.Unit.Faction then Exit(True);

  OriginVoxel := GetSightOriginVoxel(CurrentUnit);
  UnitSeen := False;
  UnitSeen := CanTargetUnit(@OriginVoxel, Tile, @ScanVoxel, CurrentUnit, False);

  if UnitSeen then
  begin
    Trajectory := TList<TPosition>.Create;
    try
      CalculateLine(OriginVoxel, ScanVoxel, True, Trajectory, CurrentUnit);
      T := FSave.GetTile(CurrentUnit.Position);
      VisibleDistance := Trajectory.Count;
      for I := 0 to Trajectory.Count - 1 do
      begin
        if T <> FSave.GetTile(TPosition.Create(Trajectory[I].X div 16, Trajectory[I].Y div 16, Trajectory[I].Z div 24)) then
          T := FSave.GetTile(TPosition.Create(Trajectory[I].X div 16, Trajectory[I].Y div 16, Trajectory[I].Z div 24));
        if T.Fire = 0 then
          VisibleDistance := VisibleDistance + T.Smoke div 3;
        if VisibleDistance > MAX_VOXEL_VIEW_DISTANCE then
        begin
          UnitSeen := False;
          Break;
        end;
      end;
    finally
      Trajectory.Free;
    end;
  end;
  Result := UnitSeen;
end;

function TTileEngine.Blockage(Tile: TTile; Part: Integer; DamageType: TItemDamageType; Direction: Integer; CheckingFromOrigin: Boolean): Integer;
var
  Wall: Integer;
  Check: Boolean;
begin
  Result := 0;
  if Tile = nil then Exit(0);
  if Tile.GetMapData(Part) = nil then Exit(0);

  Check := True;
  Wall := -1;
  if Direction <> -1 then
  begin
    Wall := Tile.GetMapData(O_OBJECT).BigWall;
    if (DamageType <> DT_SMOKE) and CheckingFromOrigin and
       ((Wall = Pathfinding.BIGWALLNESW) or (Wall = Pathfinding.BIGWALLNWSE)) then
      Check := False;
    case Direction of
      0: if (Wall = Pathfinding.BIGWALLWEST) or (Wall = Pathfinding.BIGWALLEAST) or
            (Wall = Pathfinding.BIGWALLSOUTH) or (Wall = Pathfinding.BIGWALLEASTANDSOUTH) then Check := False;
      1: if (Wall = Pathfinding.BIGWALLWEST) or (Wall = Pathfinding.BIGWALLSOUTH) then Check := False;
      2: if (Wall = Pathfinding.BIGWALLNORTH) or (Wall = Pathfinding.BIGWALLSOUTH) or
            (Wall = Pathfinding.BIGWALLWEST) or (Wall = Pathfinding.BIGWALLWESTANDNORTH) then Check := False;
      3: if (Wall = Pathfinding.BIGWALLNORTH) or (Wall = Pathfinding.BIGWALLWEST) or
            (Wall = Pathfinding.BIGWALLWESTANDNORTH) then Check := False;
      4: if (Wall = Pathfinding.BIGWALLWEST) or (Wall = Pathfinding.BIGWALLEAST) or
            (Wall = Pathfinding.BIGWALLNORTH) or (Wall = Pathfinding.BIGWALLWESTANDNORTH) then Check := False;
      5: if (Wall = Pathfinding.BIGWALLNORTH) or (Wall = Pathfinding.BIGWALLEAST) then Check := False;
      6: if (Wall = Pathfinding.BIGWALLNORTH) or (Wall = Pathfinding.BIGWALLSOUTH) or
            (Wall = Pathfinding.BIGWALLEAST) or (Wall = Pathfinding.BIGWALLEASTANDSOUTH) then Check := False;
      7: if (Wall = Pathfinding.BIGWALLSOUTH) or (Wall = Pathfinding.BIGWALLEAST) or
            (Wall = Pathfinding.BIGWALLEASTANDSOUTH) then Check := False;
      8,9: if (Wall <> 0) and (Wall <> Pathfinding.BLOCK) then Check := False;
    end;
  end
  else if (Part = O_FLOOR) and (Tile.GetMapData(Part).Block(DamageType) = 0) then
  begin
    if DamageType <> DT_NONE then
      Result := Tile.GetMapData(Part).Armor
    else if not Tile.GetMapData(Part).IsNoFloor then
      Exit(256);
  end;

  if Check then
  begin
    if (DamageType = DT_SMOKE) and (Wall <> 0) and not Tile.IsUfoDoorOpen(Part) then
      Exit(256);
    Result := Result + Tile.GetMapData(Part).Block(DamageType);
  end;

  if Tile.IsUfoDoorOpen(Part) then
    Result := 0;
end;

function TTileEngine.UnitOpensDoor(Unit: TBattleUnit; RClick: Boolean; Dir: Integer): Integer;
var
  Size, Z, TUCost: Integer;
  X, Y: Integer;
  Tile: TTile;
  Part: Integer;
  CheckPositions: TList<TPair<TPosition, Integer>>;
  Pair: TPair<TPosition, Integer>;
  DoorResult: Integer;
begin
  DoorResult := -1;
  TUCost := 0;
  Size := Unit.Armor.Size;
  Z := IfThen(Unit.Tile.TerrainLevel < -12, 1, 0);
  if Dir = -1 then Dir := Unit.Direction;

  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
    begin
      CheckPositions := TList<TPair<TPosition, Integer>>.Create;
      try
        Tile := FSave.GetTile(Unit.Position + TPosition.Create(X,Y,Z));
        if Tile = nil then Continue;
        case Dir of
          0: begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,0,0), O_NORTHWALL));
                if X <> 0 then CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,-1,0), O_WESTWALL)); end;
          1: begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,0,0), O_NORTHWALL));
                CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(1,-1,0), O_WESTWALL));
                if RClick then begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(1,0,0), O_WESTWALL));
                                  CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(1,0,0), O_NORTHWALL)); end; end;
          2: CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(1,0,0), O_WESTWALL));
          3: begin if Y = 0 then CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(1,1,0), O_WESTWALL));
                    if X = 0 then CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(1,1,0), O_NORTHWALL));
                    if RClick then begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(1,0,0), O_WESTWALL));
                                      CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,1,0), O_NORTHWALL)); end; end;
          4: CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,1,0), O_NORTHWALL));
          5: begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,0,0), O_WESTWALL));
                CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(-1,1,0), O_NORTHWALL));
                if RClick then begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,1,0), O_WESTWALL));
                                  CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,1,0), O_NORTHWALL)); end; end;
          6: begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,0,0), O_WESTWALL));
                if Y <> 0 then CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(-1,0,0), O_NORTHWALL)); end;
          7: begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,0,0), O_WESTWALL));
                CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,0,0), O_NORTHWALL));
                if X <> 0 then CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(-1,-1,0), O_WESTWALL));
                if Y <> 0 then CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(-1,-1,0), O_NORTHWALL));
                if RClick then begin CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(0,-1,0), O_WESTWALL));
                                  CheckPositions.Add(TPair<TPosition,Integer>.Create(TPosition.Create(-1,0,0), O_NORTHWALL)); end; end;
        end;
        Part := O_FLOOR;
        for Pair in CheckPositions do
        begin
          Tile := FSave.GetTile(Unit.Position + TPosition.Create(X,Y,Z) + Pair.Key);
          if Tile <> nil then
          begin
            DoorResult := Tile.OpenDoor(Pair.Value, Unit, FSave.BattleGame.ReservedAction);
            if DoorResult <> -1 then
            begin
              Part := Pair.Value;
              if DoorResult = 1 then
                CheckAdjacentDoors(Unit.Position + TPosition.Create(X,Y,Z) + Pair.Key, Pair.Value);
            end;
          end;
        end;
        if DoorResult = 0 then
        begin
          if RClick then
          begin
            if Part = O_WESTWALL then Part := O_NORTHWALL
            else Part := O_WESTWALL;
            TUCost := Tile.GetTUCost(Part, Unit.MovementType);
          end;
        end
        else if (DoorResult = 1) or (DoorResult = 4) then
          TUCost := Tile.GetTUCost(Part, Unit.MovementType);
      finally
        CheckPositions.Free;
      end;
    end;

  if TUCost <> 0 then
  begin
    if FSave.BattleGame.CheckReservedTU(Unit, TUCost) then
    begin
      if Unit.SpendTimeUnits(TUCost) then
      begin
        CalculateFOV(Unit.Position);
        for var V in Unit.VisibleUnits do
          CalculateFOV(V);
      end
      else Exit(4);
    end
    else Exit(5);
  end;

  Result := DoorResult;
end;

procedure TTileEngine.CheckAdjacentDoors(const Pos: TPosition; Part: Integer);
var
  Offset: TPosition;
  WestSide: Boolean;
  I: Integer;
  Tile: TTile;
begin
  WestSide := (Part = O_WESTWALL);
  I := 1;
  while True do
  begin
    Offset := IfThen(WestSide, TPosition.Create(0, I, 0), TPosition.Create(I, 0, 0));
    Tile := FSave.GetTile(Pos + Offset);
    if Assigned(Tile) and Assigned(Tile.GetMapData(Part)) and Tile.GetMapData(Part).IsUFODoor then
      Tile.OpenDoor(Part)
    else Break;
    Inc(I);
  end;
  I := -1;
  while True do
  begin
    Offset := IfThen(WestSide, TPosition.Create(0, I, 0), TPosition.Create(I, 0, 0));
    Tile := FSave.GetTile(Pos + Offset);
    if Assigned(Tile) and Assigned(Tile.GetMapData(Part)) and Tile.GetMapData(Part).IsUFODoor then
      Tile.OpenDoor(Part)
    else Break;
    Dec(I);
  end;
end;

function TTileEngine.CloseUfoDoors: Integer;
var
  I: Integer;
  Tile: TTile;
  Unit: TBattleUnit;
  OneNorth, OneWest: TTile;
begin
  Result := 0;
  for I := 0 to FSave.MapSizeXYZ - 1 do
  begin
    Tile := FSave.Tiles[I];
    if Assigned(Tile.Unit) and (Tile.Unit.Armor.Size > 1) then
    begin
      Unit := Tile.Unit;
      OneNorth := FSave.GetTile(Tile.Position + TPosition.Create(0,-1,0));
      OneWest := FSave.GetTile(Tile.Position + TPosition.Create(-1,0,0));
      if (Tile.IsUfoDoorOpen(O_NORTHWALL) and Assigned(OneNorth) and (OneNorth.Unit = Unit)) or
         (Tile.IsUfoDoorOpen(O_WESTWALL) and Assigned(OneWest) and (OneWest.Unit = Unit)) then
        Continue;
    end;
    Result := Result + Tile.CloseUfoDoor;
  end;
end;

function TTileEngine.CalculateLine(Origin, Target: TPosition; StoreTrajectory: Boolean; Trajectory: TList<TPosition>;
  ExcludeUnit: TBattleUnit; DoVoxelCheck: Boolean; OnlyVisible: Boolean; ExcludeAllBut: TBattleUnit): Integer;
var
  X, X0, X1, DeltaX, StepX: Integer;
  Y, Y0, Y1, DeltaY, StepY: Integer;
  Z, Z0, Z1, DeltaZ, StepZ: Integer;
  SwapXY, SwapXZ: Boolean;
  DriftXY, DriftXZ: Integer;
  CX, CY, CZ: Integer;
  LastPoint: TPosition;
  ResultVal: Integer;
  Steps: Integer;
  ExcludeAllUnits: Boolean;
begin
  ExcludeAllUnits := FSave.IsBeforeGame;
  X0 := Origin.X; X1 := Target.X;
  Y0 := Origin.Y; Y1 := Target.Y;
  Z0 := Origin.Z; Z1 := Target.Z;

  SwapXY := Abs(Y1 - Y0) > Abs(X1 - X0);
  if SwapXY then
  begin
    Exchange(X0, Y0);
    Exchange(X1, Y1);
  end;

  SwapXZ := Abs(Z1 - Z0) > Abs(X1 - X0);
  if SwapXZ then
  begin
    Exchange(X0, Z0);
    Exchange(X1, Z1);
  end;

  DeltaX := Abs(X1 - X0);
  DeltaY := Abs(Y1 - Y0);
  DeltaZ := Abs(Z1 - Z0);

  DriftXY := DeltaX div 2;
  DriftXZ := DeltaX div 2;

  StepX := IfThen(X0 > X1, -1, 1);
  StepY := IfThen(Y0 > Y1, -1, 1);
  StepZ := IfThen(Z0 > Z1, -1, 1);

  Y := Y0;
  Z := Z0;
  LastPoint := Origin;
  Steps := 0;

  if DoVoxelCheck then VoxelCheckFlush;

  X := X0;
  while True do
  begin
    CX := X; CY := Y; CZ := Z;
    if SwapXZ then Exchange(CX, CZ);
    if SwapXY then Exchange(CX, CY);

    if StoreTrajectory and Assigned(Trajectory) then
      Trajectory.Add(TPosition.Create(CX, CY, CZ));

    if DoVoxelCheck then
    begin
      ResultVal := VoxelCheck(TPosition.Create(CX, CY, CZ), ExcludeUnit, ExcludeAllUnits, OnlyVisible, ExcludeAllBut);
      if ResultVal <> V_EMPTY then
      begin
        if Assigned(Trajectory) then
          Trajectory.Add(TPosition.Create(CX, CY, CZ));
        Exit(ResultVal);
      end;
    end
    else
    begin
      ResultVal := VerticalBlockage(FSave.GetTile(LastPoint), FSave.GetTile(TPosition.Create(CX, CY, CZ)), DT_NONE);
      ResultVal := ResultVal + HorizontalBlockage(FSave.GetTile(LastPoint), FSave.GetTile(TPosition.Create(CX, CY, CZ)), DT_NONE, Steps < 2);
      Inc(Steps);
      if ResultVal > 127 then
        Exit(ResultVal);
      LastPoint := TPosition.Create(CX, CY, CZ);
    end;

    if X = X1 then Break;

    DriftXY := DriftXY - DeltaY;
    DriftXZ := DriftXZ - DeltaZ;

    if DriftXY < 0 then
    begin
      Y := Y + StepY;
      DriftXY := DriftXY + DeltaX;
      if DoVoxelCheck then
      begin
        CX := X; CZ := Z; CY := Y;
        if SwapXZ then Exchange(CX, CZ);
        if SwapXY then Exchange(CX, CY);
        ResultVal := VoxelCheck(TPosition.Create(CX, CY, CZ), ExcludeUnit, ExcludeAllUnits, OnlyVisible, ExcludeAllBut);
        if ResultVal <> V_EMPTY then
        begin
          if Assigned(Trajectory) then Trajectory.Add(TPosition.Create(CX, CY, CZ));
          Exit(ResultVal);
        end;
      end;
    end;

    if DriftXZ < 0 then
    begin
      Z := Z + StepZ;
      DriftXZ := DriftXZ + DeltaX;
      if DoVoxelCheck then
      begin
        CX := X; CZ := Z; CY := Y;
        if SwapXZ then Exchange(CX, CZ);
        if SwapXY then Exchange(CX, CY);
        ResultVal := VoxelCheck(TPosition.Create(CX, CY, CZ), ExcludeUnit, ExcludeAllUnits, OnlyVisible, ExcludeAllBut);
        if ResultVal <> V_EMPTY then
        begin
          if Assigned(Trajectory) then Trajectory.Add(TPosition.Create(CX, CY, CZ));
          Exit(ResultVal);
        end;
      end;
    end;

    X := X + StepX;
  end;

  Result := V_EMPTY;
end;

function TTileEngine.CalculateParabola(Origin, Target: TPosition; StoreTrajectory: Boolean; Trajectory: TList<TPosition>;
  ExcludeUnit: TBattleUnit; Curvature: Double; const Delta: TPosition): Integer;
var
  Ro: Double;
  Fi, Te: Double;
  ZA, ZK: Double;
  X, Y, Z, I: Integer;
  ResultVal: Integer;
  LastPos, NextPos: TPosition;
begin
  Ro := Sqrt((Target.X - Origin.X)*(Target.X - Origin.X) +
             (Target.Y - Origin.Y)*(Target.Y - Origin.Y) +
             (Target.Z - Origin.Z)*(Target.Z - Origin.Z));
  if AreSame(Ro, 0.0) then Exit(V_EMPTY);

  Fi := ArcCos((Target.Z - Origin.Z) / Ro);
  Te := ArcTan2(Target.Y - Origin.Y, Target.X - Origin.X);

  Te := Te + (Delta.X / Ro) / 2 * PI;
  Fi := Fi + ((Delta.Z + Delta.Y) / Ro) / 14 * PI * Curvature;

  ZA := Sqrt(Ro) * Curvature;
  ZK := 4.0 * ZA / Ro / Ro;

  X := Origin.X;
  Y := Origin.Y;
  Z := Origin.Z;
  I := 8;
  ResultVal := V_EMPTY;
  LastPos := TPosition.Create(X,Y,Z);
  NextPos := LastPos;

  if StoreTrajectory and Assigned(Trajectory) then
    Trajectory.Add(LastPos);

  while Z > 0 do
  begin
    X := Round(Origin.X + I * Cos(Te) * Sin(Fi));
    Y := Round(Origin.Y + I * Sin(Te) * Sin(Fi));
    Z := Round(Origin.Z + I * Cos(Fi) - ZK * (I - Ro/2.0) * (I - Ro/2.0) + ZA);
    NextPos := TPosition.Create(X,Y,Z);

    if StoreTrajectory and Assigned(Trajectory) then
      Trajectory.Delete(Trajectory.Count - 1);

    ResultVal := CalculateLine(LastPos, NextPos, StoreTrajectory, StoreTrajectory ? Trajectory : nil, ExcludeUnit);
    if ResultVal <> V_EMPTY then
    begin
      if not StoreTrajectory and Assigned(Trajectory) then
        ResultVal := CalculateLine(LastPos, NextPos, False, Trajectory, ExcludeUnit);
      Break;
    end;
    LastPos := NextPos;
    Inc(I);
  end;
  Result := ResultVal;
end;

function TTileEngine.CastedShade(Voxel: TPosition): Integer;
var
  ZStart: Integer;
  TmpCoord: TPosition;
  T: TTile;
  TmpVoxel: TPosition;
  Z: Integer;
begin
  ZStart := Voxel.Z;
  TmpCoord := Voxel div TPosition.Create(16,16,24);
  T := FSave.GetTile(TmpCoord);
  while Assigned(T) and T.IsVoid and (T.Unit = nil) do
  begin
    ZStart := TmpCoord.Z * 24;
    TmpCoord.Z := TmpCoord.Z - 1;
    T := FSave.GetTile(TmpCoord);
  end;

  TmpVoxel := Voxel;
  VoxelCheckFlush;
  for Z := ZStart downto 0 do
  begin
    TmpVoxel.Z := Z;
    if VoxelCheck(TmpVoxel, nil) <> V_EMPTY then Break;
  end;
  Result := Z;
end;

function TTileEngine.IsVoxelVisible(Voxel: TPosition): Boolean;
var
  ZStart, ZEnd: Integer;
  TmpVoxel: TPosition;
  Z: Integer;
begin
  ZStart := Voxel.Z + 3;
  if (ZStart div 24) <> (Voxel.Z div 24) then Exit(True);
  ZEnd := (ZStart div 24) * 24 + 24;
  TmpVoxel := Voxel;
  VoxelCheckFlush;
  for Z := ZStart to ZEnd - 1 do
  begin
    TmpVoxel.Z := Z;
    if VoxelCheck(TmpVoxel, nil) = V_OBJECT then Exit(False);
    TmpVoxel.X := TmpVoxel.X + 1;
    if VoxelCheck(TmpVoxel, nil) = V_OBJECT then Exit(False);
    TmpVoxel.Y := TmpVoxel.Y + 1;
    if VoxelCheck(TmpVoxel, nil) = V_OBJECT then Exit(False);
  end;
  Result := True;
end;

procedure TTileEngine.VoxelCheckFlush;
begin
  FCacheTilePos := TPosition.Create(-1,-1,-1);
  FCacheTile := nil;
  FCacheTileBelow := nil;
end;

function TTileEngine.VoxelCheck(Voxel: TPosition; ExcludeUnit: TBattleUnit; ExcludeAllUnits: Boolean; OnlyVisible: Boolean; ExcludeAllBut: TBattleUnit): Integer;
var
  Pos: TPosition;
  Tile, TileBelow: TTile;
  I: Integer;
  Mp: TMapData;
  X, Y, Idx: Integer;
  Unit: TBattleUnit;
  TilePos: TPosition;
  UnitPos: TPosition;
  TerrainHeight: Integer;
  Part: Integer;
  TZ: Integer;
begin
  if (Voxel.X < 0) or (Voxel.Y < 0) or (Voxel.Z < 0) then Exit(V_OUTOFBOUNDS);

  Pos := Voxel div TPosition.Create(16,16,24);
  if (FCacheTilePos.X = Pos.X) and (FCacheTilePos.Y = Pos.Y) and (FCacheTilePos.Z = Pos.Z) then
  begin
    Tile := FCacheTile;
    TileBelow := FCacheTileBelow;
  end
  else
  begin
    Tile := FSave.GetTile(Pos);
    if Tile = nil then Exit(V_OUTOFBOUNDS);
    TileBelow := FSave.GetTile(Pos + TPosition.Create(0,0,-1));
    FCacheTilePos := Pos;
    FCacheTile := Tile;
    FCacheTileBelow := TileBelow;
  end;

  if Tile.IsVoid and (Tile.Unit = nil) and ((TileBelow = nil) or (TileBelow.Unit = nil)) then
    Exit(V_EMPTY);

  if Assigned(Tile.GetMapData(O_FLOOR)) and Tile.GetMapData(O_FLOOR).IsGravLift and
     ((Voxel.Z mod 24 = 0) or (Voxel.Z mod 24 = 1)) then
    if not (Assigned(TileBelow) and Assigned(TileBelow.GetMapData(O_FLOOR)) and TileBelow.GetMapData(O_FLOOR).IsGravLift) then
      Exit(V_FLOOR);

  for I := V_FLOOR to V_OBJECT do
  begin
    Mp := Tile.GetMapData(I);
    if ((I = O_WESTWALL) or (I = O_NORTHWALL)) and Tile.IsUfoDoorOpen(I) then Continue;
    if Assigned(Mp) then
    begin
      X := 15 - (Voxel.X mod 16);
      Y := Voxel.Y mod 16;
      Idx := (Mp.GetLoftID((Voxel.Z mod 24) div 2) * 16) + Y;
      if (FVoxelData[Idx] and (1 shl X)) <> 0 then
        Exit(I);
    end;
  end;

  if not ExcludeAllUnits then
  begin
    Unit := Tile.Unit;
    if (Unit = nil) and Tile.HasNoFloor(TileBelow) and Assigned(TileBelow) then
    begin
      Tile := TileBelow;
      Unit := Tile.Unit;
    end;
    if Assigned(Unit) and (Unit <> ExcludeUnit) and ((ExcludeAllBut = nil) or (Unit = ExcludeAllBut)) and
       ((not OnlyVisible) or Unit.Visible) then
    begin
      UnitPos := Unit.Position;
      TerrainHeight := 0;
      for X := 0 to Unit.Armor.Size - 1 do
        for Y := 0 to Unit.Armor.Size - 1 do
        begin
          if FSave.GetTile(UnitPos + TPosition.Create(X,Y,0)).TerrainLevel < TerrainHeight then
            TerrainHeight := FSave.GetTile(UnitPos + TPosition.Create(X,Y,0)).TerrainLevel;
        end;
      TZ := UnitPos.Z * 24 + Unit.FloatHeight - TerrainHeight;
      if (Voxel.Z > TZ) and (Voxel.Z <= TZ + Unit.Height) then
      begin
        X := 15 - (Voxel.X mod 16);
        Y := Voxel.Y mod 16;
        Part := 0;
        if Unit.Armor.Size > 1 then
        begin
          TilePos := Tile.Position;
          Part := (TilePos.X - UnitPos.X) + (TilePos.Y - UnitPos.Y) * 2;
          // order change for large units
          if Part = 0 then Part := 1
          else if Part = 1 then Part := 0
          else if Part = 2 then Part := 3
          else if Part = 3 then Part := 2;
        end;
        Idx := (Unit.GetLoftemps(Part) * 16) + Y;
        if (FVoxelData[Idx] and (1 shl X)) <> 0 then
          Exit(V_UNIT);
      end;
    end;
  end;

  Result := V_EMPTY;
end;

function TTileEngine.CheckReactionFire(Unit: TBattleUnit): Boolean;
var
  Spotters: TList<TPair<TBattleUnit, Integer>>;
  AttackType: Integer;
  Reactor: TBattleUnit;
  ResultVal: Boolean;
begin
  ResultVal := False;
  if (Unit.Faction <> FSave.Side) or (Unit.Tile = nil) then Exit(False);

  Spotters := GetSpottingUnits(Unit);
  try
    if (Unit.Faction = Unit.OriginalFaction) or (Unit.Faction <> FACTION_HOSTILE) then
    begin
      AttackType := 0;
      Reactor := GetReactor(Spotters, AttackType, Unit);
      while Reactor <> Unit do
      begin
        if not TryReaction(Reactor, Unit, AttackType) then
        begin
          for I := Spotters.Count - 1 downto 0 do
            if Spotters[I].Key = Reactor then
            begin
              Spotters.Delete(I);
              Break;
            end;
          Reactor := GetReactor(Spotters, AttackType, Unit);
          Continue;
        end;
        Reactor := GetReactor(Spotters, AttackType, Unit);
        ResultVal := True;
      end;
    end;
  finally
    Spotters.Free;
  end;

  Result := ResultVal;
end;

function TTileEngine.GetSpottingUnits(Unit: TBattleUnit): TList<TPair<TBattleUnit, Integer>>;
var
  Tile: TTile;
  Bu: TBattleUnit;
  OriginVoxel, TargetVoxel: TPosition;
  FalseAction: TBattleAction;
  Ai: TAIModule;
  GotHit: Boolean;
  AttackType: Integer;
begin
  Result := TList<TPair<TBattleUnit, Integer>>.Create;
  Tile := Unit.Tile;

  if FSave.Side <> FACTION_NEUTRAL then
  begin
    for Bu in FSave.Units do
    begin
      if not Bu.IsOut and (Bu.Health <> 0) and (Bu.Stunlevel < Bu.Health) and
         (Bu.Faction <> FSave.Side) and (Bu.Faction <> FACTION_NEUTRAL) and
         (DistanceSq(Unit.Position, Bu.Position) <= MAX_VIEW_DISTANCE_SQR) then
      begin
        FillChar(FalseAction, SizeOf(FalseAction), 0);
        FalseAction.Type_ := BA_SNAPSHOT;
        FalseAction.Actor := Bu;
        FalseAction.Target := Unit.Position;
        OriginVoxel := GetOriginVoxel(FalseAction, nil);
        Ai := Bu.AIModule;
        GotHit := Assigned(Ai) and Ai.GetWasHitBy(Unit.Id) or (not Assigned(Ai) and Bu.GetHitState);

        if ((Bu.CheckViewSector(Unit.Position) or GotHit) and
            CanTargetUnit(@OriginVoxel, Tile, @TargetVoxel, Bu, False) and
            Visible(Bu, Tile)) then
        begin
          if Bu.Faction = FACTION_PLAYER then
            Unit.Visible := True;
          Bu.AddToVisibleUnits(Unit);
          AttackType := DetermineReactionType(Bu, Unit);
          if AttackType <> BA_NONE then
            Result.Add(TPair<TBattleUnit, Integer>.Create(Bu, AttackType));
        end;
      end;
    end;
  end;
end;

function TTileEngine.GetReactor(Spotters: TList<TPair<TBattleUnit, Integer>>; var AttackType: Integer; Unit: TBattleUnit): TBattleUnit;
var
  BestScore: Integer;
  Bu: TBattleUnit;
  Pair: TPair<TBattleUnit, Integer>;
begin
  BestScore := -1;
  Bu := nil;
  for Pair in Spotters do
  begin
    if not Pair.Key.IsOut and not Pair.Key.Respawn and
       (DetermineReactionType(Pair.Key, Unit) <> BA_NONE) and
       (Pair.Key.ReactionScore > BestScore) then
    begin
      BestScore := Pair.Key.ReactionScore;
      Bu := Pair.Key;
      AttackType := Pair.Value;
    end;
  end;
  if Unit.ReactionScore <= BestScore then
  begin
    if Bu.OriginalFaction = FACTION_PLAYER then
      Bu.AddReactionExp;
  end
  else
  begin
    Bu := Unit;
    AttackType := BA_NONE;
  end;
  Result := Bu;
end;

function TTileEngine.DetermineReactionType(Unit, Target: TBattleUnit): Integer;
var
  MeleeWeapon: TBattleItem;
  Weapon: TBattleItem;
begin
  MeleeWeapon := Unit.GetMeleeWeapon;
  if Assigned(MeleeWeapon) and ValidMeleeRange(Unit, Target, Unit.Direction) and
     (Unit.GetActionTUs(BA_HIT, MeleeWeapon) > 0) and
     (Unit.TimeUnits > Unit.GetActionTUs(BA_HIT, MeleeWeapon)) and
     ((Unit.OriginalFaction <> FACTION_PLAYER) or FSave.GeoscapeSave.IsResearched(MeleeWeapon.Rules.Requirements)) and
     FSave.IsItemUsable(MeleeWeapon) then
    Exit(BA_HIT);

  Weapon := Unit.GetMainHandWeapon(Unit.Faction <> FACTION_PLAYER);
  if Assigned(Weapon) and (Weapon.Rules.BattleType <> BT_MELEE) and
     (Weapon.Rules.TUSnap > 0) and
     (DistanceSq(Unit.Position, Target.Position, False) < Weapon.Rules.MaxRangeSq) and
     Assigned(Weapon.AmmoItem) and
     (Unit.GetActionTUs(BA_SNAPSHOT, Weapon) > 0) and
     (Unit.TimeUnits > Unit.GetActionTUs(BA_SNAPSHOT, Weapon)) and
     ((Unit.OriginalFaction <> FACTION_PLAYER) or FSave.GeoscapeSave.IsResearched(Weapon.Rules.Requirements)) and
     FSave.IsItemUsable(Weapon) then
    Exit(BA_SNAPSHOT);

  Result := BA_NONE;
end;

function TTileEngine.TryReaction(Unit, Target: TBattleUnit; AttackType: Integer): Boolean;
var
  Action: TBattleAction;
  Ai: TAIModule;
begin
  Action.CameraPosition := FSave.BattleState.Map.Camera.MapOffset;
  Action.Actor := Unit;
  if AttackType = BA_HIT then
    Action.Weapon := Unit.GetMeleeWeapon
  else
    Action.Weapon := Unit.GetMainHandWeapon(Unit.Faction <> FACTION_PLAYER);
  if Action.Weapon = nil then Exit(False);
  Action.Type_ := BattleActionType(AttackType);
  Action.Target := Target.Position;
  Action.TU := Unit.GetActionTUs(Action.Type_, Action.Weapon);

  if Assigned(Action.Weapon.AmmoItem) and (Action.Weapon.AmmoItem.AmmoQuantity > 0) and (Unit.TimeUnits >= Action.TU) then
  begin
    Action.Targeting := True;

    if Unit.Faction = FACTION_HOSTILE then
    begin
      Ai := Unit.AIModule;
      if Ai = nil then
      begin
        Ai := TAIModule.Create(FSave, Unit, nil);
        Unit.SetAIModule(Ai);
      end;
      if (Action.Type_ <> BA_HIT) and Assigned(Action.Weapon.AmmoItem) and (Action.Weapon.AmmoItem.Rules.ExplosionRadius > 0) and
         not Ai.ExplosiveEfficacy(Action.Target, Unit, Action.Weapon.AmmoItem.Rules.ExplosionRadius, -1) then
        Action.Targeting := False;
    end;

    if Action.Targeting and Unit.SpendTimeUnits(Action.TU) then
    begin
      Action.TU := 0;
      if Action.Type_ = BA_HIT then
        FSave.BattleGame.StatePushBack(TMeleeAttackBState.Create(FSave.BattleGame, Action))
      else
        FSave.BattleGame.StatePushBack(TProjectileFlyBState.Create(FSave.BattleGame, Action));
      Exit(True);
    end;
  end;
  Result := False;
end;

function TTileEngine.Hit(Center: TPosition; Power: Integer; DamageType: TItemDamageType; Unit: TBattleUnit): TBattleUnit;
var
  Tile: TTile;
  Bu: TBattleUnit;
  Part: Integer;
  RndPower, AdjDamage, Wounds, MoraleLoss: Integer;
  VerticalOffset: Integer;
  Below: TTile;
  Sz: Integer;
  TargetPos, Relative: TPosition;
  Bravery: Integer;
  Modifier: Integer;
begin
  Tile := FSave.GetTile(TPosition.Create(Center.X div 16, Center.Y div 16, Center.Z div 24));
  if Tile = nil then Exit(nil);
  Bu := Tile.Unit;
  AdjDamage := 0;

  VoxelCheckFlush;
  Part := VoxelCheck(Center, Unit);
  if (Part >= V_FLOOR) and (Part <= V_OBJECT) then
  begin
    RndPower := RNG.Generate(Power div 4, (Power*3) div 4);
    if (Part = V_OBJECT) and (RndPower >= Tile.GetMapData(O_OBJECT).Armor) and
       (FSave.MissionType = 'STR_BASE_DEFENSE') and Tile.GetMapData(O_OBJECT).IsBaseModule then
      FSave.ModuleMap[(Center.X div 16) div 10][(Center.Y div 16) div 10].Value2 := FSave.ModuleMap[(Center.X div 16) div 10][(Center.Y div 16) div 10].Value2 - 1;
    if Tile.Damage(Part, RndPower, FSave.ObjectiveType) then
      FSave.AddDestroyedObjective;
  end
  else if Part = V_UNIT then
  begin
    RndPower := RNG.Generate(Power * (100 - IfThen(DamageType = DT_HE, Mod.EXPLOSIVE_DAMAGE_RANGE, Mod.DAMAGE_RANGE)) div 100,
                             Power * (100 + IfThen(DamageType = DT_HE, Mod.EXPLOSIVE_DAMAGE_RANGE, Mod.DAMAGE_RANGE)) div 100);
    VerticalOffset := 0;
    if Bu = nil then
    begin
      Below := FSave.GetTile(TPosition.Create(Center.X div 16, Center.Y div 16, (Center.Z div 24) - 1));
      if Assigned(Below) then
      begin
        Bu := Below.Unit;
        if Assigned(Bu) then VerticalOffset := 24;
      end;
    end;
    if Assigned(Bu) and (Bu.Health <> 0) and (Bu.Stunlevel < Bu.Health) then
    begin
      Sz := Bu.Armor.Size * 8;
      TargetPos := Bu.Position * TPosition.Create(16,16,24) + TPosition.Create(Sz, Sz, Bu.FloatHeight - Tile.TerrainLevel);
      Relative := (Center - TargetPos) - TPosition.Create(0,0,VerticalOffset);
      Wounds := Bu.FatalWounds;
      AdjDamage := Bu.Damage(Relative, RndPower, DamageType);
      if Assigned(Unit) and (Bu.Faction <> FACTION_PLAYER) and (Wounds < Bu.FatalWounds) then
        Bu.KilledBy(Unit.Faction);
      Bravery := (110 - Bu.BaseStats.Bravery) div 10;
      Modifier := IfThen(Bu.Faction = FACTION_PLAYER, FSave.MoraleModifier, 100);
      MoraleLoss := 100 * (AdjDamage * Bravery div 10) div Modifier;
      Bu.MoraleChange(-MoraleLoss);

      if ((Bu.SpecialAbility = SPECAB_EXPLODEONDEATH) or (Bu.SpecialAbility = SPECAB_BURN_AND_EXPLODE)) and
         not Bu.IsOut and ((Bu.Health = 0) or (Bu.Stunlevel >= Bu.Health)) then
        if (DamageType <> DT_STUN) and (DamageType <> DT_HE) and (DamageType <> DT_IN) and (DamageType <> DT_MELEE) then
          FSave.BattleGame.StatePushNext(TExplosionBState.Create(FSave.BattleGame,
            TPosition.Create(Bu.Position.X * 16, Bu.Position.Y * 16, Bu.Position.Z * 24), nil, Bu, 0));

      if (Bu.OriginalFaction = FACTION_HOSTILE) and Assigned(Unit) and (Unit.OriginalFaction = FACTION_PLAYER) and
         (DamageType <> DT_NONE) and (FSave.BattleGame.CurrentAction.Type_ <> BA_HIT) then
        Unit.AddFiringExp;
    end;
  end;

  ApplyGravity(Tile);
  CalculateSunShading;
  CalculateTerrainLighting;
  CalculateFOV(Center div TPosition.Create(16,16,24));
  Result := Bu;
end;

procedure TTileEngine.Explode(Center: TPosition; Power: Integer; DamageType: TItemDamageType; MaxRadius: Integer; Unit: TBattleUnit);
var
  CenterZ, CenterX, CenterY: Double;
  HitSide, DiagonalWall: Integer;
  Power_: Integer;
  TilesAffected: TList<TTile>;
  Origin, Dest: TTile;
  ExHeight, VertDec: Integer;
  DmgRng: Integer;
  Fi, Te: Integer;
  CosTe, SinTe, SinFi, CosFi: Double;
  L: Double;
  TileX, TileY, TileZ: Integer;
  Ret: Boolean;
  TileBelow: TTile;
  Bu: TBattleUnit;
  Wounds: Integer;
  Min, Max: Integer;
  It: TBattleItem;
  Temp: TList<TBattleItem>;
  I: Integer;
  Resistance: Single;
  BurnTime: Integer;
begin
  CenterZ := Center.Z / 24 + 0.5;
  CenterX := Center.X / 16 + 0.5;
  CenterY := Center.Y / 16 + 0.5;
  HitSide := 0;
  DiagonalWall := 0;

  if DamageType = DT_IN then Power := Power div 2;

  ExHeight := Clamp(Options.BattleExplosionHeight, 0, 3);
  VertDec := 1000;
  DmgRng := IfThen(DamageType = DT_HE, Mod.EXPLOSIVE_DAMAGE_RANGE, Mod.DAMAGE_RANGE);

  case ExHeight of
    1: VertDec := 30;
    2: VertDec := 10;
    3: VertDec := 5;
  end;

  TilesAffected := TList<TTile>.Create;
  try
    Origin := FSave.GetTile(TPosition.Create(Round(CenterX), Round(CenterY), Round(CenterZ)));
    if Origin.IsBigWall then
    begin
      DiagonalWall := Origin.GetMapData(O_OBJECT).BigWall;
      if DiagonalWall = Pathfinding.BIGWALLNWSE then
        HitSide := IfThen((Center.X mod 16 - Center.Y mod 16) > 0, 1, -1);
      if DiagonalWall = Pathfinding.BIGWALLNESW then
        HitSide := IfThen((Center.X mod 16 + Center.Y mod 16 - 15) > 0, 1, -1);
    end;

    for Fi := -90 to 90 step 5 do
      for Te := 0 to 360 step 3 do
      begin
        CosTe := Cos(DegToRad(Te));
        SinTe := Sin(DegToRad(Te));
        SinFi := Sin(DegToRad(Fi));
        CosFi := Cos(DegToRad(Fi));

        Origin := FSave.GetTile(TPosition.Create(Round(CenterX), Round(CenterY), Round(CenterZ)));
        Dest := Origin;
        L := 0;
        Power_ := Power;

        while (Power_ > 0) and (L <= MaxRadius) do
        begin
          if Power_ > 0 then
          begin
            if DamageType = DT_HE then
              Dest.SetExplosive(Power_, 0);

            if not TilesAffected.Contains(Dest) then
            begin
              TilesAffected.Add(Dest);
              Min := Power_ * (100 - DmgRng) div 100;
              Max := Power_ * (100 + DmgRng) div 100;
              Bu := Dest.Unit;
              TileBelow := FSave.GetTile(Dest.Position - TPosition.Create(0,0,1));
              Wounds := 0;
              if (Bu = nil) and (Dest.Position.Z > 0) and Dest.HasNoFloor(TileBelow) then
              begin
                Bu := TileBelow.Unit;
                if Assigned(Bu) and (Bu.Height + Bu.FloatHeight - TileBelow.TerrainLevel <= 24) then
                  Bu := nil;
              end;
              if Assigned(Bu) and Assigned(Unit) then Wounds := Bu.FatalWounds;

              case DamageType of
                DT_STUN:
                  begin
                    if Assigned(Bu) then
                    begin
                      if Distance(Dest.Position, TPosition.Create(Round(CenterX), Round(CenterY), Round(CenterZ))) < 2 then
                        Bu.Damage(TPosition.Create(0,0,0), RNG.Generate(Min, Max), DamageType)
                      else
                        Bu.Damage(TPosition.Create(Round(CenterX), Round(CenterY), Round(CenterZ)) - Dest.Position, RNG.Generate(Min, Max), DamageType);
                    end;
                    for It in Dest.Inventory do
                      if Assigned(It.Unit) then
                        It.Unit.Damage(TPosition.Create(0,0,0), RNG.Generate(Min, Max), DamageType);
                  end;
                DT_HE:
                  begin
                    if Assigned(Bu) then
                    begin
                      if (Abs(Dest.Position.X - Round(CenterX)) < 2) and (Abs(Dest.Position.Y - Round(CenterY)) < 2) and (Dest.Position.Z = Round(CenterZ)) or (Dest.Position.Z > Round(CenterZ)) then
                        Bu.Damage(TPosition.Create(0,0,0), RNG.Generate(Min, Max), DamageType)
                      else
                        Bu.Damage(TPosition.Create(Round(CenterX), Round(CenterY), Round(CenterZ) + 5) - Dest.Position, RNG.Generate(Min, Max), DamageType);
                    end;
                    Temp := TList<TBattleItem>.Create;
                    try
                      Temp.AddRange(Dest.Inventory);
                      for It in Temp do
                        if Power_ > It.Rules.Armor then
                        begin
                          if Assigned(It.Unit) and (It.Unit.Status = STATUS_UNCONSCIOUS) then
                            It.Unit.Kill;
                          FSave.RemoveItem(It);
                        end;
                    finally
                      Temp.Free;
                    end;
                  end;
                DT_SMOKE:
                  begin
                    if (Dest.Smoke < 10) and (Dest.TerrainLevel > -24) then
                    begin
                      Dest.Fire := 0;
                      Dest.Smoke := RNG.Generate(7, 15);
                    end;
                  end;
                DT_IN:
                  begin
                    if not Dest.IsVoid then
                    begin
                      if (Dest.Fire = 0) and (Assigned(Dest.GetMapData(O_FLOOR)) or Assigned(Dest.GetMapData(O_OBJECT))) then
                      begin
                        Dest.Fire := Dest.Fuel + 1;
                        Dest.Smoke := Clamp(15 - (Dest.Flammability div 10), 1, 12);
                      end;
                      if Assigned(Bu) then
                      begin
                        Resistance := Bu.Armor.GetDamageModifier(DT_IN);
                        if Resistance > 0.0 then
                        begin
                          Bu.Damage(TPosition.Create(0,0,12-Dest.TerrainLevel), RNG.Generate(Mod.FIRE_DAMAGE_RANGE[0], Mod.FIRE_DAMAGE_RANGE[1]), DT_IN, True);
                          BurnTime := RNG.Generate(0, Round(5.0 * Resistance));
                          if Bu.Fire < BurnTime then Bu.Fire := BurnTime;
                        end;
                      end;
                    end;
                  end;
              end;

              if Assigned(Unit) and Assigned(Bu) and (Bu.Faction <> Unit.Faction) then
              begin
                Unit.AddFiringExp;
                if (Wounds < Bu.FatalWounds) and (Bu.Faction <> FACTION_PLAYER) then
                  Bu.KilledBy(Unit.Faction);
              end;
            end;
          end;

          L := L + 1.0;
          TileX := Round(Floor(CenterX + L * SinTe * CosFi));
          TileY := Round(Floor(CenterY + L * CosTe * CosFi));
          TileZ := Round(Floor(CenterZ + L * SinFi));

          Origin := Dest;
          Dest := FSave.GetTile(TPosition.Create(TileX, TileY, TileZ));
          if Dest = nil then Break;

          Power_ := Power_ - 10;
          if Origin.Position.Z <> TileZ then Power_ := Power_ - VertDec;

          if DamageType = DT_IN then
          begin
            // diagonal extra cost
          end;

          if L > 0.5 then
          begin
            if L > 1.5 then
            begin
              Power_ := Power_ - VerticalBlockage(Origin, Dest, DamageType, False) * 2;
              Power_ := Power_ - HorizontalBlockage(Origin, Dest, DamageType, False) * 2;
            end
            else
            begin
              // bigwall deflection
              // (simplified)
            end;
          end;
        end;
      end;

    // Detonate HE
    if DamageType = DT_HE then
      for Dest in TilesAffected do
      begin
        if Detonate(Dest) then
          FSave.AddDestroyedObjective;
        ApplyGravity(Dest);
        if FSave.GetTile(Dest.Position + TPosition.Create(0,0,1)) <> nil then
          ApplyGravity(FSave.GetTile(Dest.Position + TPosition.Create(0,0,1)));
      end;

    CalculateSunShading;
    CalculateTerrainLighting;
    CalculateFOV(Center div TPosition.Create(16,16,24));
  finally
    TilesAffected.Free;
  end;
end;

function TTileEngine.Detonate(Tile: TTile): Boolean;
var
  Explosive, RemainingPower, FireProof, Fuel: Integer;
  Tiles: array[0..8] of TTile;
  Parts: array[0..8] of Integer;
  I, J, Volume, Diemcd: Integer;
  CurrentPart, CurrentPart2: Integer;
  Destroyed: Boolean;
  BigWallDestroyed, SkipNorthWest: Boolean;
  Pos: TPosition;
begin
  Explosive := Tile.Explosive;
  if Explosive = 0 then Exit(False);
  Tile.SetExplosive(0,0,True);
  Result := False;

  Pos := Tile.Position;
  Tiles[0] := FSave.GetTile(TPosition.Create(Pos.X, Pos.Y, Pos.Z+1)); // ceiling
  Tiles[1] := FSave.GetTile(TPosition.Create(Pos.X+1, Pos.Y, Pos.Z));
  Tiles[2] := FSave.GetTile(TPosition.Create(Pos.X, Pos.Y+1, Pos.Z));
  Tiles[3] := Tile; Tiles[4] := Tile; Tiles[5] := Tile; Tiles[6] := Tile;
  Tiles[7] := FSave.GetTile(TPosition.Create(Pos.X, Pos.Y-1, Pos.Z));
  Tiles[8] := FSave.GetTile(TPosition.Create(Pos.X-1, Pos.Y, Pos.Z));

  Parts[0] := O_FLOOR; Parts[1] := O_WESTWALL; Parts[2] := O_NORTHWALL;
  Parts[3] := O_FLOOR; Parts[4] := O_WESTWALL; Parts[5] := O_NORTHWALL;
  Parts[6] := O_OBJECT; Parts[7] := O_OBJECT; Parts[8] := O_OBJECT;

  BigWallDestroyed := True;
  SkipNorthWest := False;

  for I := 8 downto 0 do
  begin
    if (Tiles[I] = nil) or (Tiles[I].GetMapData(Parts[I]) = nil) then Continue;
    if (I > 6) and not ((Tiles[I].GetMapData(Parts[I]).BigWall = 1) or (Tiles[I].GetMapData(Parts[I]).BigWall = 8) or
        ((I = 8) and (Tiles[I].GetMapData(Parts[I]).BigWall = 6)) or ((I = 7) and (Tiles[I].GetMapData(Parts[I]).BigWall = 7))) then Continue;
    if SkipNorthWest and ((I = 2) or (I = 1)) then Continue;
    RemainingPower := Explosive;
    Destroyed := False;
    Volume := 0;
    CurrentPart := Parts[I];
    FireProof := Tiles[I].GetFlammability(CurrentPart);
    Fuel := Tiles[I].GetFuel(CurrentPart) + 1;

    for J := 0 to 11 do
      if Tiles[I].GetMapData(CurrentPart).GetLoftID(J) <> 0 then Volume := Volume + 1;

    if (I = 6) and ((Tiles[I].GetMapData(CurrentPart).BigWall = 2) or (Tiles[I].GetMapData(CurrentPart).BigWall = 3)) and
       (2 * Tiles[I].GetMapData(CurrentPart).Armor > RemainingPower) then
      BigWallDestroyed := False;

    while Assigned(Tiles[I].GetMapData(CurrentPart)) and
          (2 * Tiles[I].GetMapData(CurrentPart).Armor <= RemainingPower) and
          (Tiles[I].GetMapData(CurrentPart).Armor <> 255) do
    begin
      if (I = 6) and ((Tiles[I].GetMapData(CurrentPart).BigWall = 2) or (Tiles[I].GetMapData(CurrentPart).BigWall = 3)) then
        BigWallDestroyed := True;
      if (I = 6) and ((Tiles[I].GetMapData(CurrentPart).BigWall = 6) or (Tiles[I].GetMapData(CurrentPart).BigWall = 7) or
          (Tiles[I].GetMapData(CurrentPart).BigWall = 8)) then
        SkipNorthWest := False;

      RemainingPower := RemainingPower - 2 * Tiles[I].GetMapData(CurrentPart).Armor;
      Destroyed := True;
      if (FSave.MissionType = 'STR_BASE_DEFENSE') and Tiles[I].GetMapData(CurrentPart).IsBaseModule then
        FSave.ModuleMap[Tile.Position.X div 10][Tile.Position.Y div 10].Value2 := FSave.ModuleMap[Tile.Position.X div 10][Tile.Position.Y div 10].Value2 - 1;

      Diemcd := Tiles[I].GetMapData(CurrentPart).DieMCD;
      if Diemcd <> 0 then
        CurrentPart2 := Tiles[I].GetMapData(CurrentPart).Dataset.GetObject(Diemcd).ObjectType
      else
        CurrentPart2 := CurrentPart;
      if Tiles[I].Destroy(CurrentPart, FSave.ObjectiveType) then
        Result := True;
      CurrentPart := CurrentPart2;
      if Assigned(Tiles[I].GetMapData(CurrentPart)) then
      begin
        FireProof := Tiles[I].GetFlammability(CurrentPart);
        Fuel := Tiles[I].GetFuel(CurrentPart) + 1;
      end;
    end;

    if (2 * FireProof) < RemainingPower then
    begin
      if Assigned(Tiles[I].GetMapData(O_FLOOR)) or Assigned(Tiles[I].GetMapData(O_OBJECT)) then
      begin
        Tiles[I].Fire := Fuel;
        Tiles[I].Smoke := Clamp(15 - (FireProof div 10), 1, 12);
      end;
    end;

    if Destroyed then
    begin
      if (Tiles[I].Fire > 0) and not Assigned(Tiles[I].GetMapData(O_FLOOR)) and not Assigned(Tiles[I].GetMapData(O_OBJECT)) then
        Tiles[I].Fire := 0;
      if Tiles[I].Fire = 0 then
      begin
        Tiles[I].Smoke := Clamp(RNG.Generate(1, (Volume div 2) + 3) + (Volume div 2), 0, 15);
      end;
    end;
  end;
end;

function TTileEngine.CheckForTerrainExplosions: TTile;
var
  I: Integer;
begin
  for I := 0 to FSave.MapSizeXYZ - 1 do
    if FSave.Tiles[I].Explosive > 0 then
      Exit(FSave.Tiles[I]);
  Result := nil;
end;

function TTileEngine.VerticalBlockage(StartTile, EndTile: TTile; DamageType: TItemDamageType; SkipObject: Boolean): Integer;
var
  Block: Integer;
  Direction, X, Y, Z: Integer;
  CurrTile: TTile;
begin
  if (StartTile = nil) or (EndTile = nil) then Exit(0);
  Direction := EndTile.Position.Z - StartTile.Position.Z;
  if Direction = 0 then Exit(0);

  Block := 0;
  X := StartTile.Position.X;
  Y := StartTile.Position.Y;
  Z := StartTile.Position.Z;

  if Direction < 0 then
  begin
    Block := Block + Blockage(StartTile, O_FLOOR, DamageType);
    if not SkipObject then Block := Block + Blockage(StartTile, O_OBJECT, DamageType, Pathfinding.DIR_DOWN);
    if (X <> EndTile.Position.X) or (Y <> EndTile.Position.Y) then
    begin
      X := EndTile.Position.X;
      Y := EndTile.Position.Y;
      CurrTile := FSave.GetTile(TPosition.Create(X, Y, Z));
      Block := Block + HorizontalBlockage(StartTile, CurrTile, DamageType, SkipObject);
      Block := Block + Blockage(CurrTile, O_FLOOR, DamageType);
      if not SkipObject then Block := Block + Blockage(CurrTile, O_OBJECT, DamageType, Pathfinding.DIR_DOWN);
    end;
  end
  else if Direction > 0 then
  begin
    Z := Z + 1;
    CurrTile := FSave.GetTile(TPosition.Create(X, Y, Z));
    Block := Block + Blockage(CurrTile, O_FLOOR, DamageType);
    if not SkipObject then Block := Block + Blockage(CurrTile, O_OBJECT, DamageType, Pathfinding.DIR_UP);
    if (X <> EndTile.Position.X) or (Y <> EndTile.Position.Y) then
    begin
      X := EndTile.Position.X;
      Y := EndTile.Position.Y;
      CurrTile := FSave.GetTile(TPosition.Create(X, Y, Z));
      Block := Block + HorizontalBlockage(StartTile, CurrTile, DamageType, SkipObject);
      Block := Block + Blockage(CurrTile, O_FLOOR, DamageType);
      if not SkipObject then Block := Block + Blockage(CurrTile, O_OBJECT, DamageType, Pathfinding.DIR_UP);
    end;
  end;

  Result := Block;
end;

function TTileEngine.HorizontalBlockage(StartTile, EndTile: TTile; DamageType: TItemDamageType; SkipObject: Boolean): Integer;
var
  Dir, Block: Integer;
  TmpTile: TTile;
  Pos: TPosition;
begin
  if (StartTile = nil) or (EndTile = nil) then Exit(0);
  if StartTile.Position.Z <> EndTile.Position.Z then Exit(0);
  Pathfinding.VectorToDirection(EndTile.Position - StartTile.Position, Dir);
  if Dir = -1 then Exit(0);
  Block := 0;
  Pos := StartTile.Position;

  case Dir of
    0: Block := Blockage(StartTile, O_NORTHWALL, DamageType);
    1: begin
         Block := (Blockage(StartTile, O_NORTHWALL, DamageType) + Blockage(EndTile, O_WESTWALL, DamageType)) div 2 +
                  (Blockage(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_WESTWALL, DamageType) +
                   Blockage(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_NORTHWALL, DamageType)) div 2;
         Block := Block + (Blockage(FSave.GetTile(Pos + TPosition.Create(0,-1,0)), O_OBJECT, DamageType, 4) +
                           Blockage(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_OBJECT, DamageType, 6)) div 2;
       end;
    2: Block := Blockage(EndTile, O_WESTWALL, DamageType);
    3: begin
         Block := (Blockage(EndTile, O_WESTWALL, DamageType) + Blockage(EndTile, O_NORTHWALL, DamageType)) div 2 +
                  (Blockage(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_WESTWALL, DamageType) +
                   Blockage(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_NORTHWALL, DamageType)) div 2;
         Block := Block + (Blockage(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_OBJECT, DamageType, 0) +
                           Blockage(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_OBJECT, DamageType, 6)) div 2;
       end;
    4: Block := Blockage(EndTile, O_NORTHWALL, DamageType);
    5: begin
         Block := (Blockage(EndTile, O_NORTHWALL, DamageType) + Blockage(StartTile, O_WESTWALL, DamageType)) div 2 +
                  (Blockage(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_WESTWALL, DamageType) +
                   Blockage(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_NORTHWALL, DamageType)) div 2;
         Block := Block + (Blockage(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_OBJECT, DamageType, 0) +
                           Blockage(FSave.GetTile(Pos + TPosition.Create(-1,0,0)), O_OBJECT, DamageType, 2)) div 2;
       end;
    6: Block := Blockage(StartTile, O_WESTWALL, DamageType);
    7: begin
         Block := (Blockage(StartTile, O_WESTWALL, DamageType) + Blockage(StartTile, O_NORTHWALL, DamageType)) div 2 +
                  (Blockage(FSave.GetTile(Pos + TPosition.Create(0,-1,0)), O_WESTWALL, DamageType) +
                   Blockage(FSave.GetTile(Pos + TPosition.Create(-1,0,0)), O_NORTHWALL, DamageType)) div 2;
         Block := Block + (Blockage(FSave.GetTile(Pos + TPosition.Create(0,-1,0)), O_OBJECT, DamageType, 4) +
                           Blockage(FSave.GetTile(Pos + TPosition.Create(-1,0,0)), O_OBJECT, DamageType, 2)) div 2;
       end;
  end;

  if not SkipObject or (DamageType = DT_NONE) then
    Block := Block + Blockage(StartTile, O_OBJECT, DamageType, Dir);

  Result := Block;
end;

function TTileEngine.ApplyGravity(T: TTile): TTile;
var
  P, UnitPos: TPosition;
  Occupant: TBattleUnit;
  CanFall: Boolean;
  X, Y: Integer;
  Rt, Rtb: TTile;
  It: TBattleItem;
begin
  if (T = nil) or ((T.Inventory.Count = 0) and (T.Unit = nil)) then Exit(T);

  P := T.Position;
  Rt := T;
  Occupant := T.Unit;

  if Assigned(Occupant) then
  begin
    UnitPos := Occupant.Position;
    while UnitPos.Z >= 0 do
    begin
      CanFall := True;
      for Y := 0 to Occupant.Armor.Size - 1 do
        for X := 0 to Occupant.Armor.Size - 1 do
        begin
          Rt := FSave.GetTile(TPosition.Create(UnitPos.X+X, UnitPos.Y+Y, UnitPos.Z));
          Rtb := FSave.GetTile(TPosition.Create(UnitPos.X+X, UnitPos.Y+Y, UnitPos.Z-1));
          if not Rt.HasNoFloor(Rtb) then
            CanFall := False;
        end;
      if not CanFall then Break;
      UnitPos.Z := UnitPos.Z - 1;
    end;
    if UnitPos <> Occupant.Position then
    begin
      if (Occupant.Health <> 0) and (Occupant.Stunlevel < Occupant.Health) then
      begin
        if Occupant.MovementType = MT_FLY then
        begin
          Occupant.StartWalking(Occupant.Direction, Occupant.Position, FSave.GetTile(Occupant.Position + TPosition.Create(0,0,-1)), True);
          Occupant.AbortTurn;
        end
        else
        begin
          Occupant.SetPosition(Occupant.Position); // update lastPos
          FSave.AddFallingUnit(Occupant);
        end;
      end
      else if Occupant.IsOut then
      begin
        for Y := Occupant.Armor.Size - 1 downto 0 do
          for X := Occupant.Armor.Size - 1 downto 0 do
            FSave.GetTile(Occupant.Position + TPosition.Create(X,Y,0)).Unit := nil;
        Occupant.Position := UnitPos;
      end;
    end;
  end;

  Rt := T;
  CanFall := True;
  while P.Z >= 0 and CanFall do
  begin
    Rt := FSave.GetTile(P);
    Rtb := FSave.GetTile(TPosition.Create(P.X, P.Y, P.Z-1));
    if not Rt.HasNoFloor(Rtb) then CanFall := False;
    P.Z := P.Z - 1;
  end;

  for It in T.Inventory do
  begin
    if Assigned(It.Unit) and (T.Position = It.Unit.Position) then
      It.Unit.Position := Rt.Position;
    if T <> Rt then
      Rt.AddItem(It, It.Slot);
  end;
  if T <> Rt then T.Inventory.Clear;

  Result := Rt;
end;

procedure TTileEngine.ItemDrop(T: TTile; Item: TBattleItem; Mod_: TMod; NewItem, RemoveItem: Boolean);
var
  P: TPosition;
begin
  if T = nil then Exit;
  if Item.Rules.IsFixed then Exit;

  P := T.Position;
  T.AddItem(Item, Mod_.GetInventory('STR_GROUND', True));
  if Assigned(Item.Unit) then Item.Unit.Position := P;
  if NewItem then FSave.Items.Add(Item)
  else if FSave.Side <> FACTION_PLAYER then Item.TurnFlag := True;
  if RemoveItem then Item.MoveToOwner(nil)
  else if (Item.Rules.BattleType <> BT_GRENADE) and (Item.Rules.BattleType <> BT_PROXIMITYGRENADE) then
    Item.Owner := nil;

  ApplyGravity(FSave.GetTile(P));
  if Item.Rules.BattleType = BT_FLARE then
  begin
    CalculateTerrainLighting;
    CalculateFOV(P);
  end;
end;

function TTileEngine.ValidMeleeRange(Attacker, Target: TBattleUnit; Dir: Integer): Boolean;
begin
  Result := ValidMeleeRange(Attacker.Position, Dir, Attacker, Target, nil, True);
end;

function TTileEngine.ValidMeleeRange(const Pos: TPosition; Direction: Integer; Attacker, Target: TBattleUnit; Dest: PPosition; PreferEnemy: Boolean): Boolean;
var
  PotentialTargets: TList<TBattleUnit>;
  ChosenTarget: TBattleUnit;
  P, Offset: TPosition;
  Size, X, Y: Integer;
  Origin, TargetTile, Above, Below: TTile;
  OriginVoxel, TargetVoxel: TPosition;
  I: Integer;
begin
  if (Direction < 0) or (Direction > 7) then Exit(False);
  PotentialTargets := TList<TBattleUnit>.Create;
  try
    ChosenTarget := nil;
    Size := Attacker.Armor.Size - 1;
    Pathfinding.DirectionToVector(Direction, Offset);
    for X := 0 to Size do
      for Y := 0 to Size do
      begin
        Origin := FSave.GetTile(Pos + TPosition.Create(X,Y,0));
        TargetTile := FSave.GetTile(Pos + TPosition.Create(X,Y,0) + Offset);
        Above := FSave.GetTile(Pos + TPosition.Create(X,Y,1) + Offset);
        Below := FSave.GetTile(Pos + TPosition.Create(X,Y,-1) + Offset);
        if Assigned(TargetTile) and Assigned(Origin) then
        begin
          if (Origin.TerrainLevel <= -16) and Assigned(Above) and not Above.HasNoFloor(TargetTile) then
            TargetTile := Above
          else if Assigned(Below) and TargetTile.HasNoFloor(Below) and (TargetTile.Unit = nil) and (Below.TerrainLevel <= -16) then
            TargetTile := Below;
          if Assigned(TargetTile.Unit) and ((Target = nil) or (TargetTile.Unit = Target)) then
          begin
            OriginVoxel := Origin.Position * TPosition.Create(16,16,24) + TPosition.Create(8,8, Attacker.Height + Attacker.FloatHeight - 4 - Origin.TerrainLevel);
            if CanTargetUnit(@OriginVoxel, TargetTile, @TargetVoxel, Attacker, False) then
            begin
              if Dest <> nil then Dest^ := TargetTile.Position;
              if Target <> nil then Exit(True);
              PotentialTargets.Add(TargetTile.Unit);
            end;
          end;
        end;
      end;

    for I := 0 to PotentialTargets.Count - 1 do
    begin
      if not Assigned(ChosenTarget) then
        ChosenTarget := PotentialTargets[I]
      else if (PreferEnemy and (PotentialTargets[I].Faction <> Attacker.Faction)) or
              (not PreferEnemy and (PotentialTargets[I].Faction = Attacker.Faction) and
               (PotentialTargets[I].FatalWounds > ChosenTarget.FatalWounds)) then
        ChosenTarget := PotentialTargets[I];
    end;
    if (Dest <> nil) and Assigned(ChosenTarget) then Dest^ := ChosenTarget.Position;
    Result := Assigned(ChosenTarget);
  finally
    PotentialTargets.Free;
  end;
end;

function TTileEngine.FaceWindow(Position: TPosition): Integer;
var
  Tile: TTile;
begin
  Tile := FSave.GetTile(Position);
  if Assigned(Tile) and Assigned(Tile.GetMapData(O_NORTHWALL)) and (Tile.GetMapData(O_NORTHWALL).Block(DT_NONE) = 0) then Exit(0);
  Tile := FSave.GetTile(Position + TPosition.Create(1,0,0));
  if Assigned(Tile) and Assigned(Tile.GetMapData(O_WESTWALL)) and (Tile.GetMapData(O_WESTWALL).Block(DT_NONE) = 0) then Exit(2);
  Tile := FSave.GetTile(Position + TPosition.Create(0,1,0));
  if Assigned(Tile) and Assigned(Tile.GetMapData(O_NORTHWALL)) and (Tile.GetMapData(O_NORTHWALL).Block(DT_NONE) = 0) then Exit(4);
  Tile := FSave.GetTile(Position);
  if Assigned(Tile) and Assigned(Tile.GetMapData(O_WESTWALL)) and (Tile.GetMapData(O_WESTWALL).Block(DT_NONE) = 0) then Exit(6);
  Result := -1;
end;

function TTileEngine.CheckVoxelExposure(OriginVoxel: PPosition; Tile: TTile; ExcludeUnit, ExcludeAllBut: TBattleUnit): Integer;
var
  TargetVoxel, ScanVoxel, RelPos: TPosition;
  Trajectory: TList<TPosition>;
  OtherUnit: TBattleUnit;
  TargetMinHeight, HeightRange, UnitRadius, TargetMaxHeight: Integer;
  Normal: Single;
  RelX, RelY: Integer;
  SliceTargets: array[0..5] of Integer;
  Total, Visible, I, J: Integer;
  Test: Integer;
begin
  TargetVoxel := TPosition.Create(Tile.Position.X * 16 + 8, Tile.Position.Y * 16 + 8, Tile.Position.Z * 24);
  OtherUnit := Tile.Unit;
  if OtherUnit = nil then Exit(0);
  if OtherUnit = ExcludeUnit then Exit(0);

  TargetMinHeight := TargetVoxel.Z - Tile.TerrainLevel + OtherUnit.FloatHeight;
  HeightRange := IfThen(not OtherUnit.IsOut, OtherUnit.Height, 12);
  TargetMaxHeight := TargetMinHeight + HeightRange;

  UnitRadius := OtherUnit.Loftemps;
  if OtherUnit.Armor.Size > 1 then UnitRadius := 3;

  RelPos := TargetVoxel - OriginVoxel^;
  Normal := UnitRadius / Sqrt(RelPos.X*RelPos.X + RelPos.Y*RelPos.Y);
  RelX := Round(RelPos.Y * Normal);
  RelY := Round(-RelPos.X * Normal);

  SliceTargets[0] := 0; SliceTargets[1] := 0;
  SliceTargets[2] := RelX; SliceTargets[3] := RelY;
  SliceTargets[4] := -RelX; SliceTargets[5] := -RelY;

  Total := 0;
  Visible := 0;
  Trajectory := TList<TPosition>.Create;
  try
    for I := HeightRange downto 0 step 2 do
    begin
      Inc(Total);
      ScanVoxel.Z := TargetMinHeight + I;
      for J := 0 to 2 do
      begin
        ScanVoxel.X := TargetVoxel.X + SliceTargets[J*2];
        ScanVoxel.Y := TargetVoxel.Y + SliceTargets[J*2+1];
        Trajectory.Clear;
        Test := CalculateLine(OriginVoxel^, ScanVoxel, False, Trajectory, ExcludeUnit, True, False, ExcludeAllBut);
        if Test = V_UNIT then
        begin
          if (Trajectory[0].X div 16 = ScanVoxel.X div 16) and
             (Trajectory[0].Y div 16 = ScanVoxel.Y div 16) and
             (Trajectory[0].Z >= TargetMinHeight) and (Trajectory[0].Z <= TargetMaxHeight) then
            Inc(Visible);
        end;
      end;
    end;
  finally
    Trajectory.Free;
  end;
  Result := (Visible * 100) div Total;
end;

function TTileEngine.CanTargetUnit(OriginVoxel: PPosition; Tile: TTile; ScanVoxel: PPosition; ExcludeUnit: TBattleUnit; RememberObstacles: Boolean; PotentialUnit: TBattleUnit): Boolean;
var
  TargetVoxel: TPosition;
  Trajectory: TList<TPosition>;
  Hypothetical: Boolean;
  UnitRadius, TargetSize, XOffset, YOffset: Integer;
  RelPos: TPosition;
  Normal: Single;
  RelX, RelY: Integer;
  SliceTargets: array[0..9] of Integer;
  HeightRange, TargetMinHeight, TargetMaxHeight, TargetCenterHeight: Integer;
  I, J: Integer;
  Test: Integer;
begin
  TargetVoxel := TPosition.Create(Tile.Position.X * 16 + 8, Tile.Position.Y * 16 + 8, Tile.Position.Z * 24);
  Hypothetical := PotentialUnit <> nil;
  if PotentialUnit = nil then
  begin
    PotentialUnit := Tile.Unit;
    if PotentialUnit = nil then Exit(False);
  end;
  if PotentialUnit = ExcludeUnit then Exit(False);

  TargetMinHeight := TargetVoxel.Z - Tile.TerrainLevel + PotentialUnit.FloatHeight;
  TargetMaxHeight := TargetMinHeight;
  HeightRange := IfThen(not PotentialUnit.IsOut, PotentialUnit.Height, 12);
  TargetMaxHeight := TargetMaxHeight + HeightRange;
  TargetCenterHeight := (TargetMaxHeight + TargetMinHeight) div 2;
  HeightRange := HeightRange div 2;
  if HeightRange > 10 then HeightRange := 10;
  if HeightRange <= 0 then HeightRange := 0;

  UnitRadius := PotentialUnit.Loftemps;
  TargetSize := PotentialUnit.Armor.Size - 1;
  XOffset := PotentialUnit.Position.X - Tile.Position.X;
  YOffset := PotentialUnit.Position.Y - Tile.Position.Y;
  if TargetSize > 0 then UnitRadius := 3;

  RelPos := TargetVoxel - OriginVoxel^;
  Normal := UnitRadius / Sqrt(RelPos.X*RelPos.X + RelPos.Y*RelPos.Y);
  RelX := Round(RelPos.Y * Normal);
  RelY := Round(-RelPos.X * Normal);

  SliceTargets[0] := 0; SliceTargets[1] := 0;
  SliceTargets[2] := RelX; SliceTargets[3] := RelY;
  SliceTargets[4] := -RelX; SliceTargets[5] := -RelY;
  SliceTargets[6] := RelY; SliceTargets[7] := -RelX;
  SliceTargets[8] := -RelY; SliceTargets[9] := RelX;

  Trajectory := TList<TPosition>.Create;
  try
    for I := 0 to HeightRange do
    begin
      ScanVoxel^.Z := TargetCenterHeight + heightFromCenter[I];
      for J := 0 to 4 do
      begin
        if (I < HeightRange - 1) and (J > 2) then Break;
        ScanVoxel^.X := TargetVoxel.X + SliceTargets[J*2];
        ScanVoxel^.Y := TargetVoxel.Y + SliceTargets[J*2+1];
        Trajectory.Clear;
        Test := CalculateLine(OriginVoxel^, ScanVoxel^, False, Trajectory, ExcludeUnit, True, False);
        if Test = V_UNIT then
        begin
          for var X := 0 to TargetSize do
            for var Y := 0 to TargetSize do
              if (Trajectory[0].X div 16 = ScanVoxel^.X div 16 + X + XOffset) and
                 (Trajectory[0].Y div 16 = ScanVoxel^.Y div 16 + Y + YOffset) and
                 (Trajectory[0].Z >= TargetMinHeight) and (Trajectory[0].Z <= TargetMaxHeight) then
                Exit(True);
        end
        else if (Test = V_EMPTY) and Hypothetical and (Trajectory.Count > 0) then
          Exit(True);
        if RememberObstacles and (Trajectory.Count > 0) then
          FSave.GetTile(TPosition.Create(Trajectory[0].X div 16, Trajectory[0].Y div 16, Trajectory[0].Z div 24)).SetObstacle(Test);
      end;
    end;
  finally
    Trajectory.Free;
  end;
  Result := False;
end;

function TTileEngine.CanTargetTile(OriginVoxel: PPosition; Tile: TTile; Part: Integer; ScanVoxel: PPosition; ExcludeUnit: TBattleUnit; RememberObstacles: Boolean): Boolean;
var
  TargetVoxel: TPosition;
  SpiralArray: array of Integer;
  SpiralCount: Integer;
  MinZ, MaxZ: Integer;
  MinZFound, MaxZFound, Dummy: Boolean;
  RangeZ, CenterZ: Integer;
  I, J: Integer;
  Test: Integer;
  Trajectory: TList<TPosition>;
begin
  TargetVoxel := TPosition.Create(Tile.Position.X * 16, Tile.Position.Y * 16, Tile.Position.Z * 24);
  MinZFound := False;
  MaxZFound := False;
  Dummy := False;

  case Part of
    O_OBJECT: begin SetLength(SpiralArray, 82); SpiralArray := [8,8, 8,6, 10,6, 10,8, 10,10, 8,10, 6,10, 6,8, 6,6,
                  8,4, 10,4, 12,4, 12,6, 12,8, 12,10, 12,12, 10,12, 8,12, 6,12, 4,12, 4,10, 4,8, 4,6, 4,4, 6,4,
                  8,1, 12,1, 15,1, 15,4, 15,8, 15,12, 15,15, 12,15, 8,15, 4,15, 1,15, 1,12, 1,8, 1,4, 1,1, 4,1];
               SpiralCount := 41; end;
    O_NORTHWALL: begin SetLength(SpiralArray, 14); SpiralArray := [7,0, 9,0, 6,0, 11,0, 4,0, 13,0, 2,0]; SpiralCount := 7; end;
    O_WESTWALL: begin SetLength(SpiralArray, 14); SpiralArray := [0,7, 0,9, 0,6, 0,11, 0,4, 0,13, 0,2]; SpiralCount := 7; end;
    O_FLOOR: begin SetLength(SpiralArray, 82); SpiralArray := [8,8, 8,6, 10,6, 10,8, 10,10, 8,10, 6,10, 6,8, 6,6,
                  8,4, 10,4, 12,4, 12,6, 12,8, 12,10, 12,12, 10,12, 8,12, 6,12, 4,12, 4,10, 4,8, 4,6, 4,4, 6,4,
                  8,1, 12,1, 15,1, 15,4, 15,8, 15,12, 15,15, 12,15, 8,15, 4,15, 1,15, 1,12, 1,8, 1,4, 1,1, 4,1];
               SpiralCount := 41; MinZFound := True; MinZ := 0; MaxZFound := True; MaxZ := 0; end;
    MapData.O_DUMMY: begin SetLength(SpiralArray, 82); SpiralArray := [8,8, 8,6, 10,6, 10,8, 10,10, 8,10, 6,10, 6,8, 6,6,
                  8,4, 10,4, 12,4, 12,6, 12,8, 12,10, 12,12, 10,12, 8,12, 6,12, 4,12, 4,10, 4,8, 4,6, 4,4, 6,4,
                  8,1, 12,1, 15,1, 15,4, 15,8, 15,12, 15,15, 12,15, 8,15, 4,15, 1,15, 1,12, 1,8, 1,4, 1,1, 4,1];
               SpiralCount := 41; MinZFound := True; MinZ := 12; MaxZFound := True; MaxZ := 12; end;
  else Exit(False);
  end;

  VoxelCheckFlush;

  if not MinZFound then
  begin
    for J := 1 to 11 do
    begin
      for I := 0 to SpiralCount - 1 do
      begin
        if VoxelCheck(TPosition.Create(TargetVoxel.X + SpiralArray[I*2], TargetVoxel.Y + SpiralArray[I*2+1], TargetVoxel.Z + J*2), nil, True) = Part then
        begin
          MinZ := J*2;
          MinZFound := True;
          Break;
        end;
      end;
      if MinZFound then Break;
    end;
  end;

  if not MinZFound then
  begin
    if RememberObstacles then
    begin
      MinZFound := True;
      MinZ := 10;
      Dummy := True;
    end
    else Exit(False);
  end;

  if not MaxZFound then
  begin
    for J := 10 downto 0 do
    begin
      for I := 0 to SpiralCount - 1 do
      begin
        if VoxelCheck(TPosition.Create(TargetVoxel.X + SpiralArray[I*2], TargetVoxel.Y + SpiralArray[I*2+1], TargetVoxel.Z + J*2), nil, True) = Part then
        begin
          MaxZ := J*2;
          MaxZFound := True;
          Break;
        end;
      end;
      if MaxZFound then Break;
    end;
  end;

  if not MaxZFound then
  begin
    if RememberObstacles then
    begin
      MaxZFound := True;
      MaxZ := 10;
      Dummy := True;
    end
    else Exit(False);
  end;

  if MinZ > MaxZ then MinZ := MaxZ;
  RangeZ := MaxZ - MinZ;
  if RangeZ > 10 then RangeZ := 10;
  CenterZ := (MaxZ + MinZ) div 2;

  Trajectory := TList<TPosition>.Create;
  try
    for J := 0 to RangeZ do
    begin
      ScanVoxel^.Z := TargetVoxel.Z + CenterZ + heightFromCenter[J];
      for I := 0 to SpiralCount - 1 do
      begin
        ScanVoxel^.X := TargetVoxel.X + SpiralArray[I*2];
        ScanVoxel^.Y := TargetVoxel.Y + SpiralArray[I*2+1];
        Trajectory.Clear;
        Test := CalculateLine(OriginVoxel^, ScanVoxel^, False, Trajectory, ExcludeUnit, True);
        if (Test = Part) and not Dummy then
        begin
          if (Trajectory[0].X div 16 = ScanVoxel^.X div 16) and
             (Trajectory[0].Y div 16 = ScanVoxel^.Y div 16) and
             (Trajectory[0].Z div 24 = ScanVoxel^.Z div 24) then
            Exit(True);
        end;
        if RememberObstacles and (Trajectory.Count > 0) then
          FSave.GetTile(TPosition.Create(Trajectory[0].X div 16, Trajectory[0].Y div 16, Trajectory[0].Z div 24)).SetObstacle(Test);
      end;
    end;
  finally
    Trajectory.Free;
  end;
  Result := False;
end;

function TTileEngine.ValidateThrow(var Action: TBattleAction; OriginVoxel, TargetVoxel: TPosition; Curve: PDouble; VoxelType: PInteger; Forced: Boolean): Boolean;
var
  Curvature: Double;
  TargetTile: TTile;
  Test: Integer;
  Trajectory: TList<TPosition>;
  HitPos, TilePos: TPosition;
  FoundCurve: Boolean;
begin
  FoundCurve := False;
  Curvature := 0.5;
  if Action.Type_ = BA_THROW then
    Curvature := Max(0.48, 1.73 / Sqrt(Sqrt(Action.Actor.BaseStats.Strength / Action.Weapon.Rules.Weight)) + IfThen(Action.Actor.IsKneeled, 0.1, 0.0))
  else
    Curvature := 1.73 / Sqrt(Sqrt(70.0 / 10.0)) + IfThen(Action.Actor.IsKneeled, 0.1, 0.0);

  TargetTile := FSave.GetTile(Action.Target);
  if (Action.Type_ = BA_THROW) and Assigned(TargetTile) and Assigned(TargetTile.GetMapData(O_OBJECT)) and
     (TargetTile.GetMapData(O_OBJECT).GetTUCost(MT_WALK) = 255) and
     not (TargetTile.IsBigWall and (TargetTile.GetMapData(O_OBJECT).BigWall < 1) or (TargetTile.GetMapData(O_OBJECT).BigWall > 3)) then
    Exit(False);

  if not ValidThrowRange(@Action, OriginVoxel, TargetTile) then Exit(False);

  Trajectory := TList<TPosition>.Create;
  try
    while not FoundCurve and (Curvature < 5.0) do
    begin
      Trajectory.Clear;
      Test := CalculateParabola(OriginVoxel, TargetVoxel, True, Trajectory, Action.Actor, Curvature, TPosition.Create(0,0,0));
      HitPos := (Trajectory.Last + TPosition.Create(0,0,1)) div TPosition.Create(16,16,24);
      TilePos := Projectile.TProjectile.GetPositionFromEnd(Trajectory, Projectile.TProjectile.ItemDropVoxelOffset) div TPosition.Create(16,16,24);
      if Forced or ((Test <> V_OUTOFBOUNDS) and (TilePos = Action.Target)) then
      begin
        if VoxelType <> nil then VoxelType^ := Test;
        FoundCurve := True;
      end
      else
      begin
        Curvature := Curvature + 0.5;
        if (Test <> V_OUTOFBOUNDS) and (Action.Actor.Faction = FACTION_PLAYER) then
          FSave.GetTile(HitPos).SetObstacle(Test);
      end;
    end;
  finally
    Trajectory.Free;
  end;

  if Curvature >= 5.0 then Exit(False);
  if Curve <> nil then Curve^ := Curvature;
  Result := True;
end;

function TTileEngine.GetOriginVoxel(var Action: TBattleAction; Tile: TTile): TPosition;
var
  DirYShift, DirXShift: array[0..7] of Integer;
  Origin: TPosition;
  TileAbove: TTile;
  Direction: Integer;
begin
  DirYShift[0] := 1; DirYShift[1] := 1; DirYShift[2] := 8; DirYShift[3] := 15;
  DirYShift[4] := 15; DirYShift[5] := 15; DirYShift[6] := 8; DirYShift[7] := 1;
  DirXShift[0] := 8; DirXShift[1] := 14; DirXShift[2] := 15; DirXShift[3] := 15;
  DirXShift[4] := 8; DirXShift[5] := 1; DirXShift[6] := 1; DirXShift[7] := 1;

  if Tile = nil then Tile := Action.Actor.Tile;
  Origin := Tile.Position;
  TileAbove := FSave.GetTile(Origin + TPosition.Create(0,0,1));
  Result := TPosition.Create(Origin.X * 16, Origin.Y * 16, Origin.Z * 24);

  if (Action.Actor.Position = Origin) or (Action.Type_ <> BA_LAUNCH) then
  begin
    Result.Z := Result.Z - Tile.TerrainLevel + Action.Actor.Height + Action.Actor.FloatHeight;
    if Action.Type_ = BA_THROW then Result.Z := Result.Z - 3
    else Result.Z := Result.Z - 4;

    if Result.Z >= (Origin.Z + 1) * 24 then
    begin
      if Assigned(TileAbove) and TileAbove.HasNoFloor(nil) then
        Origin.Z := Origin.Z + 1
      else
      begin
        while Result.Z >= (Origin.Z + 1) * 24 do
          Result.Z := Result.Z - 1;
        Result.Z := Result.Z - 4;
      end;
    end;
    Direction := GetDirectionTo(Origin, Action.Target);
    Result.X := Result.X + DirXShift[Direction] * Action.Actor.Armor.Size;
    Result.Y := Result.Y + DirYShift[Direction] * Action.Actor.Armor.Size;
  end
  else
  begin
    Result.X := Result.X + 8;
    Result.Y := Result.Y + 8;
    Result.Z := Result.Z + 16;
  end;
end;

function TTileEngine.GetDirectionTo(Origin, Target: TPosition): Integer;
var
  OX, OY: Double;
  Angle: Double;
  Pie: array[0..3] of Double;
begin
  OX := Target.X - Origin.X;
  OY := Target.Y - Origin.Y;
  Angle := ArcTan2(OX, -OY);
  Pie[0] := (PI_4 * 4.0) - PI_4 / 2.0;
  Pie[1] := (PI_4 * 3.0) - PI_4 / 2.0;
  Pie[2] := (PI_4 * 2.0) - PI_4 / 2.0;
  Pie[3] := (PI_4 * 1.0) - PI_4 / 2.0;

  if (Angle > Pie[0]) or (Angle < -Pie[0]) then Result := 4
  else if Angle > Pie[1] then Result := 3
  else if Angle > Pie[2] then Result := 2
  else if Angle > Pie[3] then Result := 1
  else if Angle < -Pie[1] then Result := 5
  else if Angle < -Pie[2] then Result := 6
  else if Angle < -Pie[3] then Result := 7
  else Result := 0;
end;

procedure TTileEngine.RecalculateFOV;
var
  Unit: TBattleUnit;
begin
  for Unit in FSave.Units do
    if Unit.Tile <> nil then
      CalculateFOV(Unit);
end;

procedure TTileEngine.SetDangerZone(const Pos: TPosition; Radius: Integer; Unit: TBattleUnit);
var
  Tile: TTile;
  OriginVoxel, TargetVoxel: TPosition;
  Trajectory: TList<TPosition>;
  X, Y: Integer;
begin
  Tile := FSave.GetTile(Pos);
  if Tile = nil then Exit;
  Tile.Dangerous := True;
  OriginVoxel := (Pos * TPosition.Create(16,16,24)) + TPosition.Create(8,8,12 - Tile.TerrainLevel);

  for X := -Radius to Radius do
    for Y := -Radius to Radius do
      if (X <> 0) or (Y <> 0) then
        if (X*X + Y*Y) <= (Radius*Radius) then
        begin
          Tile := FSave.GetTile(Pos + TPosition.Create(X,Y,0));
          if Tile <> nil then
          begin
            TargetVoxel := ((Pos + TPosition.Create(X,Y,0)) * TPosition.Create(16,16,24)) + TPosition.Create(8,8,12 - Tile.TerrainLevel);
            Trajectory := TList<TPosition>.Create;
            try
              if CalculateLine(OriginVoxel, TargetVoxel, False, Trajectory, Unit, True, False, Unit) = V_EMPTY then
                if (Trajectory.Count > 0) and (Trajectory.Last div TPosition.Create(16,16,24) = Pos + TPosition.Create(X,Y,0)) then
                  Tile.Dangerous := True;
            finally
              Trajectory.Free;
            end;
          end;
        end;
end;

function TTileEngine.DistanceUnitToPositionSq(Unit: TBattleUnit; const Pos: TPosition; ConsiderZ: Boolean): Integer;
var
  X, Y, Z: Integer;
begin
  X := Unit.Position.X - Pos.X;
  Y := Unit.Position.Y - Pos.Y;
  Z := IfThen(ConsiderZ, Unit.Position.Z - Pos.Z, 0);
  if Unit.Armor.Size > 1 then
  begin
    if Unit.Position.X < Pos.X then X := X + 1;
    if Unit.Position.Y < Pos.Y then Y := Y + 1;
  end;
  Result := X*X + Y*Y + Z*Z;
end;

function TTileEngine.Distance(Pos1, Pos2: TPosition): Integer;
var
  X, Y: Integer;
begin
  X := Pos1.X - Pos2.X;
  Y := Pos1.Y - Pos2.Y;
  Result := Ceil(Sqrt(X*X + Y*Y));
end;

function TTileEngine.DistanceSq(Pos1, Pos2: TPosition; ConsiderZ: Boolean): Integer;
var
  X, Y, Z: Integer;
begin
  X := Pos1.X - Pos2.X;
  Y := Pos1.Y - Pos2.Y;
  Z := IfThen(ConsiderZ, Pos1.Z - Pos2.Z, 0);
  Result := X*X + Y*Y + Z*Z;
end;

procedure TTileEngine.TogglePersonalLighting;
begin
  FPersonalLighting := not FPersonalLighting;
  CalculateUnitLighting;
end;

end.