unit Tile;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, Position, MapData, MapDataSet,
  Surface, BattleUnit, BattleItem, RuleInventory, Particle, RNG, SerializationHelper;

type
  TTilePart = (O_FLOOR, O_WESTWALL, O_NORTHWALL, O_OBJECT);

  TTileSerializationKey = record
    Index: Byte;
    _mapDataSetID: Byte;
    _mapDataID: Byte;
    _smoke: Byte;
    _fire: Byte;
    boolFields: Byte;
    totalBytes: UInt32;
  end;

  TTile = class
  private
    const LIGHTLAYERS = 3;
    FObjects: array[0..3] of TMapData;
    FMapDataID: array[0..3] of Integer;
    FMapDataSetID: array[0..3] of Integer;
    FCurrentFrame: array[0..3] of Integer;
    FDiscovered: array[0..2] of Boolean;
    FLight: array[0..LIGHTLAYERS-1] of Integer;
    FLastLight: array[0..LIGHTLAYERS-1] of Integer;
    FSmoke: Integer;
    FFire: Integer;
    FExplosive: Integer;
    FExplosiveType: Integer;
    FPos: TPosition;
    FUnit: TBattleUnit;
    FInventory: TList<TBattleItem>;
    FAnimationOffset: Integer;
    FMarkerColor: Integer;
    FVisible: Integer;
    FPreview: Integer;
    FTUMarker: Integer;
    FOverlaps: Integer;
    FDanger: Boolean;
    FParticles: TList<TParticle>;
    FObstacle: Integer;
  public
    class var SerializationKey: TTileSerializationKey;
    class constructor CreateSerializationKey;
    const NOT_CALCULATED = -1;
    constructor Create(Pos: TPosition);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    procedure LoadBinary(var Buffer: PByte; const SerKey: TTileSerializationKey);
    function Save: TYamlNode;
    procedure SaveBinary(var Buffer: PByte);
    function GetMapData(Part: TTilePart): TMapData;
    procedure SetMapData(Dat: TMapData; MapDataID, MapDataSetID: Integer; Part: TTilePart);
    procedure GetMapDataIDs(out MapDataID, MapDataSetID: Integer; Part: TTilePart);
    function IsVoid: Boolean;
    function GetTUCost(Part: Integer; MovementType: TMovementType): Integer;
    function HasNoFloor(TileBelow: TTile): Boolean;
    function IsBigWall: Boolean;
    function GetTerrainLevel: Integer;
    property Position: TPosition read FPos;
    function GetFootstepSound(TileBelow: TTile): Integer;
    function OpenDoor(Part: TTilePart; Unit: TBattleUnit = nil; Reserve: TBattleActionType = BA_NONE): Integer;
    function IsUfoDoorOpen(TP: TTilePart): Boolean;
    function CloseUfoDoor: Integer;
    procedure SetDiscovered(Flag: Boolean; Part: Integer);
    function IsDiscovered(Part: Integer): Boolean;
    procedure ResetLight(Layer: Integer);
    procedure AddLight(Light, Layer: Integer);
    function GetShade: Integer;
    function Destroy(Part: TTilePart; Type_: TSpecialTileType): Boolean;
    function Damage(Part: TTilePart; Power: Integer; Type_: TSpecialTileType): Boolean;
    procedure SetExplosive(Power, DamageType: Integer; Force: Boolean = False);
    function GetExplosive: Integer;
    function GetExplosiveType: Integer;
    function GetFlammability: Integer;
    function GetFuel: Integer;
    function GetFlammability(Part: TTilePart): Integer;
    function GetFuel(Part: TTilePart): Integer;
    procedure Ignite(Power: Integer);
    procedure Animate;
    function GetSprite(Part: Integer): TSurface;
    procedure SetUnit(Unit: TBattleUnit; TileBelow: TTile = nil);
    function GetUnit: TBattleUnit;
    property Fire: Integer read FFire write FFire;
    procedure AddSmoke(Smoke: Integer);
    procedure SetSmoke(Smoke: Integer);
    property Smoke: Integer read FSmoke;
    property AnimationOffset: Integer read FAnimationOffset;
    procedure AddItem(Item: TBattleItem; Ground: TRuleInventory);
    procedure RemoveItem(Item: TBattleItem);
    function GetTopItemSprite: Integer;
    procedure PrepareNewTurn(SmokeDamage: Boolean);
    property Inventory: TList<TBattleItem> read FInventory;
    property MarkerColor: Integer read FMarkerColor write FMarkerColor;
    property Visible: Integer read FVisible write FVisible;
    property Preview: Integer read FPreview write FPreview;
    property TUMarker: Integer read FTUMarker write FTUMarker;
    property Overlaps: Integer read FOverlaps;
    procedure AddOverlap;
    property Dangerous: Boolean read FDanger write FDanger;
    property ParticleCloud: TList<TParticle> read FParticles;
    procedure AddParticle(Particle: TParticle);
    procedure SetObstacle(Part: Integer);
    function GetObstacle(Part: Integer): Boolean;
    function IsObstacle: Boolean;
    procedure ResetObstacle;
  end;

