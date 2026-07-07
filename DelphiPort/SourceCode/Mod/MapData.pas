unit MapData;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  MapDataSet, RuleItem;

type
  TSpecialTileType = (stTile, stStartPoint, stUfoPowerSource, stUfoNavigation,
                      stUfoConstruction, stAlienFood, stAlienReproduction,
                      stAlienEntertainment, stAlienSurgery, stExamRoom,
                      stAlienAlloys, stAlienHabitat, stDeadTile, stEndPoint,
                      stMustDestroy);

  TMovementType = (mtWalk, mtFly, mtSlide, mtFloat, mtSink);
  TVoxelType = (vtEmpty, vtFloor, vtWestWall, vtNorthWall, vtObject, vtUnit, vtOutOfBounds);
  TTilePart = (tpFloor, tpWestWall, tpNorthWall, tpObject);

  TMapData = class
  private
    FDataset: TMapDataSet;
    FSpecialType: TSpecialTileType;
    FIsUfoDoor: Boolean;
    FStopLOS: Boolean;
    FIsNoFloor: Boolean;
    FIsGravLift: Boolean;
    FIsDoor: Boolean;
    FBlockFire: Boolean;
    FBlockSmoke: Boolean;
    FBaseModule: Boolean;
    FYOffset: Integer;
    FTUWalk: Integer;
    FTUFly: Integer;
    FTUSlide: Integer;
    FTerrainLevel: Integer;
    FFootstepSound: Integer;
    FDieMCD: Integer;
    FAltMCD: Integer;
    FObjectType: TTilePart;
    FLightSource: Integer;
    FArmor: Integer;
    FFlammable: Integer;
    FFuel: Integer;
    FExplosive: Integer;
    FExplosiveType: Integer;
    FBigWall: Integer;
    FSprite: array[0..7] of Integer;
    FBlock: array[0..5] of Integer;
    FLoftID: array[0..11] of Integer;
    FMiniMapIndex: Word;
  public
    const O_DUMMY = 999;
    constructor Create(ADataset: TMapDataSet);
    destructor Destroy; override;
    function GetDataset: TMapDataSet;
    function GetSprite(FrameID: Integer): Integer;
    procedure SetSprite(FrameID, Value: Integer);
    function IsUFODoor: Boolean;
    function IsNoFloor: Boolean;
    function GetBigWall: Integer;
    function IsDoor: Boolean;
    function IsGravLift: Boolean;
    procedure SetFlags(IsUfoDoor, StopLOS, NoFloor: Boolean; BigWall: Integer; IsGravLift, IsDoor, BlockFire, BlockSmoke, BaseModule: Boolean);
    function GetBlock(DT: TItemDamageType): Integer;
    procedure SetBlockValue(LightBlock, VisionBlock, HEBlock, SmokeBlock, FireBlock, GasBlock: Integer);
    procedure SetHEBlock(HEBlock: Integer);
    function GetYOffset: Integer;
    procedure SetYOffset(Value: Integer);
    procedure SetObjectType(AType: TTilePart);
    function GetObjectType: TTilePart;
    function GetSpecialType: TSpecialTileType;
    procedure SetSpecialType(Value: Integer; OType: TTilePart);
    function GetTUCost(MovementType: TMovementType): Integer;
    procedure SetTUCosts(Walk, Fly, Slide: Integer);
    function GetTerrainLevel: Integer;
    procedure SetTerrainLevel(Value: Integer);
    function GetFootstepSound: Integer;
    procedure SetFootstepSound(Value: Integer);
    function GetAltMCD: Integer;
    procedure SetAltMCD(Value: Integer);
    function GetDieMCD: Integer;
    procedure SetDieMCD(Value: Integer);
    function GetLightSource: Integer;
    procedure SetLightSource(Value: Integer);
    function GetArmor: Integer;
    procedure SetArmor(Value: Integer);
    function GetFlammable: Integer;
    procedure SetFlammable(Value: Integer);
    function GetFuel: Integer;
    procedure SetFuel(Value: Integer);
    function GetLoftID(Layer: Integer): Integer;
    procedure SetLoftID(ALoft, Layer: Integer);
    function GetExplosive: Integer;
    procedure SetExplosive(Value: Integer);
    function GetExplosiveType: Integer;
    procedure SetExplosiveType(Value: Integer);
    procedure SetMiniMapIndex(AIndex: Word);
    function GetMiniMapIndex: Word;
    procedure SetBigWall(Value: Integer);
    procedure SetTUWalk(Value: Integer);
    procedure SetTUFly(Value: Integer);
    procedure SetTUSlide(Value: Integer);
    function IsBaseModule: Boolean;
    procedure SetNoFloor(Value: Boolean);
    procedure SetStopLOS(Value: Boolean);
  end;

