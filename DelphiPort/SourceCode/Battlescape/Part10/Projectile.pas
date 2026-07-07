unit Projectile;

interface

uses
  Classes, SysUtils,
  Battlescape.Position,
  Battlescape.BattlescapeGame,
  Savegame.SavedBattleGame,
  Savegame.Tile,
  Savegame.BattleUnit,
  Savegame.BattleItem,
  Mod.Mod,
  Mod.RuleItem,
  Mod.MapData;

type
  TProjectile = class
  public const
    ItemDropVoxelOffset = -2;
  private
    FMod: TMod;
    FSave: TSavedBattleGame;
    FAction: TBattleAction;
    FOrigin: TPosition;
    FTargetVoxel: TPosition;
    FTrajectory: TList<TPosition>;
    FPosition: Integer;
    FSprite: TSurface;
    FSpeed: Integer;
    FBulletSprite: Integer;
    FReversed: Boolean;
    FVaporColor: Integer;
    FVaporDensity: Integer;
    FVaporProbability: Integer;
    procedure ApplyAccuracy(Origin: TPosition; var Target: TPosition; Accuracy: Double; KeepRange, ExtendLine: Boolean);
  public
    constructor Create(Mod_: TMod; Save: TSavedBattleGame; Action: TBattleAction; Origin, TargetVoxel: TPosition; Ammo: TBattleItem);
    destructor Destroy; override;
    function CalculateTrajectory(Accuracy: Double): Integer; overload;
    function CalculateTrajectory(Accuracy: Double; const OriginVoxel: TPosition; ExcludeUnit: Boolean = True): Integer; overload;
    function CalculateThrow(Accuracy: Double): Integer;
    function Move: Boolean;
    function GetPosition(Offset: Integer = 0): TPosition;
    function GetParticle(I: Integer): Integer;
    function GetItem: TBattleItem;
    function GetSprite: TSurface;
    procedure SkipTrajectory;
    function GetOrigin: TPosition;
    function GetTarget: TPosition;
    function IsReversed: Boolean;
    procedure AddVaporCloud;
    class function GetPositionFromStart(const Trajectory: TList<TPosition>; Pos: Integer): TPosition; static;
    class function GetPositionFromEnd(const Trajectory: TList<TPosition>; Pos: Integer): TPosition; static;
  end;

implementation

uses
  Engine.SurfaceSet,
  Engine.Surface,
  Engine.RNG,
  Engine.Options,
  Battlescape.TileEngine,
  Battlescape.Map,
  Battlescape.Camera,
  fmath;

{ TProjectile }

constructor TProjectile.Create(Mod_: TMod; Save: TSavedBattleGame; Action: TBattleAction; Origin, TargetVoxel: TPosition; Ammo: TBattleItem);
begin
  FMod := Mod_;
  FSave := Save;
  FAction := Action;
  FOrigin := Origin;
  FTargetVoxel := TargetVoxel;
  FPosition := 0;
  FBulletSprite := -1;
  FReversed := False;
  FVaporColor := -1;
  FVaporDensity := -1;
  FVaporProbability := 5;

  FSpeed := Options.BattleFireSpeed;
  if Assigned(FAction.Weapon) then
  begin
    if FAction.Type_ = BA_THROW then
      FSprite := FMod.SurfaceSet['FLOOROB.PCK'].GetFrame(GetItem.Rules.FloorSprite)
    else
    begin
      if Assigned(Ammo) then
      begin
        FBulletSprite := Ammo.Rules.BulletSprite;
        FVaporColor := Ammo.Rules.VaporColor;
        FVaporDensity := Ammo.Rules.VaporDensity;
        FVaporProbability := Ammo.Rules.VaporProbability;
        FSpeed := Max(1, FSpeed + Ammo.Rules.BulletSpeed);
      end;
      if FBulletSprite = -1 then
        FBulletSprite := FAction.Weapon.Rules.BulletSprite;
      if FVaporColor = -1 then
        FVaporColor := FAction.Weapon.Rules.VaporColor;
      if FVaporDensity = -1 then
        FVaporDensity := FAction.Weapon.Rules.VaporDensity;
      if FVaporProbability = 5 then
        FVaporProbability := FAction.Weapon.Rules.VaporProbability;
      if (Ammo = nil) or (Ammo = FAction.Weapon) or (Ammo.Rules.BulletSpeed = 0) then
        FSpeed := Max(1, FSpeed + FAction.Weapon.Rules.BulletSpeed);
    end;
  end;

  if (TargetVoxel.X - Origin.X) + (TargetVoxel.Y - Origin.Y) >= 0 then
    FReversed := True;

  FTrajectory := TList<TPosition>.Create;
