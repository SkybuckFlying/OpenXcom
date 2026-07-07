unit Pathfinding;

interface

uses
  Classes, SysUtils,
  Savegame.SavedBattleGame,
  Savegame.Tile,
  Savegame.BattleUnit,
  Mod.Armor,
  Engine.Options,
  Battlescape.Position,
  Battlescape.PathfindingNode,
  Battlescape.PathfindingOpenSet;

type
  TPathPreview = set of (PATH_ARROWS, PATH_TU_COST, PATH_FULL);

  TPathfinding = class
  public const
    DIR_UP = 8;
    DIR_DOWN = 9;
    O_BIGWALL = -1;
    bigWallTypes = (BLOCK, BIGWALLNESW, BIGWALLNWSE, BIGWALLWEST, BIGWALLNORTH,
                    BIGWALLEAST, BIGWALLSOUTH, BIGWALLEASTANDSOUTH, BIGWALLWESTANDNORTH);
  private
    FSave: TSavedBattleGame;
    FNodes: TList<TPathfindingNode>;
    FSize: Integer;
    FUnit: TBattleUnit;
    FPathPreviewed: Boolean;
    FStrafeMove: Boolean;
    FTotalTUCost: Integer;
    FModifierUsed: Boolean;
    FMovementType: TMovementType;
    FPath: TList<Integer>;

    function GetNode(Pos: TPosition): TPathfindingNode;
    function IsBlocked(Tile: TTile; Part: Integer; MissileTarget: TBattleUnit; BigWallExclusion: Integer = -1): Boolean;
    function BresenhamPath(Origin, Target: TPosition; MissileTarget: TBattleUnit; Sneak: Boolean = False; MaxTUCost: Integer = 1000): Boolean;
    function AStarPath(Origin, Target: TPosition; MissileTarget: TBattleUnit; Sneak: Boolean = False; MaxTUCost: Integer = 1000): Boolean;
    function CanFallDown(DestinationTile: TTile): Boolean; overload;
    function CanFallDown(DestinationTile: TTile; Size: Integer): Boolean; overload;
    function IsOnStairs(StartPosition, EndPosition: TPosition): Boolean;
  public
    class var red: Integer;
    class var green: Integer;
    class var yellow: Integer;

    constructor Create(Save: TSavedBattleGame);
    destructor Destroy; override;

    procedure Calculate(Unit: TBattleUnit; EndPosition: TPosition; MissileTarget: TBattleUnit = nil; MaxTUCost: Integer = 1000);
    class procedure DirectionToVector(Direction: Integer; var Vector: TPosition);
    class procedure VectorToDirection(Vector: TPosition; var Dir: Integer);
    function GetStartDirection: Integer;
    function DequeuePath: Integer;
    function GetTUCost(StartPosition: TPosition; Direction: Integer; var EndPosition: TPosition;
                       Unit: TBattleUnit; Target: TBattleUnit; Missile: Boolean): Integer;
    procedure AbortPath;
    function GetStrafeMove: Boolean;
    function ValidateUpDown(Bu: TBattleUnit; const StartPosition: TPosition; Direction: Integer; Missile: Boolean = False): Boolean;
    function PreviewPath(Remove: Boolean = False): Boolean;
    function RemovePreview: Boolean;
    procedure SetUnit(Unit: TBattleUnit);
    function FindReachable(Unit: TBattleUnit; TuMax: Integer): TList<Integer>;
    function GetTotalTUCost: Integer;
    function IsPathPreviewed: Boolean;
    function IsModifierUsed: Boolean;
    function GetPath: TList<Integer>;
    function CopyPath: TList<Integer>;

    property PathPreviewed: Boolean read FPathPreviewed;
  end;

implementation

uses
  Math,
  Mod.MapData,
  Engine.RNG;

{ TPathfinding }

constructor TPathfinding.Create(Save: TSavedBattleGame);
var
  I: Integer;
  P: TPosition;
begin
  FSave := Save;
  FSize := Save.MapSizeXYZ;
  FNodes := TList<TPathfindingNode>.Create;
  FNodes.Capacity := FSize;
  for I := 0 to FSize - 1 do
  begin
    Save.GetTileCoords(I, P.X, P.Y, P.Z);
    FNodes.Add(TPathfindingNode.Create(P));
  end;
  FPath := TList<Integer>.Create;
  FUnit := nil;
  FPathPreviewed := False;
  FStrafeMove := False;
  FTotalTUCost := 0;
  FModifierUsed := False;
  FMovementType := MT_WALK;

  // Initialize static colors
  red := 3;
  yellow := 10;
  green := 4;
end;

destructor TPathfinding.Destroy;
begin
  FNodes.Free;
  FPath.Free;
  inherited;
end;

function TPathfinding.GetNode(Pos: TPosition): TPathfindingNode;
begin
  Result := FNodes[FSave.GetTileIndex(Pos)];
end;

procedure TPathfinding.Calculate(Unit: TBattleUnit; EndPosition: TPosition; MissileTarget: TBattleUnit; MaxTUCost: Integer);
var
  StartPosition: TPosition;
  DestinationTile, TileBelow: TTile;
  Size, Its: Integer;
  DirArray: array[0..2] of Integer;
  X, Y: Integer;
  CheckTile: TTile;
  Sneak: Boolean;