implementation

class constructor TTile.CreateSerializationKey;
begin
  SerializationKey.Index := 4;
  SerializationKey._mapDataSetID := 2;
  SerializationKey._mapDataID := 2;
  SerializationKey._smoke := 1;
  SerializationKey._fire := 1;
  SerializationKey.boolFields := 1;
  SerializationKey.totalBytes := 4 + 2*4 + 2*4 + 1 + 1 + 1;
end;

constructor TTile.Create(Pos: TPosition);
begin
  FPos := Pos;
  FSmoke := 0;
  FFire := 0;
  FExplosive := 0;
  FExplosiveType := 0;
  FUnit := nil;
  FAnimationOffset := 0;
  FMarkerColor := 0;
  FVisible := 0;
  FPreview := -1;
  FTUMarker := -1;
  FOverlaps := 0;
  FDanger := False;
  FObstacle := 0;
  FInventory := TList<TBattleItem>.Create;
  FParticles := TList<TParticle>.Create;
  for var i := 0 to 3 do
  begin
    FObjects[i] := nil;
    FMapDataID[i] := -1;
    FMapDataSetID[i] := -1;
    FCurrentFrame[i] := 0;
  end;
  for var layer := 0 to LIGHTLAYERS-1 do
  begin
    FLight[layer] := 0;
    FLastLight[layer] := -1;
  end;
  for var i := 0 to 2 do
    FDiscovered[i] := False;
end;

destructor TTile.Destroy;
begin
  FInventory.Free;
  for var p in FParticles do p.Free;
  FParticles.Free;
  inherited;
end;

procedure TTile.Load(const Node: TYamlNode);
begin
  for var i := 0 to 3 do
  begin
    FMapDataID[i] := Node['mapDataID'][i].AsInteger(FMapDataID[i]);
    FMapDataSetID[i] := Node['mapDataSetID'][i].AsInteger(FMapDataSetID[i]);
  end;
  FFire := Node['fire'].AsInteger(FFire);
  FSmoke := Node['smoke'].AsInteger(FSmoke);
  if Node['discovered'] <> nil then
    for var i := 0 to 2 do
      FDiscovered[i] := Node['discovered'][i].AsBoolean;
  if Node['openDoorWest'] <> nil then
    FCurrentFrame[1] := 7;
  if Node['openDoorNorth'] <> nil then
    FCurrentFrame[2] := 7;
  if (FFire <> 0) or (FSmoke <> 0) then
    FAnimationOffset := Random(4);
end;

procedure TTile.LoadBinary(var Buffer: PByte; const SerKey: TTileSerializationKey);
begin
  for var i := 0 to 3 do
    FMapDataID[i] := UnserializeInt(Buffer, SerKey._mapDataID);
  for var i := 0 to 3 do
    FMapDataSetID[i] := UnserializeInt(Buffer, SerKey._mapDataSetID);
  FSmoke := UnserializeInt(Buffer, SerKey._smoke);
  FFire := UnserializeInt(Buffer, SerKey._fire);
  var boolFields := UnserializeInt(Buffer, SerKey.boolFields);
  FDiscovered[0] := (boolFields and 1) <> 0;
  FDiscovered[1] := (boolFields and 2) <> 0;
  FDiscovered[2] := (boolFields and 4) <> 0;
  FCurrentFrame[1] := IfThen((boolFields and 8) <> 0, 7, 0);
  FCurrentFrame[2] := IfThen((boolFields and $10) <> 0, 7, 0);
  if (FFire <> 0) or (FSmoke <> 0) then
    FAnimationOffset := Random(4);