end;

destructor TProjectile.Destroy;
begin
  FTrajectory.Free;
  inherited;
end;

function TProjectile.CalculateTrajectory(Accuracy: Double): Integer;
var
  OriginVoxel: TPosition;
begin
  OriginVoxel := FSave.TileEngine.GetOriginVoxel(FAction, FSave.GetTile(FOrigin));
  Result := CalculateTrajectory(Accuracy, OriginVoxel, True);
end;

function TProjectile.CalculateTrajectory(Accuracy: Double; const OriginVoxel: TPosition; ExcludeUnit: Boolean): Integer;
var
  TargetTile: TTile;
  Bu: TBattleUnit;
  Test: Integer;
  HitPos: TPosition;
  HitUnit, TargetUnit: TBattleUnit;
begin
  TargetTile := FSave.GetTile(FAction.Target);
  Bu := FAction.Actor;

  if ExcludeUnit then
    Test := FSave.TileEngine.CalculateLine(OriginVoxel, FTargetVoxel, False, FTrajectory, Bu)
  else
    Test := FSave.TileEngine.CalculateLine(OriginVoxel, FTargetVoxel, False, FTrajectory, nil);

  if (Test <> V_EMPTY) and (FTrajectory.Count > 0) and
     (FAction.Actor.Faction = FACTION_PLAYER) and
     (FAction.AutoShotCounter = 1) and
     ((SDL_GetModState and KMOD_CTRL) = 0) and
     (not Options.ForceFire) and
     FSave.BattleGame.PanicHandled and
     (FAction.Type_ <> BA_LAUNCH) then
  begin
    HitPos := TPosition.Create(FTrajectory[0].X div 16, FTrajectory[0].Y div 16, FTrajectory[0].Z div 24);
    if (Test = V_UNIT) and Assigned(FSave.GetTile(HitPos)) and (FSave.GetTile(HitPos).Unit = nil) then
      HitPos.Z := HitPos.Z - 1;

    if (HitPos <> FAction.Target) and (FAction.Result = '') then
    begin
      if (Test = V_NORTHWALL) and (HitPos.Y - 1 <> FAction.Target.Y) then
        Exit(V_EMPTY)
      else if (Test = V_WESTWALL) and (HitPos.X - 1 <> FAction.Target.X) then
        Exit(V_EMPTY)
      else if Test = V_UNIT then
      begin
        HitUnit := FSave.GetTile(HitPos).Unit;
        TargetUnit := TargetTile.Unit;
        if HitUnit <> TargetUnit then Exit(V_EMPTY);
      end
      else
        Exit(V_EMPTY);
    end;
  end;

  FTrajectory.Clear;

  if FAction.Type_ = BA_LAUNCH then
  begin
    if FAction.Actor.Faction = FACTION_PLAYER then Accuracy := 0.60
    else Accuracy := 0.55;
    // extend line only if <=1 waypoint
    if FAction.Waypoints.Count <= 1 then
      ApplyAccuracy(OriginVoxel, FTargetVoxel, Accuracy, False, True)
    else
      ApplyAccuracy(OriginVoxel, FTargetVoxel, Accuracy, False, False);
  end
  else
    ApplyAccuracy(OriginVoxel, FTargetVoxel, Accuracy, False, True);

  Result := FSave.TileEngine.CalculateLine(OriginVoxel, FTargetVoxel, True, FTrajectory, Bu);