begin
  FTotalTUCost := 0;
  FPath.Clear;
  if (EndPosition.X > FSave.MapSizeX - Unit.Armor.Size) or
     (EndPosition.Y > FSave.MapSizeY - Unit.Armor.Size) or
     (EndPosition.X < 0) or (EndPosition.Y < 0) then Exit;

  Sneak := Options.SneakyAI and (Unit.Faction = FACTION_HOSTILE);
  StartPosition := Unit.Position;
  FMovementType := Unit.MovementType;
  if Assigned(MissileTarget) and (MaxTUCost = -1) then
  begin
    FMovementType := MT_FLY;
    MaxTUCost := 10000;
  end;
  FUnit := Unit;

  DestinationTile := FSave.GetTile(EndPosition);
  if IsBlocked(DestinationTile, O_FLOOR, MissileTarget) or IsBlocked(DestinationTile, O_OBJECT, MissileTarget) then Exit;

  if IsOnStairs(StartPosition, EndPosition) then
  begin
    EndPosition.Z := EndPosition.Z + 1;
    DestinationTile := FSave.GetTile(EndPosition);
  end;

  while (EndPosition.Z < FSave.MapSizeZ) and (DestinationTile.TerrainLevel = -24) do
  begin
    EndPosition.Z := EndPosition.Z + 1;
    DestinationTile := FSave.GetTile(EndPosition);
  end;
  if EndPosition.Z = FSave.MapSizeZ then Exit;

  while CanFallDown(DestinationTile, Unit.Armor.Size) and (FMovementType <> MT_FLY) do
  begin
    EndPosition.Z := EndPosition.Z - 1;
    DestinationTile := FSave.GetTile(EndPosition);
  end;

  if IsBlocked(DestinationTile, O_FLOOR, MissileTarget) or IsBlocked(DestinationTile, O_OBJECT, MissileTarget) then Exit;

  Size := Unit.Armor.Size - 1;
  if Size >= 1 then
  begin
    DirArray[0] := 4; DirArray[1] := 2; DirArray[2] := 3;
    for X := 0 to Size do
      for Y := 0 to Size do
        if (X <> 0) or (Y <> 0) then
        begin
          CheckTile := FSave.GetTile(EndPosition + TPosition.Create(X, Y, 0));
          if (IsBlocked(DestinationTile, CheckTile, DirArray[0], Unit) and
              IsBlocked(DestinationTile, CheckTile, DirArray[0], MissileTarget)) or
             (Assigned(CheckTile.Unit) and (CheckTile.Unit <> Unit) and CheckTile.Unit.Visible and (CheckTile.Unit <> MissileTarget)) then
            Exit;
          if (X > 0) and (Y > 0) then
            if (CheckTile.GetMapData(O_NORTHWALL).IsDoor) or (CheckTile.GetMapData(O_WESTWALL).IsDoor) then
              Exit;
        end;
  end;

  FStrafeMove := Options.Strafe and ((SDL_GetModState and KMOD_CTRL) <> 0) and (StartPosition.Z = EndPosition.Z) and
                 (Abs(StartPosition.X - EndPosition.X) <= 1) and (Abs(StartPosition.Y - EndPosition.Y) <= 1);

  // Try Bresenham
  if (StartPosition.Z = EndPosition.Z) and BresenhamPath(StartPosition, EndPosition, MissileTarget, Sneak) then
  begin
    // Path is stored in reverse, so reverse it
    FPath.Reverse;
    Exit;
  end
  else
    AbortPath;

  // A*
  if not AStarPath(StartPosition, EndPosition, MissileTarget, Sneak, MaxTUCost) then
    AbortPath;
end;

function TPathfinding.BresenhamPath(Origin, Target: TPosition; MissileTarget: TBattleUnit; Sneak: Boolean; MaxTUCost: Integer): Boolean;
var
  XD: array[0..7] of Integer;
  YD: array[0..7] of Integer;
  X, X0, X1, DeltaX, StepX: Integer;
  Y, Y0, Y1, DeltaY, StepY: Integer;
  Z, Z0, Z1, DeltaZ, StepZ: Integer;
  SwapXY, SwapXZ: Boolean;
  DriftXY, DriftXZ: Integer;
  CX, CY, CZ: Integer;
  LastPoint, NextPoint: TPosition;
  Dir: Integer;
  LastTUCost: Integer;
  TuCost: Integer;
  DiagonalCost: Integer;