end;

function TTile.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['position'] := FPos.ToYaml;
  for var i := 0 to 3 do
  begin
    Result['mapDataID'].Add(FMapDataID[i]);
    Result['mapDataSetID'].Add(FMapDataSetID[i]);
  end;
  if FSmoke <> 0 then Result['smoke'] := FSmoke;
  if FFire <> 0 then Result['fire'] := FFire;
  if FDiscovered[0] or FDiscovered[1] or FDiscovered[2] then
    for var i := 0 to 2 do
      Result['discovered'].Add(FDiscovered[i]);
  if IsUfoDoorOpen(O_WESTWALL) then
    Result['openDoorWest'] := True;
  if IsUfoDoorOpen(O_NORTHWALL) then
    Result['openDoorNorth'] := True;
end;

procedure TTile.SaveBinary(var Buffer: PByte);
begin
  for var i := 0 to 3 do
    SerializeInt(Buffer, SerializationKey._mapDataID, FMapDataID[i]);
  for var i := 0 to 3 do
    SerializeInt(Buffer, SerializationKey._mapDataSetID, FMapDataSetID[i]);
  SerializeInt(Buffer, SerializationKey._smoke, FSmoke);
  SerializeInt(Buffer, SerializationKey._fire, FFire);
  var boolFields := 0;
  if FDiscovered[0] then boolFields := boolFields or 1;
  if FDiscovered[1] then boolFields := boolFields or 2;
  if FDiscovered[2] then boolFields := boolFields or 4;
  if IsUfoDoorOpen(O_WESTWALL) then boolFields := boolFields or 8;
  if IsUfoDoorOpen(O_NORTHWALL) then boolFields := boolFields or $10;
  SerializeInt(Buffer, SerializationKey.boolFields, boolFields);
end;

function TTile.GetMapData(Part: TTilePart): TMapData;
begin
  Result := FObjects[Ord(Part)];
end;

procedure TTile.SetMapData(Dat: TMapData; MapDataID, MapDataSetID: Integer; Part: TTilePart);
begin
  FObjects[Ord(Part)] := Dat;
  FMapDataID[Ord(Part)] := MapDataID;
  FMapDataSetID[Ord(Part)] := MapDataSetID;
end;

procedure TTile.GetMapDataIDs(out MapDataID, MapDataSetID: Integer; Part: TTilePart);
begin
  MapDataID := FMapDataID[Ord(Part)];
  MapDataSetID := FMapDataSetID[Ord(Part)];
end;

function TTile.IsVoid: Boolean;
begin
  Result := (FObjects[0] = nil) and (FObjects[1] = nil) and (FObjects[2] = nil) and (FObjects[3] = nil) and (FSmoke = 0) and (FInventory.Count = 0);
end;

function TTile.GetTUCost(Part: Integer; MovementType: TMovementType): Integer;
begin
  if FObjects[Part] <> nil then
  begin
    if FObjects[Part].IsUFODoor and (FCurrentFrame[Part] > 1) then Exit(0);
    if (Part = Ord(O_OBJECT)) and (FObjects[Part].BigWall >= 4) then Exit(0);
    Result := FObjects[Part].GetTUCost(MovementType);
  end
  else Result := 0;
end;

function TTile.HasNoFloor(TileBelow: TTile): Boolean;
begin
  if (TileBelow <> nil) and (TileBelow.GetTerrainLevel = -24) then Exit(False);
  if FObjects[Ord(O_FLOOR)] <> nil then
    Result := FObjects[Ord(O_FLOOR)].IsNoFloor
  else
    Result := True;
end;

function TTile.IsBigWall: Boolean;
begin
  Result := (FObjects[Ord(O_OBJECT)] <> nil) and (FObjects[Ord(O_OBJECT)].BigWall <> 0);
end;