implementation

{ TMapData }

constructor TMapData.Create(ADataset: TMapDataSet);
begin
  inherited Create;
  FDataset := ADataset;
  FSpecialType := stTile;
  FIsUfoDoor := False; FStopLOS := False; FIsNoFloor := False; FIsGravLift := False;
  FIsDoor := False; FBlockFire := False; FBlockSmoke := False; FBaseModule := False;
  FYOffset := 0; FTUWalk := 0; FTUFly := 0; FTUSlide := 0; FTerrainLevel := 0;
  FFootstepSound := 0; FDieMCD := 0; FAltMCD := 0; FObjectType := tpFloor;
  FLightSource := 0; FArmor := 0; FFlammable := 0; FFuel := 0; FExplosive := 0;
  FExplosiveType := 0; FBigWall := 0; FMiniMapIndex := 0;
  FillChar(FSprite, SizeOf(FSprite), 0);
  FillChar(FBlock, SizeOf(FBlock), 0);
  FillChar(FLoftID, SizeOf(FLoftID), 0);
end;

destructor TMapData.Destroy;
begin
  inherited;
end;

function TMapData.GetDataset: TMapDataSet;
begin
  Result := FDataset;
end;

function TMapData.GetSprite(FrameID: Integer): Integer;
begin
  Result := FSprite[FrameID];
end;

procedure TMapData.SetSprite(FrameID, Value: Integer);
begin
  FSprite[FrameID] := Value;
end;

function TMapData.IsUFODoor: Boolean;
begin
  Result := FIsUfoDoor;
end;

function TMapData.IsNoFloor: Boolean;
begin
  Result := FIsNoFloor;
end;

function TMapData.GetBigWall: Integer;
begin
  Result := FBigWall;
end;

function TMapData.IsDoor: Boolean;
begin
  Result := FIsDoor;
end;

function TMapData.IsGravLift: Boolean;
begin
  Result := FIsGravLift;
end;

procedure TMapData.SetFlags(IsUfoDoor, StopLOS, NoFloor: Boolean; BigWall: Integer;
  IsGravLift, IsDoor, BlockFire, BlockSmoke, BaseModule: Boolean);
begin
  FIsUfoDoor := IsUfoDoor;
  FStopLOS := StopLOS;
  FIsNoFloor := NoFloor;
  FBigWall := BigWall;
  FIsGravLift := IsGravLift;
  FIsDoor := IsDoor;
  FBlockFire := BlockFire;
  FBlockSmoke := BlockSmoke;
  FBaseModule := BaseModule;
end;

function TMapData.GetBlock(DT: TItemDamageType): Integer;
begin
  case DT of
    dtNone: Result := FBlock[1];
    dtSmoke: Result := FBlock[3];
    dtHe, dtIn, dtStun: Result := FBlock[2];
  else
    Result := 0;
  end;
end;

procedure TMapData.SetBlockValue(LightBlock, VisionBlock, HEBlock, SmokeBlock, FireBlock, GasBlock: Integer);
begin
  FBlock[0] := LightBlock;
  FBlock[1] := IfThen(VisionBlock = 1, 255, 0);
  FBlock[2] := HEBlock;
  FBlock[3] := IfThen(SmokeBlock = 1, 256, 0);
  FBlock[4] := FireBlock;
  FBlock[5] := GasBlock;
end;

procedure TMapData.SetHEBlock(HEBlock: Integer);
begin
  FBlock[2] := HEBlock;
end;

function TMapData.GetYOffset: Integer;
begin
  Result := FYOffset;
end;

procedure TMapData.SetYOffset(Value: Integer);
begin
  FYOffset := Value;
end;