begin
  XD[0] := 0; XD[1] := 1; XD[2] := 1; XD[3] := 1; XD[4] := 0; XD[5] := -1; XD[6] := -1; XD[7] := -1;
  YD[0] := -1; YD[1] := -1; YD[2] := 0; YD[3] := 1; YD[4] := 1; YD[5] := 1; YD[6] := 0; YD[7] := -1;

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

  Y := Y0; Z := Z0;
  LastPoint := Origin;
  LastTUCost := -1;
  FTotalTUCost := 0;

  X := X0;
  while X <> X1 + StepX do
  begin
    CX := X; CY := Y; CZ := Z;
    if SwapXZ then Exchange(CX, CZ);
    if SwapXY then Exchange(CX, CY);

    if (X <> X0) or (Y <> Y0) or (Z <> Z0) then
    begin
      NextPoint := TPosition.Create(CX, CY, CZ);
      // find direction
      Dir := -1;
      for Dir := 0 to 7 do
        if (XD[Dir] = CX - LastPoint.X) and (YD[Dir] = CY - LastPoint.Y) then Break;

      TuCost := GetTUCost(LastPoint, Dir, NextPoint, FUnit, MissileTarget, Assigned(MissileTarget) and (MaxTUCost = 10000));
      if Sneak and FSave.GetTile(NextPoint).Visible then
        Exit(False);

      // Check diagonal costs
      if (NextPoint.X = CX) and (NextPoint.Y = CY) and (NextPoint.Z = CZ) and (TuCost < 255) then
      begin
        if (TuCost = LastTUCost) or
           ((Dir mod 2 = 1) and (TuCost = LastTUCost + LastTUCost div 2)) or
           ((Dir mod 2 = 0) and (TuCost + TuCost div 2 = LastTUCost)) or
           (LastTUCost = -1) then
        begin
          FPath.Add(Dir);
        end
        else
          Exit(False);
      end
      else
        Exit(False);

      if MissileTarget = nil then
      begin
        LastTUCost := TuCost;
        FTotalTUCost := FTotalTUCost + TuCost;
      end;
      LastPoint := TPosition.Create(CX, CY, CZ);
    end;

    DriftXY := DriftXY - DeltaY;
    DriftXZ := DriftXZ - DeltaZ;

    if DriftXY < 0 then
    begin
      Y := Y + StepY;
      DriftXY := DriftXY + DeltaX;
    end;
    if DriftXZ < 0 then
    begin
      Z := Z + StepZ;
      DriftXZ := DriftXZ + DeltaX;
    end;

    X := X + StepX;
  end;

  Result := True;
end;

function TPathfinding.AStarPath(Origin, Target: TPosition; MissileTarget: TBattleUnit; Sneak: Boolean; MaxTUCost: Integer): Boolean;
var
  Node: TPathfindingNode;
  OpenList: TPathfindingOpenSet;
  CurrentNode: TPathfindingNode;
  CurrentPos: TPosition;
  Direction: Integer;
  NextPos: TPosition;
  TuCost: Integer;
  NextNode: TPathfindingNode;
  IsMissile: Boolean;
begin
  for Node in FNodes do Node.Reset;

  Node := GetNode(Origin);
  Node.Connect(0, nil, 0, Target);
  OpenList := TPathfindingOpenSet.Create;
  try
    OpenList.Push(Node);
    IsMissile := Assigned(MissileTarget) and (MaxTUCost = 10000);

    while not OpenList.Empty do
    begin
      CurrentNode := OpenList.Pop;
      CurrentPos := CurrentNode.Position;
      CurrentNode.Checked := True;

      if (CurrentPos.X = Target.X) and (CurrentPos.Y = Target.Y) and (CurrentPos.Z = Target.Z) then
      begin
        FPath.Clear;
        while CurrentNode.PrevNode <> nil do
        begin
          FPath.Add(CurrentNode.PrevDir);
          CurrentNode := CurrentNode.PrevNode;
        end;
        Result := True;
        Exit;
      end;

      for Direction := 0 to 9 do
      begin
        NextPos := CurrentPos;
        TuCost := GetTUCost(CurrentPos, Direction, NextPos, FUnit, MissileTarget, IsMissile);
        if TuCost >= 255 then Continue;
        if Sneak and FSave.GetTile(NextPos).Visible then TuCost := TuCost * 2;
        NextNode := GetNode(NextPos);
        if NextNode.Checked then Continue;
        FTotalTUCost := CurrentNode.GetTUCost(IsMissile) + TuCost;
        if (not NextNode.InOpenSet or (NextNode.GetTUCost(IsMissile) > FTotalTUCost)) and (FTotalTUCost <= MaxTUCost) then
        begin
          NextNode.Connect(FTotalTUCost, CurrentNode, Direction, Target);
          OpenList.Push(NextNode);
        end;
      end;
    end;
    Result := False;
  finally
    OpenList.Free;
  end;
end;

function TPathfinding.GetTUCost(StartPosition: TPosition; Direction: Integer; var EndPosition: TPosition;
                                Unit: TBattleUnit; Target: TBattleUnit; Missile: Boolean): Integer;
var
  Size: Integer;
  X, Y: Integer;
  Offset: TPosition;
  StartTile, DestinationTile, BelowDestination, AboveDestination: TTile;
  FellDown: Boolean;
  TriedStairs: Boolean;
  Cost: Integer;
  NumberOfPartsGoingUp, NumberOfPartsGoingDown, NumberOfPartsFalling: Integer;
  TotalCost: Integer;
  WallCounter, WallTmp, WallCost: Integer;
  VerticalOffset: TPosition;
  TmpDirection: Integer;