function TTile.GetTerrainLevel: Integer;
begin
  Result := 0;
  if FObjects[Ord(O_FLOOR)] <> nil then
    Result := FObjects[Ord(O_FLOOR)].TerrainLevel;
  if (FObjects[Ord(O_OBJECT)] <> nil) and (FObjects[Ord(O_OBJECT)].TerrainLevel < Result) then
    Result := FObjects[Ord(O_OBJECT)].TerrainLevel;
end;

function TTile.GetFootstepSound(TileBelow: TTile): Integer;
begin
  Result := -1;
  if FObjects[Ord(O_FLOOR)] <> nil then
    Result := FObjects[Ord(O_FLOOR)].FootstepSound;
  if (FObjects[Ord(O_OBJECT)] <> nil) and (FObjects[Ord(O_OBJECT)].BigWall <= 1) and (FObjects[Ord(O_OBJECT)].FootstepSound > -1) then
    Result := FObjects[Ord(O_OBJECT)].FootstepSound;
  if (FObjects[Ord(O_FLOOR)] = nil) and (FObjects[Ord(O_OBJECT)] = nil) and (TileBelow <> nil) and (TileBelow.GetTerrainLevel = -24) then
    Result := TileBelow.GetMapData(O_OBJECT).FootstepSound;
end;

function TTile.OpenDoor(Part: TTilePart; Unit: TBattleUnit; Reserve: TBattleActionType): Integer;
begin
  if FObjects[Ord(Part)] = nil then Exit(-1);
  if FObjects[Ord(Part)].IsDoor then
  begin
    if (Unit <> nil) and (Unit.Armor.Size > 1) then Exit(-1);
    if (Unit <> nil) and (Unit.TimeUnits < FObjects[Ord(Part)].GetTUCost(Unit.MovementType) + Unit.GetActionTUs(Reserve, Unit.GetMainHandWeapon(False))) then Exit(4);
    if (FUnit <> nil) and (FUnit <> Unit) and (FUnit.Position <> FPos) then Exit(-1);
    var altMCD := FObjects[Ord(Part)].AltMCD;
    var altObj := FObjects[Ord(Part)].Dataset.GetObject(altMCD);
    SetMapData(altObj, altMCD, FMapDataSetID[Ord(Part)], altObj.ObjectType);
    SetMapData(nil, -1, -1, Part);
    Exit(0);
  end;
  if FObjects[Ord(Part)].IsUFODoor and (FCurrentFrame[Ord(Part)] = 0) then
  begin
    if (Unit <> nil) and (Unit.TimeUnits < FObjects[Ord(Part)].GetTUCost(Unit.MovementType) + Unit.GetActionTUs(Reserve, Unit.GetMainHandWeapon(False))) then Exit(4);
    FCurrentFrame[Ord(Part)] := 1;
    Exit(1);
  end;
  if FObjects[Ord(Part)].IsUFODoor and (FCurrentFrame[Ord(Part)] <> 7) then Exit(3);
  Result := -1;
end;

function TTile.IsUfoDoorOpen(TP: TTilePart): Boolean;
begin
  var part := Ord(TP);
  Result := (FObjects[part] <> nil) and FObjects[part].IsUFODoor and (FCurrentFrame[part] <> 0);
end;

function TTile.CloseUfoDoor: Integer;
begin
  Result := 0;
  for var part := 0 to 3 do
    if IsUfoDoorOpen(TTilePart(part)) then
    begin
      FCurrentFrame[part] := 0;
      Result := 1;
    end;
end;

procedure TTile.SetDiscovered(Flag: Boolean; Part: Integer);
begin
  if FDiscovered[Part] <> Flag then
  begin
    FDiscovered[Part] := Flag;
    if (Part = 2) and Flag then
    begin
      FDiscovered[0] := True;
      FDiscovered[1] := True;
    end;
    if FUnit <> nil then
      FUnit.SetCache(nil);
  end;
end;

function TTile.IsDiscovered(Part: Integer): Boolean;
begin
  Result := FDiscovered[Part];
end;

procedure TTile.ResetLight(Layer: Integer);
begin
  FLight[Layer] := 0;
  FLastLight[Layer] := FLight[Layer];