end;

function TProjectile.CalculateThrow(Accuracy: Double): Integer;
var
  TargetTile: TTile;
  OriginVoxel, TargetVoxel: TPosition;
  Targets: TList<TPosition>;
  Curvature: Double;
  Test: Integer;
  Forced: Boolean;
  Tu: TBattleUnit;
  P: TPosition;
  I: Integer;
  Deltas: TPosition;
  EndPoint: TPosition;
  EndTile: TTile;
begin
  TargetTile := FSave.GetTile(FAction.Target);
  OriginVoxel := FSave.TileEngine.GetOriginVoxel(FAction, nil);
  TargetVoxel := FAction.Target * TPosition.Create(16,16,24) + TPosition.Create(8,8, (1 + -TargetTile.TerrainLevel));
  Targets := TList<TPosition>.Create;
  Forced := False;

  if FAction.Type_ = BA_THROW then
    Targets.Add(TargetVoxel)
  else
  begin
    Tu := TargetTile.Unit;
    if (Tu = nil) and (FAction.Target.Z > 0) and TargetTile.HasNoFloor(nil) then
      Tu := FSave.GetTile(FAction.Target - TPosition.Create(0,0,1)).Unit;
    if Options.ForceFire and ((SDL_GetModState and KMOD_CTRL) <> 0) and (FSave.Side = FACTION_PLAYER) then
    begin
      Targets.Add(FAction.Target * TPosition.Create(16,16,24) + TPosition.Create(0,0,12));
      Forced := True;
    end
    else if Assigned(Tu) and ((FAction.Actor.Faction <> FACTION_PLAYER) or Tu.Visible) then
    begin
      TargetVoxel.Z := TargetVoxel.Z + Tu.FloatHeight;
      Targets.Add(TargetVoxel + TPosition.Create(0,0, Tu.Height div 2 + 1));
      Targets.Add(TargetVoxel + TPosition.Create(0,0, 2));
      Targets.Add(TargetVoxel + TPosition.Create(0,0, Tu.Height - 1));
    end
    else if Assigned(TargetTile.GetMapData(O_OBJECT)) then
    begin
      TargetVoxel := FAction.Target * TPosition.Create(16,16,24) + TPosition.Create(8,8,0);
      Targets.Add(TargetVoxel + TPosition.Create(0,0,13));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,8));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,23));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,2));
    end
    else if Assigned(TargetTile.GetMapData(O_NORTHWALL)) then
    begin
      TargetVoxel := FAction.Target * TPosition.Create(16,16,24) + TPosition.Create(8,0,0);
      Targets.Add(TargetVoxel + TPosition.Create(0,0,13));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,8));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,20));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,3));
    end
    else if Assigned(TargetTile.GetMapData(O_WESTWALL)) then
    begin
      TargetVoxel := FAction.Target * TPosition.Create(16,16,24) + TPosition.Create(0,8,0);
      Targets.Add(TargetVoxel + TPosition.Create(0,0,13));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,8));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,20));
      Targets.Add(TargetVoxel + TPosition.Create(0,0,2));
    end
    else if Assigned(TargetTile.GetMapData(O_FLOOR)) then
      Targets.Add(TargetVoxel);
  end;

  Test := V_OUTOFBOUNDS;
  for I := 0 to Targets.Count - 1 do
  begin
    TargetVoxel := Targets[I];
    if FSave.TileEngine.ValidateThrow(FAction, OriginVoxel, TargetVoxel, Curvature, Test, Forced) then
      Break;
  end;

  if not Forced and (Test = V_OUTOFBOUNDS) then Exit(Test);

  Test := V_OUTOFBOUNDS;
  while Test = V_OUTOFBOUNDS do
  begin
    Deltas := TargetVoxel;
    if FAction.Type_ = BA_THROW then
    begin
      ApplyAccuracy(OriginVoxel, Deltas, Accuracy, True, False);
      Deltas := Deltas - TargetVoxel;
    end
    else
    begin
      ApplyAccuracy(OriginVoxel, TargetVoxel, Accuracy, True, False);
      Deltas := TPosition.Create(0,0,0);
    end;

    FTrajectory.Clear;
    Test := FSave.TileEngine.CalculateParabola(OriginVoxel, TargetVoxel, True, FTrajectory, FAction.Actor, Curvature, Deltas);
    if Forced then Exit(O_OBJECT);
    EndPoint := GetPositionFromEnd(FTrajectory, ItemDropVoxelOffset) div TPosition.Create(16,16,24);
    EndTile := FSave.GetTile(EndPoint);
    if (FAction.Type_ = BA_THROW) and Assigned(EndTile) and
       Assigned(EndTile.GetMapData(O_OBJECT)) and
       (EndTile.GetMapData(O_OBJECT).GetTUCost(MT_WALK) = 255) and
       not (EndTile.IsBigWall and (EndTile.GetMapData(O_OBJECT).BigWall < 1) or (EndTile.GetMapData(O_OBJECT).BigWall > 3)) then
      Test := V_OUTOFBOUNDS;
  end;

  Result := Test;