begin
  FUnit := Unit;
  EndPosition := StartPosition;
  DirectionToVector(Direction, EndPosition);
  EndPosition := EndPosition + StartPosition;
  FellDown := False;
  TriedStairs := False;
  Size := Unit.Armor.Size - 1;
  Cost := 0;
  NumberOfPartsGoingUp := 0;
  NumberOfPartsGoingDown := 0;
  NumberOfPartsFalling := 0;
  TotalCost := 0;

  for X := 0 to Size do
    for Y := 0 to Size do
    begin
      Offset := TPosition.Create(X, Y, 0);
      StartTile := FSave.GetTile(StartPosition + Offset);
      DestinationTile := FSave.GetTile(EndPosition + Offset);
      BelowDestination := FSave.GetTile(EndPosition + Offset + TPosition.Create(0,0,-1));
      AboveDestination := FSave.GetTile(EndPosition + Offset + TPosition.Create(0,0,1));

      if (StartTile = nil) or (DestinationTile = nil) then Exit(255);

      if (X = 0) and (Y = 0) and (FMovementType <> MT_FLY) and CanFallDown(StartTile) then
      begin
        if Direction <> DIR_DOWN then Exit(255)
        else FellDown := True;
      end;

      if (Direction < DIR_UP) and (StartTile.TerrainLevel > -16) then
      begin
        if IsBlocked(StartTile, DestinationTile, Direction, Target) then Exit(255);
        if StartTile.TerrainLevel - DestinationTile.TerrainLevel > 8 then Exit(255);
      end;

      VerticalOffset := TPosition.Create(0,0,0);
      if (Direction < DIR_UP) and (StartTile.TerrainLevel <= -16) and Assigned(AboveDestination) and
         (not AboveDestination.HasNoFloor(DestinationTile)) then
      begin
        Inc(NumberOfPartsGoingUp);
        VerticalOffset.Z := 1;
        if not TriedStairs then
        begin
          EndPosition.Z := EndPosition.Z + 1;
          DestinationTile := FSave.GetTile(EndPosition + Offset);
          BelowDestination := FSave.GetTile(EndPosition + TPosition.Create(X,Y,-1));
          TriedStairs := True;
        end;
      end
      else if (Direction < DIR_UP) and not FellDown and (FMovementType <> MT_FLY) and Assigned(BelowDestination) and
              CanFallDown(DestinationTile) and (BelowDestination.TerrainLevel <= -12) then
      begin
        Inc(NumberOfPartsGoingDown);
        if NumberOfPartsGoingDown = (Size+1)*(Size+1) then
        begin
          EndPosition.Z := EndPosition.Z - 1;
          DestinationTile := FSave.GetTile(EndPosition + Offset);
          BelowDestination := FSave.GetTile(EndPosition + TPosition.Create(X,Y,-1));
          FellDown := True;
        end;
      end
      else if not Missile and (FMovementType = MT_FLY) and Assigned(BelowDestination) and Assigned(BelowDestination.Unit) and
              (BelowDestination.Unit <> Unit) and
              (BelowDestination.Unit.Height + BelowDestination.Unit.FloatHeight - BelowDestination.TerrainLevel > 26) then
        Exit(255);

      if DestinationTile = nil then Exit(255);

      if (Direction < DIR_UP) and (EndPosition.Z = StartTile.Position.Z) then
      begin
        if IsBlocked(StartTile, DestinationTile, Direction, Target) then Exit(255);
        if StartTile.TerrainLevel - DestinationTile.TerrainLevel > 8 then Exit(255);
      end
      else if (Direction >= DIR_UP) and not FellDown then
      begin
        if ValidateUpDown(Unit, StartPosition + Offset, Direction, Missile) then
          Cost := 8
        else
          Exit(255);
      end;

      if (FMovementType <> MT_FLY) and not FellDown and CanFallDown(StartTile) then
      begin
        Inc(NumberOfPartsFalling);
        if (NumberOfPartsFalling = (Size+1)*(Size+1)) and (Direction <> DIR_DOWN) then
          Exit(0);
      end;

      StartTile := FSave.GetTile(StartTile.Position + VerticalOffset);

      if (Direction < DIR_UP) and (NumberOfPartsGoingUp <> 0) then
      begin
        if IsBlocked(StartTile, DestinationTile, Direction, Target) then Exit(255);
        if StartTile.TerrainLevel - DestinationTile.TerrainLevel > 8 then Exit(255);
      end;

      // Wall cost
      WallCounter := 0;
      WallCost := 0;
      if (Direction in [0,7,1]) then
      begin
        WallTmp := StartTile.GetTUCost(O_NORTHWALL, FMovementType);
        if WallTmp > 0 then
        begin
          WallCost := WallCost + WallTmp;
          Inc(WallCounter);
        end;
      end;
      if not FellDown and (Direction in [2,1,3]) then
      begin
        WallTmp := DestinationTile.GetTUCost(O_WESTWALL, FMovementType);
        if WallTmp > 0 then
        begin
          WallCost := WallCost + WallTmp;
          Inc(WallCounter);
        end;
      end;
      if not FellDown and (Direction in [4,3,5]) then
      begin
        WallTmp := DestinationTile.GetTUCost(O_NORTHWALL, FMovementType);
        if WallTmp > 0 then
        begin
          WallCost := WallCost + WallTmp;
          Inc(WallCounter);
        end;
      end;
      if Direction in [6,5,7] then
      begin
        WallTmp := StartTile.GetTUCost(O_WESTWALL, FMovementType);
        if WallTmp > 0 then
        begin
          WallCost := WallCost + WallTmp;
          Inc(WallCounter);
        end;
      end;
      if WallCounter > 0 then WallCost := WallCost div WallCounter;

      if (X > 0) and (Y > 0) then
        if (DestinationTile.GetMapData(O_NORTHWALL).IsDoor) or (DestinationTile.GetMapData(O_WESTWALL).IsDoor) then
          Exit(255);

      if IsBlocked(DestinationTile, O_FLOOR, Target) or IsBlocked(DestinationTile, O_OBJECT, Target) then Exit(255);

      if (Direction < DIR_UP) and not FellDown and DestinationTile.HasNoFloor(nil) then
        Cost := 4
      else if Direction < DIR_UP then
      begin
        Cost := Cost + DestinationTile.GetTUCost(O_FLOOR, FMovementType);
        if not FellDown and not TriedStairs and Assigned(DestinationTile.GetMapData(O_OBJECT)) then
          Cost := Cost + DestinationTile.GetTUCost(O_OBJECT, FMovementType);
        if VerticalOffset.Z > 0 then Cost := Cost + 1;
      end;

      if (Direction < DIR_UP) and (Direction mod 2 = 1) then
        Cost := Round(Cost * 1.5);

      Cost := Cost + WallCost;

      if (FUnit.Faction <> FACTION_PLAYER) and (FUnit.SpecialAbility < SPECAB_BURNFLOOR) and (DestinationTile.Fire > 0) then
        Cost := Cost + 32;

      if (FSave.Depth > 0) and ((DestinationTile.Fire > 0) or (DestinationTile.Smoke > 0)) then
        Cost := Cost + 2;

      if Missile and Assigned(DestinationTile.Unit) then
      begin
        if (DestinationTile.Unit <> Target) and not DestinationTile.Unit.IsOut then
        begin
          if DestinationTile.Unit.Faction = FUnit.Faction then Exit(255);
          if Assigned(FUnit.UnitRules) and (DestinationTile.Unit.TurnsSinceSpotted <= FUnit.UnitRules.Intelligence) then
            Exit(255);
        end;
      end;

      TotalCost := TotalCost + Cost;
      Cost := 0;
    end;

  // Big unit checks
  if Size > 0 then
  begin
    TotalCost := TotalCost div ((Size+1)*(Size+1));
    // Additional diagonal checks
  end;

  if Missile then Result := 0
  else Result := TotalCost;