end;

procedure TTile.AddLight(Light, Layer: Integer);
begin
  if FLight[Layer] < Light then
    FLight[Layer] := Light;
end;

function TTile.GetShade: Integer;
var
  light: Integer;
begin
  light := 0;
  for var layer := 0 to LIGHTLAYERS-1 do
    if FLight[layer] > light then
      light := FLight[layer];
  Result := Max(0, 15 - light);
end;

function TTile.Destroy(Part: TTilePart; Type_: TSpecialTileType): Boolean;
var
  originalPart: TMapData;
  originalMapDataSetID: Integer;
begin
  Result := False;
  if FObjects[Ord(Part)] = nil then Exit;
  if FObjects[Ord(Part)].IsGravLift then Exit(False);
  Result := FObjects[Ord(Part)].SpecialType = Type_;
  originalPart := FObjects[Ord(Part)];
  originalMapDataSetID := FMapDataSetID[Ord(Part)];
  SetMapData(nil, -1, -1, Part);
  if originalPart.DieMCD <> 0 then
  begin
    var dead := originalPart.Dataset.GetObject(originalPart.DieMCD);
    SetMapData(dead, originalPart.DieMCD, originalMapDataSetID, dead.ObjectType);
  end;
  if originalPart.Explosive <> 0 then
    SetExplosive(originalPart.Explosive, originalPart.ExplosiveType);
end;

function TTile.Damage(Part: TTilePart; Power: Integer; Type_: TSpecialTileType): Boolean;
begin
  Result := False;
  if (FObjects[Ord(Part)] <> nil) and (Power >= FObjects[Ord(Part)].Armor) then
    Result := Destroy(Part, Type_);
end;

procedure TTile.SetExplosive(Power, DamageType: Integer; Force: Boolean);
begin
  if Force or (FExplosive < Power) then
  begin
    FExplosive := Power;
    FExplosiveType := DamageType;
  end;
end;

function TTile.GetExplosive: Integer;
begin
  Result := FExplosive;
end;

function TTile.GetExplosiveType: Integer;
begin
  Result := FExplosiveType;
end;

function TTile.GetFlammability: Integer;
begin
  Result := 255;
  for var i := 0 to 3 do
    if (FObjects[i] <> nil) and (FObjects[i].Flammable < Result) then
      Result := FObjects[i].Flammable;
end;

function TTile.GetFuel: Integer;
begin
  Result := 0;
  for var i := 0 to 3 do
    if (FObjects[i] <> nil) and (FObjects[i].Fuel > Result) then
      Result := FObjects[i].Fuel;
end;

function TTile.GetFlammability(Part: TTilePart): Integer;
begin
  Result := FObjects[Ord(Part)].Flammable;
end;

function TTile.GetFuel(Part: TTilePart): Integer;
begin
  Result := FObjects[Ord(Part)].Fuel;
end;

procedure TTile.Ignite(Power: Integer);
begin
  if GetFlammability = 255 then Exit;
  Power := Power - (GetFlammability div 10) + 15;
  if Power < 0 then Power := 0;
  if RNG.Percent(Power) and (GetFuel > 0) then
  begin
    if FFire = 0 then
    begin
      FSmoke := 15 - Clamp(GetFlammability div 10, 1, 12);
      FOverlaps := 1;
      FFire := GetFuel + 1;
      FAnimationOffset := RNG.Generate(0,3);
    end;
  end;
end;

procedure TTile.Animate;
var
  newframe: Integer;
begin
  for var i := 0 to 3 do
  begin
    if FObjects[i] = nil then Continue;
    if FObjects[i].IsUFODoor and ((FCurrentFrame[i] = 0) or (FCurrentFrame[i] = 7)) then Continue;
    newframe := FCurrentFrame[i] + 1;
    if FObjects[i].IsUFODoor and (FObjects[i].SpecialType = START_POINT) and (newframe = 3) then
      newframe := 7;
    if newframe = 8 then newframe := 0;
    FCurrentFrame[i] := newframe;
  end;
  var i := FParticles.Count - 1;
  while i >= 0 do
  begin
    if not FParticles[i].Animate then
    begin
      FParticles[i].Free;
      FParticles.Delete(i);
    end;
    Dec(i);
  end;