end;

procedure TProjectile.ApplyAccuracy(Origin: TPosition; var Target: TPosition; Accuracy: Double; KeepRange, ExtendLine: Boolean);
var
  XDiff, YDiff: Integer;
  RealDistance: Double;
  MaxRange: Double;
  Weapon: TRuleItem;
  Modifier: Double;
  UpperLimit, LowerLimit: Integer;
  XDist, YDist, ZDist: Integer;
  XYShift, ZShift: Integer;
  Deviation: Integer;
  Rotation, Tilt: Double;
  CosFi, SinFi, CosTe, SinTe: Double;
begin
  XDiff := Origin.X - Target.X;
  YDiff := Origin.Y - Target.Y;
  RealDistance := Sqrt(XDiff*XDiff + YDiff*YDiff);
  MaxRange := IfThen(KeepRange, RealDistance, 16*1000);
  if FAction.Type_ = BA_HIT then MaxRange := 46;

  Weapon := FAction.Weapon.Rules;

  if (FAction.Type_ <> BA_THROW) and (FAction.Type_ <> BA_HIT) then
  begin
    Modifier := 0.0;
    UpperLimit := Weapon.AimRange;
    LowerLimit := Weapon.MinRange;
    if Options.BattleUFOExtenderAccuracy then
    begin
      if FAction.Type_ = BA_AUTOSHOT then UpperLimit := Weapon.AutoRange
      else if FAction.Type_ = BA_SNAPSHOT then UpperLimit := Weapon.SnapRange;
    end;
    if RealDistance / 16 < LowerLimit then
      Modifier := (Weapon.Dropoff * (LowerLimit - RealDistance / 16)) / 100
    else if UpperLimit < RealDistance / 16 then
      Modifier := (Weapon.Dropoff * (RealDistance / 16 - UpperLimit)) / 100;
    Accuracy := Max(0.0, Accuracy - Modifier);
  end;

  XDist := Abs(Origin.X - Target.X);
  YDist := Abs(Origin.Y - Target.Y);
  ZDist := Abs(Origin.Z - Target.Z);

  if XDist div 2 <= YDist then XYShift := XDist div 4 + YDist
  else XYShift := (XDist + YDist) div 2;

  if XYShift <= ZDist then ZShift := XYShift div 2 + ZDist
  else ZShift := XYShift + ZDist div 2;

  Deviation := RNG.Generate(0, 100) - Round(Accuracy * 100);
  if Deviation >= 0 then Deviation := Deviation + 50
  else Deviation := Deviation + 10;
  Deviation := Max(1, ZShift * Deviation div 200);

  Target.X := Target.X + RNG.Generate(0, Deviation) - Deviation div 2;
  Target.Y := Target.Y + RNG.Generate(0, Deviation) - Deviation div 2;
  Target.Z := Target.Z + RNG.Generate(0, Deviation div 2) div 2 - Deviation div 8;

  if ExtendLine then
  begin
    Rotation := ArcTan2(Target.Y - Origin.Y, Target.X - Origin.X) * 180 / PI;
    Tilt := ArcTan2(Target.Z - Origin.Z,
                    Sqrt((Target.X - Origin.X)*(Target.X - Origin.X) +
                         (Target.Y - Origin.Y)*(Target.Y - Origin.Y))) * 180 / PI;
    CosFi := Cos(DegToRad(Tilt));
    SinFi := Sin(DegToRad(Tilt));
    CosTe := Cos(DegToRad(Rotation));
    SinTe := Sin(DegToRad(Rotation));
    Target.X := Round(Origin.X + MaxRange * CosTe * CosFi);
    Target.Y := Round(Origin.Y + MaxRange * SinTe * CosFi);
    Target.Z := Round(Origin.Z + MaxRange * SinFi);
  end;