end;

class procedure TPathfinding.DirectionToVector(Direction: Integer; var Vector: TPosition);
var
  X: array[0..9] of Integer;
  Y: array[0..9] of Integer;
  Z: array[0..9] of Integer;
begin
  X[0] := 0; X[1] := 1; X[2] := 1; X[3] := 1; X[4] := 0; X[5] := -1; X[6] := -1; X[7] := -1; X[8] := 0; X[9] := 0;
  Y[0] := -1; Y[1] := -1; Y[2] := 0; Y[3] := 1; Y[4] := 1; Y[5] := 1; Y[6] := 0; Y[7] := -1; Y[8] := 0; Y[9] := 0;
  Z[0] := 0; Z[1] := 0; Z[2] := 0; Z[3] := 0; Z[4] := 0; Z[5] := 0; Z[6] := 0; Z[7] := 0; Z[8] := 1; Z[9] := -1;
  Vector.X := X[Direction];
  Vector.Y := Y[Direction];
  Vector.Z := Z[Direction];
end;

class procedure TPathfinding.VectorToDirection(Vector: TPosition; var Dir: Integer);
var
  X: array[0..7] of Integer;
  Y: array[0..7] of Integer;
  I: Integer;
begin
  X[0] := 0; X[1] := 1; X[2] := 1; X[3] := 1; X[4] := 0; X[5] := -1; X[6] := -1; X[7] := -1;
  Y[0] := -1; Y[1] := -1; Y[2] := 0; Y[3] := 1; Y[4] := 1; Y[5] := 1; Y[6] := 0; Y[7] := -1;
  Dir := -1;
  for I := 0 to 7 do
    if (X[I] = Vector.X) and (Y[I] = Vector.Y) then
    begin
      Dir := I;
      Exit;
    end;
end;

function TPathfinding.GetStartDirection: Integer;
begin
  if FPath.Count = 0 then Result := -1
  else Result := FPath[FPath.Count - 1];
end;

function TPathfinding.DequeuePath: Integer;
begin
  if FPath.Count = 0 then Result := -1
  else
  begin
    Result := FPath[FPath.Count - 1];
    FPath.Delete(FPath.Count - 1);
  end;
end;

function TPathfinding.IsBlocked(Tile: TTile; Part: Integer; MissileTarget: TBattleUnit; BigWallExclusion: Integer): Boolean;
var
  Unit: TBattleUnit;
  TileWest, TileNorth: TTile;
  Pos: TPosition;