end;

function TTile.GetSprite(Part: Integer): TSurface;
begin
  if FObjects[Part] = nil then Exit(nil);
  Result := FObjects[Part].Dataset.Surfaceset.GetFrame(FObjects[Part].GetSprite(FCurrentFrame[Part]));
end;

procedure TTile.SetUnit(Unit: TBattleUnit; TileBelow: TTile);
begin
  if Unit <> nil then
    Unit.SetTile(Self, TileBelow);
  FUnit := Unit;
end;

function TTile.GetUnit: TBattleUnit;
begin
  Result := FUnit;
end;

procedure TTile.AddSmoke(Smoke: Integer);
begin
  if FFire = 0 then
  begin
    if FOverlaps = 0 then
      FSmoke := Clamp(FSmoke + Smoke, 1, 15)
    else
      FSmoke := FSmoke + Smoke;
    FAnimationOffset := RNG.Generate(0,3);
    AddOverlap;
  end;
end;

procedure TTile.SetSmoke(Smoke: Integer);
begin
  FSmoke := Smoke;
  FAnimationOffset := RNG.Generate(0,3);
end;

procedure TTile.AddItem(Item: TBattleItem; Ground: TRuleInventory);
begin
  Item.Slot := Ground;
  FInventory.Add(Item);
  Item.Tile := Self;
end;

procedure TTile.RemoveItem(Item: TBattleItem);
begin
  FInventory.Remove(Item);
  Item.Tile := nil;
end;

function TTile.GetTopItemSprite: Integer;
var
  biggestWeight, biggestItem: Integer;
begin
  biggestWeight := -1;
  biggestItem := -1;
  for var item in FInventory do
    if item.Rules.Weight > biggestWeight then
    begin
      biggestWeight := item.Rules.Weight;
      biggestItem := item.Rules.FloorSprite;
    end;
  Result := biggestItem;
end;

procedure TTile.PrepareNewTurn(SmokeDamage: Boolean);
begin
  if (FOverlaps <> 0) and (FSmoke <> 0) and (FFire = 0) then
    FSmoke := Clamp((FSmoke div FOverlaps) - 1, 0, 15);
  if FSmoke <> 0 then
  begin
    if (FUnit <> nil) and not FUnit.IsOut then
    begin
      if FFire <> 0 then
      begin
        if ((FUnit.Armor.Size = 1) or not FUnit.TookFireDamage) and
           (FUnit.SpecialAbility <> Ord(SPECAB_BURNFLOOR)) and (FUnit.SpecialAbility <> Ord(SPECAB_BURN_AND_EXPLODE)) then
        begin
          FUnit.ToggleFireDamage;
          FUnit.Damage(Position.Create(0,0,0), FSmoke, DT_IN, True);
          if RNG.Percent(Round(40 * FUnit.Armor.GetDamageModifier(DT_IN))) then
          begin
            var burnTime := RNG.Generate(0, Round(5.0 * FUnit.Armor.GetDamageModifier(DT_IN)));
            if FUnit.Fire < burnTime then
              FUnit.Fire := burnTime;
          end;
        end;
      end
      else if SmokeDamage and (FUnit.Armor.GetDamageModifier(DT_SMOKE) > 0) and (FUnit.Armor.Size = 1) then
        FUnit.Damage(Position.Create(0,0,0), (FSmoke div 4) + 1, DT_SMOKE, True);
    end;
  end;
  FOverlaps := 0;
end;

procedure TTile.AddOverlap;
begin
  Inc(FOverlaps);
end;

procedure TTile.AddParticle(Particle: TParticle);
begin
  FParticles.Add(Particle);
end;

procedure TTile.SetObstacle(Part: Integer);
begin
  FObstacle := FObstacle or (1 shl Part);
end;

function TTile.GetObstacle(Part: Integer): Boolean;
begin
  Result := (FObstacle and (1 shl Part)) <> 0;
end;

function TTile.IsObstacle: Boolean;
begin
  Result := FObstacle <> 0;
end;

procedure TTile.ResetObstacle;
begin
  FObstacle := 0;
end;

end.