end;

function TProjectile.Move: Boolean;
var
  I: Integer;
begin
  for I := 0 to FSpeed - 1 do
  begin
    Inc(FPosition);
    if FPosition >= FTrajectory.Count then
    begin
      Dec(FPosition);
      Exit(False);
    end;
    if (FSave.Depth > 0) and (FVaporColor <> -1) and (FAction.Type_ <> BA_THROW) and RNG.Percent(FVaporProbability) then
      AddVaporCloud;
  end;
  Result := True;
end;

class function TProjectile.GetPositionFromStart(const Trajectory: TList<TPosition>; Pos: Integer): TPosition;
begin
  if (Pos >= 0) and (Pos < Trajectory.Count) then Result := Trajectory[Pos]
  else if Pos < 0 then Result := Trajectory[0]
  else Result := Trajectory[Trajectory.Count - 1];
end;

class function TProjectile.GetPositionFromEnd(const Trajectory: TList<TPosition>; Pos: Integer): TPosition;
begin
  Result := GetPositionFromStart(Trajectory, Trajectory.Count + Pos - 1);
end;

function TProjectile.GetPosition(Offset: Integer): TPosition;
begin
  Result := GetPositionFromStart(FTrajectory, FPosition + Offset);
end;

function TProjectile.GetParticle(I: Integer): Integer;
begin
  if FBulletSprite <> -1 then Result := FBulletSprite + I
  else Result := -1;
end;

function TProjectile.GetItem: TBattleItem;
begin
  if FAction.Type_ = BA_THROW then Result := FAction.Weapon
  else Result := nil;
end;

function TProjectile.GetSprite: TSurface;
begin
  Result := FSprite;
end;

procedure TProjectile.SkipTrajectory;
begin
  while Move do;
end;

function TProjectile.GetOrigin: TPosition;
begin
  Result := FTrajectory[0] div TPosition.Create(16,16,24);
end;

function TProjectile.GetTarget: TPosition;
begin
  Result := FAction.Target;
end;

function TProjectile.IsReversed: Boolean;
begin
  Result := FReversed;
end;

procedure TProjectile.AddVaporCloud;
var
  Tile: TTile;
  TilePos, VoxelPos: TPosition;
  I: Integer;
  Particle: TParticle;
begin
  Tile := FSave.GetTile(FTrajectory[FPosition] div TPosition.Create(16,16,24));
  if Tile = nil then Exit;
  FSave.BattleGame.Map.Camera.ConvertMapToScreen(FTrajectory[FPosition] div TPosition.Create(16,16,24), TilePos);
  TilePos := TilePos + FSave.BattleGame.Map.Camera.MapOffset;
  FSave.BattleGame.Map.Camera.ConvertVoxelToScreen(FTrajectory[FPosition], VoxelPos);
  for I := 0 to FVaporDensity - 1 do
  begin
    Particle := TParticle.Create(VoxelPos.X - TilePos.X + RNG.Seedless(0,4) - 2,
                                 VoxelPos.Y - TilePos.Y + RNG.Seedless(0,4) - 2,
                                 RNG.Seedless(48, 224), FVaporColor, RNG.Seedless(32, 44));
    Tile.AddParticle(Particle);
  end;
end;

end.