begin
  if Tile = nil then Exit(True);

  if Part = O_BIGWALL then
  begin
    if Assigned(Tile.GetMapData(O_OBJECT)) and (Tile.GetMapData(O_OBJECT).BigWall <> 0) and
       (Tile.GetMapData(O_OBJECT).BigWall <= BIGWALLNWSE) and
       (Tile.GetMapData(O_OBJECT).BigWall <> BigWallExclusion) then
      Exit(True)
    else Exit(False);
  end;

  if Part = O_WESTWALL then
  begin
    if Assigned(Tile.GetMapData(O_OBJECT)) and
       ((Tile.GetMapData(O_OBJECT).BigWall = BIGWALLWEST) or
        (Tile.GetMapData(O_OBJECT).BigWall = BIGWALLWESTANDNORTH)) then
      Exit(True);
    TileWest := FSave.GetTile(Tile.Position + TPosition.Create(-1,0,0));
    if TileWest = nil then Exit(True);
    if Assigned(TileWest.GetMapData(O_OBJECT)) and
       ((TileWest.GetMapData(O_OBJECT).BigWall = BIGWALLEAST) or
        (TileWest.GetMapData(O_OBJECT).BigWall = BIGWALLEASTANDSOUTH)) then
      Exit(True);
  end;

  if Part = O_NORTHWALL then
  begin
    if Assigned(Tile.GetMapData(O_OBJECT)) and
       ((Tile.GetMapData(O_OBJECT).BigWall = BIGWALLNORTH) or
        (Tile.GetMapData(O_OBJECT).BigWall = BIGWALLWESTANDNORTH)) then
      Exit(True);
    TileNorth := FSave.GetTile(Tile.Position + TPosition.Create(0,-1,0));
    if TileNorth = nil then Exit(True);
    if Assigned(TileNorth.GetMapData(O_OBJECT)) and
       ((TileNorth.GetMapData(O_OBJECT).BigWall = BIGWALLSOUTH) or
        (TileNorth.GetMapData(O_OBJECT).BigWall = BIGWALLEASTANDSOUTH)) then
      Exit(True);
  end;

  if Part = O_FLOOR then
  begin
    if Assigned(Tile.Unit) then
    begin
      Unit := Tile.Unit;
      if (Unit = FUnit) or (Unit = MissileTarget) or Unit.IsOut then Exit(False);
      if Assigned(FUnit) then
      begin
        if (FUnit.Faction = FACTION_PLAYER) and Unit.Visible then Exit(True);
        if FUnit.Faction = Unit.Faction then Exit(True);
        if (FUnit.Faction = FACTION_HOSTILE) and
           (FUnit.UnitsSpottedThisTurn.IndexOf(Unit) <> -1) then Exit(True);
      end;
    end
    else if Tile.HasNoFloor(nil) and (FMovementType <> MT_FLY) then
    begin
      Pos := Tile.Position;
      while Pos.Z >= 0 do
      begin
        Unit := FSave.GetTile(Pos).Unit;
        if (Unit <> nil) and (Unit <> FUnit) then
        begin
          if Assigned(FUnit) and (FUnit.Armor.Size > 1) then Exit(True);
          if (Unit <> FUnit) and (Unit <> MissileTarget) and not Unit.IsOut and (Unit.Armor.Size > 1) then Exit(True);
        end;
        if not FSave.GetTile(Pos).HasNoFloor(nil) then Break;
        Pos.Z := Pos.Z - 1;
      end;
    end;
  end;

  // Doors blocking for missiles
  if Assigned(MissileTarget) and Assigned(Tile.GetMapData(TTilePart(Part))) and
     (Tile.GetMapData(TTilePart(Part)).IsDoor or
      (Tile.GetMapData(TTilePart(Part)).IsUFODoor and not Tile.IsUfoDoorOpen(TTilePart(Part)))) then
    Exit(True);

  if Tile.GetTUCost(Part, FMovementType) = 255 then Exit(True);
  Result := False;
end;

function TPathfinding.IsBlocked(StartTile, EndTile: TTile; const Direction: Integer; MissileTarget: TBattleUnit): Boolean;
var
  Pos: TPosition;
  Tile: TTile;
begin
  Pos := StartTile.Position;
  case Direction of
    0: Result := IsBlocked(StartTile, O_NORTHWALL, MissileTarget);
    1: Result := IsBlocked(StartTile, O_NORTHWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,-1,0) + TPosition.Create(1,0,0)), O_WESTWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_WESTWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_NORTHWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_BIGWALL, MissileTarget, BIGWALLNESW) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,-1,0)), O_BIGWALL, MissileTarget, BIGWALLNESW);
    2: Result := IsBlocked(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_WESTWALL, MissileTarget);
    3: Result := IsBlocked(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_WESTWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_NORTHWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0) + TPosition.Create(1,0,0)), O_NORTHWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0) + TPosition.Create(1,0,0)), O_WESTWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(1,0,0)), O_BIGWALL, MissileTarget, BIGWALLNWSE) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_BIGWALL, MissileTarget, BIGWALLNWSE);
    4: Result := IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_NORTHWALL, MissileTarget);
    5: Result := IsBlocked(StartTile, O_WESTWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_WESTWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_NORTHWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0)), O_BIGWALL, MissileTarget, BIGWALLNESW) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(-1,0,0)), O_BIGWALL, MissileTarget, BIGWALLNESW) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,1,0) + TPosition.Create(-1,0,0)), O_NORTHWALL, MissileTarget);
    6: Result := IsBlocked(StartTile, O_WESTWALL, MissileTarget);
    7: Result := IsBlocked(StartTile, O_WESTWALL, MissileTarget) or
                 IsBlocked(StartTile, O_NORTHWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(-1,0,0)), O_NORTHWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,-1,0)), O_WESTWALL, MissileTarget) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(0,-1,0)), O_BIGWALL, MissileTarget, BIGWALLNWSE) or
                 IsBlocked(FSave.GetTile(Pos + TPosition.Create(-1,0,0)), O_BIGWALL, MissileTarget, BIGWALLNWSE);
  else Result := False;
  end;
end;

function TPathfinding.CanFallDown(DestinationTile: TTile): Boolean;
var
  Below: TTile;