procedure TMapData.SetObjectType(AType: TTilePart);
begin
  FObjectType := AType;
end;

function TMapData.GetObjectType: TTilePart;
begin
  Result := FObjectType;
end;

function TMapData.GetSpecialType: TSpecialTileType;
begin
  Result := FSpecialType;
end;

procedure TMapData.SetSpecialType(Value: Integer; OType: TTilePart);
begin
  FSpecialType := TSpecialTileType(Value);
  FObjectType := OType;
end;

function TMapData.GetTUCost(MovementType: TMovementType): Integer;
begin
  case MovementType of
    mtWalk: Result := FTUWalk;
    mtFly: Result := FTUFly;
    mtSlide: Result := FTUSlide;
  else
    Result := 0;
  end;
end;

procedure TMapData.SetTUCosts(Walk, Fly, Slide: Integer);
begin
  FTUWalk := Walk;
  FTUFly := Fly;
  FTUSlide := Slide;
end;

function TMapData.GetTerrainLevel: Integer;
begin
  Result := FTerrainLevel;
end;

procedure TMapData.SetTerrainLevel(Value: Integer);
begin
  FTerrainLevel := Value;
end;

function TMapData.GetFootstepSound: Integer;
begin
  Result := FFootstepSound;
end;

procedure TMapData.SetFootstepSound(Value: Integer);
begin
  FFootstepSound := Value;
end;

function TMapData.GetAltMCD: Integer;
begin
  Result := FAltMCD;
end;

procedure TMapData.SetAltMCD(Value: Integer);
begin
  FAltMCD := Value;
end;

function TMapData.GetDieMCD: Integer;
begin
  Result := FDieMCD;
end;

procedure TMapData.SetDieMCD(Value: Integer);
begin
  FDieMCD := Value;
end;

function TMapData.GetLightSource: Integer;
begin
  if FLightSource = 1 then
    Result := 15
  else
    Result := FLightSource - 1;
end;

procedure TMapData.SetLightSource(Value: Integer);
begin
  FLightSource := Value;
end;

function TMapData.GetArmor: Integer;
begin
  Result := FArmor;
end;

procedure TMapData.SetArmor(Value: Integer);
begin
  FArmor := Value;
end;

function TMapData.GetFlammable: Integer;
begin
  Result := FFlammable;
end;

procedure TMapData.SetFlammable(Value: Integer);
begin
  FFlammable := Value;
end;

function TMapData.GetFuel: Integer;
begin
  Result := FFuel;
end;

procedure TMapData.SetFuel(Value: Integer);
begin
  FFuel := Value;
end;

function TMapData.GetLoftID(Layer: Integer): Integer;
begin
  Result := FLoftID[Layer];
end;

procedure TMapData.SetLoftID(ALoft, Layer: Integer);
begin
  FLoftID[Layer] := ALoft;
end;

function TMapData.GetExplosive: Integer;
begin
  Result := FExplosive;
end;

procedure TMapData.SetExplosive(Value: Integer);
begin
  FExplosive := Value;
end;

function TMapData.GetExplosiveType: Integer;
begin
  Result := FExplosiveType;
end;

procedure TMapData.SetExplosiveType(Value: Integer);
begin
  FExplosiveType := Value;
end;

procedure TMapData.SetMiniMapIndex(AIndex: Word);
begin
  FMiniMapIndex := AIndex;
end;

function TMapData.GetMiniMapIndex: Word;
begin
  Result := FMiniMapIndex;
end;

procedure TMapData.SetBigWall(Value: Integer);
begin
  FBigWall := Value;
end;

procedure TMapData.SetTUWalk(Value: Integer);
begin
  FTUWalk := Value;
end;

procedure TMapData.SetTUFly(Value: Integer);
begin
  FTUFly := Value;
end;

procedure TMapData.SetTUSlide(Value: Integer);
begin
  FTUSlide := Value;
end;

function TMapData.IsBaseModule: Boolean;
begin
  Result := FBaseModule;
end;

procedure TMapData.SetNoFloor(Value: Boolean);
begin
  FIsNoFloor := Value;
end;

procedure TMapData.SetStopLOS(Value: Boolean);
begin
  FStopLOS := Value;
  FBlock[1] := IfThen(Value, 255, 0);
end;

end.