begin
  if DestinationTile.Position.Z = 0 then Exit(False);
  Below := FSave.GetTile(DestinationTile.Position - TPosition.Create(0,0,1));
  Result := DestinationTile.HasNoFloor(Below);
end;

function TPathfinding.CanFallDown(DestinationTile: TTile; Size: Integer): Boolean;
var
  X, Y: Integer;
begin
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
      if not CanFallDown(FSave.GetTile(DestinationTile.Position + TPosition.Create(X,Y,0))) then
        Exit(False);
  Result := True;
end;

function TPathfinding.IsOnStairs(StartPosition, EndPosition: TPosition): Boolean;
begin
  // Check south stairs
  if Assigned(FSave.GetTile(EndPosition + TPosition.Create(0,1,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(0,1,0)).TerrainLevel = -16) and
     Assigned(FSave.GetTile(EndPosition + TPosition.Create(0,2,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(0,2,0)).TerrainLevel = -8) and
     ((StartPosition.X = EndPosition.X) and (StartPosition.Y = EndPosition.Y + 1) or
      (StartPosition.X = EndPosition.X) and (StartPosition.Y = EndPosition.Y + 2) or
      (StartPosition.X = EndPosition.X) and (StartPosition.Y = EndPosition.Y + 3)) then
    Exit(True);

  // Check east stairs
  if Assigned(FSave.GetTile(EndPosition + TPosition.Create(1,0,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(1,0,0)).TerrainLevel = -16) and
     Assigned(FSave.GetTile(EndPosition + TPosition.Create(2,0,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(2,0,0)).TerrainLevel = -8) and
     ((StartPosition.X = EndPosition.X + 1) and (StartPosition.Y = EndPosition.Y) or
      (StartPosition.X = EndPosition.X + 2) and (StartPosition.Y = EndPosition.Y) or
      (StartPosition.X = EndPosition.X + 3) and (StartPosition.Y = EndPosition.Y)) then
    Exit(True);

  // TFTD stairs (levels -18 and -12)
  if Assigned(FSave.GetTile(EndPosition + TPosition.Create(0,1,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(0,1,0)).TerrainLevel = -18) and
     Assigned(FSave.GetTile(EndPosition + TPosition.Create(0,2,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(0,2,0)).TerrainLevel = -12) and
     ((StartPosition.X = EndPosition.X) and (StartPosition.Y = EndPosition.Y + 1) or
      (StartPosition.X = EndPosition.X) and (StartPosition.Y = EndPosition.Y + 2) or
      (StartPosition.X = EndPosition.X) and (StartPosition.Y = EndPosition.Y + 3)) then
    Exit(True);

  if Assigned(FSave.GetTile(EndPosition + TPosition.Create(1,0,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(1,0,0)).TerrainLevel = -18) and
     Assigned(FSave.GetTile(EndPosition + TPosition.Create(2,0,0))) and
     (FSave.GetTile(EndPosition + TPosition.Create(2,0,0)).TerrainLevel = -12) and
     ((StartPosition.X = EndPosition.X + 1) and (StartPosition.Y = EndPosition.Y) or
      (StartPosition.X = EndPosition.X + 2) and (StartPosition.Y = EndPosition.Y) or
      (StartPosition.X = EndPosition.X + 3) and (StartPosition.Y = EndPosition.Y)) then
    Exit(True);

  Result := False;
end;

function TPathfinding.ValidateUpDown(Bu: TBattleUnit; const StartPosition: TPosition; Direction: Integer; Missile: Boolean): Boolean;
var
  EndPos: TPosition;
  StartTile, DestTile, BelowStart: TTile;
begin
  DirectionToVector(Direction, EndPos);
  EndPos := EndPos + StartPosition;
  StartTile := FSave.GetTile(StartPosition);
  BelowStart := FSave.GetTile(StartPosition + TPosition.Create(0,0,-1));
  DestTile := FSave.GetTile(EndPos);

  if Assigned(StartTile.GetMapData(O_FLOOR)) and Assigned(DestTile.GetMapData(O_FLOOR)) and
     StartTile.GetMapData(O_FLOOR).IsGravLift and DestTile.GetMapData(O_FLOOR).IsGravLift then
  begin
    if Missile then
    begin
      if (Direction = DIR_UP) and (DestTile.GetMapData(O_FLOOR).GetLoftID(0) <> 0) then Exit(False);
      if (Direction = DIR_DOWN) and (StartTile.GetMapData(O_FLOOR).GetLoftID(0) <> 0) then Exit(False);
    end;
    Exit(True);
  end
  else
  begin
    if Bu.MovementType = MT_FLY then
    begin
      if ((Direction = DIR_UP) and Assigned(DestTile) and DestTile.HasNoFloor(StartTile)) or
         ((Direction = DIR_DOWN) and Assigned(DestTile) and StartTile.HasNoFloor(BelowStart)) then
        Exit(True);
    end;
  end;
  Result := False;
end;

function TPathfinding.PreviewPath(Remove: Boolean): Boolean;
var
  Pos, Dest: TPosition;
  TUs, Energy, Size, Total, Dir: Integer;
  TuCost: Integer;
  X, Y: Integer;
  Tile: TTile;
  Running: Boolean;
  Reserve: Boolean;
begin
  if FPath.Count = 0 then Exit(False);
  if not Remove and FPathPreviewed then Exit(False);

  FPathPreviewed := not Remove;

  Pos := FUnit.Position;
  TUs := FUnit.TimeUnits;
  if FUnit.IsKneeled then TUs := TUs - 8;
  Energy := FUnit.Energy;
  Size := FUnit.Armor.Size - 1;
  Total := IfThen(FUnit.IsKneeled, 8, 0);
  FModifierUsed := (SDL_GetModState and KMOD_CTRL) <> 0;
  Running := Options.Strafe and FModifierUsed and (FUnit.Armor.Size = 1) and (FPath.Count > 1);

  for Dir in FPath do
  begin
    TuCost := GetTUCost(Pos, Dir, Dest, FUnit, nil, False);
    if Running and (Dir < DIR_UP) then
    begin
      TuCost := Round(TuCost * 0.75);
      Energy := Energy - Round(TuCost * 1.5 / 2);
    end
    else
      Energy := Energy - TuCost div 2;
    TUs := TUs - TuCost;
    Total := Total + TuCost;
    Reserve := FSave.BattleGame.CheckReservedTU(FUnit, Total, True);
    Pos := Dest;

    for X := Size downto 0 do
      for Y := Size downto 0 do
      begin
        Tile := FSave.GetTile(Pos + TPosition.Create(X,Y,0));
        if not Remove then
        begin
          if (X = Size) and (Y = Size) then Tile.Preview := 10;
          Tile.TUMarker := Max(0, TUs);
          Tile.MarkerColor := IfThen((TUs >= 0) and (Energy >= 0),
                                     IfThen(Reserve, Pathfinding.green, Pathfinding.yellow),
                                     Pathfinding.red);
        end
        else
        begin
          Tile.Preview := -1;
          Tile.TUMarker := -1;
          Tile.MarkerColor := 0;
        end;
      end;
  end;
  Result := True;
end;

function TPathfinding.RemovePreview: Boolean;
begin
  if not FPathPreviewed then Exit(False);
  Result := PreviewPath(True);
end;

procedure TPathfinding.AbortPath;
begin
  FTotalTUCost := 0;
  FPath.Clear;
end;

function TPathfinding.GetStrafeMove: Boolean;
begin
  Result := FStrafeMove;
end;

function TPathfinding.IsPathPreviewed: Boolean;
begin
  Result := FPathPreviewed;
end;

function TPathfinding.IsModifierUsed: Boolean;
begin
  Result := FModifierUsed;
end;

procedure TPathfinding.SetUnit(Unit: TBattleUnit);
begin
  FUnit := Unit;
  if Unit <> nil then FMovementType := Unit.MovementType
  else FMovementType := MT_WALK;
end;

function TPathfinding.FindReachable(Unit: TBattleUnit; TuMax: Integer): TList<Integer>;
var
  StartNode: TPathfindingNode;
  OpenList: TPathfindingOpenSet;
  CurrentNode: TPathfindingNode;
  CurrentPos: TPosition;
  Direction: Integer;
  NextPos: TPosition;
  TuCost: Integer;
  NextNode: TPathfindingNode;
  TotalTuCost: Integer;
  EnergyMax: Integer;
  Reachable: TList<TPathfindingNode>;
  Node: TPathfindingNode;
begin
  FUnit := Unit;
  FMovementType := Unit.MovementType;
  EnergyMax := Unit.Energy;

  for Node in FNodes do Node.Reset;

  StartNode := GetNode(Unit.Position);
  StartNode.Connect(0, nil, 0);
  OpenList := TPathfindingOpenSet.Create;
  Reachable := TList<TPathfindingNode>.Create;
  try
    OpenList.Push(StartNode);
    while not OpenList.Empty do
    begin
      CurrentNode := OpenList.Pop;
      CurrentPos := CurrentNode.Position;

      for Direction := 0 to 9 do
      begin
        NextPos := CurrentPos;
        TuCost := GetTUCost(CurrentPos, Direction, NextPos, Unit, nil, False);
        if TuCost = 255 then Continue;
        if (CurrentNode.GetTUCost(False) + TuCost > TuMax) or
           ((CurrentNode.GetTUCost(False) + TuCost) div 2 > EnergyMax) then Continue;
        NextNode := GetNode(NextPos);
        if NextNode.Checked then Continue;
        TotalTuCost := CurrentNode.GetTUCost(False) + TuCost;
        if (not NextNode.InOpenSet) or (NextNode.GetTUCost(False) > TotalTuCost) then
        begin
          NextNode.Connect(TotalTuCost, CurrentNode, Direction);
          OpenList.Push(NextNode);
        end;
      end;
      CurrentNode.Checked := True;
      Reachable.Add(CurrentNode);
    end;

    Reachable.Sort(MinNodeCosts);
    Result := TList<Integer>.Create;
    for Node in Reachable do
      Result.Add(FSave.GetTileIndex(Node.Position));
  finally
    OpenList.Free;
    Reachable.Free;
  end;
end;

function TPathfinding.GetTotalTUCost: Integer;
begin
  Result := FTotalTUCost;
end;

function TPathfinding.GetPath: TList<Integer>;
begin
  Result := FPath;
end;

function TPathfinding.CopyPath: TList<Integer>;
begin
  Result := TList<Integer>.Create;
  Result.AddRange(FPath);
end;

end.